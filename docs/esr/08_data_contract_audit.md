# ESR-002 — Application Data Contract Audit

## Slice and objective

This is ESR-002, Slice 1. It documents the current application data shapes and the typed contracts that will be required later. It does not define or implement those contracts.

The audit covers the complete active `lib/` tree, including providers, services, Firebase access, HTTP boundaries, route arguments, widgets that parse response maps, bundled JSON assets, and existing models. Production behavior remains unchanged.

## Audit method and interpretation

The project was inspected for:

- `Map<String, dynamic>`, raw `Map`, and `List<dynamic>` representations;
- explicit `dynamic` declarations and values inferred from decoded JSON;
- `jsonDecode` and `json.decode` at service, provider, and UI boundaries;
- direct HTTP response parsing;
- direct Firestore document reads and writes;
- existing model classes, duplicate representations, and route/widget map arguments.

Lexical inventory:

| Signal | Count |
|---|---:|
| Dart files containing at least one audited signal | 91 |
| `Map<String, dynamic>` occurrences | 271 |
| `dynamic` tokens | 343 |
| direct JSON decode calls | 45 |
| Firestore/document-data markers | 22 |

These counts are discovery signals, not proposed model counts. They include model factory input maps, framework generics, and dormant commented code. In particular, `lib/l10n/app_localizations.dart` uses framework-required `dynamic`, and most of `lib/core/widgets/tool_meta_section.dart` is commented legacy code. Neither should create an application contract by itself.

## Executive findings

1. The application has two working typed boundaries: `BlogPost` and a partial `CardModel`. Neither establishes a general contract pattern for the active core domains.
2. Kundali has typed classes, but active providers and UI continue to exchange maps. `KundaliModel` and `KundaliData` describe different, partially overlapping views and are not the active response authority.
3. Firestore user and profile documents have no typed adapters. Key aliases such as `backendProfileId`, `backend_profile_id`, `backendUserId`, and `backend_user_id` are normalized ad hoc.
4. HTTP decoding occurs in services, providers, and widgets/pages. Several UI files decode or interpret backend/asset JSON directly.
5. Profile, location, birth details, backend identifiers, selected reports, Love participants, and purchase data are copied between maps with no shared type.
6. Panchang and Muhurth each have multiple consumers and caches that assume the same untyped nested shapes independently.
7. Runtime behavior depends on permissive coercion: `?.toString()`, `int.tryParse`, default empty maps/lists, alternate response envelopes, and aliases. Future model parsing must preserve those coercions and defaults.

## Domain summary

| Domain | Current typed model | Dynamic/map usage | Main duplicate or split | Estimated contracts |
|---|---|---|---|---:|
| User | Firebase `User` only | Yes | Firebase identity, Firestore user, backend user | 6 |
| Profile | None | Yes | Firestore map, Provider map, form maps | 8 |
| Session | Firebase `User` snapshot only | Limited maps; implicit state | Firebase session and backend token/user ID | 4 |
| Kundali | Partial `KundaliModel`; separate `KundaliData` | Extensive | Four result paths and two typed representations | 15–20 |
| Horoscope | None | Yes | Three providers plus personalized service | 7 |
| Panchang | `PanchangEvent` only | Extensive | Provider maps, derived getters, UI maps | 10–12 |
| Transit | None | Yes | Raw current response, derived planet maps, content response | 6 |
| Notifications | None | Yes | Backend list, Provider count, FCM data map | 6 |
| Reports | None | Yes | Asset catalog, route maps, checkout/payment maps | 9–11 |
| Love | `LoveTool` enum only | Extensive | Payload/result copies and four result shapes | 12–16 |
| AskNow | None | Yes | Backend status, Provider flags, page chat maps | 8–10 |
| Cards | Partial `CardModel` | Yes | Active provider composition and alternate API service | 7–9 |
| Muhurth | None | Yes | Page and Cards caches/API parsing | 5–7 |
| Shared/Common | `BlogPost`, `TrendingQuestion` | Yes | Location and API envelopes repeated | 10–12 |

# Domain audits

## User

| Required report item | Finding |
|---|---|
| Current data source | Firebase Auth; Firestore `users/{uid}`; `/api/auth/register`; `/api/auth/token`; `/api/user/bootstrap` |
| Current model | Firebase SDK `User`; no application-owned user model |
| Missing models | Application user document, identity snapshot, backend registration request/response, backend link, token response, bootstrap response |
| Duplicate models/representations | Firebase `User`, Firestore user map, backend numeric user identity, and page-local backend IDs |
| Uses `dynamic`? | Yes, through decoded backend bodies and Firestore values |
| Uses `Map<String, dynamic>`? | Yes, especially bootstrap input/output and Firestore writes |
| Estimated contracts required | 6 |

