// lib/features/subscription/subscription_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:jyotishasha_app/core/constants/app_colors.dart';
import 'package:jyotishasha_app/core/constants/subscription_sections.dart';
import 'package:jyotishasha_app/core/models/asknow/asknow_contracts.dart';
import 'package:jyotishasha_app/core/state/language_provider.dart';
import 'package:jyotishasha_app/core/state/subscription_provider.dart';

/// S5.1 status foundation + S5.2 Google Play purchase flow + S5.4
/// Restore Purchases + premium pricing redesign. `GET
/// /api/profile/subscription-info` remains the only source of truth for
/// the status shown — every value here is exactly what the backend
/// returned, never inferred client-side, before or after a purchase or a
/// restore. Purchase/restore/confirm logic, [SubscriptionProvider],
/// [BillingRepository]/[PlayBillingRepository], and the backend are all
/// unchanged by the redesign below — this file only changes how the same
/// data and the same actions are presented.
///
/// Deliberately out of scope (per spec): Apple IAP.
class SubscriptionPage extends StatefulWidget {
  /// Whether to automatically trigger a load on mount. Defaults to
  /// `true` (real production behavior, matching `KundaliOverviewPage`'s
  /// identical `autoLoad` parameter); set to `false` only to
  /// deterministically test the loading/error/empty states without
  /// racing a real fetch attempt.
  final bool autoLoad;

  const SubscriptionPage({super.key, this.autoLoad = true});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  /// Tracks the last purchase-error already shown as a SnackBar, so a
  /// rebuild (e.g. from the status refresh after a successful purchase)
  /// never re-shows a stale message.
  String? _lastShownPurchaseError;

  /// Same de-duplication, for [SubscriptionProvider.restoreErrorMessage]
  /// — a separate field since Subscribe and Restore are independent
  /// actions, but the same [_purchaseErrorText] mapper is reused for
  /// both (no duplicated error-copy logic).
  String? _lastShownRestoreError;

