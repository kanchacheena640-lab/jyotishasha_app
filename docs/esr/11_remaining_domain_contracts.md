# ESR-002 — Remaining Domain Contracts

## Slice

ESR-002 Slice-4

## Scope

This slice defines immutable application contracts for Kundali, Horoscope,
Panchang, Transit, Notifications, Reports, Love, AskNow, Cards, and Muhurth.
The contracts are additive and do not replace existing production maps or alter
providers, services, repositories, widgets, navigation, or runtime behavior.

All contracts use const constructors, nullable fields, `fromJson()`, `toJson()`,
`copyWith()`, value equality, and stable `hashCode`. Numeric and boolean wire
values tolerate the string/number variants identified by the data-contract
audit.

## Shared contract support

File: `lib/core/models/contract_support.dart`

`ContractValue` supplies deep value equality for nested lists and maps. The
support functions provide tolerant string, integer, decimal, boolean, map, and
list parsing. This is serialization infrastructure only and contains no domain
logic.

## Kundali contracts

File: `lib/core/models/kundali/kundali_contracts.dart`

| Model | Fields | Canonical JSON compatibility |
|---|---|---|
| `KundaliProfile` | `name`, `birthDetails`, `language`, `ayanamsa` | Flat profile/birth keys; accepts audited place and language aliases through `BirthDetails` |
| `KundaliRequest` | `profile` | Emits the existing flat request body; accepts nested `profile` |
| `ChartHouse` | `house`, `sign`, `planets` | `house`, `sign`, `planets`; accepts `rashi` |
| `PlanetPlacement` | `name`, `sign`, `house`, `degree`, `nakshatra`, `pada`, `motion`, `details` | Preserves `sign`; accepts `rashi` and numeric strings |
| `ChartData` | `houses`, `planets` | `houses`, `planets` |
| `NotablePlacement` | `planet`, `description`, `details` | `planet`, `description`, `details`; accepts `summary` |
| `KundaliHouseOverview` | `house`, `focus`, `summary`, `notablePlacements` | `house`, `focus`, `summary`, `notable_placements` |
| `DashaPeriod` | `start`, `end`, `period` | `start`, `end`, `period` |
| `Antardasha` | `planet`, `period`, `impact` | Accepts `planet`, `antardasha`, `name`, and `impact_snippet` |
| `Mahadasha` | `planet`, `period`, `antardashas`, `impact` | `planet`, period keys, `antardashas`, `impact` |
| `KundaliDashaSummary` | `currentMahadasha`, `currentAntardasha`, `currentPeriod`, `impactSnippet`, `mahadashas` | `current_block`, `mahadashas`; accepts current-field aliases |
| `YogaDoshaEntry` | `name`, `present`, `description`, `remedies`, `details` | Accepts yoga/dosha title and active/present variants |
| `YogaDoshaCollection` | `yogas`, `doshas` | `yogas`, `doshas`; accepts `yog_doshas` |
| `LifeAspect` | `name`, `title`, `summary`, `details` | Accepts `name`/`key`/`type` and summary/content variants |
| `GemstoneRecommendation` | `gemstone`, `planet`, `substone`, `paragraph` | `gemstone`, `planet`, `substone`, `paragraph` |
| `KundaliMoonTraits` | `title`, `element`, `personality`, `rulingPlanet`, `symbol`, `image` | Canonical `ruling_planet` with camel-case alias |
| `KundaliToolResult` | `type`, `data` | `type`, `data`; accepts `tool` and `result` |
| `KundaliResponse` | success, profile/chart, planets/houses, dasha, yoga/dosha, life aspects, gemstone, moon traits, tool results, error | Preserves the audited top-level snake-case response keys |

## Horoscope contracts

File: `lib/core/models/horoscope/horoscope_contracts.dart`

