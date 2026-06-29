# ESR-003 — Network Boundary Audit

## Slice

ESR-003 Slice-1 — Network Boundary Audit

## Purpose

This document inventories the application's current network and persistence
boundaries before repository boundaries are introduced. It records current
ownership and behavior only. No production owner, data flow, or runtime
behavior is changed by this slice.

The audit covers active Dart code under `lib/`, including HTTP, Firebase,
local storage, Google Play Billing, Google Mobile Ads, direct JSON conversion,
and externally hosted content opened by the application.

## Migration priority

| Priority | Meaning |
|---|---|
| P0 | Security, purchase integrity, startup, or identity boundary; migrate first and preserve behavior exactly |
| P1 | Active, duplicated, or presentation-owned data boundary used by a primary feature |
| P2 | Active boundary with narrower impact or an existing service abstraction |
| P3 | Unused, legacy, or presentation-only boundary; confirm intended lifecycle before migration |

## Executive summary

The application has boundary wrappers in several services, but it does not yet
have repository ownership. HTTP is also performed directly by providers,
widgets, and pages. Firebase identity and Firestore document access are repeated
outside `AuthService` and `ProfileService`. Billing is independently managed by
`AskNowProvider`, `ReportPaymentPage`, and startup code. Ads have multiple
competing abstractions and direct feature-level SDK ownership.

The highest-risk seams are:

1. authentication and backend-token acquisition;
2. purchase verification and completion;
3. profile/session reads split across Firebase and backend identifiers;
4. repeated Kundali generation and Google Places calls;
5. FCM registration split between the dashboard, Firestore, and the backend;
6. production UI classes that own HTTP, Firestore, billing, or ad SDK objects.

No `http.put()`, `http.delete()`, `http.patch()`, `MultipartRequest`, or other
multipart upload is present in active `lib/` code.

## HTTP boundary inventory

### Backend authentication and user bootstrap

| Boundary | Current owner | Current callers | Data flow | Missing repository | Duplicate logic / dependency issue | Priority |
|---|---|---|---|---|---|---|
| `POST /api/auth/register` | `BackendAuthService.registerFirebaseUser()` | `AuthService._syncUser()` after social authentication | Firebase user identity -> JSON `{firebase_uid, email, name}` -> backend -> `backend_user_id` -> Firestore user document | Authentication/session repository | `AuthService` coordinates Firebase, Firestore, and backend registration; concrete static HTTP dependency and raw maps | P0 |
| `POST /api/auth/token` | `BackendAuthService.getBackendToken()` | All three `NotificationService` operations | Firebase UID -> JSON -> backend token -> bearer header | Authentication/session repository | Token is fetched separately for each notification call; token ownership is not centralized and differs from direct Firebase ID-token use in the dashboard | P0 |
| `POST /api/user/bootstrap` | `KundaliProvider.bootstrapUser()` and `UserBootstrapService.syncProfile()` | `BirthDetailPage`, `AddProfilePage`; `UserBootstrapService` has no production caller | Profile map -> backend bootstrap -> decoded backend response / identifier | User/profile repository | Same endpoint has two owners; one wrapper is orphaned; bootstrap is coupled to Kundali provider state | P0 |

### Kundali and astrology

| Boundary | Current owner | Current callers | Data flow | Missing repository | Duplicate logic / dependency issue | Priority |
|---|---|---|---|---|---|---|
| `POST /api/full-kundali-modern` | `KundaliProvider` | `BirthDetailPage`, `AddProfilePage` | Birth/profile map -> JSON -> Kundali response map in provider | Kundali repository | One of six independent owners of the same endpoint | P1 |
| Same endpoint | `FirebaseKundaliProvider` | `DashboardPage`, `AstrologyPage`, `AstrologyToolSection` | Firebase user -> Firestore active profile -> request map -> HTTP -> provider map | Kundali and profile repositories | Crosses auth, Firestore, network, serialization, and presentation state in one provider | P1 |
| Same endpoint | `ManualKundaliProvider` | `ManualKundaliFormPage`, `ManualKundaliResultPage` | Form map -> JSON -> response map | Kundali repository | Repeats transport and decoding | P1 |
| Same endpoint | `KundaliFormPage` | Page-local submit action | Form controllers -> request map -> HTTP -> navigation/result | Kundali repository | Widget owns transport and status handling | P1 |
| Same endpoint | `ToolResultPage` | Tool result screen | Kundali map -> HTTP; response -> SharedPreferences cache -> UI | Kundali repository plus cache data source | Widget owns remote and local data sources | P1 |
| Same endpoint | `GetAnyoneHoroscopeCard` | Embedded dashboard/card interaction | Direct Places lookup -> birth payload -> HTTP -> result UI | Location and Kundali repositories | Widget owns two external systems and duplicates both flows | P1 |