  @override
  void initState() {
    super.initState();
    if (widget.autoLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = context.read<SubscriptionProvider>();
        provider.loadSubscriptionInfo();
        provider.loadAvailableProducts();
      });
    }
  }

  Future<void> _load() async {
    await context.read<SubscriptionProvider>().loadSubscriptionInfo();
  }

  String _purchaseErrorText(String code, bool isHindi) {
    switch (code) {
      case 'cancelled':
        return isHindi ? 'भुगतान रद्द कर दिया गया।' : 'Purchase cancelled.';
      case 'billing_unavailable':
        return isHindi
            ? 'इस डिवाइस पर Google Play Billing उपलब्ध नहीं है।'
            : 'Google Play Billing is not available on this device.';
      case 'segment_required':
        // Defensive: the section-selection sheet always supplies a
        // valid selection or never calls subscribeToPlan at all, so
        // this should not be reachable through the UI — kept for
        // completeness/any future caller of subscribeToPlan.
        return isHindi
            ? 'कृपया आगे बढ़ने से पहले एक सेक्शन चुनें।'
            : 'Please choose a section before continuing.';
      case 'product_not_found':
        return isHindi
            ? 'सब्सक्रिप्शन प्रोडक्ट नहीं मिला।'
            : 'Subscription product not found.';
      case 'auth_failed':
        return isHindi
            ? 'प्रमाणीकरण विफल रहा। कृपया पुनः लॉगिन करें।'
            : 'Authentication failed. Please sign in again.';
      case 'backend_confirmation_failed':
        return isHindi
            ? 'हम आपकी खरीद की पुष्टि नहीं कर सके। यदि आपसे शुल्क लिया गया है, तो कृपया सहायता से संपर्क करें।'
            : "We couldn't confirm your purchase with our server. If you "
                  'were charged, please contact support.';
      case 'purchase_failed':
        return isHindi
            ? 'भुगतान विफल रहा। कृपया पुनः प्रयास करें।'
            : 'Purchase failed. Please try again.';
      case 'no_purchases_found':
        return isHindi
            ? 'इस अकाउंट से कोई सक्रिय खरीद नहीं मिली।'
            : 'No active purchases were found for this account.';
      case 'activation_pending':
        return isHindi
            ? 'भुगतान प्राप्त हो गया है। आपकी सदस्यता सक्रिय होने की प्रक्रिया में है — कृपया थोड़ी देर बाद देखें।'
            : 'Payment received. Your subscription is being activated — '
                  'please check back shortly.';
      case 'activation_incomplete':
        return isHindi
            ? 'भुगतान प्राप्त हो गया, लेकिन हम आपकी सदस्यता सक्रिय नहीं कर सके। कृपया सहायता से संपर्क करें।'
            : "Payment received, but we couldn't activate your "
                  'subscription. Please contact support.';
      default:
        // A raw Play error message or a caught network exception's
        // toString() — shown as-is rather than swallowed.
        return code;
    }
  }

  /// Shows the current [SubscriptionProvider.purchaseErrorMessage] as a
  /// SnackBar exactly once per new message — never leaves it silently
  /// unsurfaced, never repeats it on unrelated rebuilds.
  void _maybeShowPurchaseError(SubscriptionProvider provider, bool isHindi) {
    final message = provider.purchaseErrorMessage;
    if (message == null || message == _lastShownPurchaseError) return;

    _lastShownPurchaseError = message;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(_purchaseErrorText(message, isHindi))),
        );
    });
  }

  /// Same pattern as [_maybeShowPurchaseError], for a Restore Purchases
  /// attempt. A successful restore needs no separate toast — the status
  /// card above already reflects it once `subscriptionData` refreshes.
  void _maybeShowRestoreError(SubscriptionProvider provider, bool isHindi) {
    final message = provider.restoreErrorMessage;
    if (message == null || message == _lastShownRestoreError) return;

    _lastShownRestoreError = message;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(_purchaseErrorText(message, isHindi))),
        );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = context.watch<LanguageProvider>().currentLang == 'hi';
    final provider = context.watch<SubscriptionProvider>();

    _maybeShowPurchaseError(provider, isHindi);
    _maybeShowRestoreError(provider, isHindi);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF9F6),
        elevation: 0,
        centerTitle: true,
        foregroundColor: const Color(0xFF1F1B2E),
        title: Text(
          isHindi ? 'सब्सक्रिप्शन प्लान' : 'Subscription Plans',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(child: _buildBody(provider, isHindi)),
    );
  }

  Widget _buildBody(SubscriptionProvider provider, bool isHindi) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null) {
      return _StatusMessage(
        icon: Icons.error_outline_rounded,
        message: isHindi
            ? 'सब्सक्रिप्शन जानकारी लोड करने में समस्या हुई।'
            : 'Something went wrong loading your subscription.',
        onRetry: _load,
        isHindi: isHindi,
      );
    }

    final data = provider.subscriptionData;
    // Backend's own `active`/`is_active` field only — not a client-side
    // inference.
    final isActive = data?['active'] == true || data?['is_active'] == true;
    // Google Play Confirm Contract fix: `isActive` alone is true for
    // BOTH an active trial AND a real paid subscription (the backend's
    // is_active is intentionally trial-inclusive — see membership_state's
    // own docstring). "Manage in Play Store" only makes sense for a
    // genuine Google Play membership, which is exactly what
    // membership_state's first-class ACTIVE/GRACE_PERIOD values mean —
    // never inferred from is_active/is_trial booleans, matching how
    // premium_gate.dart/_MembershipStrip already prefer membership_state
    // over those legacy fields.
    final membershipState = data?['membership_state']?.toString().toUpperCase();
    final isPlayManagedSubscription =
        membershipState == 'ACTIVE' || membershipState == 'GRACE_PERIOD';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // "If subscription is active, show a compact membership summary
          // at the top" — scoped exactly to that condition, per spec.
          // Trial access itself is unchanged: the summary card still
          // shows for an active trial; only the Play Store action below
          // is now gated on a genuine paid membership.
          if (data != null && isActive) ...[
            _MembershipSummaryCard(data: data, isHindi: isHindi),
            if (isPlayManagedSubscription) ...[
              const SizedBox(height: 10),
              _ManageInPlayStoreAction(isHindi: isHindi),
            ],
            const SizedBox(height: 24),
          ] else if (data == null)
            _StatusMessage(
              icon: Icons.workspace_premium_outlined,
              message: isHindi
                  ? 'अभी कोई सब्सक्रिप्शन जानकारी उपलब्ध नहीं है।'
                  : 'No subscription information available yet.',
              onRetry: _load,
              isHindi: isHindi,
            ),
          // Plans are always shown (active, expired, or never-subscribed)
          // — an active/trial user needs to see them too, to understand
          // which tiers are upgrades. This replaces the previous
          // behavior of hiding plans entirely once subscribed.
          _TieredPlansSection(provider: provider, data: data, isHindi: isHindi),
          const SizedBox(height: 20),
          _RestorePurchasesAction(provider: provider, isHindi: isHindi),
        ],
      ),
    );
  }
}