| Model | Fields | Canonical JSON compatibility |
|---|---|---|
| `HoroscopeQuery` | `sign`, `language`, `year`, `month` | `sign`, `lang`, `year`, `month` |
| `HoroscopeCacheKey` | `sign`, `language`, `period`, `year` | `sign`, `language`, `period`, `year`; accepts `lang` and `month` |
| `DailyHoroscope` | `heading`, `intro`, `paragraph`, `tips`, `luckyColor`, `luckyNumber` | Preserves `lucky_color` and `lucky_number` |
| `MonthlyHoroscope` | title/theme, career/love/health sections, advice, key dates | Preserves `career_money`, `love_relationships`, `health_lifestyle`, `monthly_advice`, `key_dates` |
| `HoroscopeSection` | `key`, `title`, `content`, `points` | Accepts content/text/summary variants |
| `YearlyHoroscope` | `title`, keyed `sections` | Preserves all audited yearly section keys and accepts string or map sections |
| `PersonalizedHoroscopeResponse` | `ok`, `horoscope`, `error` | Preserves the `ok`/`horoscope` response envelope |

## Panchang contracts

File: `lib/core/models/panchang/panchang_contracts.dart`

| Model | Fields | Canonical JSON compatibility |
|---|---|---|
| `PanchangRequest` | coordinates, `date`, `language` | `latitude`, `longitude`, `date`, `language`; accepts `lat`, `lng`, `lang` |
| `TimeRange` | `start`, `end` | `start`, `end` |
| `PanchangNamedElement` | names, `start`, `end`, `details` | `name`, `name_hi`, `start`, `end`, `details` |
| `Tithi` | named-element fields, `paksha` | Adds canonical `paksha` |
| `Nakshatra` | named-element fields, `pada` | Adds numeric/string-compatible `pada` |
| `ChaughadiyaSlot` | `name`, `start`, `end`, `nature`, `active` | Preserves slot keys and tolerant active values |
| `ChaughadiyaSchedule` | `day`, `night` | `day`, `night` slot lists |
| `PanchakStatus` | `active`, `message`, `start`, `end` | Preserves panchak status keys |
| `PanchangEvent` | `id`, `title`, `start`, `end`, `type`, `details` | Accepts title/name variants |
| `PanchangDay` | day identity, solar times, named elements, ranges, panchak, chaughadiya, events | Preserves all audited Panchang day keys |
| `PanchangResponse` | `selectedDate`, `nextDate` | `selected_date`, `next_date` |
| `PanchangCacheKey` | date, coordinates, language | Accepts coordinate and language aliases |

## Transit contracts

File: `lib/core/models/transit/transit_contracts.dart`

| Model | Fields | Canonical JSON compatibility |
|---|---|---|
| `PlanetTransitPosition` | `rashi`, `degree`, `motion` | Preserves position keys and numeric-string degrees |
| `FutureTransit` | `enteringDate`, `rashi`, `details` | Canonical `entering_date` |
| `CurrentTransitResponse` | keyed `positions`, keyed `futureTransits` | `positions`, `future_transits` |
| `TransitPlanetView` | display name/rashi/degree/motion/next change | Preserves derived-map keys including `rashi_number` and `next_change` |
| `TransitContentRequest` | `ascendant`, `planet`, `house`, `language` | Canonical query keys with `lang` |
| `TransitContentSection` | `title`, `content`, `points` | Accepts content/text/summary variants |
| `TransitContentResponse` | `heading`, `summary`, `sections`, `points`, `closing`, `articleUrl` | Canonical `article_url` with camel-case alias |

## Notification contracts

File: `lib/core/models/notifications/notification_contracts.dart`

| Model | Fields | Canonical JSON compatibility |
|---|---|---|
| `NotificationDestination` | `route`, `arguments` | `route`, `arguments`; accepts `extra` |
| `NotificationData` | `destination`, raw `payload` | Preserves all FCM data while typing route information |
| `AppNotification` | `id`, `title`, `body`, `isRead`, `createdAt`, `data` | Accepts notification ID, body/message, read, and timestamp variants |
| `NotificationListResponse` | `notifications` | Accepts both a top-level list and `{notifications: [...]}` |
| `UnreadCountResponse` | `unreadCount` | Canonical `unread_count` with camel-case alias |
| `MarkNotificationReadRequest` | `notificationId` | Canonical `notification_id` |

## Love contracts

File: `lib/core/models/love/love_contracts.dart`