### Current sources and shapes

- `lib/services/auth_service.dart` copies Firebase fields into Firestore: `uid`, `name`, `email`, `photo`, `provider`, `createdAt`, `updatedAt`, `lastLogin`, `activeProfileId`, and `backend_user_id`.
- `lib/services/backend_auth_service.dart` posts `firebase_uid`, `email`, `phone`, and `name`; it reads `success`, `user_id`, and `token` from untyped decoded responses.
- `lib/services/user_bootstrap_service.dart` accepts and returns `Map<String, dynamic>` and only checks `ok`/`error`.
- `lib/features/login/login_page.dart`, `lib/features/birth/birth_detail_page.dart`, and dashboard/profile flows access the same Firestore user record directly.

### Required contract family

- `AppUserDocument`
- `AuthIdentitySnapshot`
- `BackendUserLink`
- `RegisterUserRequest` / `RegisterUserResponse`
- `BackendTokenResponse`
- `UserBootstrapResponse`

The adapter must preserve nullable identity fields and the current numeric-or-string handling of backend IDs.

## Profile

| Required report item | Finding |
|---|---|
| Current data source | Firestore `users/{uid}/profiles`; profile forms; bootstrap response |
| Current model | None |
| Missing models | Profile, profile draft, birth details, profile location, astrology summary, create/update payload, active-profile selection, backend identifiers |
| Duplicate models/representations | Firestore documents, `ProfileProvider` maps, `FirebaseKundaliProvider.profileData`, form controllers/maps |
| Uses `dynamic`? | Yes |
| Uses `Map<String, dynamic>`? | Yes, throughout service, provider, routes, and UI |
| Estimated contracts required | 8 |

### Current sources and shapes

- `lib/services/profile_service.dart` returns `List<Map<String, dynamic>>` and merges document IDs into Firestore data.
- `lib/core/state/profile_provider.dart` owns `activeProfile` and `otherProfiles` as maps. It selects using `isActive` while root Firestore also stores `activeProfileId`.
- Common fields are `id`, `name`, `dob`, `tob`, `pob`, `lat`, `lng`, `place_id`, `timezone`, `gender`, `language`, `isActive`, `createdAt`, and `updatedAt`.
- Astrology/profile completion fields include `lagna`, `moon_sign`, `nakshatra`, `profile_complete`, `backend_user_id`, and `backend_profile_id`.
- Alias handling exists for `backendProfileId`/`backend_profile_id`, `backendProfileID`, `backendUserId`, and `backendUserID`.
- `lib/features/profile/add_profile_page.dart`, `edit_profile_page.dart`, `profile_page.dart`, and `profile_list_page.dart` create, mutate, and display profile maps directly.

### Required contract family

- `Profile`
- `ProfileId` and `BackendProfileId`
- `ProfileDraft`
- `BirthDetails`
- `ProfileLocation`
- `ProfileAstrologySummary`
- `ProfileCreateRequest` / `ProfileUpdateRequest`
- `ActiveProfileSelection`

Parsing must retain current field aliases, date string formats, nullable coordinates, first-profile activation behavior, and the distinction between absent active profile and an empty fallback map.

## Session

| Required report item | Finding |
|---|---|
| Current data source | `FirebaseAuth.instance.currentUser`; Firebase SDK persistence; backend token endpoint |
| Current model | Firebase SDK `User`; no explicit application session state |
| Missing models | Session snapshot, authentication state, backend session credentials, sign-in outcome |
| Duplicate models/representations | Point-in-time Firebase reads across router/pages/services; backend token and backend user ID stored separately |
| Uses `dynamic`? | Indirectly through token/user records |
| Uses `Map<String, dynamic>`? | Not for Firebase session itself; yes for backend session responses |
| Estimated contracts required | 4 |

### Current sources and shapes

- Router, Splash, dashboard, services, reports, AskNow, and profile pages independently read `currentUser`.
- No app-owned state distinguishes unknown/restoring, authenticated, unauthenticated, or backend-linked states.
- The backend JWT response is decoded ad hoc, while `backend_user_id` is reread directly from Firestore in AskNow and report payment.

### Required contract family

- `SessionSnapshot`
- `AuthenticationState`
- `BackendSessionCredentials`
- `SignInOutcome`

The first contract implementation must preserve snapshot-based behavior; adding reactive session semantics would be a behavior change and is outside this slice.