// =====================================================================
// Tier grouping — pure presentation-layer parsing of the already-issued
// product IDs (SubscriptionProductIds) and the backend's own `plan`
// string. Neither computes entitlement or purchase eligibility; both
// only decide how existing data is grouped and labeled on screen.
// =====================================================================

enum _Tier { silver, gold, platinum }

extension on _Tier {
  /// Ascending value order — used only to label a tier "Upgrade" or
  /// "Unavailable" relative to the user's current tier. Never used to
  /// gate a purchase; the Subscribe button still calls the exact same
  /// [SubscriptionProvider.subscribeToPlan] regardless.
  int get rank => switch (this) {
    _Tier.silver => 1,
    _Tier.gold => 2,
    _Tier.platinum => 3,
  };

  String label(bool isHindi) => switch (this) {
    _Tier.silver => isHindi ? 'सिल्वर' : 'Silver',
    _Tier.gold => isHindi ? 'गोल्ड' : 'Gold',
    _Tier.platinum => isHindi ? 'प्लैटिनम' : 'Platinum',
  };

  /// Entitlement-accurate, tier- AND period-differentiated copy — the
  /// product/backend contract has no per-tier feature-list field, so
  /// this is hand-maintained UI copy (same spirit as
  /// `SubscriptionProductIds` itself being a hand-maintained tier→SKU
  /// mapping). Verified directly against
  /// `modules/entitlement/plan_access_policy.py::PLAN_SEGMENT_ACCESS`
  /// on the backend's deployed `main` (not guessed): Silver is
  /// `ACCESS_SELECTED` (exactly one of the six [SubscriptionSections]
  /// the user picks before purchase — see `_showSilverSectionSheet`,
  /// which this copy must stay consistent with); Gold and Platinum are
  /// both `ACCESS_ALL` (identical entitlement — the backend grants
  /// Platinum nothing beyond what Gold already grants; confirmed no
  /// other Platinum-specific benefit exists anywhere in the backend's
  /// config/contracts). Never claims a "savings"/"best value" framing
  /// for Platinum: its real Play Console price
  /// (`config/google_play_products.py`) is actually HIGHER per month
  /// than Gold Yearly for the exact same access, so any such claim
  /// would be false.
  ///
  /// [isYearly] is required because Silver/Gold's transit-report
  /// entitlement genuinely differs by billing period (a monthly plan
  /// grants that allowance once; a yearly plan grants it every month of
  /// the subscription year) — this is the "smallest presentation-layer
  /// adjustment" this task's own audit called for, since `_Tier` alone
  /// can't express that distinction. Platinum has no monthly variant at
  /// all (`SubscriptionProductIds` — yearly-only), so its copy is fixed
  /// regardless of [isYearly].
  ///
  /// Transit-report business rules (confirmed by the product owner, not
  /// invented): Short Planet = Venus/Mars/Mercury only, explicitly
  /// confirmed. "Big Planet" is deliberately never itemized by name —
  /// no authoritative definition of which planets qualify exists
  /// anywhere in this app or the backend, so naming any would be
  /// inventing a claim. Every transit line uses "when applicable"/"up
  /// to" so this copy never promises a transit event that may not occur
  /// during the relevant period. This describes the PURCHASED PLAN'S
  /// ENTITLEMENT only — the Transit Report Auto-Generation Engine
  /// itself is a separate, not-yet-built phase (explicitly out of scope
  /// here); nothing below claims a report is generated automatically by
  /// the current app build.
  List<String> features(bool isHindi, bool isYearly) => switch (this) {
    _Tier.silver => isHindi
        ? [
            '1 प्रीमियम सेक्शन चुनें',
            isYearly
                ? 'हर महीने 1 शॉर्ट प्लैनेट ट्रांजिट रिपोर्ट'
                : '1 शॉर्ट प्लैनेट ट्रांजिट रिपोर्ट',
            'शुक्र, मंगल या बुध',
          ]
        : [
            'Choose 1 Premium Section',
            isYearly
                ? '1 Short Planet Transit Report each month'
                : '1 Short Planet Transit Report',
            'Venus, Mars or Mercury',
          ],
    _Tier.gold => isHindi
        ? [
            'सभी 6 प्रीमियम सेक्शन',
            isYearly
                ? 'हर महीने अधिकतम 2 शॉर्ट प्लैनेट ट्रांजिट रिपोर्ट'
                : 'अधिकतम 2 शॉर्ट प्लैनेट ट्रांजिट रिपोर्ट',
            isYearly
                ? 'सदस्यता वर्ष के दौरान लागू होने पर बिग प्लैनेट ट्रांजिट रिपोर्ट'
                : 'लागू होने पर 1 बिग प्लैनेट ट्रांजिट रिपोर्ट',
          ]
        : [
            'All 6 Premium Sections',
            isYearly
                ? 'Up to 2 Short Planet Transit Reports each month'
                : 'Up to 2 Short Planet Transit Reports',
            isYearly
                ? 'Big Planet Transit Reports when applicable during your subscription year'
                : '1 Big Planet Transit Report when applicable',
          ],
    _Tier.platinum => isHindi
        ? const [
            'सभी 6 प्रीमियम सेक्शन',
            'सभी लागू ट्रांजिट रिपोर्ट',
            'पूरे साल का प्रीमियम एक्सेस',
          ]
        : const [
            'All 6 Premium Sections',
            'All Applicable Transit Reports',
            'Full-year premium access',
          ],
  };
}

