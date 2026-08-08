# ESR-003 — Repository Interfaces

## Slice

ESR-003 Slice-2 — Repository Interfaces

## Purpose

This slice establishes dependency inversion for application data boundaries.
It defines abstract repository contracts without introducing implementations or
migrating any production caller.

All interfaces live in `lib/core/repositories/`. They depend only on Dart core
types and the immutable ESR-002 contracts under `lib/core/models/`.

## Dependency direction

```text
Presentation / Application State
              |
              v
     Repository Interfaces
              |
              v
       ESR-002 Contracts

Future Repository Implementations
              |
              +--> Repository Interfaces
              +--> Remote / Local Data Sources
              +--> Platform SDK Adapters
```

The following dependency rules are mandatory:

* presentation and application-state code may depend on repository interfaces;
* repository interfaces may depend on ESR-002 contracts and Dart core only;
* future implementations must implement these interfaces;
* HTTP, Firebase, SharedPreferences, billing, ads, Providers, and services must
  never be imported into the interface layer;
* data-source and SDK types must not escape through repository signatures;
* no production caller uses these interfaces during Slice-2.

## Repository inventory

| Repository | Purpose and owned responsibility | Explicitly excluded | Primary contracts |
|---|---|---|---|
| `UserRepository` | User records, backend identity registration, profile bootstrap identity, messaging-token metadata | Session state, profile CRUD, transport, SDKs, presentation state | `User`, `UserIdentity`, `Profile` |
| `SessionRepository` | Current/session stream, provider-neutral sign-in, sign-out, backend token | Routing, startup, user/profile persistence, authentication SDK types | `Session` |
| `ProfileRepository` | Profile CRUD and active-profile selection | Session ownership, Kundali generation, persistence SDKs, UI state | `Profile` |
| `KundaliRepository` | Canonical Kundali request/response boundary | Profile selection, cache policy, HTTP/Firebase, UI state | `KundaliRequest`, `KundaliResponse` |
| `HoroscopeRepository` | Daily, monthly, yearly, and personalized horoscope retrieval | Sign/profile selection, cache presentation, HTTP, derived astrology logic | Horoscope query/result contracts |
| `PanchangRepository` | Canonical Panchang request/response boundary | Clock/reset policy, location selection, provider caching, HTTP | `PanchangRequest`, `PanchangResponse` |
| `TransitRepository` | Current transit and personalized transit content | UI initialization, alert derivation, links, HTTP | Current/content transit contracts |
| `NotificationRepository` | Notification list/count/read state and backend device-token registration | Foreground listeners, routing, token acquisition, Firebase SDK | Notification contracts |
| `LoveRepository` | Typed Love request dispatch and result envelope | Forms, location lookup, report checkout, endpoint logic in UI | `LoveCompatibilityRequest`, `LoveApiResponse<LoveResult>` |
| `AskNowRepository` | Free/paid questions, entitlement status, rewards, chat-pack verification | Billing SDK, ads, chat UI, backend-user lookup | AskNow contracts |
| `ReportRepository` | Report catalog and standard/relationship generation requests | Billing lifecycle, forms, navigation, asset/HTTP mechanics | Report contracts |
| `MuhurthRepository` | Shared Muhurth request/response for pages and cards | Location selection, card composition, cache UI, HTTP | `MuhurthRequest`, `MuhurthResponse` |
| `CardRepository` | Typed card-feed retrieval for a coordinate context | Rendering, image choice, sharing, Provider coupling, HTTP | `CardFeedResponse` |
| `BillingRepository` | SDK-neutral availability, product lookup, purchase stream, purchase start/completion | SDK types, entitlement policy, backend verification, navigation | `ChatPackProduct`, `ReportPurchaseReceipt` |
| `LocationRepository` | Place search, place details, and timezone resolution | Form state, API keys, transport/SDKs, profile persistence | `BirthDetails` |
| `SettingsRepository` | Persisted application language | Localization rendering, profile preferences, SharedPreferences, Provider state | Dart `String` |

`repositories.dart` is the interface-layer barrel export. It introduces no
types or behavior.

## Interface methods

### User and session

`UserRepository` exposes user lookup/persistence, backend registration, profile
bootstrap, and messaging-token persistence. `SessionRepository` separately owns
the live session boundary, sign-in/sign-out, and backend authorization token.
This separation prevents persisted user data from becoming the application
session controller.

`UserRepository.bootstrapProfile(Map<String, dynamic>)` preserves the legacy
bootstrap boundary exactly at both edges: raw request map in, complete decoded
backend response map out. ESR-002 identified a dedicated bootstrap request and
response contract as missing, so Slice-2 preserves the full raw map boundary
temporarily rather than narrowing behavior or inventing unapproved typed
models.

### Profiles

`ProfileRepository` exposes list, individual lookup, active lookup, create,
update, delete, and active selection. Every operation carries an explicit
Firebase user identifier until ESR-008 and ESR-010 establish session and profile
ownership. The identifier is a domain string, not a Firebase SDK object.

