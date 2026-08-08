# Enterprise Software Refactoring Tracker

Current Phase

ESR-031

Current Slice

Final Closure

Current Focus

Final Git Commit

Current Status

ESR-031 COMPLETE

Remaining Work

Final Git Commit

---

Authoritative Final Reconciled State

`MERGED` indicates a roadmap item whose intended scope was absorbed into completed ESR work and no longer remains as a standalone pending ESR item.

| ESR ID | Module | Files | Purpose | Risk | Status |
|---|---|---|---|---|---|
| ESR-000 | Architecture Decision Records (ADR) | `docs/esr/06_architecture_decisions.md` | Maintain all locked architecture decisions throughout the ESR migration. | LOW | COMPLETE |
| ESR-001 | Regression Baseline | `test/esr/`; `test/characterization/`; `integration_test/`; existing startup, auth, profile, notification, and commerce entry files | Add characterization coverage for the audited startup, routing, session, profile, notification, and purchase behavior before structural changes. | HIGH | COMPLETE |
| ESR-002 | Application Data Contracts | `lib/core/models/`; `lib/core/profile/` (new); feature `data/` folders | Define typed contracts for user/profile, kundali, horoscope, panchang, notifications, reports, Love, AskNow, Cards, and shared identifiers currently represented by dynamic maps. | HIGH | COMPLETE |
| ESR-003 | Network and Repository Boundaries | `lib/services/`; `lib/core/network/` (new); feature repositories (new) | Move direct HTTP/Firebase persistence calls behind explicit repositories while preserving current endpoints, payloads, and response behavior. | HIGH | COMPLETE |
| ESR-004 | Root Provider Composition | `lib/app/providers/` (new); `lib/main.dart`; root Provider declarations | Move root dependency and Provider registration into one bounded composition point while preserving current scopes and creation behavior. | HIGH | MERGED |
| ESR-005 | Application Bootstrap | `lib/app/bootstrap/` (new); `lib/services/play_billing_stub.dart`; Firebase initialization files; `lib/main.dart` | Extract ordered Firebase, Crashlytics, messaging, billing, ads, and HTTP-override startup work, including explicit bootstrap failure state. | HIGH | MERGED |
| ESR-006 | AppCoordinator | `lib/app/coordinator/` (new); `lib/app/app.dart`; `lib/app/bootstrap/` (new) | Establish one application-level coordinator for bootstrap completion and root application state. | HIGH | MERGED |
| ESR-007 | main.dart Cleanup | `lib/main.dart`; `lib/app/bootstrap/` (new); `lib/app/coordinator/` (new); `lib/app/providers/` (new) | Reduce `main()` to binding, bootstrap invocation, root composition, and `runApp()`. | HIGH | MERGED |
| ESR-008 | Authentication and Session | `lib/services/auth_service.dart`; `lib/core/session/` (new); `lib/features/login/`; `lib/features/splash/`; logout call sites | Centralize Firebase session observation, sign-in/out, backend identity synchronization, Login/Splash decisions, and session-state reset. | HIGH | MERGED |
| ESR-009 | Router and Navigation | `lib/app/routes/`; feature navigation call sites; notification route handling | Remove the bootstrap/router import cycle, centralize route paths and typed arguments, reconcile missing routes, and migrate mixed GoRouter/Navigator decisions. | HIGH | MERGED |
| ESR-010 | User and Profile Ownership | `lib/core/state/profile_provider.dart`; `lib/services/profile_service.dart`; `lib/core/profile/` (new); `lib/features/profile/`; `lib/features/birth/` | Establish one profile repository and canonical active-profile authority across root `activeProfileId`, profile `isActive`, Provider state, and profile forms. | HIGH | COMPLETE |
| ESR-011 | Language and Localization | `lib/core/state/language_provider.dart`; `lib/core/localization/` (new); `lib/app/app.dart`; profile language call sites; `lib/l10n/` | Centralize SharedPreferences language ownership, reconcile profile/app language, and verify generated localization behavior. | HIGH | MERGED |
| ESR-012 | Location Ownership | `lib/services/location_service.dart`; `lib/core/location/` (new); `lib/core/widgets/place_picker.dart`; all location-enabled forms/pages | Replace duplicated place controllers, suggestions, coordinates, timezone, and defaults with one typed location result and shared picker flow. | HIGH | MERGED |
| ESR-013 | Kundali Domain | Kundali Providers; `lib/core/kundali/` (new); `lib/features/kundali/`; `lib/features/manual_kundali/`; Astrology kundali consumers | Consolidate Firebase-profile, manual, bootstrap, and direct-form kundali paths behind one repository and one canonical result contract. | HIGH | DEFERRED |
| ESR-014 | Horoscope Domain | Daily/Monthly/Yearly Providers; `lib/core/horoscope/` (new); `lib/features/horoscope/`; horoscope widgets | Consolidate horoscope API access, typed responses, cache keys, refresh ownership, and screen consumption. | MEDIUM | COMPLETE |
| ESR-015 | Panchang Domain | `lib/core/state/panchang_provider.dart`; `lib/core/panchang/` (new); `lib/features/panchang/`; Panchang/chaughadiya widgets | Separate repository, cache, clock-driven state, coordinates, derived values, and UI ownership. | HIGH | COMPLETE |
| ESR-016 | Transit Domain | `lib/core/state/transit_provider.dart`; `lib/core/transit/` (new); `lib/features/transit/`; `lib/core/widgets/transit_alert_widget.dart` | Isolate current/personalized transit data, constructor fetch behavior, content loading, and alert/detail state. | MEDIUM | MERGED |
| ESR-017 | Dashboard Coordination | `lib/features/dashboard/`; dashboard coordinator (new); dependent core widgets | Move profile/FCM/kundali/horoscope/panchang/notification initialization out of Dashboard UI and reduce Home to feature composition and bounded refresh behavior. | HIGH | MERGED |
| ESR-018 | Notifications and FCM | `lib/services/notification_service.dart`; `lib/core/state/notification_provider.dart`; `lib/core/notifications/` (new); greeting/dashboard notification UI | Establish typed notification ownership, repository-backed list/count state, foreground event handling, lifecycle refresh, token registration, and notification routing. | HIGH | COMPLETE |
| ESR-019 | Cards Domain | `lib/features/cards/`; `lib/core/state/panchang_provider.dart`; Cards tests/fixtures | Activate one Cards data path, separate retrieval from composition, type card data, remove direct Provider coupling, and preserve rendering/share behavior. | HIGH | MERGED |
| ESR-020 | Muhurth Domain | `lib/features/muhurth/`; `lib/core/muhurth/` (new); Cards muhurth integration | Give Muhurth page and Cards one backend/cache owner, one location contract, and one result representation. | HIGH | MERGED |
| ESR-021 | AskNow Domain | `lib/features/asknow/`; `lib/core/state/asknow_provider.dart`; `lib/services/asknow_service.dart`; backend identity access | Separate chat history, entitlement/status, backend requests, pending answers, rewards, ads, and observable Provider state. | HIGH | MERGED |
| ESR-022 | Billing and Purchase Ownership | `lib/services/play_billing_stub.dart`; AskNow billing files; Report billing files; purchase tests | Establish explicit owners for product lookup, purchase streams, verification tokens, completion, retries, and session cleanup across AskNow and Reports. | HIGH | NO MIGRATION REQUIRED |
| ESR-023 | Reports Domain | `lib/features/reports/`; `lib/services/report_service.dart`; report models/repository (new); report asset loaders | Type catalog, selection, checkout, payment, and outcome data; remove form-map duplication; define webhook payload ownership, including `purchaseToken` and `user_id`. | HIGH | COMPLETE |
| ESR-024 | Love Domain | `lib/features/love/`; Love models/repository (new); `lib/services/location_service.dart` integration | Type Love payloads/results, consolidate API state, remove route/Provider payload duplication, and simplify result navigation state. | HIGH | MERGED |
| ESR-025 | Reports–Love Boundary | Love premium/report entry files; Report catalog/payment files; `lib/app/routes/` | Remove the bidirectional feature dependency while preserving relationship-report purchase and result flows through typed navigation data. | HIGH | NO MIGRATION REQUIRED |
| ESR-026 | Ads Ownership | `lib/core/ads/`; ad-consuming feature widgets/pages; bootstrap integration | Consolidate Mobile Ads initialization, cached ad objects, widget readiness, rewarded completion, and ad disposal under one active service path. | MEDIUM | MERGED |
| ESR-027 | Share and Temporary Media | `lib/core/utils/share_utils.dart`; `lib/core/widgets/global_share_button.dart`; share-producing Astrology/Kundali/Cards files; shared service (new) | Centralize render capture, temporary-file lifetime, share payloads, and cleanup across all share flows. | MEDIUM | MERGED |
| ESR-028 | Tool Results and Local Cache | `lib/features/tools/`; `lib/core/registry/tool_registry.dart`; SharedPreferences cache adapter (new) | Move direct tool HTTP/cache logic out of ToolResultPage and align tool inputs/results with canonical kundali contracts. | MEDIUM | MERGED |
| ESR-029 | Lifecycle and Global State | `lib/core/utils/global_context.dart`; lifecycle observers/listeners/timers; form controllers; root Providers | Retire global BuildContext access, align subscriptions/timers/controllers with owners, and enforce session/application/feature/screen lifetimes documented in the ownership audit. | HIGH | MERGED |
| ESR-030 | Orphan and Dependency Cleanup | Audited unused Providers, services, models, catalogs, routes, screens/widgets; dependency-boundary tests | Remove superseded paths only after migrations land, eliminate remaining feature cycles/direct Provider coupling, and verify allowed dependency directions. | MEDIUM | COMPLETE |
| ESR-031 | Integration and Release Gate | `test/esr/`; `integration_test/`; `docs/esr/05_esr_tracker.md`; migrated module entry points | Run startup, auth/profile, personalized-data, notification, commerce, navigation, lifecycle, and dependency regression suites before closing ESR phases. | HIGH | COMPLETE |