## Kundali

| Required report item | Finding |
|---|---|
| Current data source | `/api/full-kundali-modern`; `/api/user/bootstrap`; Firestore active profile; direct form HTTP |
| Current model | Partial `KundaliModel` with `Planet`, `HouseOverview`, `DashaSummary`, `GemstoneSuggestion`, `MoonTraits`; separate `KundaliData`/`HouseData` |
| Missing models | Request/profile/chart, placements, houses, dashas, yogas/doshas, life aspects, result sections, tool-specific results |
| Duplicate models/representations | `KundaliModel` vs `KundaliData`; four live map-based response paths |
| Uses `dynamic`? | Extensively |
| Uses `Map<String, dynamic>`? | Extensively across providers and UI |
| Estimated contracts required | 15–20 |

### Current sources and paths

- `KundaliProvider.kundaliData`
- `ManualKundaliProvider.kundali`
- `FirebaseKundaliProvider.kundaliData` and `profileData`
- direct decode in `lib/features/kundali/kundali_form_page.dart`
- timestamped tool response/cache maps in `lib/features/tools/tool_result_page.dart`

All paths reach similar backend data but use different request keys (`place`, `pob`, `place_name`), optional timezone/language handling, and different injection of a `profile` node.

### Existing model gaps and duplication

- `KundaliModel` is not used by active providers or result pages.
- `KundaliData` only represents twelve chart houses and is consumed by `kundali_chart_widget.dart`.
- Existing `Planet` expects `sign`, while active UI/backend paths also use `rashi`, `planet_overview`, and `chart_data.planets` variants.
- Widgets parse nested keys directly: `houses_overview`, `planet_overview`, `dasha_summary`, `current_block`, `current_mahadasha`, `current_antardasha`, `mahadashas`, `life_aspects`, `yogas`, `manglik_dosh`, `sadhesati`, `moon_traits`, and `gemstone_suggestion`.

### Required contract family

- `KundaliRequest`
- `KundaliProfile`
- `KundaliResponse`
- `ChartData` and `ChartHouse`
- `PlanetPlacement`
- `HouseOverview` and `NotablePlacement`
- `DashaSummary`, `DashaPeriod`, `Mahadasha`, and `Antardasha`
- `YogaDoshaCollection` and typed entries
- `LifeAspect`
- `GemstoneRecommendation`
- `MoonTraits`
- typed tool result variants

The eventual canonical response must absorb or retire both existing typed representations only after fixtures confirm actual backend variants.

### Main map consumers

`lib/features/kundali/`, `lib/features/manual_kundali/`, `lib/features/astrology/`, `lib/features/tools/`, `lib/core/widgets/astrology_studio_widget.dart`, `lib/core/registry/tool_registry.dart`, and Kundali result widgets.

## Horoscope

| Required report item | Finding |
|---|---|
| Current data source | Daily, monthly, yearly, and personalized backend endpoints |
| Current model | None; daily/monthly values are flattened into Provider fields |
| Missing models | Query/cache key, daily response, monthly response, yearly response/sections, personalized envelope |
| Duplicate models/representations | Three root providers plus `PersonalizedHoroscopeService`; UI normalizes yearly sections again |
| Uses `dynamic`? | Yes |
| Uses `Map<String, dynamic>`? | Yes, especially yearly/personalized responses |
| Estimated contracts required | 7 |

### Current shapes

- Daily: `heading`, `intro`, `paragraph`, `tips`, `lucky_color`, `lucky_number`.
- Monthly: `title`, `theme`, `career_money`, `love_relationships`, `health_lifestyle`, `monthly_advice`, `key_dates`.
- Yearly: `title` plus untyped sections such as `introduction`, `planetary_overview`, `career_finance`, `love_relationships`, `health_wellness`, `spirituality_remedies`, and `final_summary`.
- Personalized service accepts/returns `Map<String, dynamic>` and unwraps an `ok`/`horoscope` response.
- `lib/core/widgets/horoscope_card_widget.dart` accepts `dynamic` content and converts strings/lists/maps in UI.

### Required contract family

- `HoroscopeQuery`
- `DailyHoroscope`
- `MonthlyHoroscope`
- `YearlyHoroscope`
- `HoroscopeSection`
- `PersonalizedHoroscopeResponse`
- `HoroscopeCacheKey`

## Panchang

