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
/// [_resolveRoute]. A future destination type only needs to carry its own
/// `route` (bypassing [_resolveRoute]'s fallback entirely) to be handled
/// with zero changes to this class.
///
/// N1 (navigation reliability): no backend payload ever sends an explicit
/// `route`, so [_resolveRoute] previously defaulted EVERY destination to
/// `/event` — including Personalized Alerts (semantic catalog ids like
/// `"mood_positive"`) and Dasha/Dasha-pre (composite ids like
/// `"dasha_pre_{uid}_{maha}_{antar}"`), neither of which `EventDispatcherPage`
/// can resolve (it does, and must keep doing, `int.tryParse(eventId)` — see
/// its own docstring) — landing both on a "No data available" dead end.
///
/// N1.1 (contract hardening): [_resolveRoute]'s decision is now based
/// SOLELY on [NotificationDispatchDestination.type] — the backend's own
/// authoritative discriminator for what kind of notification this is —
/// never on whether `eventId` happens to look numeric. `eventId` is
/// payload data ([_astroEventBackedTypes]'s destinations still use it to
/// fetch by id; [_notificationDetailRoute]'s destinations still show it as
/// context) but it plays no role in ROUTING itself any more: a future
/// type that happens to carry a numeric-looking id must not "accidentally"
/// resolve to `/event` just because `int.tryParse` would succeed on it —
/// only a recognized AstroEvent-backed `type` does. `event`/`transit`/
/// `panchang`/`panchak` resolve to `/event` exactly as before; a malformed
/// or missing `eventId` on one of THOSE types still fails safely, because
/// `EventDispatcherPage` itself already guards `int.tryParse(eventId) ==
/// null` before ever calling its repository (unchanged, untouched by N1.1)
/// — the safety net for a bad id lives there, not in this routing decision.
final class NotificationNavigationService {
  NotificationNavigationService({required GoRouter router}) : _router = router;

  static const String _dashboardRoute = '/dashboard';

  /// Destination for a [NotificationDispatchDestination] whose `type` is
  /// backed by a real AstroEvent row fetchable by integer id — `event`,
  /// `panchang`, `panchak` today. `transit` moved to [_transitArticleRoute]
  /// in N3 — see that field's own docstring.
  static const String _eventRoute = '/event';

  /// N3 — destination for `type: "transit"` (Personalized Planetary Transit,
  /// T-1). Unlike `event`/`panchang`/`panchak`, a transit notification's
  /// real destination is not a re-fetched AstroEvent resource but the
  /// specific Planet-in-House article the backend already resolved for this
  /// user's own house + language and sent directly in the payload
  /// (`data.url` — see `services/notification_builder.py::
  /// build_transit_content()`). Routed to its own page
  /// ([TransitArticlePage]) rather than `/event` so `EventDispatcherPage`
  /// never has to special-case a payload-carried URL it was never built to
  /// use.
  static const String _transitArticleRoute = '/transit-article';

  /// Destination for every OTHER `type` with no explicit `route`:
  /// Personalized Alerts (`alert`), Dasha/Dasha-pre (`dasha`/`dasha_pre`),
  /// a missing `type`, or any future/unrecognized `type` — as long as SOME
  /// renderable content (`title`/`body`) came through, this is a real
  /// destination, not a dead end. Added by N1, driven by `type` since N1.1
  /// (see [_astroEventBackedTypes]).
  static const String _notificationDetailRoute = '/notification-detail';

  /// N1.1 — the complete, authoritative set of `type` values backed by a
  /// real AstroEvent row (see `services/notification_builder.py` and
  /// `services/event_scheduler.py` in the backend: EVENT/DASHA T-5/
  /// DASHA-start/PANCHAK/PANCHANG sections). Deliberately NOT derived
  /// from `eventId`'s shape any more — this is the one, explicit place
  /// that set is declared, so it can never silently grow to match
  /// whatever a numeric-looking id happens to be. `transit` was removed in
  /// N3 (see [_transitArticleRoute]) — it is still AstroEvent-backed
  /// server-side, but its Flutter destination is no longer
  /// `EventDispatcherPage`.
  static const Set<String> _astroEventBackedTypes = {
    'event',
    'panchang',
    'panchak',
  };

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
    final explicitRoute = destination.route;
    if (explicitRoute != null) return explicitRoute;

    if (destination.type == 'transit') return _transitArticleRoute;

    return _astroEventBackedTypes.contains(destination.type)
        ? _eventRoute
        : _notificationDetailRoute;
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
      debugPrint(
        '[NotificationNavigationService] drain failed, queue preserved for retry: $e',
      );
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