### Horoscope, Panchang, transit, events, Muhurth, and cards

| Boundary | Current owner | Current callers | Data flow | Missing repository | Duplicate logic / dependency issue | Priority |
|---|---|---|---|---|---|---|
| `GET /api/daily-horoscope` | `DailyProvider` | `HoroscopePage`, `DashboardPage`, `DashboardHomeSection`, greeting/horoscope widgets | Sign + language query -> response map -> in-memory provider cache | Horoscope repository | Provider is transport, cache, and presentation state owner | P1 |
| `GET /api/monthly-horoscope` | `MonthlyProvider` | `HoroscopePage`, `HoroscopeCardWidget` | Sign + language query -> response map -> in-memory cache | Horoscope repository | Same transport/cache pattern as daily and yearly | P1 |
| `GET /api/yearly-horoscope` | `YearlyProvider` | `HoroscopePage`, `HoroscopeCardWidget` | Sign + year + language query -> response map -> in-memory cache | Horoscope repository | Same transport/cache pattern as daily and monthly | P1 |
| `GET /api/personalized/daily`, `/tomorrow`, `/weekly` | `PersonalizedHoroscopeService` | No production callers | Profile ID query -> `ok/horoscope` envelope | Horoscope repository | Orphan wrapper overlaps the active horoscope domain and has no shared error/transport policy | P3 |
| `POST /api/panchang` | `PanchangProvider` | `DashboardPage`, `PanchangPage`, Panchang/chaughadiya widgets, Cards flow | Coordinates + date + language -> response maps -> timed in-memory cache | Panchang repository | Provider owns transport, timer, cache policy, and state | P1 |
| `GET /api/transit/current`, `GET /api/transit` | `TransitProvider` | `DashboardHomeSection`, transit alert/content widgets | Optional ascendant/planet/house/language query -> response maps | Transit repository | Provider owns two endpoint shapes, timeouts, and UI state | P1 |
| `POST /api/events/home-upcoming` | `HomeUpcomingEventsProvider` | No production registration or caller | Coordinates -> decoded event list | Events repository | Orphan provider; lifecycle and feature intent need confirmation | P3 |
| `POST /api/muhurth/list` | `MuhurthPage` | Page-local search | Activity + coordinates + language -> result list | Muhurth repository | Page owns HTTP; duplicate endpoint in `CardsProvider` | P1 |
| Same endpoint | `CardsProvider` | `CardsPage` card composition | Activity + Panchang coordinates + language -> result list -> memory cache -> cards | Muhurth repository | Cross-feature provider depends directly on `PanchangProvider`; duplicates request and response handling | P1 |
| `POST /api/cards` | `CardService` | No production callers | Coordinates -> decoded `cards` list | Cards repository | Orphan wrapper; active Cards flow instead composes local assets and Muhurth data | P3 |

### AskNow, Love, reports, notifications, and messaging