_Tier? _tierOf(String? value) {
  final v = (value ?? '').toLowerCase();
  if (v.contains('platinum')) return _Tier.platinum;
  if (v.contains('gold')) return _Tier.gold;
  if (v.contains('silver')) return _Tier.silver;
  return null;
}

/// `true`/`false` for a recognized period, `null` when the value doesn't
/// encode one at all (e.g. the backend's own `"SILVER"`-with-no-suffix
/// example) — callers treat `null` as "matches either period".
bool? _isYearlyOf(String? value) {
  final v = (value ?? '').toLowerCase();
  if (v.contains('year')) return true;
  if (v.contains('month')) return false;
  return null;
}

/// One tier's resolved products, grouped from the flat
/// [SubscriptionProvider.availableProducts] list — never invents a
/// product Play didn't actually resolve.
class _TierProducts {
  const _TierProducts({required this.tier, this.monthly, this.yearly});

  final _Tier tier;
  final ChatPackProduct? monthly;
  final ChatPackProduct? yearly;

  bool get hasAny => monthly != null || yearly != null;
}

List<_TierProducts> _groupByTier(List<ChatPackProduct> products) {
  final result = <_Tier, _TierProducts>{};
  for (final product in products) {
    final tier = _tierOf(product.productId);
    if (tier == null) continue;
    final isYearly = _isYearlyOf(product.productId) ?? false;
    final existing = result[tier];
    result[tier] = _TierProducts(
      tier: tier,
      monthly: isYearly ? existing?.monthly : product,
      yearly: isYearly ? product : existing?.yearly,
    );
  }
  // Fixed Silver → Gold → Platinum order, only tiers Play actually
  // resolved at least one product for.
  return [
    for (final tier in [_Tier.silver, _Tier.gold, _Tier.platinum])
      if (result[tier]?.hasAny ?? false) result[tier]!,
  ];
}

/// "Which plan they currently have" — parsed once from the backend's own
/// `plan` string, reused by every tier card below instead of each
/// re-parsing it.
class _CurrentPlan {
  const _CurrentPlan({required this.tier, required this.isYearly});

  final _Tier tier;

  /// `null` when the backend's plan string doesn't encode a period
  /// (matches the task's own `"Silver"`-with-no-suffix example) — a
  /// tier card then treats itself as current regardless of which period
  /// is toggled.
  final bool? isYearly;

  static _CurrentPlan? from(Map<String, dynamic>? data) {
    if (data?['active'] != true && data?['is_active'] != true) return null;
    final tier = _tierOf(data?['plan']?.toString());
    if (tier == null) return null;
    return _CurrentPlan(tier: tier, isYearly: _isYearlyOf(data?['plan']?.toString()));
  }
}

