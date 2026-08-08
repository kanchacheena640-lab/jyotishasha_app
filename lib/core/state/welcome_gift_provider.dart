import 'package:flutter/foundation.dart';

import 'package:jyotishasha_app/core/repositories/implementations/local_welcome_gift_repository.dart';
import 'package:jyotishasha_app/core/repositories/welcome_gift_repository.dart';

/// Drives the Welcome Gift onboarding flow's visibility + claim state.
///
/// [isClaimed] is the single source of truth both the Home Hero (Welcome
/// Gift card) and the Welcome Gift screen read: once true, the card must
/// never show again anywhere. Backed by [WelcomeGiftRepository] — local
/// only for this task via [LocalWelcomeGiftRepository], swappable for a
/// backend-backed implementation later (see that class's TODO) with no
/// changes to this provider's public shape or to any UI widget.
class WelcomeGiftProvider extends ChangeNotifier {
  WelcomeGiftProvider({WelcomeGiftRepository? repository})
    : _repository = repository ?? LocalWelcomeGiftRepository();

  final WelcomeGiftRepository _repository;

  /// Starts `false`/loading so the Home Hero never flashes the card for a
  /// user who already claimed it before the stored flag has been read.
  bool isClaimed = false;
  bool isLoading = true;

  /// True only while [claim] is in flight — lets the Welcome Gift screen
  /// disable its button and show a spinner, same shape as
  /// `SubscriptionProvider.isPurchasing`/`isRestoring`.
  bool isClaiming = false;

  /// Loads the claimed flag once — call from Home's init so the card's
  /// visibility is decided before the user can interact with it.
  Future<void> loadStatus() async {
    isClaimed = await _repository.isClaimed();
    isLoading = false;
    notifyListeners();
  }

  /// "Claim Free Access" — for this task, this only simulates activation:
  /// it marks the gift as claimed locally. It does not generate reports,
  /// activate a subscription, or call the backend.
  ///
  /// TODO(backend): once a real Welcome Gift activation endpoint exists,
  /// call it here first (server-side: grant the 5 reports + 15-day
  /// premium membership) and only mark [isClaimed] once that call
  /// succeeds — mirroring how `SubscriptionProvider` confirms a purchase
  /// with the backend before updating local state, so the backend stays
  /// the source of truth for entitlements here too.
  Future<void> claim() async {
    if (isClaiming) return;
    isClaiming = true;
    notifyListeners();

    try {
      // TODO(backend): replace this local-only write with a real backend
      // activation call once available; keep marking [_repository] only
      // after that call succeeds.
      await _repository.markClaimed();
      isClaimed = true;
    } finally {
      isClaiming = false;
      notifyListeners();
    }
  }
}