## Historical Archive - ESR-001 Progress

Historical archive. This section records the ESR-001 state at the time it was completed and is not the current ESR status.

Completed:

- Test discovery and shared test infrastructure.
- Initial startup, routing, session restoration, authentication-decision, and Splash characterization coverage.
- A minimal integration-test discovery smoke test.
- Profile selection, activation, deletion, root ownership, and identifier-normalization characterization coverage.
- Notification count, API fallback/shape, lifecycle refresh, mark-read, and list-refresh characterization coverage.
- AskNow and Report purchase status, product, verification payload, completion, guard, failure, and relationship-report characterization coverage.
- Full suite verification: 31 unit/widget tests and 1 integration smoke test pass.
- Analyzer attribution: the full pre-ESR baseline remains 208 issues; `test/esr/` introduces 0 issues.
- Production verification: no `lib/` files are modified; Android release signing remains configured.

External Firebase and billing singleton boundaries are locked with source characterization where direct execution would require production dependency-injection changes. Those architecture changes are intentionally deferred to later ESRs.

---

## Historical Archive - Final Status

Historical archive. This section records the ESR-001 completion state and is not the current ESR status.

**Status:** COMPLETE

### Validation

* flutter analyze: PASS (no new ESR-001 issues introduced)
* flutter test: PASS
* flutter run: PASS
* Manual verification: PASS