| Required report item | Finding |
|---|---|
| Current data source | `/api/panchang`; current clock; location/language input |
| Current model | `PanchangEvent` only; no response model |
| Missing models | Request, envelope, day, named elements, time ranges, chaughadiya slot, panchak, event result |
| Duplicate models/representations | `fullPanchang`/`nextPanchang`, derived getters, event markup maps, UI maps |
| Uses `dynamic`? | Yes, including `List<dynamic>` slots |
| Uses `Map<String, dynamic>`? | Yes |
| Estimated contracts required | 10–12 |

### Current shapes

- Request: `latitude`, `longitude`, `date`, `language`.
- Envelope: `selected_date`, `next_date`.
- Day fields: `sunrise`, `sunset`, `weekday`, `month_name`, `tithi`, `nakshatra`, `yoga`, `karan`, `rahu_kaal`, `abhijit_muhurta`, `brahma_muhurta`, `panchak`, and `chaughadiya.day/night`.
- Nested objects repeatedly assume `name`, `paksha`, `start`, `end`, `active`, `message`, `nature`, and localized name variants.
- `PanchangEventMarkup` clones raw maps and derives event objects; Panchang, greeting, cards, and alert widgets still consume raw Provider maps.

### Required contract family

- `PanchangRequest`
- `PanchangResponse`
- `PanchangDay`
- `PanchangNamedElement`
- `Tithi` / `Nakshatra`
- `TimeRange`
- `ChaughadiyaSchedule` / `ChaughadiyaSlot`
- `PanchakStatus`
- `PanchangEvent`
- `PanchangCacheKey`

## Transit

| Required report item | Finding |
|---|---|
| Current data source | `/api/transit/current`; personalized `/api/transit` |
| Current model | None |
| Missing models | Current response, planet position, future transition, derived display planet, personalized request/response/section |
| Duplicate models/representations | Raw `positions`/`future_transits`, derived `allPlanets` maps, `contentData` |
| Uses `dynamic`? | Yes |
| Uses `Map<String, dynamic>`? | Yes |
| Estimated contracts required | 6 |

### Current shapes

- Current response uses `positions` keyed by planet and `future_transits` lists.
- Position fields include `rashi`, `degree`, and `motion`; future entries use `entering_date`.
- Provider derives maps with `name`, `rashi`, `rashi_number`, `degree`, `motion`, and `next_change`.
- Personalized response exposes `heading`, `summary`, `sections`, `points`, `closing`, and optional `article_url` through direct map reads.

### Required contract family

- `CurrentTransitResponse`
- `PlanetTransitPosition`
- `FutureTransit`
- `TransitPlanetView`
- `TransitContentRequest`
- `TransitContentResponse` / `TransitContentSection`

## Notifications

| Required report item | Finding |
|---|---|
| Current data source | Notification backend; Firebase Messaging event data |
| Current model | None |
| Missing models | Notification item, list envelope, unread response, mark-read request, FCM payload/navigation data |
| Duplicate models/representations | Backend unread value, Provider count, foreground increments; list Future/snapshot maps |
| Uses `dynamic`? | Yes through raw list/maps |
| Uses `Map<String, dynamic>`? | Implicit/raw; service returns untyped `List` |
| Estimated contracts required | 6 |

### Current shapes

- Unread endpoint reads `unread_count`.
- List endpoint accepts both a top-level list and `{ "notifications": [...] }`.
- Notification UI reads `id`, `title`, `body`, and nested `data.route` directly.
- Mark-read posts `notification_id`.
- Foreground FCM callback increments count without parsing a typed message contract.

### Required contract family

- `AppNotification`
- `NotificationData`
- `NotificationDestination`
- `NotificationListResponse`
- `UnreadCountResponse`
- `MarkNotificationReadRequest`

## Reports

| Required report item | Finding |
|---|---|
| Current data source | `reports.json`/`reports_hi.json`; profile maps; Google Play; report webhook |
| Current model | None |
| Missing models | Catalog item, localized content, selection, checkout form, report birth details, purchase receipt, generation requests/outcome |
| Duplicate models/representations | Dashboard/catalog asset maps, selected-report maps, child/parent form maps, payment payload |
| Uses `dynamic`? | Yes |
| Uses `Map<String, dynamic>`? | Yes throughout pages/widgets/service |
| Estimated contracts required | 9–11 |

### Current shapes

- Catalog fields include `id`, `title`, `title_hi`, `description`, `description_hi`, `short_description`, `fullDescription`, `fullDescription_hi`, `category`, `category_hi`, `price`, and `image`.
- Report selection is passed as a map from dashboard/catalog to checkout/payment.
- Checkout data includes `name`, `email`, `dob`, `tob`, `pob`, `lat`, `lng`, `phone`, `language`, and optional `love_payload`.
- Payment reads Firestore `backend_user_id`, Google Play `PurchaseDetails`, product ID `reports51`, and the server verification token.
- `ReportService` builds webhook payloads using `product`, `purchase_token`, `user_id`, location fields, and optional `boy_is_user`/`partner`.
- The backend result is reduced to `bool`; the app has no generated-report model.