### Astrology domains

* `KundaliRepository.generateKundali()` uses `KundaliRequest` and
  `KundaliResponse`.
* `HoroscopeRepository` uses `HoroscopeQuery` for period-based requests and
  returns the period-specific result contract. Personalized endpoints retain
  the audited integer profile identifier.
* `PanchangRepository.getPanchang()` uses the canonical request and response.
* `TransitRepository` separates current transit from typed content retrieval.
* `MuhurthRepository.getMuhurth()` supplies the single future boundary shared
  by the Muhurth page and Cards domain.

### Notifications, Love, AskNow, reports, and cards

Notification list/count/read operations use the ESR-002 notification envelopes.
Device-token registration remains a repository responsibility, but acquisition
and foreground message coordination remain outside the repository.

Love, AskNow, and Reports use their complete ESR-002 request and response
contracts. Purchase verification for AskNow remains an AskNow backend operation;
the platform purchase lifecycle remains in `BillingRepository`.

`CardRepository` returns `CardFeedResponse`. Coordinates remain primitive named
parameters because ESR-002 contains no card-feed request contract. A future
implementation must not leak its asset, Panchang, Muhurth, or HTTP sources.

### Billing, location, and settings

`BillingRepository` uses `ChatPackProduct` as the existing product-detail
contract and `ReportPurchaseReceipt` as the existing SDK-neutral purchase
receipt. The interface does not expose `InAppPurchase`, `PurchaseDetails`, or
any billing enum.

`LocationRepository` uses `BirthDetails` for both place suggestions and resolved
places because that completed ESR-002 contract already carries place name,
place ID, coordinates, and timezone. Search results may leave unresolved fields
nullable.

`SettingsRepository` uses a nullable string for the current language because no
standalone settings contract exists and the current storage boundary contains
only `app_lang`.

## Planned implementation mapping

Slice-2 creates no implementation. The following mapping defines the intended
future owners for ESR-003 Slice-3 and later service migration.

| Interface | Current boundaries to be placed behind the future implementation |
|---|---|
| `UserRepository` | User synchronization in `AuthService`, user bootstrap paths, dashboard FCM metadata persistence |
| `SessionRepository` | `AuthService`, `BackendAuthService`, direct `FirebaseAuth.currentUser` and backend-token reads |
| `ProfileRepository` | `ProfileService` plus direct Firestore access in birth, profile, login, AskNow, report, and Kundali paths |
| `KundaliRepository` | `KundaliProvider`, `FirebaseKundaliProvider`, `ManualKundaliProvider`, direct page/widget HTTP owners |
| `HoroscopeRepository` | Daily/monthly/yearly providers and `PersonalizedHoroscopeService` |
| `PanchangRepository` | `PanchangProvider` remote boundary |
| `TransitRepository` | `TransitProvider` remote boundaries |
| `NotificationRepository` | `NotificationService` and dashboard backend device-token registration |
| `LoveRepository` | `LoveApiService` remote boundary |
| `AskNowRepository` | `AskNowService` and AskNow backend verification call |
| `ReportRepository` | `ReportService` and report catalog asset loaders |
| `MuhurthRepository` | Direct Muhurth page and Cards-provider requests |
| `CardRepository` | `CardService`, Cards asset loading, and future card-source composition |
| `BillingRepository` | `PlayBillingStub`, `AskNowProvider` purchase lifecycle, `ReportPaymentPage` purchase lifecycle |
| `LocationRepository` | `LocationService`, `PlaceAutocompleteField`, and `GetAnyoneHoroscopeCard` Places requests |
| `SettingsRepository` | `LanguageProvider` SharedPreferences access |

The mapping does not authorize removal, replacement, or rewiring of any current
owner. Each migration requires a separately authorized slice and regression
validation.

## Ownership constraints

* Each future implementation is the single owner of its named data source
  capability.
* Session and persisted user data remain separate interfaces.
* Profile persistence and Kundali generation remain separate interfaces.
* Billing owns platform purchase mechanics; domain repositories own backend
  verification and entitlement semantics.
* Notifications own notification data; a later coordinator owns foreground
  events and navigation.
* Ads are intentionally absent because ESR-003 Slice-2 requested repository
  boundaries, while ESR-026 owns ad lifecycle consolidation.

## Architecture review

* Sixteen abstract interfaces were added; no implementation was added.
* The interface layer contains no HTTP, Firebase, SharedPreferences, billing
  SDK, ads SDK, Provider, or service import.
* Method signatures use ESR-002 contracts wherever a completed contract exists.
* No existing provider, service, widget, route, repository caller, or bootstrap
  path is changed.
* No runtime dependency or runtime behavior is changed.

## Slice result

Repository dependency inversion contracts are defined and ready for a future,
explicitly authorized implementation slice. ESR-003 Slice-3 is not started by
this document.