### Summary

Completed:

* Regression baseline established.
* Shared testing infrastructure created.
* Startup characterization.
* Splash characterization.
* Routing characterization.
* Authentication characterization.
* Session restoration characterization.
* Profile characterization.
* Notification characterization.
* Commerce / Purchase characterization.
* Integration test infrastructure.
* Analyzer baseline attributed.
* No production behavior changes.
* Ready to begin ESR-002.

## Historical Archive - ESR-002 Progress

Historical archive. This section records the ESR-002 state at the time it was completed and is not the current ESR status.

Status: COMPLETE

Completed:

* ✅ Slice-1 — Data Contract Audit
* ✅ Slice-2 — Shared Foundation Contracts
* ✅ Slice-3 — User / Session / Profile Contracts
* ✅ Slice-4 — Remaining Domain Contracts
* ✅ Final Validation

## Historical Record - ESR-003 Progress

Status: Historical archive snapshot from ESR-003

Completed:

* ✅ Slice-1 — Network Boundary Audit
* ✅ Slice-2 — Repository Interfaces
* ✅ Slice-3 — Repository Implementations
* ✅ Slice-4 Part-1 — ProfileService
* ✅ Slice-4 Part-2 — AuthService

Current:

* 🟡 Slice-4 Part-3 — UserBootstrapService