### Required contract family

- `ReportCatalogItem`
- `LocalizedReportContent`
- `ReportSelection`
- `ReportCheckoutDraft`
- `ReportBirthDetails`
- `ReportPurchaseReceipt`
- `ReportGenerationRequest`
- `RelationshipReportRequest`
- `ReportGenerationOutcome`

## Love

| Required report item | Finding |
|---|---|
| Current data source | Love form; `LoveApiService`; route arguments; Provider; report flow |
| Current model | `LoveTool` and local `Gender` enums only |
| Missing models | Person/birth input, request, response envelope, result union, match/mangal/marriage/truth results, report handoff |
| Duplicate models/representations | Form payload, Provider payload, hub widget payload, route result maps, report `love_payload` |
| Uses `dynamic`? | Extensively |
| Uses `Map<String, dynamic>`? | Extensively |
| Estimated contracts required | 12–16 |

### Current shapes

- Request participants use `name`, `dob`, `tob`, `pob`, `lat`, `lng`, gender/boy ownership, and `language`.
- API expects `{ok, data}` and returns `data` as a raw map.
- Match-making parses `ashtakoot`, `verdict`, `sections`, `score`, `max_score`, `score_pct`, `koota_notes`, `strengths`, `risks`, `reasons`, and disclaimers.
- Mangal result parses `mangal_dosh`, `boy`, `girl`, `is_mangalic`, `severity`, `dosha`, and remedies.
- Marriage probability parses `user_result`, `partner_result`, probability/status/reason fields.
- Truth-or-dare parses blocks, verdict, insight, bullets, and disclaimer content.
- Result pages read `ModalRoute.settings.arguments as Map<String, dynamic>` and reconstruct nested maps in UI.

### Required contract family

- `LovePersonInput`
- `LoveCompatibilityRequest`
- `LoveApiResponse<T>`
- sealed `LoveResult`
- `MatchMakingResult`, `AshtakootResult`, `KootaResult`, `CompatibilityVerdict`
- `MangalDoshaResult` / `PersonDoshaResult`
- `MarriageProbabilityResult`
- `TruthOrDareResult`
- `LoveResultSection`
- `LoveReportHandoff`

## AskNow

| Required report item | Finding |
|---|---|
| Current data source | Profile map; AskNow backend; reward endpoint; Google Play purchase stream |
| Current model | None |
| Missing models | Birth payload, question request, answer, status, reward result, chat message, product/purchase verification |
| Duplicate models/representations | Backend status and Provider flags; pending answer and page chat map; profile aliases |
| Uses `dynamic`? | Yes |
| Uses `Map<String, dynamic>`? | Yes in service, provider, and page |
| Estimated contracts required | 8–10 |

### Current shapes

- `AskNowService.buildBirthFromProfile` accepts aliases such as `pob`/`place_name`/`placeName`, `lat`/`latitude`, `lng`/`longitude`, and `timezone`/`tz`.
- Request fields include `user_id`, `question`, and `birth`.
- Answer may be a string or map; the service cleans it into `answer` and also reads `remaining_tokens` variants.
- Status fields: `free_available`, `free_used_today`, `remaining_tokens`.
- Reward fields: `success`, `total_tokens`, and added/remaining variants.
- Page chat uses `List<Map<String, String>>` with `sender` and `text`.
- Purchase verification posts `user_id`, `product_id`, and `purchase_token`.

### Required contract family

- `AskNowBirthData`
- `AskQuestionRequest`
- `AskAnswerResponse`
- `AskNowStatus`
- `RewardQuestionResponse`
- `ChatMessage`
- `ChatPackProduct`
- `ChatPackVerificationRequest` / `ChatPackVerificationResult`

## Cards

| Required report item | Finding |
|---|---|
| Current data source | Card API, local templates/assets, Astro/Insight JSON, Panchang, Muhurth API |
| Current model | `CardModel`, but `template`, `meta`, and `reasons` remain untyped |
| Missing models | Card response envelope, template, typed metadata variants, Astro/Insight source entries, share content |
| Duplicate models/representations | `CardService` API path and active `CardsProvider` composition path |
| Uses `dynamic`? | Yes |
| Uses `Map<String, dynamic>`? | Yes inside the existing model and templates |
| Estimated contracts required | 7–9 |