| Boundary | Current owner | Current callers | Data flow | Missing repository | Duplicate logic / dependency issue | Priority |
|---|---|---|---|---|---|---|
| `POST /api/chat/free`, `/api/chat/pack` | `AskNowService` | `AskNowProvider` | Backend user ID + question + profile -> answer/status map | AskNow repository | Static service and raw maps; provider also owns billing and reward state | P1 |
| `POST /api/chat/status`, `/api/chat/reward` | `AskNowService` | `AskNowChatPage` / `AskNowProvider` | Backend user ID -> entitlement/token state | AskNow repository | Identity lookup is separately performed through Firestore in the page | P1 |
| `POST /api/chatpack/verify` | `AskNowProvider` | Purchase-stream callback | Purchase product/token + pending backend user ID -> verification response -> purchase completion -> local entitlement state | Purchase/entitlement repository | Billing, backend verification, HTTP, and UI state share one provider; details in Billing audit | P0 |
| `POST /api/love/report`, `/truth-or-dare`, `/love-marriage-probability` | `LoveApiService` selected by `LoveTool` | `LoveProvider` and Love result pages | Love payload map -> selected endpoint -> result map | Love repository | Service contains endpoint dispatch; provider retains raw maps | P2 |
| `POST /webhook` | `ReportService` | Two branches in `ReportPaymentPage` | Paid report/form data -> request payload -> success boolean | Report/purchase repository | Payment page completes purchase before report submission; `purchaseToken` is accepted by the service but is not included in the HTTP payload | P0 |
| `GET /api/user-notifications/unread-count`, `GET /api/user-notifications`, `POST /mark-read` | `NotificationService` | `NotificationProvider`, `GreetingHeaderWidget` | Firebase current user -> backend-token request -> bearer HTTP -> count/list/update | Notification repository and session/token owner | Each operation repeats auth and token resolution; widget calls service directly | P1 |
| `POST /api/users/update-fcm` | `DashboardPage` | Dashboard initialization | FCM permission/token -> Firestore update -> Firebase ID token -> backend HTTP | Messaging registration repository | Page owns Messaging, Auth, Firestore, and HTTP; no token-refresh listener is centralized | P0 |

### Google Maps Platform and WordPress

| Boundary | Current owner | Current callers | Data flow | Missing repository | Duplicate logic / dependency issue | Priority |
|---|---|---|---|---|---|---|
| Places autocomplete, place details, timezone REST endpoints | `LocationService` | Place picker; birth, profile, manual Kundali, report, Love, Panchang, and Muhurth forms/pages | User input/place ID/coordinates -> Google REST -> raw prediction/detail/timezone maps | Location repository | API key and URL construction are coupled to client code; errors and response shapes are raw | P1 |
| Places autocomplete and details | `PlaceAutocompleteField` | Widget consumers | Typed text -> direct Google REST -> widget suggestions/selection | Location repository | Duplicates `LocationService` inside a reusable widget | P1 |
| Places autocomplete and details | `GetAnyoneHoroscopeCard` | Embedded feature card | Typed text -> direct Google REST -> Kundali request | Location repository | Third implementation of Places transport | P1 |
| WordPress posts REST endpoint | `BlogService` | No production callers | GET `_embed` posts -> decoded list | Content/blog repository | Orphan service; reader page only receives a URL | P3 |

### Other outbound network surfaces

`BlogReaderPage` loads a supplied URL in a WebView. `TransitContentPage`,
`MorePage`, `AppFooterFeedbackWidget`, and `HoroscopePage` launch external
article, policy, website, or Play Store URLs. These are navigation/content
boundaries rather than JSON data APIs. They currently have presentation
ownership and no centralized external-link policy. Priority: P3.

### HTTP dependency findings

* The `http` package is instantiated through top-level static methods; no shared
  client owns base URL, headers, timeout, retry, cancellation, or error mapping.
* Backend base URLs are repeated in services, providers, widgets, and pages.
* Authentication uses both a backend token obtained from Firebase UID and a
  Firebase ID token obtained directly from `FirebaseUser`.
* Raw `Map<String, dynamic>` values cross all layers even though ESR-002
  contracts now exist. Contract adoption belongs to later slices.
* Status handling is inconsistent: some callers throw, some return booleans or
  empty collections, and others store string errors in providers.
* `main.dart` installs a global IPv4 `HttpOverrides` implementation, making
  transport policy a bootstrap concern.

## Direct JSON boundary inventory

All active direct `jsonDecode()` and `jsonEncode()` sites are grouped below.