Upcoming:

* ⬜ Slice-4 Part-4 — Remaining Services
  * Kundali
  * Horoscope
  * Panchang
  * Transit
  * Notification
  * Reports
  * Love
  * AskNow
  * Billing
  * Cards
  * Muhurth
* ⬜ Final Validation

## Incremental Migration Policy

Service migration must be performed incrementally.

Each part must:

* preserve runtime behavior
* pass flutter analyze
* pass flutter test
* pass flutter run
* complete manual verification
* complete architecture review

Only after one part passes may the next part begin.

This phased migration reduces risk, simplifies debugging, and provides clean rollback points.

## Architecture Decision — User Service Boundary

There is currently no standalone UserService in the production codebase.

User persistence responsibilities are distributed across AuthService, BackendAuthService, UserBootstrapService, and direct Firestore access.

Until a future approved ESR phase explicitly consolidates those responsibilities, UserBootstrapService remains an independent bootstrap boundary and must not be renamed or treated as UserService.

---

## Appended Reconciliation — 2026-07-03

Historical archive record. The authoritative current state is reflected in the top-of-file current sections and tracker statuses above.

Updated Status Overlay

* Current Phase: ESR-031
* Current Slice: Final Closure
* Current Focus: Global Pre-Commit Validation
* ESR-003: COMPLETE
* ESR-010: COMPLETE
* ESR-013: DEFERRED
* ESR-014: COMPLETE
* ESR-015: COMPLETE
* ESR-018: COMPLETE
* ESR-022: NO MIGRATION REQUIRED
* ESR-023: COMPLETE
* ESR-025: NO MIGRATION REQUIRED
* ESR-030: COMPLETE
* ESR-031: COMPLETE

ESR-030 Completion Record

* ESR-030 COMPLETE
* ProfileRepositoryAdapter removed from production runtime
* FirestoreProfileRepository is now the production runtime owner
* No public contract changes
* No ProfileProvider changes
* No runtime behavior changes
* Migration Analyzer: PASS
* Characterization: PASS
* flutter run: Not Assessable (environment)
* Manual Verification: Not Assessable (environment)

Final Reconciliation Recorded At The Time

* Completed implementation areas: Profile, Daily Horoscope, Monthly Horoscope, Yearly Horoscope, Personalized Horoscope, Panchang, Notification, Reports
* No Migration Required: Billing, Checkout, Cross Feature Integration
* Deferred: Kundali
* Remaining work only:
  * Remove unused ProfileRepositoryAdapter source file if no production references remain
  * Global Pre-Commit Validation
  * Final Git Commit

---

## Appended Validation Update — 2026-07-03

Historical archive record. The authoritative current state is reflected in the top-of-file current sections and tracker statuses above.

Latest ESR-030 / ESR-031 Validation

* Migration Analyzer: PASS
* Characterization: PASS
* flutter run: PASS
* Manual Verification: PASS

Manual Verification Evidence

* Login: PASS
* Dashboard: PASS
* Profile CRUD: PASS
* Notifications: PASS
* Reports Purchase: PASS
* Love Report: PASS
* Horoscope: PASS
* Panchang: PASS

Validation Status Overlay

* ESR-030 latest validation record: PASS
* ESR-031 final validation record: PASS