### Current shapes

- Base card fields: `type`, `design_type`, `image`, bilingual title/content, `cta`, `template`, `meta`, `muhurth_type`, `score`, `date`, and `reasons`.
- Template maps contain localized title, subtitle, content, CTA, footer, and share text.
- Metadata shape varies by card type: Panchang times, planet, night thought, CTA/share strings, or Muhurth data.
- `CardsProvider` decodes Astro and Insight assets as raw lists and reads entry fields in composition/UI.
- `CardService` expects `{cards: [...]}` but is separate from the active Provider composition path.

### Required contract family

- `CardFeedResponse`
- `Card`
- `CardTemplate`
- sealed `CardMetadata`
- `AstroCardSource`
- `InsightCardSource`
- `CardShareContent`
- `CardType` / `CardDesignType`

## Muhurth

| Required report item | Finding |
|---|---|
| Current data source | `/api/muhurth/list`; location picker; Panchang coordinates |
| Current model | None |
| Missing models | Activity, request, response, result/window, reason, cache key |
| Duplicate models/representations | `MuhurthPage` results/global cache and `CardsProvider` private cache |
| Uses `dynamic`? | Yes, results are `List<dynamic>` |
| Uses `Map<String, dynamic>`? | Results are implicit maps; request/result wrappers are raw |
| Estimated contracts required | 5–7 |

### Current shapes

- Request: `activity`, `latitude`, `longitude`, `days`, `top_k`, `language`.
- Response: `results`.
- Result fields used by page/cards include `date`, `score`, `reasons`, and nested descriptive Panchang factors such as `tithi`, `nakshatra`, and weekday.
- Page-level `muhurthCache` and `CardsProvider._muhurthCache` use separately composed string keys.

### Required contract family

- `MuhurthActivity`
- `MuhurthRequest`
- `MuhurthResponse`
- `MuhurthResult`
- `MuhurthReason`
- `MuhurthCacheKey`

## Shared/Common

| Required report item | Finding |
|---|---|
| Current data source | Google Places endpoints, generic HTTP responses, route arguments, SharedPreferences, static assets |
| Current model | `BlogPost`, `TrendingQuestion`; scattered typed string maps |
| Missing models | Coordinates/location, API failure/envelope, language/date/time values, route arguments, tool cache entry |
| Duplicate models/representations | Location suggestions/details reimplemented across widgets/pages; generic success/error envelopes |
| Uses `dynamic`? | Yes |
| Uses `Map<String, dynamic>`? | Yes |
| Estimated contracts required | 10–12 |

### Current shared boundaries

- `LocationService`, `place_picker.dart`, `place_autocomplete_field.dart`, `get_anyone_horoscope_card.dart`, profile forms, Panchang, Muhurth, Love, reports, and manual Kundali use overlapping place shapes.
- Typical place fields are `description`, `place_id`, `lat`, `lng`, and timezone/offset variants.
- `ToolResultPage` stores decoded wrapper/result maps with cache timestamps in SharedPreferences.
- `app_routes.dart` passes untyped extra maps, notably report details.
- Constants/catalogs such as `life_aspect_meta.dart`, `planet_meta.dart`, `yog_dosh_meta.dart`, `astrology_meta.dart`, card templates, and report assets use map catalogs that should eventually be typed configuration.
- `BlogPost` is typed, but its service chain is currently unreachable; it is not a pattern used by active domains.

### Required contract family

- `Coordinates`
- `PlaceSuggestion`
- `PlaceDetails`
- `LanguageCode`
- `LocalDate`, `LocalTime`, and `TimeZoneOffset` value objects
- `ApiError`
- `ApiResponse<T>` only where the backend really uses a shared envelope
- typed route argument objects
- `ToolCacheEntry<T>`
- typed static catalog entries

# Direct decode and loose-boundary inventory

## Service/provider boundaries

- User/session: `backend_auth_service.dart`, `user_bootstrap_service.dart`.
- Profile/Firebase: `profile_service.dart`, `firebase_kundali_provider.dart`, and direct user reads in AskNow/report pages.
- Kundali/tools: `kundali_provider.dart`, `manual_kundali_provider.dart`, `firebase_kundali_provider.dart`, `kundali_form_page.dart`, `tool_result_page.dart`.
- Horoscope: `daily_provider.dart`, `monthly_provider.dart`, `yearly_provider.dart`, `personalized_horoscope_service.dart`.
- Panchang/events: `panchang_provider.dart`, `home_upcoming_events_provider.dart`.
- Transit: `transit_provider.dart`.
- Notifications: `notification_service.dart`.
- Reports: report asset decode in `report_catalog_page.dart`; webhook request is constructed in `report_service.dart`.
- Love: `love_api_service.dart`.
- AskNow: `asknow_service.dart`.
- Cards/Muhurth: `card_service.dart`, `cards_provider.dart`, `muhurth_page.dart`.
- Shared: `location_service.dart`, `blog_service.dart`.