/// "Group plans clearly" — Silver → Gold → Platinum, one premium card
/// per tier, each with a Monthly/Yearly toggle when both are available.
/// Renders nothing (not an error, not a placeholder) when Play hasn't
/// resolved any product yet — identical fallback to the previous
/// `_PlansSection`.
class _TieredPlansSection extends StatelessWidget {
  const _TieredPlansSection({
    required this.provider,
    required this.data,
    required this.isHindi,
  });

  final SubscriptionProvider provider;
  final Map<String, dynamic>? data;
  final bool isHindi;

  @override
  Widget build(BuildContext context) {
    final tiers = _groupByTier(provider.availableProducts);
    if (tiers.isEmpty) return const SizedBox.shrink();

    final current = _CurrentPlan.from(data);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isHindi ? 'उपलब्ध प्लान' : 'Available Plans',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F1B2E),
          ),
        ),
        const SizedBox(height: 12),
        for (final tierProducts in tiers) ...[
          _TierCard(
            tierProducts: tierProducts,
            current: current,
            provider: provider,
            isHindi: isHindi,
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

/// One premium pricing card for a single tier — plan name, a
/// Monthly/Yearly toggle (when both periods resolved), price, a short
/// feature summary, a Current Plan badge, and the Subscribe button.
/// Purely presentational local state (which period is toggled); the
/// purchase action is the exact same
/// [SubscriptionProvider.subscribeToPlan] call the app already used.
///
/// No "Recommended" badge: no field anywhere in [ChatPackProduct] or the
/// backend's subscription-info response marks any tier as recommended,
/// and the spec is explicit that this badge should be omitted rather
/// than invented when no such business rule exists.
class _TierCard extends StatefulWidget {
  const _TierCard({
    required this.tierProducts,
    required this.current,
    required this.provider,
    required this.isHindi,
  });

  final _TierProducts tierProducts;
  final _CurrentPlan? current;
  final SubscriptionProvider provider;
  final bool isHindi;

  @override
  State<_TierCard> createState() => _TierCardState();
}

class _TierCardState extends State<_TierCard> {
  late bool _yearlySelected = _initialSelection();

  bool _initialSelection() {
    final tp = widget.tierProducts;
    final current = widget.current;
    // Default to the period the user is already on, when this card is
    // their current tier and that period is known.
    if (current != null &&
        current.tier == tp.tier &&
        current.isYearly != null &&
        (current.isYearly! ? tp.yearly != null : tp.monthly != null)) {
      return current.isYearly!;
    }
    // Otherwise default to Yearly when available (common pricing-page
    // convention), else whatever single period this tier actually has.
    if (tp.yearly != null) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = widget.isHindi;
    final tp = widget.tierProducts;
    final current = widget.current;
    final provider = widget.provider;

    final hasBoth = tp.monthly != null && tp.yearly != null;
    final selectedProduct = _yearlySelected ? (tp.yearly ?? tp.monthly) : (tp.monthly ?? tp.yearly);

    final isCurrentTier = current?.tier == tp.tier;
    final isCurrentPeriod =
        isCurrentTier &&
        (current!.isYearly == null || current.isYearly == _yearlySelected);
    final isBelowCurrentTier = current != null && tp.tier.rank < current.tier.rank;
    final isAboveCurrentTier = current != null && tp.tier.rank > current.tier.rank;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrentPeriod
              ? AppColors.primary
              : const Color(0xFFE4D9FA),
          width: isCurrentPeriod ? 1.6 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  tp.tier.label(isHindi),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F1B2E),
                  ),
                ),
              ),
              if (isCurrentPeriod)
                _Pill(
                  text: isHindi ? 'वर्तमान प्लान' : 'Current Plan',
                  background: AppColors.primary.withValues(alpha: 0.12),
                  foreground: AppColors.primary,
                )
              else if (isAboveCurrentTier)
                _Pill(
                  text: isHindi ? 'अपग्रेड' : 'Upgrade',
                  background: const Color(0xFFFCF1D6),
                  foreground: const Color(0xFFB8860B),
                ),
            ],
          ),
          const SizedBox(height: 10),
          for (final feature in tp.tier.features(isHindi, _yearlySelected)) ...[
            _FeatureLine(text: feature),
            const SizedBox(height: 4),
          ],
          const SizedBox(height: 12),
          if (hasBoth)
            _PeriodToggle(
              yearlySelected: _yearlySelected,
              isHindi: isHindi,
              onChanged: (value) => setState(() => _yearlySelected = value),
            ),
          if (hasBoth) const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedProduct?.price ?? '-',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F1B2E),
                      ),
                    ),
                    Text(
                      hasBoth
                          ? (_yearlySelected
                                ? (isHindi ? 'वार्षिक' : 'per year')
                                : (isHindi ? 'मासिक' : 'per month'))
                          : (_isYearlyOf(selectedProduct?.productId) == true
                                ? (isHindi ? 'वार्षिक' : 'per year')
                                : (isHindi ? 'मासिक' : 'per month')),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _TierActionButton(
                isCurrentPeriod: isCurrentPeriod,
                isUnavailable: isBelowCurrentTier,
                isUpgrade: isAboveCurrentTier,
                isPurchasing: provider.isPurchasing,
                isHindi: isHindi,
                onPressed: selectedProduct?.productId == null
                    ? null
                    : () => _handleSubscribeTap(
                        context,
                        tp.tier,
                        selectedProduct!.productId!,
                        isHindi,
                        provider,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Silver-plan section-selection fix: for every tier except Silver,
  /// this is exactly the same direct [SubscriptionProvider.
  /// subscribeToPlan] call the app already made — Gold/Platinum
  /// behavior is byte-for-byte unchanged. For Silver, Google Play
  /// Billing must never start before the user has explicitly chosen
  /// which one of the six premium sections this plan grants — so this
  /// awaits [_showSilverSectionSheet] first, and only calls
  /// [SubscriptionProvider.subscribeToPlan] if the user actually picked
  /// one. Dismissing the sheet (back gesture / tap outside / swipe
  /// down) returns `null` here — no default/automatic selection is ever
  /// substituted, and billing simply never starts, exactly as required.
  Future<void> _handleSubscribeTap(
    BuildContext context,
    _Tier tier,
    String productId,
    bool isHindi,
    SubscriptionProvider provider,
  ) async {
    if (tier != _Tier.silver) {
      provider.subscribeToPlan(productId);
      return;
    }

    final selectedSegment = await _showSilverSectionSheet(context, isHindi);
    if (selectedSegment == null) return; // user dismissed without choosing

    provider.subscribeToPlan(productId, selectedSegment: selectedSegment);
  }
}

/// Silver-plan section-selection fix: the smallest UI that satisfies
/// "user must select one of the six premium sections before Google Play
/// purchase starts" without introducing a new standalone screen — a
/// modal bottom sheet integrated into the existing Subscribe tap,
/// matching this file's existing card/pill visual language (same
/// [AppColors.primary], same rounded-container shape already used by
/// `_TierCard` itself). Returns the chosen canonical
/// [SubscriptionSections] value, or `null` if the user dismissed it
/// without choosing — the caller ([_TierCardState._handleSubscribeTap])
/// is the one place that turns a `null` into "billing does not start".
Future<String?> _showSilverSectionSheet(BuildContext context, bool isHindi) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isHindi ? 'एक सेक्शन चुनें' : 'Choose your one section',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F1B2E),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isHindi
                    ? 'सिल्वर प्लान में नीचे दिए गए छह प्रीमियम सेक्शन में से केवल एक शामिल है। खरीदारी शुरू करने से पहले चुनें — यह चयन बाद में नहीं बदला जा सकता।'
                    : 'Silver includes exactly ONE of the six premium sections '
                          'below. Choose before purchase — this cannot be '
                          'changed afterward.',
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 16),
              for (final section in SubscriptionSections.all) ...[
                _SilverSectionOption(
                  label: SubscriptionSections.label(section, isHindi),
                  onTap: () => Navigator.of(sheetContext).pop(section),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      );
    },
  );
}

