import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'package:jyotishasha_app/core/notifications/notification_dispatcher.dart';

/// A single queued navigation request, awaiting a router that is safely
/// ready to act on it.
///
/// Deliberately decoupled from [NotificationDispatchDestination]: it only
/// needs a route and an optional extra payload, so any future navigation
/// source — a deep link, a dynamic link, a second notification tap arriving
/// before the first is consumed — can be queued the same way without any
/// change to [NotificationNavigationService] itself.
final class PendingNavigation {
  const PendingNavigation({required this.route, this.extra});

  final String route;
  final Object? extra;
}

/// Single owner of "where does a notification tap take the user, and how do
/// we get there safely." No screen — Dashboard, Splash, Login,
/// EventDispatcherPage, or any future destination screen — contains any of
/// this logic; they are only ever navigated *to*, never responsible for
/// deciding how they were reached.
///
/// Guarantees one invariant regardless of entry mode (cold start,
/// background, foreground): the resulting navigation stack is always
/// exactly `[/dashboard, <destination route>]` — identical to the stack
/// produced by the in-app bell → notification list tap path. It does this
/// by never calling into the router before the app has proven it is safely
/// past its own startup/auth-gate sequence (i.e. has reached `/dashboard`
/// at least once this session); a tap that arrives before that point is
/// queued rather than raced against `runApp()` — the defect identified in
/// BUG-009, where a raw `appRouter.push('/event', ...)` could land with no
/// guaranteed screen beneath it.
///
/// Generic by construction: this class never hardcodes EventDispatcherPage
/// or `/event` into its navigation mechanism — [openDestination] always
/// pushes whatever route the supplied destination resolves to via
/// [_resolveRoute]. `/event` appears in exactly one place, as today's only
/// registered fallback destination handler; a future destination type
/// (report, transit, panchang, blog, subscription, or a deep/dynamic link)
/// only needs to carry its own route to be handled with zero changes to
/// this class.
final class NotificationNavigationService {
  NotificationNavigationService({required GoRouter router}) : _router = router;

  static const String _dashboardRoute = '/dashboard';

  /// Fallback target for destinations that don't specify their own
  /// [NotificationDispatchDestination.route] — true of every destination
  /// [NotificationDispatcher] parses today, since `/event` is currently the
  /// only registered handler for a notification/event tap. This is not an
  /// assumption baked into the navigation mechanism itself: any
  /// destination that carries its own `route` bypasses this entirely.
  static const String _defaultDestinationRoute = '/event';

  final GoRouter _router;
  final Queue<PendingNavigation> _queue = Queue<PendingNavigation>();

  bool _started = false;
  bool _dashboardReached = false;
  bool _draining = false;

  /// Starts observing the router for its first arrival at `/dashboard`.
  /// Call once, at app startup, independent of whether a notification has
  /// actually been tapped yet — mirrors [FcmTokenManager.start]'s
  /// application-level, UI-independent lifecycle.
  void start() {
    if (_started) return;
    _started = true;
    _router.routerDelegate.addListener(_onRouterChanged);
    // Covers the (rare) case where /dashboard is already the current
    // location by the time start() runs, e.g. a hot restart in debug —
    // otherwise this only ever fires from the listener below.
    _onRouterChanged();
  }

  /// Single entry point for every notification-destined navigation,
  /// regardless of source (FCM tap today; Notification Center tap or a
  /// deep/dynamic link in future). Never navigates directly — always goes
  /// through the same ready/queue decision, so every caller gets the
  /// identical stack guarantee.
  void openDestination(NotificationDispatchDestination destination) {
    final navigation = PendingNavigation(
      route: _resolveRoute(destination),
      extra: destination,
    );

    if (_dashboardReached) {
      _resetToDashboard();
      _push(navigation);
    } else {
      _queue.add(navigation);
    }
  }

  String _resolveRoute(NotificationDispatchDestination destination) {
    return destination.route ?? _defaultDestinationRoute;
  }

  void _onRouterChanged() {
    // _draining guards against the reentrant call that _drainQueue's own
    // _resetToDashboard()/_push() calls trigger (they notify this same
    // listener synchronously, mid-drain) — without it, a drain in progress
    // would recurse into itself.
    if (_dashboardReached || _draining) return;

    final currentPath = _router.routerDelegate.currentConfiguration.uri.path;
    if (currentPath != _dashboardRoute) return;

    _drainQueue();
  }

  /// Drains the queue exactly once it's safe to do so — but only ever
  /// commits to [_dashboardReached] on a fully successful pass. If
  /// [_resetToDashboard] (or, defensively, a push) throws, the exception is
  /// swallowed here rather than left to propagate into a
  /// [ChangeNotifier] listener callback, [_dashboardReached] is left
  /// exactly as it was, and every item that had not yet been removed from
  /// [_queue] is still sitting in it — so the very next time the router
  /// settles on `/dashboard` (or the app is otherwise navigated), this
  /// method runs again and gets another chance. The queue can therefore
  /// never be marked "drained" without actually having been drained, which
  /// is what makes a permanent, unrecoverable stall impossible.
  void _drainQueue() {
    if (_queue.isEmpty) {
      _dashboardReached = true;
      return;
    }

    _draining = true;
    try {
      _resetToDashboard();
      while (_queue.isNotEmpty) {
        _push(_queue.removeFirst());
      }
      _dashboardReached = true;
    } catch (e, stackTrace) {
      debugPrint('[NotificationNavigationService] drain failed, queue preserved for retry: $e');
      debugPrint('[NotificationNavigationService] stack trace:\n$stackTrace');
    } finally {
      _draining = false;
    }
  }

  void _resetToDashboard() => _router.go(_dashboardRoute);

  void _push(PendingNavigation navigation) =>
      _router.push(navigation.route, extra: navigation.extra);

  /// Stops observing the router. Not currently called anywhere — this
  /// service is intended to live for the app's full process lifetime, like
  /// the other top-level singletons in `main.dart` — but is provided for
  /// completeness/testability.
  void dispose() {
    _router.routerDelegate.removeListener(_onRouterChanged);
  }
}