## JSON decoded directly in UI or presentation-owned files

- `lib/core/widgets/get_anyone_horoscope_card.dart`
- `lib/core/widgets/place_autocomplete_field.dart`
- `lib/features/dashboard/dashboard_home_section.dart`
- `lib/features/kundali/kundali_form_page.dart`
- `lib/features/reports/pages/report_catalog_page.dart`
- `lib/features/tools/tool_result_page.dart`
- `lib/features/muhurth/muhurth_page.dart`
- `lib/features/cards/provider/cards_provider.dart` (Provider also composes presentation cards)

These are contract-boundary candidates, not authorization for repository or architecture changes in this slice.

# File-level dynamic/map inventory

The following active or potentially active files contain application-owned loose data. Files are grouped by the contract domain they primarily serve; some participate in more than one domain.

## User, Profile, and Session

- `lib/app/routes/app_routes.dart`
- `lib/services/auth_service.dart`
- `lib/services/backend_auth_service.dart`
- `lib/services/user_bootstrap_service.dart`
- `lib/services/profile_service.dart`
- `lib/core/state/profile_provider.dart`
- `lib/core/state/firebase_kundali_provider.dart`
- `lib/features/login/login_page.dart`
- `lib/features/birth/birth_detail_page.dart`
- `lib/features/profile/add_profile_page.dart`
- `lib/features/profile/edit_profile_page.dart`
- `lib/features/profile/profile_page.dart`
- `lib/features/profile/profile_list_page.dart`
- `lib/features/asknow/asknow_chat_page.dart`
- `lib/features/reports/pages/report_payment_page.dart`

## Kundali and Astrology tools

- `lib/core/models/kundali_model.dart`
- `lib/core/models/kundali_models.dart`
- `lib/core/state/kundali_provider.dart`
- `lib/core/state/manual_kundali_provider.dart`
- `lib/core/state/firebase_kundali_provider.dart`
- `lib/core/registry/tool_registry.dart`
- `lib/core/widgets/astrology_studio_widget.dart`
- `lib/features/kundali/kundali_detail_page.dart`
- `lib/features/kundali/kundali_form_page.dart`
- `lib/features/kundali/kundali_section_detail_page.dart`
- all files under `lib/features/kundali/widgets/`
- `lib/features/manual_kundali/manual_kundali_form_page.dart`
- `lib/features/manual_kundali/manual_kundali_result_page.dart`
- `lib/features/astrology/astrology_tool_detail_page.dart`
- `lib/features/astrology/data/astrology_meta.dart`
- `lib/features/astrology/widgets/astrology_profile_card.dart`
- `lib/features/astrology/widgets/astrology_tool_section.dart`
- `lib/features/astrology/widgets/manual_astrology_tool_section.dart`
- `lib/features/tools/tool_result_page.dart`
- all result widgets under `lib/features/tools/widgets/`
- `lib/core/constants/life_aspect_meta.dart`
- `lib/core/constants/planet_meta.dart`
- `lib/core/constants/yog_dosh_meta.dart`

## Horoscope

- `lib/core/state/daily_provider.dart`
- `lib/core/state/monthly_provider.dart`
- `lib/core/state/yearly_provider.dart`
- `lib/services/personalized_horoscope_service.dart`
- `lib/core/widgets/horoscope_card_widget.dart`
- `lib/core/widgets/get_anyone_horoscope_card.dart`
- `lib/features/horoscope/horoscope_page.dart`

## Panchang and Transit

- `lib/core/state/panchang_provider.dart`
- `lib/core/state/home_upcoming_events_provider.dart`
- `lib/core/utils/panchang_event_markup.dart`
- `lib/features/panchang/panchang_page.dart`
- `lib/core/widgets/panchang_card_widget.dart`
- `lib/core/widgets/chaughadiya_alert_widget.dart`
- `lib/core/state/transit_provider.dart`
- `lib/core/widgets/transit_alert_widget.dart`
- `lib/features/transit/pages/transit_content_page.dart`

## Notifications