/// One tappable row in [_showSilverSectionSheet] — plain, list-style
/// selection (no pre-checked/highlighted default state anywhere), so
/// nothing about this UI implies a section is already chosen until the
/// user actually taps one.
class _SilverSectionOption extends StatelessWidget {
  const _SilverSectionOption({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F3FE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE4D9FA)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F1B2E),
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodToggle extends StatelessWidget {
  const _PeriodToggle({
    required this.yearlySelected,
    required this.isHindi,
    required this.onChanged,
  });

  final bool yearlySelected;
  final bool isHindi;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _PeriodOption(
              label: isHindi ? 'मासिक' : 'Monthly',
              selected: !yearlySelected,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _PeriodOption(
              label: isHindi ? 'वार्षिक' : 'Yearly',
              selected: yearlySelected,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodOption extends StatelessWidget {
  const _PeriodOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.primary : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}

class _FeatureLine extends StatelessWidget {
  const _FeatureLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 3),
          child: Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF16A34A)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4B5563),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.text,
    required this.background,
    required this.foreground,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: foreground,
        ),
      ),
    );
  }
}

/// The Subscribe button's three states — same underlying action
/// ([SubscriptionProvider.subscribeToPlan]) for every enabled case;
/// "Current Plan" and "Unavailable" only ever disable the button, never
/// change what tapping it would do.
class _TierActionButton extends StatelessWidget {
  const _TierActionButton({
    required this.isCurrentPeriod,
    required this.isUnavailable,
    required this.isUpgrade,
    required this.isPurchasing,
    required this.isHindi,
    required this.onPressed,
  });