| Category | Owners | Purpose / dependency issue |
|---|---|---|
| Backend HTTP serialization | `UserBootstrapService`, `BackendAuthService`, `ReportService`, `AskNowService`, `PersonalizedHoroscopeService`, `NotificationService`, `AskNowProvider`, `DailyProvider`, `MonthlyProvider`, `YearlyProvider`, `TransitProvider`, `PanchangProvider`, `KundaliProvider`, `ManualKundaliProvider`, `FirebaseKundaliProvider`, `HomeUpcomingEventsProvider`, `CardsProvider`, `CardService`, `LoveApiService`, `ToolResultPage`, `KundaliFormPage`, `GetAnyoneHoroscopeCard`, `MuhurthPage`, `DashboardPage` | Manual raw-map serialization is colocated with transport and presentation state |
| Google REST decoding | `LocationService`, `PlaceAutocompleteField`, `GetAnyoneHoroscopeCard` | Same external response shapes are decoded by three owners |
| Persistent cache serialization | `ToolResultPage` | JSON wrapper with timestamp and Kundali data is encoded/decoded directly in the widget |
| Bundled asset decoding | `CardsProvider`, `ReportCatalogPage`, `DashboardHomeSection` | Local assets are decoded in provider/page/widget owners; this is not remote HTTP but remains a data-source boundary |
| Model helper | `KundaliModel.fromRawJson()` | Convenience constructor decodes a raw JSON string into the existing model |

The commented JSON block in `ToolMetaSection` is not an active boundary.

## Firebase boundary inventory

### Authentication and session

| Boundary | Current owner | Current callers / flow | Missing repository | Duplicate logic / dependency issue | Priority |
|---|---|---|---|---|---|
| Google/Facebook sign-in, Firebase sign-out, user sync | `AuthService` | `LoginPage` -> provider SDK -> FirebaseAuth -> Firestore user doc -> backend registration | Authentication/session repository | One service owns provider SDKs, FirebaseAuth, Firestore, and backend sync | P0 |
| Auth-based routing | `AppRoutes` | Synchronous `FirebaseAuth.instance.currentUser` redirect | Session controller | Router reads concrete SDK state; no auth-state stream owner | P0 |
| Startup auth branch | `SplashPage` | Reads current user then routes | Session controller / AppCoordinator | Duplicates router session decision and keeps startup logic in UI | P0 |
| Dashboard/profile/form identity reads | `DashboardPage`, `DashboardHomeSection`, `ReportCheckoutForm`, `ReportPaymentPage`, `AskNowChatPage`, `BirthDetailPage`, `AddProfilePage`, `FirebaseKundaliProvider`, `NotificationService` | Each reads `FirebaseAuth.instance.currentUser` directly | Session controller | Firebase identity is not a single owned dependency | P0 |
| Direct sign-out | `ProfilePage` | Calls `FirebaseAuth.instance.signOut()` then navigates | Authentication/session repository | Bypasses `AuthService.signOut()` and any future coordinated cleanup | P0 |

### Firestore

The canonical document pattern in current code is
`users/{firebaseUid}` with nested `profiles/{profileId}`. Root user documents
store cross-system fields including `backend_user_id`, `activeProfile`, and FCM
metadata.

| Boundary | Current owner | Current callers / data flow | Missing repository | Duplicate logic / dependency issue | Priority |
|---|---|---|---|---|---|
| User document creation/update after sign-in | `AuthService` | Auth result -> read/write `users/{uid}` -> backend registration ID -> root doc | User/session repository | Root user schema and backend bootstrap are coupled to auth service | P0 |
| Profile CRUD and active-profile selection | `ProfileService` | `ProfileProvider` -> `users/{uid}/profiles/*` plus `users/{uid}.activeProfile` | Profile repository | Best existing service boundary, but it owns concrete Auth/Firestore and raw maps | P1 |
| Initial default profile write | `BirthDetailPage` | Form -> backend bootstrap through `KundaliProvider` -> merge root user -> set `profiles/default` | Profile repository | Page duplicates profile persistence and uses a fixed ID | P1 |
| Add-profile write | `AddProfilePage` | Form -> backend bootstrap -> generated profile doc -> root `activeProfile` update | Profile repository | Duplicates `ProfileService.addProfile()` in UI | P1 |
| Default-profile read after login | `LoginPage` | Reads `profiles/default` to choose next route | Profile/session repository | Presentation owns persistence and assumes fixed profile ID | P1 |
| Active profile + root user read for Kundali | `FirebaseKundaliProvider` | Reads root `activeProfile`, then nested profile, then backend Kundali endpoint | Profile and Kundali repositories | Provider spans two data sources and presentation state | P1 |
| Backend user ID lookup | `AskNowChatPage` and `ReportPaymentPage` | Repeated reads of `users/{uid}.backend_user_id` | User/session repository | Same lookup is duplicated, including twice in AskNow page | P0 |
| FCM token persistence | `DashboardPage` | Messaging token -> root user `fcm_token`, server timestamp -> backend registration | Messaging repository | Same token is persisted to two systems by UI | P0 |