| Model | Fields | Canonical JSON compatibility |
|---|---|---|
| `LovePersonInput` | `name`, Slice-3 `BirthDetails`, `gender` | Preserves flat participant birth/location fields |
| `LoveCompatibilityRequest` | `language`, `boyIsUser`, `user`, `partner` | Canonical `boy_is_user`, `user`, `partner` |
| `LoveApiResponse<T>` | `ok`, typed `data`, `error` | Preserves `{ok, data, error}` envelope |
| `LoveResult` | sealed result base | Serialization contract for all Love result variants |
| `LoveResultSection` | `id`, `title`, `data` | Preserves section identifier and dynamic audited section data |
| `KootaResult` | `name`, `score`, `maxScore`, `notes` | Canonical `max_score`; numeric-string compatible |
| `AshtakootResult` | `totalScore`, `maxScore`, `kootas` | Canonical `total_score`, `max_score`, `kootas` |
| `CompatibilityVerdict` | `level`, `reasonLine`, `scorePercent` | Preserves `reason_line`, `score_pct` |
| `MatchMakingResult` | `ashtakoot`, `verdict`, `sections` | Preserves match-making response keys |
| `PersonDoshaResult` | `name`, `isMangalic`, `severity`, `dosha`, `remedies` | Canonical `is_mangalic` |
| `MangalDoshaResult` | `signal`, `summary`, `boy`, `girl` | Accepts nested `mangal_dosh` or direct result |
| `MarriagePersonResult` | `name`, `percent`, `band`, `reasons` | Canonical `pct`; accepts probability/status aliases |
| `MarriageProbabilityResult` | `userResult`, `partnerResult` | `user_result`, `partner_result` |
| `TruthOrDareResult` | `verdict`, `verdictLine`, `blocks` | `verdict`, `verdict_line`, `blocks` |
| `LoveReportHandoff` | report identity and compatibility request | Canonical `report_id`, `report_title`, `love_payload` |

## Report contracts

File: `lib/core/models/reports/report_contracts.dart`

| Model | Fields | Canonical JSON compatibility |
|---|---|---|
| `LocalizedReportContent` | title, descriptions, category | Preserves existing mixed `short_description` and `fullDescription` names |
| `ReportCatalogItem` | `id`, English/Hindi content, `price`, `image` | Preserves all audited `_hi` catalog keys |
| `ReportSelection` | typed catalog item | Accepts nested `report` or existing flat route map |
| `ReportBirthDetails` | `name`, Slice-3 `BirthDetails` | Accepts `lat`/`lng` and `latitude`/`longitude` |
| `ReportCheckoutDraft` | identity/contact, birth details, language, Love payload | Preserves checkout keys and `love_payload` |
| `ReportPurchaseReceipt` | `product`, `purchaseToken`, `userId` | Canonical `purchase_token`, `user_id`; accepts camel-case aliases |
| `ReportGenerationRequest` | identity/contact, product, birth details, purchase/user identity, language | Preserves webhook `latitude`/`longitude` and purchase keys |
| `RelationshipReportRequest` | generation request, `boyIsUser`, typed partner | Canonical `boy_is_user`, `partner` |
| `ReportGenerationOutcome` | `success`, `reportId`, `message` | Accepts success/ok and report ID aliases |

## AskNow contracts

File: `lib/core/models/asknow/asknow_contracts.dart`

| Model | Fields | Canonical JSON compatibility |
|---|---|---|
| `AskNowBirthData` | `name`, Slice-3 `BirthDetails` | Preserves audited profile birth aliases |
| `AskQuestionRequest` | `userId`, `question`, `birth` | Canonical `user_id`, `question`, `birth` |
| `AskAnswerResponse` | `success`, `answer`, `remainingTokens`, `message` | Accepts string/nested answer and all audited remaining-token aliases |
| `AskNowStatus` | `freeAvailable`, `freeUsedToday`, `remainingTokens` | Preserves status endpoint keys |
| `RewardQuestionResponse` | `success`, `addedTokens`, `totalTokens` | Accepts added/remaining token aliases |
| `ChatMessage` | `sender`, `text`, `createdAt` | Preserves page chat keys; timestamp remains opaque |
| `ChatPackProduct` | `productId`, `title`, `price`, `tokens` | Accepts product ID and token/question aliases |
| `ChatPackVerificationRequest` | `userId`, `productId`, `purchaseToken` | Preserves purchase verification payload keys |
| `ChatPackVerificationResult` | `success`, `remainingTokens`, `message` | Accepts success/ok and token aliases |

