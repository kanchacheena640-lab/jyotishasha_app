# ESR-003 — Repository Implementations

## Slice

ESR-003 Slice-3 — Repository Implementations

## Scope

This slice provides concrete implementations for the repository interfaces
listed in the approved four-part sequence. Implementations are additive and are
not connected to existing providers, services, widgets, routes, or bootstrap
code.

`LocationRepository` and `SettingsRepository` are outside the supplied Slice-3
part list and remain interface-only.

## Implementation inventory

| Part | Interface | Implementation | Boundary |
|---|---|---|---|
| 1 | `UserRepository` | `FirebaseUserRepository` | Firestore user documents, backend registration, profile bootstrap, FCM metadata |
| 1 | `SessionRepository` | `FirebaseSessionRepository` | Firebase authentication state, existing auth service, backend token |
| 1 | `ProfileRepository` | `FirestoreProfileRepository` | Firestore profile CRUD and active-profile ownership |
| 2 | `KundaliRepository` | `HttpKundaliRepository` | Full Kundali backend endpoint |
| 2 | `HoroscopeRepository` | `HttpHoroscopeRepository` | Daily, monthly, yearly, and personalized horoscope endpoints |
| 2 | `PanchangRepository` | `HttpPanchangRepository` | Panchang backend endpoint |
| 3 | `TransitRepository` | `HttpTransitRepository` | Current and personalized transit endpoints |
| 3 | `NotificationRepository` | `BackendNotificationRepository` | Existing notification service and backend FCM registration |
| 4 | `ReportRepository` | `AssetReportRepository` | Report assets and existing report service |
| 4 | `LoveRepository` | `BackendLoveRepository` | Existing Love API service, configured by `LoveTool` |
| 4 | `AskNowRepository` | `BackendAskNowRepository` | Existing AskNow service and chat-pack verification endpoint |
| 4 | `BillingRepository` | `PlayBillingRepository` | Google Play Billing purchase lifecycle |
| 4 | `CardRepository` | `HttpCardRepository` | Cards backend endpoint |
| 4 | `MuhurthRepository` | `HttpMuhurthRepository` | Muhurth backend endpoint |

## Dependency and ownership rules

* Implementations depend inward on repository interfaces and ESR-002 contracts.
* SDK, HTTP, Firebase, asset, and service dependencies remain inside concrete
  implementations.
* No implementation type is exported by the interface barrel
  `lib/core/repositories/repositories.dart`.
* No existing runtime owner imports an implementation in this slice.
* Current services remain operational until the separately scoped service
  migration slice changes ownership.

## Compatibility decisions

* Endpoint URLs, payload keys, status handling, timeouts, asset paths, Firebase
  collection paths, and active-profile fields follow the audited production
  boundaries.
* `FirebaseUserRepository.bootstrapProfile()` preserves the legacy bootstrap
  HTTP boundary exactly by posting the raw request map and returning the
  complete decoded backend response map because ESR-002 did not define typed
  bootstrap request or response contracts.
* `BackendLoveRepository` receives `LoveTool` in its constructor because the
  interface request contract intentionally contains no endpoint selector.
* `PlayBillingRepository` converts SDK products and purchase events to existing
  ESR-002 contracts and retains observed SDK purchase objects privately for
  completion.
* `AssetReportRepository` calls the existing `ReportService`; its current
  purchase-token wire behavior is preserved rather than corrected in this
  implementation slice.
* Every external dependency supports constructor injection where the existing
  SDK permits it, while default construction matches the production singleton
  or client.

## Runtime impact

None. These classes are not registered, instantiated, or consumed by current
production paths. Provider and service migration is deferred to ESR-003
Slice-4.

## Validation

* Focused repository implementation analysis: PASS — 0 issues.
* Full `flutter analyze`: baseline retained at 202 existing issues; no new
  implementation issue.
* `flutter test`: PASS — 47 tests.
* `flutter run`: PASS — Android debug build installed and launched on the
  connected Infinix X6812.

## Architecture review

* All 14 requested repository interfaces have concrete implementations.
* No repository interface was modified.
* The interface barrel still exports interfaces only.
* No Provider, service, widget, route, or bootstrap caller was modified.
* No runtime behavior or runtime dependency was changed.

## Future Cleanup

During ESR-030 — Orphan and Dependency Cleanup, repository implementations
should be evaluated for domain-based folder organization (`user/`, `profile/`,
`kundali/`, and similar domain folders) to improve maintainability.

This is a documentation note only. It does not move or rename files, modify
imports, or change runtime behavior.