No Firestore snapshot listener is active; current access is request/response
`get`, `set`, `update`, and `delete` access.

### Firebase Messaging

| Boundary | Current owner | Current callers / data flow | Missing repository | Duplicate logic / dependency issue | Priority |
|---|---|---|---|---|---|
| Foreground message listener | `main.dart` | `FirebaseMessaging.onMessage` -> global Kundali context -> `NotificationProvider` unread refresh | Messaging coordinator | Startup holds a UI-context bridge and presentation dependency | P0 |
| Permission, token creation/retry, topic subscription, Firestore/backend registration | `DashboardPage` | Dashboard init -> Messaging SDK -> Firestore + HTTP | Messaging repository/coordinator | Registration only occurs through dashboard lifecycle | P0 |

### Firebase Analytics and Crashlytics

| Boundary | Current owner | Current callers / data flow | Missing repository | Duplicate logic / dependency issue | Priority |
|---|---|---|---|---|---|
| Analytics singleton and route observer | Global in `main.dart`; `AppRoutes` consumes it | Route transitions -> `FirebaseAnalyticsObserver` | Analytics abstraction/coordinator | Global concrete instance crosses bootstrap and routing | P2 |
| Flutter fatal error handler | `main.dart` | `FlutterError.onError` -> `FirebaseCrashlytics.recordFlutterFatalError` | Crash reporting abstraction/coordinator | Only Flutter framework fatal errors are visibly wired here; initialization is coupled to bootstrap | P2 |

## Local storage and cache inventory

### SharedPreferences

| Boundary | Current owner | Current callers / data flow | Missing repository | Duplicate logic / dependency issue | Priority |
|---|---|---|---|---|---|
| Key `app_lang` | `LanguageProvider` | `setLanguage()` writes; `loadSavedLanguage()` reads; application/widgets consume provider state | Settings repository/local data source | Provider owns persistence and presentation state | P2 |
| Dynamic Tool Result cache key | `ToolResultPage` | Read JSON wrapper -> compare timestamp -> use cached Kundali/tool result; fresh response -> write wrapper | Kundali/tool cache repository | Widget owns TTL interpretation, JSON serialization, remote call, and persistent cache | P1 |

No other active SharedPreferences keys were found.

### In-memory caches

| Boundary | Current owner | Data flow / lifecycle | Missing repository | Dependency issue | Priority |
|---|---|---|---|---|---|
| Daily/monthly/yearly request guards | Corresponding horoscope providers | Last query dimensions and response retained until provider disposal | Horoscope repository cache | Cache policy is embedded in UI state | P1 |
| Panchang response and reset policy | `PanchangProvider` | Full/next Panchang retained; reset after configured local hour | Panchang repository cache | Timer, location, caching, and network share provider ownership | P1 |
| Muhurth result map | `CardsProvider` | Keyed by activity, language, and Panchang coordinates; process-memory lifetime | Muhurth repository cache | Cross-provider dependency and no centralized invalidation | P2 |
| Ad object caches | Ad managers/widgets/pages | Loaded SDK ad object retained until show/dispose/failure | Ad coordinator | Multiple incompatible lifecycles; detailed below | P1 |

### Temporary files

The following presentation owners render images to the platform temporary
directory and pass the resulting path to `share_plus`:

* `ManualKundaliResultPage` — `manual_kundali_profile.png`;
* `KundaliDetailPage` — `kundali_share.png`;
* `PlanetResultWidget` — planet-specific PNG;
* `LifeAspectWidget` — `life_aspect_share.png`;
* `YogDoshResultWidget` — yoga-analysis PNG;
* `AstrologyPage` — `astrology_profile.png`;
* `AstrologyToolDetailPage` — `tool_result.png`;
* `CardRenderer` — `jyotishasha_card.png`.

These are share artifacts rather than durable domain storage. There is no
explicit cleanup owner; filenames can be reused and files remain subject to OS
temporary-directory lifecycle. A future share/export boundary is appropriate,
but priority is P2 because behavior is currently local and short-lived.

No application-documents-directory file store, database, secure-storage store,
or explicit disk cache was found in active `lib/` code.

## Google Play Billing boundary inventory

| Boundary | Current owner | Current callers / data flow | Missing repository | Duplicate logic / dependency issue | Priority |
|---|---|---|---|---|---|
| Billing availability probe | `PlayBillingStub` | `main.dart` awaits `InAppPurchase.isAvailable()` before `runApp()` | Billing gateway/coordinator | Startup waits on billing; result is discarded | P0 |
| AskNow consumable purchase | `AskNowProvider` | `main.dart` and `AskNowChatPage` initialize listener; chat starts purchase | Product ID -> query -> `buyConsumable(autoConsume: true)` -> purchase stream -> backend verification -> `completePurchase()` -> local token count | Purchase and entitlement repository | Provider owns SDK subscription, HTTP verification, pending user identity, entitlement state, and UI notifications | P0 |
| Report consumable purchase | `ReportPaymentPage` | Pay button and page-local stream subscription | Fixed product `reports51` -> query -> purchase -> complete -> report webhook -> success navigation | Purchase/report repository | Stateful page owns complete purchase lifecycle and Firestore user lookup; behavior differs from AskNow | P0 |

### Purchase verification and token findings

* AskNow sends `serverVerificationData` as `purchase_token` to
  `/api/chatpack/verify` before calling `completePurchase()`.
* Report payment passes the same server verification token into
  `ReportService.sendReportRequest()`, but `ReportService` does not serialize
  that parameter into its webhook payload. The service therefore exposes a
  verification-token input without transmitting it.
* Report payment calls `completePurchase()` before the webhook result is known.
  The relationship-report branch also completes the purchase before validating
  `love_payload`.
* Both flows use `buyConsumable(autoConsume: true)` and also explicitly complete
  purchases. Their state machines and error handling are separate.
* The report listener handles purchased/error states but has no explicit
  pending, restored, or canceled branch. AskNow handles those statuses but
  requires `_pendingUserId`, including for restored purchases.
* No centralized purchase ledger, idempotency key, persisted pending purchase,
  restore workflow, or purchase-verification repository is present.

These observations are audit findings only; changing purchase order or token
handling requires a separately scoped, behavior-preserving migration.

## Google Mobile Ads boundary inventory

| Boundary | Current owner | Current callers / data flow | Missing repository | Duplicate logic / dependency issue | Priority |
|---|---|---|---|---|---|---|
| SDK initialization | `AdService.initialize()` exists; direct initialization in `main.dart` is commented | No active call to `AdService.initialize()` | Ad coordinator | Active widgets/managers construct ads while the visible centralized initializer is unused | P1 |
| Reusable banner | `BannerAdWidget` | Dashboard, Darshan, Panchang, Muhurth, astrology, manual Kundali, and AskNow screens | Ad gateway/coordinator | Widget directly owns SDK load/dispose state | P1 |
| Direct banner | `TransitContentPage` | Transit page lifecycle | Ad gateway/coordinator | Duplicates `BannerAdWidget` behavior in a feature page | P1 |
| AskNow rewarded flow | `RewardedAdManager` | `AskNowChatPage` loads and shows; after two completions page calls provider/backend reward endpoint | Ad/reward coordinator | Static manager treats dismissal as completion through its callback state, while backend reward policy lives in page/provider | P0 |
| General ad service | `AdService` | No production callers | Ad gateway/coordinator | Parallel unused banner/interstitial/rewarded abstraction using `AdIds` test IDs | P3 |
| Other rewarded implementation | `RewardAdService` | No production callers | Ad gateway/coordinator | Separate stateful rewarded implementation with hard-coded Google test ID | P3 |
| Rewarded button | `RewardedAdButton` | No production callers | Ad gateway/coordinator | Third rewarded lifecycle implementation | P3 |
| Interstitial button | `InterstitialAdButton` | No production callers | Ad gateway/coordinator | Feature-as-widget SDK owner; no active interstitial caller found | P3 |