  final bool isCurrentPeriod;
  final bool isUnavailable;
  final bool isUpgrade;
  final bool isPurchasing;
  final bool isHindi;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    if (isCurrentPeriod) {
      return OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          disabledForegroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
        ),
        child: Text(
          isHindi ? 'सक्रिय' : 'Active',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      );
    }

    if (isUnavailable) {
      return OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          disabledForegroundColor: const Color(0xFF9CA3AF),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        child: Text(
          isHindi ? 'अनुपलब्ध' : 'Unavailable',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      );
    }

    return ElevatedButton(
      onPressed: (isPurchasing || onPressed == null) ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: isPurchasing
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Text(
              isUpgrade
                  ? (isHindi ? 'अपग्रेड करें' : 'Upgrade')
                  : (isHindi ? 'सब्सक्राइब करें' : 'Subscribe'),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
    );
  }
}

/// "Add one Restore Purchases action" — a single, minimal text button;
/// always available regardless of the currently-shown status, since
/// that's exactly the situation restore exists for (e.g. the backend
/// shows Inactive but the user genuinely owns a Play subscription that
/// never got confirmed). Tapping it only ever calls
/// [SubscriptionProvider.restorePurchases] — no purchase dialog of its
/// own, nothing duplicated from the Subscribe flow above.
class _RestorePurchasesAction extends StatelessWidget {
  const _RestorePurchasesAction({required this.provider, required this.isHindi});

  final SubscriptionProvider provider;
  final bool isHindi;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: provider.isRestoring
            ? null
            : () => provider.restorePurchases(),
        child: provider.isRestoring
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                isHindi ? 'खरीद पुनर्स्थापित करें' : 'Restore Purchases',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
      ),
    );
  }
}

/// S5.X — opens Google Play's own subscription-management page. No
/// `sku` param: the backend's `plan` field (e.g. `"SILVER_MONTHLY"`) is
/// an internal plan name, not the Play Console product ID, and mapping
/// one to the other client-side would duplicate backend config
/// (`config/google_play_products.py`) fragilely. Omitting `sku` still
/// takes the user straight to every subscription they have with this
/// app under Google's own account-management UI, which covers
/// cancel/change-plan/payment-method — exactly what this button is for.
class _ManageInPlayStoreAction extends StatelessWidget {
  const _ManageInPlayStoreAction({required this.isHindi});

  final bool isHindi;

  static final Uri _manageSubscriptionsUri = Uri.parse(
    'https://play.google.com/store/account/subscriptions'
    '?package=com.jyotishasha.app',
  );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: () => launchUrl(
          _manageSubscriptionsUri,
          mode: LaunchMode.externalApplication,
        ),
        icon: const Icon(Icons.open_in_new_rounded, size: 16),
        label: Text(
          isHindi ? 'Play Store में प्रबंधित करें' : 'Manage in Play Store',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
    );
  }
}

/// The live subscription-status card — reused visual shell (white, 18dp
/// radius, soft lavender border, subtle shadow), restyled with a premium
/// header accent for the pricing-page redesign. Same fields, same
/// backend data, same formatting as before — only the presentation
/// changed.
class _MembershipSummaryCard extends StatelessWidget {
  const _MembershipSummaryCard({required this.data, required this.isHindi});

  final Map<String, dynamic> data;
  final bool isHindi;