- `lib/services/notification_service.dart`
- `lib/core/state/notification_provider.dart`
- `lib/core/widgets/greeting_header_widget.dart`
- `lib/main.dart`

## Reports and Love

- `lib/services/report_service.dart`
- `lib/features/reports/pages/report_catalog_page.dart`
- `lib/features/reports/pages/report_checkout_page.dart`
- `lib/features/reports/pages/report_payment_page.dart`
- `lib/features/reports/widgets/report_card.dart`
- `lib/features/reports/widgets/report_checkout_form.dart`
- `lib/features/love/services/love_api_service.dart`
- `lib/features/love/providers/love_provider.dart`
- `lib/features/love/pages/love_partner_form_page.dart`
- `lib/features/love/pages/love_result_hub_page.dart`
- `lib/features/love/pages/match_making_result_page.dart`
- `lib/features/love/pages/mangal_dosh_result_page.dart`
- `lib/features/love/pages/marriage_probability_result_page.dart`
- `lib/features/love/pages/truth_or_dare_result_page.dart`
- `lib/features/love/widgets/key_match_card.dart`
- `lib/features/love/widgets/love_premium_cta_card.dart`

## AskNow

- `lib/services/asknow_service.dart`
- `lib/core/state/asknow_provider.dart`
- `lib/features/asknow/asknow_chat_page.dart`

## Cards and Muhurth

- `lib/features/cards/data/card_model.dart`
- `lib/features/cards/data/card_service.dart`
- `lib/features/cards/data/card_templates.dart`
- `lib/features/cards/provider/cards_provider.dart`
- `lib/features/cards/presentation/cards_page.dart`
- `lib/features/cards/presentation/widgets/card_renderer.dart`
- `lib/features/cards/presentation/widgets/share_poster.dart`
- `lib/features/muhurth/muhurth_page.dart`

## Shared/Common

- `lib/services/location_service.dart`
- `lib/core/widgets/place_autocomplete_field.dart`
- `lib/core/widgets/place_picker.dart`
- `lib/services/blog_service.dart`
- `lib/core/models/blog_models.dart`
- `lib/core/utils/translator.dart`
- `lib/features/dashboard/dashboard_home_section.dart`

## Exclusions and dormant findings

- Generated localization delegate generics are framework contracts, not application data contracts.
- `lib/core/widgets/tool_meta_section.dart` contains a large commented legacy implementation. Its shapes are useful historical evidence for Kundali fields but are not active runtime consumers.
- Strongly typed static maps such as `Map<String, String>` still indicate potential value/configuration objects, but are lower priority than external `dynamic` boundaries.
- Flutter/Firebase/Google Play SDK types (`User`, `PurchaseDetails`, `ProductDetails`, message SDK types) should be adapted at boundaries rather than duplicated field-for-field without need.

# Contract design constraints for later ESR-002 slices

1. Preserve current wire names, including snake_case and known camelCase aliases.
2. Preserve permissive numeric parsing where backend IDs, scores, coordinates, counts, and tokens may arrive as strings or numbers.
3. Preserve null/default behavior. Existing flows intentionally fall back to empty collections, empty strings, zero, `false`, or `null` depending on the boundary.
4. Keep DTO parsing separate from domain/view derivation. Transit display planets, Panchang events, and Cards composition are derived forms, not wire DTOs.
5. Do not make fields required until representative fixtures prove they are always present.
6. Model alternate envelopes explicitly where currently supported, especially notification lists and Love/AskNow responses.
7. Use typed identifiers and value objects only where they do not alter serialization or equality behavior relied on by current code.
8. Treat existing `KundaliModel`, `KundaliData`, and `CardModel` as migration inputs, not automatically canonical contracts.
9. Add fixture-backed characterization before replacing any map consumer.
10. Contract introduction alone must not move HTTP/Firebase calls, change Provider ownership, or start repository work.

# Recommended implementation order for subsequent ESR-002 slices

This is a design sequence, not work started by this audit:

1. Shared primitives: identifiers, coordinates/place, date/time parsing, and tolerant JSON helpers.
2. User, Session, and Profile contracts, because their maps feed nearly every personalized domain.
3. Kundali request/profile and top-level response, followed by nested result contracts based on fixtures.
4. Horoscope, Panchang, and Transit response contracts.
5. Notification contracts.
6. Cards and Muhurth contracts together because the active Cards Provider consumes Muhurth and Panchang data.
7. AskNow status/message/purchase contracts.
8. Love result union and Reports checkout/purchase/report handoff contracts together.

No repository, Provider, route, or runtime migration is implied until its own tracked ESR slice explicitly authorizes it.