Ad identifiers are split between `AdUnits` and `AdIds`. `AdIds` contains Google
test IDs, while `AdUnits` contains a separate application-specific set despite
comments describing them as test units. Centralized environment/configuration
ownership is missing. No native or rewarded-interstitial ad use was found.

## Cross-boundary ownership map

| Data or capability | Current owners | Required future single owner |
|---|---|---|
| Firebase session/current user | Auth service, router, splash, providers, services, pages, widgets | Session controller backed by auth repository |
| Backend user identity/token | Auth service, backend auth service, Firestore readers, dashboard | Session/auth repository |
| User profile | Profile service/provider, birth/add/login pages, Firebase Kundali provider | Profile repository |
| Kundali generation | Three providers, two pages, one widget | Kundali repository |
| Place and timezone lookup | Location service plus two widgets | Location repository |
| Muhurth list | Muhurth page and Cards provider | Muhurth repository |
| Notifications/FCM | Notification service/provider, greeting widget, dashboard, main | Notification and messaging repositories/coordinator |
| Purchases | Startup stub, AskNow provider, Report payment page | Billing gateway plus purchase repositories |
| Ads | Multiple services, managers, widgets, and a feature page | Ad gateway/coordinator |
| App settings/cache | Language provider, Tool Result page, feature providers | Settings and feature-specific cache data sources |

## Recommended migration order for later ESR-003 slices

This is sequencing guidance, not implementation:

1. Define transport, failure, and authentication-token boundaries without
   changing endpoint calls or response behavior.
2. Establish the session/current-user owner and backend identity access.
3. Isolate billing verification and FCM registration because both combine
   identity with external side effects.
4. Introduce profile and Kundali repositories, preserving the existing six
   call paths during incremental migration.
5. Consolidate Places, horoscope, Panchang, transit, Muhurth, notifications,
   Love, AskNow, reports, cards, events, and blog boundaries one domain at a
   time.
6. Move SharedPreferences/cache and temporary share-file responsibilities only
   when their owning feature slice is active.
7. Consolidate ad lifecycle/configuration after initialization and reward
   semantics have characterization coverage.
8. Remove orphan or duplicate wrappers only after call-site migration and
   runtime validation prove they are unnecessary.

## Architecture review

### Conformance

* This slice is documentation only.
* No repository, service, provider, widget, route, or runtime dependency is
  introduced or modified.
* Existing ESR-002 contracts are treated as available migration contracts, not
  substituted into production paths.
* Runtime data flow and backend wire behavior remain unchanged.

### Findings against ESR rules

* **One data = one owner:** not yet satisfied at Kundali, Places, Muhurth,
  identity/profile, messaging, billing, ads, and several cache boundaries.
* **Dashboard = presentation layer:** not yet satisfied; `DashboardPage` owns
  FCM permission/token registration, Firestore persistence, backend HTTP, and
  feature data initialization.
* **One bootstrap / AppCoordinator:** not yet satisfied; `main.dart` initializes
  Firebase, Crashlytics, billing, providers, foreground messaging, and global
  transport behavior directly.
* **Feature isolation:** weakened by `CardsProvider` depending on
  `PanchangProvider`, by widgets calling services/HTTP directly, and by shared
  Firebase document access in feature pages.

These are the starting conditions for ESR-003. They are not resolved in this
audit slice.

## Slice result

The network and persistence boundaries are inventoried and prioritized. The
project is ready for the next explicitly authorized ESR-003 slice after the
required validation and tracker update. No repository has been created.