  String _string(dynamic value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? '-' : text;
  }

  /// Capitalizes the backend's raw `status` string for display only
  /// (e.g. `"trial"` → `"Trial"`) — purely cosmetic formatting, not a
  /// reinterpretation of the value. Falls back to `-` untouched.
  String _displayStatus() {
    final raw = data['status']?.toString().trim();
    if (raw == null || raw.isEmpty) return '-';
    return raw[0].toUpperCase() + raw.substring(1);
  }

  /// `started_at`/`end_at` come back as ISO date(-time) strings; formats
  /// them the same `DD-MM-YYYY` way every other date on this app already
  /// displays (see `KundaliOverviewPage`'s Birth Details section) —
  /// falls back to the raw backend string if it isn't parseable, never
  /// hides or fabricates a value.
  String _formatDate(dynamic raw) {
    final text = raw?.toString();
    if (text == null || text.isEmpty) return '-';
    try {
      final parsed = DateTime.parse(text);
      return '${parsed.day.toString().padLeft(2, '0')}-'
          '${parsed.month.toString().padLeft(2, '0')}-'
          '${parsed.year}';
    } catch (_) {
      return text;
    }
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F1B2E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Backend-provided value only — never inferred. `status` itself is
    // always "active"/"inactive" (never the string "trial"); `is_trial`
    // is the backend's own explicit flag for this (S5.X).
    final isTrial = data['is_trial'] == true;
    final isActive = data['active'] == true || data['is_active'] == true;
    final autoRenew = data['auto_renew'];
    final inGracePeriod = data['in_grace_period'] == true;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF3E8FF), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4D9FA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFEFE6D8)),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  size: 18,
                  color: Color(0xFFB8860B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isHindi ? 'आपका सब्सक्रिप्शन' : 'Your Subscription',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F1B2E),
                  ),
                ),
              ),
              if (isTrial)
                _Pill(
                  text: isHindi ? 'ट्रायल' : 'Trial',
                  background: AppColors.primary.withValues(alpha: 0.1),
                  foreground: AppColors.primary,
                ),
            ],
          ),
          const SizedBox(height: 16),
          _row(
            isHindi ? 'वर्तमान प्लान' : 'Current Plan',
            _string(data['plan']),
          ),
          _row(
            isHindi ? 'सब्सक्रिप्शन स्थिति' : 'Subscription Status',
            _displayStatus(),
          ),
          _row(
            isHindi ? 'प्रारंभ तिथि' : 'Start Date',
            _formatDate(data['started_at']),
          ),
          _row(
            isHindi ? 'समाप्ति तिथि' : 'End Date',
            _formatDate(data['end_at']),
          ),
          // Only meaningful for a real (non-trial) paid subscription —
          // the backend only ever sets `auto_renew` in that branch, so
          // a null value here already means "not applicable".
          if (isActive && !isTrial && autoRenew != null)
            _row(
              isHindi ? 'नवीनीकरण' : 'Renewal',
              autoRenew == true
                  ? (isHindi ? 'स्वतः नवीनीकरण होगा' : 'Renews automatically')
                  : (isHindi
                        ? 'रद्द किया गया — समाप्ति तिथि तक एक्सेस जारी रहेगा'
                        : 'Cancelled — access continues until the end date'),
            ),
          // "If in Grace Period, reuse existing messaging" — copy and
          // trigger condition unchanged from before the redesign.
          if (inGracePeriod) ...[
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4E5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isHindi
                    ? 'आपके भुगतान में समस्या है। एक्सेस बनाए रखने के लिए कृपया अपना भुगतान तरीका अपडेट करें।'
                    : "There's a problem with your payment. Please update "
                          'your payment method to keep your access.',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9A5B00),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Shared loading-error/empty status view — the same Icon → message →
/// Retry pattern already established across the app (e.g.
/// `KundaliOverviewPage`'s `_StatusView`), reproduced locally here since
/// that one is private to its own file and Kundali is a frozen module
/// this task does not touch.
class _StatusMessage extends StatelessWidget {
  const _StatusMessage({
    required this.icon,
    required this.message,
    required this.onRetry,
    required this.isHindi,
  });

  final IconData icon;
  final String message;
  final VoidCallback onRetry;
  final bool isHindi;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: const Color(0xFF9CA3AF)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(isHindi ? 'पुनः प्रयास करें' : 'Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