## Muhurth contracts

File: `lib/core/models/muhurth/muhurth_contracts.dart`

| Model | Fields | Canonical JSON compatibility |
|---|---|---|
| `MuhurthActivity` | `code`, `name` | Accepts activity/code/id and name/title variants |
| `MuhurthRequest` | activity, coordinates, `days`, `topK`, language | Preserves `top_k` and audited request keys |
| `MuhurthReason` | `type`, `name`, `description`, `details` | Accepts reason/summary variants |
| `MuhurthResult` | date/window, score, reasons, tithi, nakshatra, weekday | Preserves audited result fields and nested factors |
| `MuhurthResponse` | `results` | Preserves `{results: [...]}` envelope |
| `MuhurthCacheKey` | activity, coordinates, days, language | Accepts coordinate and language aliases |

## Card contracts

File: `lib/core/models/cards/card_contracts.dart`

| Model | Fields | Canonical JSON compatibility |
|---|---|---|
| `CardType` | `value` | Represents the open backend `type` value |
| `CardDesignType` | `value` | Represents the open `design_type` value |
| `CardTemplate` | bilingual title/subtitle/content/CTA/footer/share text | Preserves all template `_en`/`_hi` keys |
| `CardMetadata` | sealed metadata base | Serialization contract for metadata variants |
| `GenericCardMetadata` | raw typed JSON values | Losslessly preserves unclassified metadata |
| `PanchangCardMetadata` | `abhijit`, `rahu`, `details` | Preserves Panchang placeholders and remaining metadata |
| `MuhurthCardMetadata` | typed `MuhurthResult` | Reuses the Muhurth contract |
| `CardShareContent` | `title`, `text`, `image` | Accepts `text`/`share_text` |
| `AstroCardSource` | `type`, bilingual titles, `data` | Preserves Astro asset keys |
| `InsightCardSource` | bilingual title/content/CTA | Preserves Insight asset keys |
| `AppCard` | card identity/design/content/template/metadata/Muhurth fields | Preserves the existing `CardModel` wire keys without replacing it |
| `CardFeedResponse` | `cards` | Preserves `{cards: [...]}` envelope |

## Relationships

| Parent | Child | Purpose |
|---|---|---|
| Kundali request/profile | Slice-3 `BirthDetails` | Canonical birth/location representation |
| Panchang response | Day, named elements, ranges, slots, events | Typed Panchang response tree |
| Current transit response | Planet positions and future transitions | Preserves keyed planet response maps |
| Notification | Notification data and destination | Separates message content from navigation data |
| Love participant | Slice-3 `BirthDetails` | Reuses profile-compatible birth inputs |
| Love API response | Sealed `LoveResult` variants | Types each supported Love tool result |
| Report checkout/request | Slice-3 `BirthDetails` | Reuses profile-compatible birth inputs |
| Relationship report | Love participant/request contracts | Types the Reports–Love handoff |
| AskNow request | Slice-3 `BirthDetails` | Reuses profile-compatible birth inputs |
| Card metadata | Panchang/Muhurth metadata variants | Types shared Cards inputs |
| Muhurth card metadata | `MuhurthResult` | Avoids duplicate Muhurth result schemas |

## Migration notes

1. These contracts must remain disconnected from runtime consumers until the
   owning ESR domain phase introduces adapters and fixture-backed migration.
2. Existing `KundaliModel`, `KundaliData`, and `CardModel` remain migration
   inputs; this slice does not replace or delete them.
3. Preserve alternate envelopes for notifications, Love, AskNow, and
   personalized horoscope responses at their boundaries.
4. Preserve numeric-string parsing for scores, coordinates, identifiers,
   counts, tokens, houses, and dates represented numerically.
5. Preserve opaque section/detail maps where the audit does not establish a
   stable nested schema. Narrow those maps only after representative fixtures.
6. Keep DTO parsing separate from derived state such as transit display
   planets, Panchang events, and Cards composition.
7. Do not move network calls, persistence, ownership, cache behavior, or
   navigation as part of contract adoption.
8. Continue using Slice-2 shared contracts and Slice-3 user/session/profile
   contracts wherever wire compatibility is preserved.

## Runtime impact

None. No existing production consumer imports these contracts in Slice-4.
