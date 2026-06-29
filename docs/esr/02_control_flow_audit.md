# Enterprise Control Flow Audit

## Audit boundary

This document records executable control flow found under `lib/`. Commented-out code is not counted as active behavior. “Startup” means the path from `main()` through the first Login or Dashboard render; feature lifecycle entries are recorded separately when they begin work only after their widget is opened.

# SECTION 1 — Startup Controllers

| Controller | File | Responsibility in the current flow |
|---|---|---|
| `main()` | `lib/main.dart:41-99` | Orders binding creation, global HTTP override installation, Firebase initialization, foreground-message listener registration, Crashlytics handler assignment, billing availability check, provider registration, and `runApp()` |
| `ForceIPv4.createHttpClient()` | `lib/main.dart:30-37` | Overrides every subsequently created `HttpClient` so `findProxy` returns `DIRECT` |
| `DefaultFirebaseOptions.currentPlatform` | `lib/firebase_options.dart:18-52` | Selects the platform Firebase configuration consumed by `Firebase.initializeApp()` |
| `PlayBillingStub.init()` | `lib/services/play_billing_stub.dart:6-8` | Calls and awaits `InAppPurchase.isAvailable()` before `runApp()` |
| `FirebaseMessaging.onMessage` callback | `lib/main.dart:50-59` | Handles later foreground FCM events by locating `NotificationProvider` through `globalKundaliContext` and incrementing unread state |
| `MultiProvider` provider factories | `lib/main.dart:68-98` | Defines application-scope provider access. `AskNowProvider` is eager; the other factories retain Provider's default lazy behavior |
| `AskNowProvider.initBilling()` | `lib/core/state/asknow_provider.dart:55-83` | Creates the application-scope purchase-stream listener; invoked by the eager provider factory |
| `LanguageProvider.loadSavedLanguage()` | `lib/core/state/language_provider.dart:22-26` | Begins an unawaited SharedPreferences read for `app_lang`, then notifies the root widget |
| `JyotishashaApp.build()` | `lib/app/app.dart:16-42` | Reads language state, publishes a global provider-aware context, and constructs `MaterialApp.router` with theme, locale, delegates, and router |
| Top-level `appRouter` construction | `lib/app/routes/app_routes.dart:27-101` | Creates the GoRouter, initial location, analytics observer, redirect policy, error page, and route builders |
| GoRouter top-level `redirect` | `lib/app/routes/app_routes.dart:34-51` | Checks `FirebaseAuth.instance.currentUser`; protects all routes except Login and Splash for a null user and redirects an authenticated Login request to Dashboard |
| Root-route redirect | `lib/app/routes/app_routes.dart:65` | Converts `/` to `/splash` |
| `SplashPage.initState()` | `lib/features/splash/splash_page.dart:15-18` | Starts `_checkAuthAndNavigate()` as soon as the splash state is created |
| `SplashPage._checkAuthAndNavigate()` | `lib/features/splash/splash_page.dart:20-45` | Waits two seconds, checks mounted state and the Firebase user snapshot, then schedules Login-or-Dashboard navigation in a microtask |
| `_LoginPageState` construction | `lib/features/login/login_page.dart:14-16` | Constructs `AuthService`, which captures Firebase Auth and Firestore singletons; no sign-in starts until the button is pressed |
| `DashboardPage.initState()` | `lib/features/dashboard/dashboard_page.dart:39-50` | Schedules a one-time post-frame callback that starts profile loading and `_initFlow()` |
| `DashboardPage._initFlow()` | `lib/features/dashboard/dashboard_page.dart:55-90` | Rechecks the user, starts FCM initialization without awaiting it, awaits the core dashboard data chain, then schedules another unread-count load |
| `DashboardPage._loadAndRefreshAll()` | `lib/features/dashboard/dashboard_page.dart:95-128` | Sequences active-profile/kundali loading, daily horoscope loading, and panchang loading |
| `DashboardPage._printAndSaveFcmToken()` | `lib/features/dashboard/dashboard_page.dart:133-176` | Requests notification permission, obtains/recreates a token, subscribes to `general_0`, writes Firestore, and invokes backend token synchronization |
| `DashboardHomeSection.initState()` | `lib/features/dashboard/dashboard_home_section.dart:45-53` | Registers the lifecycle observer and begins home-report and unread-count loading |
| `BannerAdWidget.initState()` | `lib/core/ads/banner_ad_widget.dart:19-22` | Starts the banner load rendered on the initial dashboard tab |

The cold-start controller chain is therefore `main()` -> provider/root widget build -> GoRouter redirect -> Splash -> Firebase user decision -> Login or Dashboard. Dashboard feature initialization starts after the Dashboard has already been selected and rendered.

# SECTION 2 — Navigation Decision Points

## Central router decisions

| File | Decision | Trigger | Destination |
|---|---|---|---|
| `lib/app/routes/app_routes.dart:29` | Select initial router location | GoRouter construction | `/splash` |
| `lib/app/routes/app_routes.dart:34-51` | Redirect null users away from protected locations | Any redirect evaluation where `currentUser == null` and location is neither Login nor Splash | `/login` |
| `lib/app/routes/app_routes.dart:34-51` | Redirect authenticated users away from Login | Redirect evaluation where `currentUser != null` and location is `/login` | `/dashboard` |
| `lib/app/routes/app_routes.dart:65` | Root route redirect | Matched `/` | `/splash` |
| `lib/app/routes/app_routes.dart:68-99` | Map matched paths to page builders | Match of `/splash`, `/onboarding`, `/login`, `/birth`, `/dashboard`, `/astrology`, `/reports`, `/asknow`, `/profile`, `/subscription`, `/darshan`, or `/astrology/detail` | Corresponding page widget; the detail route also reads `state.extra` |
| `lib/app/routes/app_routes.dart:54-61` | Select fallback UI | No registered route matches | Router 404 `Scaffold` |

## GoRouter calls and shell-level decisions

| File | Decision | Trigger | Destination |
|---|---|---|---|
| `lib/features/splash/splash_page.dart:33-43` | Replace Splash with Login, Dashboard, or fallback Login | Two-second delay completes; null/non-null user; catch fallback | `/login` or `/dashboard` via `context.go()` |
| `lib/features/login/login_page.dart:40-48` | Choose post-Google-login route | `profiles/default` exists, is absent, or Firestore read throws | `/dashboard` when it exists; `/birth` otherwise |
| `lib/features/onboarding/onboarding_page.dart:57` | Leave onboarding | Continue button on final onboarding page | `/login` |
| `lib/features/birth/birth_detail_page.dart:391` | Finish birth/profile setup | Save flow completes and widget is mounted | `/dashboard` |
| `lib/features/horoscope/horoscope_page.dart:182` | Leave horoscope feature | Astrology action button | `/astrology` |
| `lib/features/dashboard/dashboard_home_section.dart:331` | Open Darshan | Day-lord CTA tap | Push `/darshan` |
| `lib/features/astrology/widgets/astrology_tool_section.dart:225-228` | Open selected generated astrology tool | Tool tap after resolving title/data/current kundali | Push `/astrology/detail` with `extra` |
| `lib/features/astrology/widgets/manual_astrology_tool_section.dart:282-285` | Open selected manual astrology tool | Tool tap after resolving title/data/current manual kundali | Push `/astrology/detail` with `extra` |
| `lib/core/widgets/engagement_cards_widget.dart:20-49,67` | Go to the route stored by each card | Card tap | `/love-compatibility`, `/yog-dosh`, or `/asknow` |
| `lib/features/dashboard/dashboard_page.dart:203-209,269-271` | Switch dashboard feature without router navigation | Bottom-navigation index changes | In-memory page: Home, Astrology, Reports, Cards, or Profile |
| `lib/features/dashboard/dashboard_page.dart:214-235` | Handle system back | Back on non-Home tab; first Home back; second Home back within two seconds | Home tab; snackbar/no route change; then `SystemNavigator.pop()` |

Only `/asknow` among the three `EngagementCardsWidget` destinations is declared in `app_routes.dart`. No `/love-compatibility` or `/yog-dosh` GoRoute appears in the current route table.

## Direct `Navigator` page transitions

| File | Decision | Trigger | Destination |
|---|---|---|---|
| `lib/core/widgets/astrology_studio_widget.dart:80-86` | Push selected astrology category | Category card tap | `AstrologyPage(selectedSection: cat["key"])` |
| `lib/core/widgets/blog_carousel_widget.dart:71-82` | Open blog only when URL is non-empty | Blog card tap | `BlogReaderPage` with URL/title |
| `lib/core/widgets/trending_questions_widget.dart:24-29` | Open AskNow | Trending-question widget tap | `AskNowChatPage` |
| `lib/core/widgets/transit_alert_widget.dart:259-272` | Open transit detail only when active profile exists, then request content in a microtask | Planet alert tap | `TransitContentPage` |
| `lib/core/widgets/panchang_card_widget.dart:170-175` | Open panchang | View-details button | `PanchangPage` |
| `lib/core/widgets/greeting_header_widget.dart:247-252` | Open daily horoscope | Read-more tap | `HoroscopePage(initialTab: 0)` |
| `lib/core/widgets/greeting_header_widget.dart:282-285` | Open Darshan | Darshan shortcut tap | `DarshanPage` |
| `lib/core/widgets/greeting_header_widget.dart:327-330` | Open Panchang | Panchang shortcut tap | `PanchangPage` |
| `lib/core/widgets/greeting_header_widget.dart:366-369` | Open Cards | Cards shortcut tap | `CardsPage` |
| `lib/core/widgets/get_anyone_horoscope_card.dart:140-146` | Open generated kundali only after HTTP 200 and mounted check | Form/API success | `KundaliDetailPage(data)` |
| `lib/features/tools/tool_result_page.dart:395-400` | Open astrology from related tool | Related-tool card tap | `AstrologyPage` |
| `lib/features/manual_kundali/manual_kundali_form_page.dart:239-243` | Open manual result | Submission completes while mounted | `ManualKundaliResultPage` |
| `lib/features/kundali/kundali_form_page.dart:58-66` | Open kundali result | Kundali HTTP response is 200 and widget is mounted | `KundaliDetailPage(data)` |
| `lib/features/astrology/astrology_page.dart:186-194` | Enter default love tool | Love action button | `LovePartnerFormPage(tool: matchMaking)` |
| `lib/features/dashboard/dashboard_home_section.dart:219-225` | Open selected cards category | Home cards callback supplies a type | `CardsPage(initialType: type)` |
| `lib/features/dashboard/dashboard_home_section.dart:228-234` | Open all muhurth content | “See more” callback | `MuhurthPage` |
| `lib/features/dashboard/dashboard_home_section.dart:279-290` | Begin selected report checkout | Home report tap | `ReportCheckoutPage(selectedReport, activeProfile)` |
| `lib/features/reports/pages/report_catalog_page.dart:419-432` | Special-case relationship report | Buy action where report ID is `relationship_future_report` | `LovePartnerFormPage` after current frame |
| `lib/features/reports/pages/report_catalog_page.dart:435-454` | Begin ordinary report checkout | Buy action for any other report | `ReportCheckoutPage(selectedReport, activeProfile)` after current frame |
| `lib/features/reports/pages/report_checkout_page.dart:64-72` | Move from form to payment | Checkout form submits data | `ReportPaymentPage` |
| `lib/features/reports/pages/report_payment_page.dart:190-201` | Replace payment with fixed-title success | Relationship report generation returns `ok` | `ReportSuccessPage` |
| `lib/features/reports/pages/report_payment_page.dart:237-248` | Replace payment with selected-report success | Ordinary report generation returns `ok` | `ReportSuccessPage` |
| `lib/features/reports/pages/report_success_page.dart:98` | Clear pages back to stack root | “Go Home” button | First route in the current Navigator stack |
| `lib/features/love/pages/love_partner_form_page.dart:167-182` | Choose free tool flow | Submit where `widget.tool != null` | `LoveResultHubPage(tool, payload)` |
| `lib/features/love/pages/love_partner_form_page.dart:185-197` | Choose paid report flow | Submit where `widget.tool == null` | `ReportPaymentPage` for relationship report |
| `lib/features/love/widgets/love_premium_cta_card.dart:61-73` | Enter premium payment only when provider payload exists | Enabled CTA tap | `ReportPaymentPage` |
| `lib/features/love/pages/love_result_hub_page.dart:52-106` | Auto-open a result once its requested provider result appears | `LoveProvider` listener update and per-tool navigation flag is false | Matching one of four result pages via post-frame `Navigator.push` |
| `lib/features/love/pages/love_result_hub_page.dart:140-156` | Reopen cached matchmaking result or start loading it | Matchmaking card tap | `MatchMakingResultPage` when result exists; otherwise no immediate navigation |
| `lib/features/love/pages/love_result_hub_page.dart:184-200` | Reopen cached mangal-dosh result or start loading it | Mangal Dosh card tap | `MangalDoshResultPage` when result exists; otherwise no immediate navigation |
| `lib/features/love/pages/love_result_hub_page.dart:229-243` | Reopen cached truth-or-dare result or start loading it | Truth-or-Dare card tap | `TruthOrDareResultPage` when result exists; otherwise no immediate navigation |
| `lib/features/love/pages/love_result_hub_page.dart:271-285` | Reopen cached marriage-probability result or start loading it | Marriage Probability card tap | `MarriageProbabilityResultPage` when result exists; otherwise no immediate navigation |
| `lib/features/profile/profile_page.dart:28-49` | Clear navigation after logout | Logout sequence completes | Named `/login`, removing all earlier routes |
| `lib/features/profile/profile_page.dart:73-77` | Add profile and refresh on `true` result | Add button | `AddProfilePage` |
| `lib/features/profile/profile_page.dart:104-111` | Edit active profile and refresh on `true` result | Active-profile edit button | `EditProfilePage(activeProfile)` |
| `lib/features/profile/profile_page.dart:206-216` | Activate, edit, or delete another profile | Popup selection | State mutation, or `EditProfilePage`; delete has no route change |
| `lib/features/profile/profile_list_page.dart:42-47` | Replace named route by bottom-nav index | Index 0-3; index 4 returns | `/home`, `/panchang`, `/astrology`, or `/asknow` |
| `lib/features/profile/profile_list_page.dart:53-58` | Add and refresh | Floating action button | `AddProfilePage` |
| `lib/features/profile/profile_list_page.dart:126-132` | Edit and refresh | Row edit button | `EditProfilePage(profile)` |

The central GoRouter declares `/astrology` and `/asknow`, but does not declare `/home` or `/panchang`. These `ProfileListPage` calls use `Navigator.pushReplacementNamed`, not `context.go()`.

## Local-route dismissal and modal decisions

| File | Decision | Trigger | Destination |
|---|---|---|---|
| `lib/features/blog/blog_reader_page.dart:50` | Close reader | Back button | Previous route |
| `lib/features/birth/birth_detail_page.dart:124,188` | Close custom date/time picker after assigning selected value | Picker selection | Previous modal route |
| `lib/features/panchang/panchang_page.dart:118` | Close place dialog, then change location | Valid place selection | Underlying Panchang page |
| `lib/features/muhurth/muhurth_page.dart:268` | Close location bottom sheet, then refetch | Valid place selection | Underlying Muhurth page |
| `lib/features/asknow/asknow_chat_page.dart:394` | Close pack sheet before validating/starting purchase | Buy action | Underlying AskNow page |
| `lib/features/asknow/chatpack_success_page.dart:54` | Close success page | Button tap | Previous route |
| `lib/features/profile/add_profile_page.dart:201` | Return successful add result | Profile save completes | Previous route with `true` |
| `lib/features/profile/edit_profile_page.dart:165` | Return successful edit result | Update succeeds | Previous route with `true` |
| `lib/features/profile/edit_profile_page.dart:189,193` | Resolve delete confirmation | Cancel/Delete dialog action | Dialog caller with `false`/`true` |
| `lib/features/profile/edit_profile_page.dart:204` | Return successful delete result | Delete succeeds while mounted | Previous route with `true` |

Date/time pickers and bottom sheets are also opened with `showDatePicker`, `showTimePicker`, `showDialog`, or `showModalBottomSheet` in the birth/profile/manual-kundali/love/report/panchang/muhurth/AskNow/greeting/mahadasha flows. The table above enumerates explicit application-owned `Navigator.pop` decisions; framework-owned picker dismissal is handled inside Flutter's picker APIs.

# SECTION 3 — Authentication Decision Points

| File | Check or action | Why the current code performs it |
|---|---|---|
| `lib/app/routes/app_routes.dart:34-51` | Reads `FirebaseAuth.instance.currentUser` | Enforces route admission: null users are sent to Login; authenticated Login requests are sent to Dashboard |
| `lib/features/splash/splash_page.dart:20-43` | Reads `FirebaseAuth.instance.currentUser` after two seconds | Chooses the initial Login or Dashboard landing; catch path attempts Login |
| `lib/services/auth_service.dart:16-43` | Google sign-in, Firebase credential sign-in, then `user != null` | Establishes Firebase identity and starts Firestore/backend synchronization only when Firebase returned a user |
| `lib/services/auth_service.dart:51-67` | Facebook sign-in status, Firebase credential sign-in, then `user != null` | Rejects unsuccessful Facebook login and synchronizes only a valid Firebase user |
| `lib/services/auth_service.dart:137-155` | Firebase, Google, and Facebook sign-out calls | Clears identity from all three authentication providers represented by this service |
| `lib/features/login/login_page.dart:21-50` | Calls `AuthService.signInWithGoogle()` and checks `user == null`; then checks Firestore `profiles/default` | Stops when login is cancelled/failed; otherwise distinguishes existing-profile Dashboard flow from Birth setup flow |
| `lib/features/profile/profile_page.dart:28-49` | Direct Google and Firebase sign-out | Implements the Profile page logout sequence before clearing the stack to Login; this path does not call `AuthService.signOut()` |
| `lib/features/dashboard/dashboard_page.dart:55-63` | Checks current user at dashboard init | Stops all dashboard Firebase/backend initialization when the user snapshot is null |
| `lib/features/dashboard/dashboard_page.dart:161-167` | Rechecks current user before Firestore FCM update | Obtains the UID needed to update `users/{uid}` after asynchronous token work |
| `lib/features/dashboard/dashboard_page.dart:178-194` | Reads user and requests ID token | Supplies bearer authorization for backend FCM synchronization; returns if no token exists |
| `lib/features/dashboard/dashboard_home_section.dart:71-82` | Polls until `currentUser` is non-null | Delays unread-count loading until an authenticated Firebase user is visible |
| `lib/core/state/firebase_kundali_provider.dart:45-62` | Checks current user | Obtains UID for root-user and active-profile Firestore reads; aborts when absent |
| `lib/services/profile_service.dart:11-13,39-41,54-56,72-74,94-96,113-118` | Each CRUD method reads `_auth.currentUser?.uid` | Scopes profile operations to the signed-in user's subcollection and returns an empty/null/false/no-op value when no UID exists |
| `lib/services/notification_service.dart:12-16,57-59,98-100` | Each notification operation checks current user | Supplies Firebase UID for backend-token lookup and prevents notification API calls without a session |
| `lib/features/birth/birth_detail_page.dart:327-328` | Checks current user before save/bootstrap flow | Supplies UID for the new user's Firestore data and prevents an unauthenticated birth save |
| `lib/features/profile/add_profile_page.dart:122-123` | Checks current user before profile creation flow | Supplies the user identity used by the subsequent Firestore/backend work |
| `lib/features/asknow/asknow_chat_page.dart:102-104` | Checks current user in `_getBackendUserId()` | Supplies UID to read `backend_user_id` from Firestore |
| `lib/features/asknow/asknow_chat_page.dart:308-326` | Rechecks user before opening payment sheet when cached backend ID is absent | Prevents pack purchase setup without a Firebase user and resolves the backend user ID |
| `lib/features/reports/pages/report_payment_page.dart:42-48` | Checks current user before reading backend user ID | Prevents report purchase/report generation identity lookup without a Firebase session |
| `lib/features/reports/widgets/report_checkout_form.dart:54` | Reads `currentUser?.email` | Prefills the checkout email; an absent user produces an empty string rather than aborting |

There is no `authStateChanges`, `idTokenChanges`, or `userChanges` listener in `lib/`. Authentication is evaluated through point-in-time reads and explicit sign-in/sign-out calls.

# SECTION 4 — Application Initialization

## Application and landing initialization

| Initialization | Start point | Ordering and scope |
|---|---|---|
| Flutter binding | `lib/main.dart:42` | First executable startup step |
| Global HTTP override | `lib/main.dart:44-45` | Installed before Firebase and all UI |
| Firebase Core | `lib/main.dart:48` | Awaited before listeners, Crashlytics, billing, or UI |
| Foreground FCM handling | `lib/main.dart:50-59` | Listener registered after Firebase; its subscription handle is not stored in this file |
| Crashlytics | `lib/main.dart:61` | Replaces `FlutterError.onError` with `recordFlutterFatalError` |
| Billing availability | `lib/main.dart:63`, `lib/services/play_billing_stub.dart:6-8` | Awaited before UI; returned availability is not stored |
| Provider graph | `lib/main.dart:68-98` | Installed around the root app; only AskNow is explicitly eager |
| AskNow billing events | `lib/main.dart:87-94`, `lib/core/state/asknow_provider.dart:55-83` | Eager purchase-stream subscription |
| Language/SharedPreferences | `lib/main.dart:71-73`, `lib/core/state/language_provider.dart:22-26` | Begins when root first watches the lazy provider; not awaited by provider creation |
| Theme/localization/router | `lib/app/app.dart:16-41` | Constructed during root build |
| Firebase Analytics route observation | `lib/main.dart:39`, `lib/app/routes/app_routes.dart:31` | Top-level analytics singleton is supplied to router observer |
| Splash auth selection | `lib/features/splash/splash_page.dart:15-43` | Begins in Splash `initState`; executes after fixed delay |
| Login service access | `lib/features/login/login_page.dart:14-16` | `AuthService` captures Auth/Firestore instances when Login state is created |
| Dashboard profile loading | `lib/features/dashboard/dashboard_page.dart:43-48` | Starts unawaited after first Dashboard frame |
| Dashboard FCM registration | `lib/features/dashboard/dashboard_page.dart:67-70,133-198` | Starts unawaited from `_initFlow()` |
| Dashboard kundali | `lib/features/dashboard/dashboard_page.dart:95-108`, `lib/core/state/firebase_kundali_provider.dart:45-133` | First awaited core-data stage; Firestore active profile then backend request |
| Dashboard daily data | `lib/features/dashboard/dashboard_page.dart:110-119`, `lib/core/state/daily_provider.dart:37-74` | Starts only when kundali data exists |
| Dashboard panchang | `lib/features/dashboard/dashboard_page.dart:121-127`, `lib/core/state/panchang_provider.dart:24-28,62-111` | Provider construction starts a minute timer; request starts after daily stage completes |
| Dashboard unread counts | `lib/features/dashboard/dashboard_home_section.dart:71-83`, `lib/features/dashboard/dashboard_page.dart:76-86` | Home starts one load; `_initFlow()` schedules another after core loading plus two seconds |
| Dashboard home reports | `lib/features/dashboard/dashboard_home_section.dart:88-115` | Loads and shuffles report asset data in Home `initState` |
| Dashboard banner ad | `lib/core/ads/banner_ad_widget.dart:19-43` | Loads when the initial Home-tab banner state is created |
| Mobile Ads SDK | `lib/main.dart:65-66`, `lib/core/ads/ad_service.dart:12-25` | The `main.dart` call is commented out; `AdService.initialize()` exists but no call to it appears in `lib/` |

## Feature-local initialization entry points

These do not run at process startup unless their widget becomes part of the selected flow.

| Feature/controller | Initialization begun in current code |
|---|---|
| `ToolResultPage.initState()` (`lib/features/tools/tool_result_page.dart:42-45`) | Starts tool data loading with its SharedPreferences cache path |
| `HoroscopePage.initState()` (`lib/features/horoscope/horoscope_page.dart:28-45`) | Creates TabController, installs tab listener, and loads the initial tab post-frame |
| `AstrologyPage.initState()` (`lib/features/astrology/astrology_page.dart:38-44`) | Schedules selected-section scrolling after 400 ms |
| `DarshanPage.initState()` (`lib/features/darshan/darshan_page.dart:28-60`) | Configures global audio context, sets day data, starts animation, and schedules mantra autoplay post-frame |
| `ReportCheckoutForm.initState()` (`lib/features/reports/widgets/report_checkout_form.dart:42-95`) | Creates controllers from profile/Firebase email and notifies parent post-frame |
| `ReportPaymentPage.initState()` (`lib/features/reports/pages/report_payment_page.dart:56-68`) | Loads backend user ID and subscribes to purchase updates |
| `ReportCatalogPage.initState()` (`lib/features/reports/pages/report_catalog_page.dart:33-51`) | Loads English and Hindi report assets |
| `AskNowChatPage.initState()` (`lib/features/asknow/asknow_chat_page.dart:53-74`) | Creates input/focus state, focuses post-frame, reasserts billing listener, loads rewarded ad, then syncs chat status and provider listener post-frame |
| `CardsPage.initState()` (`lib/features/cards/presentation/cards_page.dart:20-36`) | In a microtask, ensures panchang exists and then loads cards |
| `BlogReaderPage.initState()` (`lib/features/blog/blog_reader_page.dart:19-37`) | Creates WebViewController, navigation delegate, and loads URL |
| `ProfilePage` / `ProfileListPage` (`lib/features/profile/profile_page.dart:21-25`, `lib/features/profile/profile_list_page.dart:18-22`) | Start profile loading in microtasks |
| `MuhurthPage.initState()` (`lib/features/muhurth/muhurth_page.dart:80-84`) | Starts initial muhurth request post-frame |
| `PanchangPage.initState()` (`lib/features/panchang/panchang_page.dart:32-37`) | Starts language-aware panchang load post-frame |
| Ad widgets (`lib/core/ads/banner_ad_widget.dart`, `interstitial_ad_button.dart`, `rewarded_ad_button.dart`) | Load their respective ad objects in `initState()` |
| Transit content/alert (`lib/features/transit/pages/transit_content_page.dart:21-40`, `lib/core/widgets/transit_alert_widget.dart:22-40`) | Loads banner ad; creates and listens to page controller |
| Home presentation widgets (`shubh_muhurth_banner_widget.dart`, `chaughadiya_alert_widget.dart`, `rotating_earth.dart`) | Start periodic rotation/scroll or repeating animations on state creation |

# SECTION 5 — Lifecycle Controllers

## Application lifecycle observer

| Construct | File | What it controls |
|---|---|---|
| `WidgetsBindingObserver` | `lib/features/dashboard/dashboard_home_section.dart:39-40` | Makes Dashboard Home eligible for application lifecycle callbacks |
| `WidgetsBinding.instance.addObserver/removeObserver` | `lib/features/dashboard/dashboard_home_section.dart:49,58` | Registers on Home creation and unregisters on disposal |
| `didChangeAppLifecycleState` / `AppLifecycleState.resumed` | `lib/features/dashboard/dashboard_home_section.dart:64-67` | Reloads unread notification count whenever the app resumes |

No other active `WidgetsBindingObserver` or `didChangeAppLifecycleState` implementation appears under `lib/`.

## Streams and listeners

| Construct | File | What it controls |
|---|---|---|
| `FirebaseMessaging.onMessage.listen` | `lib/main.dart:50-59` | Foreground push events increment global unread state; no subscription variable is retained |
| `AskNowProvider._purchaseSub` | `lib/core/state/asknow_provider.dart:32,55-88` | Processes pending, purchased/restored, canceled, and error purchase statuses; canceled in provider `dispose()` |
| `ReportPaymentPage._purchaseSub` | `lib/features/reports/pages/report_payment_page.dart:31,56-77` | Sends purchase updates to report-payment handling and payment errors to UI; canceled in page `dispose()` |
| `TabController.addListener` | `lib/features/horoscope/horoscope_page.dart:31-40` | Loads daily/monthly/yearly data after tab index changes finish |
| `PageController.addListener` | `lib/core/widgets/transit_alert_widget.dart:22-40` | Mirrors fractional page position into widget state; controller disposed with widget |
| `AskNowProvider.addListener/removeListener` | `lib/features/asknow/asknow_chat_page.dart:134-195` | Surfaces provider errors, applies pending answers, and scrolls chat; detached in page disposal |
| `LoveProvider.addListener/removeListener` | `lib/features/love/pages/love_result_hub_page.dart:39-45,371-381` | Drives auto-navigation when requested love-tool results arrive; detached in disposal |
| WebView `NavigationDelegate` | `lib/features/blog/blog_reader_page.dart:22-37` | Allows in-WebView navigation and clears page loading state when a page finishes |
| Ad listeners/full-screen callbacks | `lib/core/ads/`, `lib/features/transit/pages/transit_content_page.dart` | Update ad readiness, dispose failed/dismissed ads, preload subsequent ads, and invoke completion callbacks |

## `Future.delayed`

| File | Delay | Controlled action |
|---|---:|---|
| `lib/features/splash/splash_page.dart:22` | 2 s | Holds Splash before auth decision |
| `lib/features/dashboard/dashboard_page.dart:77-86` | 2 s after core dashboard load | Starts another unread-count request |
| `lib/features/dashboard/dashboard_home_section.dart:75-78` | 300 ms per loop | Polls until Firebase current user becomes non-null |
| `lib/core/widgets/greeting_header_widget.dart:29-36` | 2 s after first frame | Loads unread count in greeting header |
| `lib/core/widgets/greeting_header_widget.dart:420-423` | 200 ms | Reloads unread count after a notification-related action |
| `lib/features/profile/profile_page.dart:37` | 600 ms | Delays sign-out after showing logout snackbar |
| `lib/features/astrology/astrology_page.dart:41-43` | 400 ms | Delays scrolling to the requested astrology section |
| `lib/features/love/providers/love_provider.dart:77-81` | 40 ms per loop | Waits for an in-progress tool request to finish instead of starting another |
| `lib/core/ads/rewarded_ad_manager.dart:25-27` | 5 s | Retries rewarded-ad load after failure |

## Post-frame callbacks

| File | Controlled action |
|---|---|
| `lib/features/dashboard/dashboard_page.dart:43-49` | Starts profile and dashboard initialization after first frame |
| `lib/core/widgets/greeting_header_widget.dart:29-36` | Begins delayed unread load after first frame |
| `lib/core/widgets/greeting_header_widget.dart:91-99` | Refetches daily data after a language mismatch is observed during build |
| `lib/core/widgets/chaughadiya_alert_widget.dart:31` | Starts auto-scroll only after scroll clients can attach |
| `lib/features/darshan/darshan_page.dart:58-60` | Starts mantra autoplay after layout |
| `lib/features/love/pages/love_result_hub_page.dart:59-63` | Pushes a newly available result page after the current frame |
| `lib/features/reports/widgets/report_checkout_form.dart:94-96` | Notifies parent after form controllers are initialized |
| `lib/features/astrology/widgets/astrology_tool_section.dart:187-189` | Scrolls to the selected category chip |
| `lib/features/reports/pages/report_catalog_page.dart:421-431,442-454` | Defers report navigation until after the current frame |
| `lib/features/horoscope/horoscope_page.dart:43-45` | Loads initial selected horoscope tab |
| `lib/features/asknow/asknow_chat_page.dart:63-65,72-74` | Requests input focus; then synchronizes status and attaches provider listener |
| `lib/features/asknow/asknow_chat_page.dart:125-132` | Scrolls the message list after layout |
| `lib/features/panchang/panchang_page.dart:34-37` | Starts provider load with current language |
| `lib/features/muhurth/muhurth_page.dart:82-84` | Starts initial muhurth request |

## `Future.microtask`

| File | Controlled action |
|---|---|
| `lib/features/splash/splash_page.dart:30-40` | Moves GoRouter navigation out of Splash's immediate async continuation |
| `lib/services/auth_service.dart:35-37` | Starts Google user's Firestore/backend synchronization without awaiting it |
| `lib/core/widgets/transit_alert_widget.dart:267-275` | Starts transit-content fetch after pushing the detail page |
| `lib/features/cards/presentation/cards_page.dart:26-36` | Performs panchang-then-cards initialization after state creation |
| `lib/features/profile/profile_page.dart:23-25` | Starts profile load after state creation |
| `lib/features/profile/profile_list_page.dart:20-22` | Starts profile load after state creation |

## Timers and repeating controllers

| Controller | File | What it controls | Disposal behavior |
|---|---|---|---|
| One-shot `Timer` | `lib/features/asknow/asknow_chat_page.dart:49,150-171` | Debounces display of provider error snackbars by 120 ms | Canceled before replacement and in `dispose()` |
| One-minute `Timer.periodic` | `lib/core/state/panchang_provider.dart:8,24-28` | Calls `notifyListeners()` so time-sensitive Panchang UI can update | Canceled in provider `dispose()` |
| 2.5-second `Timer.periodic` | `lib/core/widgets/shubh_muhurth_banner_widget.dart:18,21-34` | Rotates `_currentIndex` through four banners | Canceled in widget `dispose()` |
| 50-ms `Timer.periodic` | `lib/core/widgets/chaughadiya_alert_widget.dart:20,31-42` | Auto-scrolls and wraps the chaughadiya strip | Canceled in widget `dispose()` |
| Repeating `AnimationController` | `lib/core/widgets/rotating_earth.dart:12-27` | Infinite 12-second earth rotation | Disposed |
| Repeating `AnimationController` | `lib/core/widgets/transit_alert_widget.dart:434-455` | Three-second reversing floating-planet animation | Disposed |
| Repeating `AnimationController` | `lib/core/widgets/chaughadiya_alert_widget.dart:19,26-29,96-100` | 900-ms reversing blink animation | Disposed |
| Repeating `AnimationController` | `lib/features/darshan/darshan_page.dart:24,49-55,99-102` | Six-second reversing Darshan scale animation | Disposed |

# SECTION 6 — Global State Access

## Top-level runtime objects

| Object | File | Access and role |
|---|---|---|
| `analytics` | `lib/main.dart:39` | Top-level `FirebaseAnalytics.instance`; imported by `app_routes.dart` for navigation observation |
| `appRouter` | `lib/app/routes/app_routes.dart:27` | Top-level GoRouter used by the root `MaterialApp.router` |
| `globalKundaliContext` | `lib/core/utils/global_context.dart:3` | Mutable nullable global context assigned in every `JyotishashaApp.build()` and read by the foreground FCM callback |
| `muhurthCache` | `lib/features/muhurth/muhurth_page.dart:28,120-153` | Mutable top-level cache keyed by activity, coordinates, and language; shared by all Muhurth page instances |

## Top-level data/style objects

These are globally accessible library objects but do not coordinate application control flow.

| Object | File | Role |
|---|---|---|
| `_allQuestions` | `lib/data/trending_questions.dart:24` | Private const trending-question collection |
| `askNowQuestions` | `lib/data/asknow_questions.dart:3` | Top-level final mutable map of AskNow prompts |
| `nightThoughtsHi`, `nightThoughtsEn` | `lib/features/cards/data/night_thoughts.dart:1,63` | Const localized card text lists |
| `CARD_TEMPLATES` | `lib/features/cards/data/card_templates.dart:3` | Const card-template map |
| `PlanetNameMap` | `lib/core/constants/planet_names.dart:3` | Const localized planet-name map |
| `_titleStyle`, `_paraStyle` | `lib/core/widgets/horoscope_card_widget.dart:277-282` | Private const shared text styles |

## Shared static mutable objects

| Object | File | Role |
|---|---|---|
| `PlayBillingStub._iap` | `lib/services/play_billing_stub.dart:4` | Static `InAppPurchase.instance` used by pre-UI availability probe |
| `RewardedAdManager._rewardedAd`, `_isLoading` | `lib/core/ads/rewarded_ad_manager.dart:5-6` | Process-wide rewarded-ad object and load guard |
| `AdService._initialized`, `_interstitial`, `_rewarded` | `lib/core/ads/ad_service.dart:7,55,85` | Static SDK-initialization flag and cached full-screen ad objects |
| `CardRenderer._random` | `lib/features/cards/presentation/widgets/card_renderer.dart:140` | Static Random instance shared by card rendering |
| `ToolRegistry.toolWidgets` | `lib/core/registry/tool_registry.dart:12` | Static map from tool IDs to widget factories |
| `HouseRemedies.remedies` | `lib/data/house_remedies.dart:7` | Static final remedy map |
| `YogDoshMeta.all` | `lib/core/constants/yog_dosh_meta.dart:4` | Static final metadata list |
| `PlanetMeta.allPlanets` | `lib/core/constants/planet_meta.dart:4` | Static final planet metadata list |
| `LifeAspectMeta.allAspects`, `profileTools` | `lib/core/constants/life_aspect_meta.dart:2,151` | Static final life-aspect/tool metadata lists |

## Static immutable configuration and catalogs

| Owner / file | Static objects exposed by the current code |
|---|---|
| `DefaultFirebaseOptions` — `lib/firebase_options.dart` | Android `FirebaseOptions`; `currentPlatform` is the static selector getter |
| `AppLocalizations` — `lib/l10n/app_localizations.dart` | Localization delegate, delegate list, and supported locale list |
| `AppColors` — `lib/core/constants/app_colors.dart` | Shared color and gradient constants |
| `AppColors` / `AppTheme` — `lib/app/theme/app_theme.dart` | Theme color/gradient constants and static light-theme getter |
| `AdIds` — `lib/core/ads/ad_ids.dart` | Test banner, interstitial, rewarded, and native ad-unit constants |
| `AdUnits` — `lib/core/ads/ad_units.dart` | Application banner, interstitial, and rewarded ad-unit constants |
| `RazorpayKeys` — `lib/core/constants/razorpay_keys.dart` | Live and test payment-key constants |
| `ShareTemplates` — `lib/core/utils/share_templates.dart` | English/Hindi share-text constants for daily, Darshan, muhurtha, AskNow, and default content |
| `LoveRoutes` — `lib/features/love/love_routes.dart` | Static route-string constants for Love and report flows; these constants are not registered by `app_routes.dart` |
| `TransitContentPage` state — `lib/features/transit/pages/transit_content_page.dart:58` | Static Hindi planet-name map |
| `ReportPaymentPage` state — `lib/features/reports/pages/report_payment_page.dart:28` | Static Play product ID |
| `KundaliProvider` — `lib/core/state/kundali_provider.dart:16-21` | Static full-kundali and bootstrap endpoint constants |
| `ManualKundaliProvider` — `lib/core/state/manual_kundali_provider.dart:10-11` | Static manual-kundali endpoint constant |
| Static service classes — `lib/services/asknow_service.dart`, `backend_auth_service.dart`, `blog_service.dart`, `location_service.dart`, `notification_service.dart`, `personalized_horoscope_service.dart`, `report_service.dart`, `user_bootstrap_service.dart`, `lib/features/cards/data/card_service.dart`, `lib/features/love/services/love_api_service.dart` | Shared base URL, endpoint, or API-key constants owned by each service class |

The static metadata collections in `HouseRemedies`, `YogDoshMeta`, `PlanetMeta`, `LifeAspectMeta`, and `ToolRegistry` are listed in the preceding mutable-object table because `final` fixes the field reference but the referenced Map/List objects remain mutable.

## Framework/plugin singleton access

| Singleton | Current access sites and purpose |
|---|---|
| `FirebaseAuth.instance` | Router, Splash, dashboard, providers, services, checkout/payment, AskNow, Birth, Add Profile, and logout use it for point-in-time session access |
| `FirebaseFirestore.instance` | Auth/profile/kundali/dashboard/login/birth/Add Profile/AskNow/report flows use it for user and profile data |
| `FirebaseAnalytics.instance` | Bound to top-level `analytics` in `main.dart` |
| `FirebaseCrashlytics.instance` | Supplies Flutter fatal-error handler in `main.dart` |
| `FirebaseMessaging.instance` | Dashboard permission, token, deletion, and topic subscription |
| `InAppPurchase.instance` | `PlayBillingStub`, `AskNowProvider`, and `ReportPaymentPage` share plugin billing access |
| `FacebookAuth.instance` | `AuthService` Facebook sign-in and logout |
| `MobileAds.instance` | `AdService.initialize()`; the active call from `main.dart` is commented out |
| `WidgetsBinding.instance` | Lifecycle observer registration and all post-frame scheduling |
| `AudioPlayer.global` | Darshan assigns process-wide audio context |
| `SharedPreferences.getInstance()` | Language persistence and tool-result caching |

## Application-scope provider objects

`MultiProvider` exposes `LanguageProvider`, `ProfileProvider`, `FirebaseKundaliProvider`, `KundaliProvider`, `ManualKundaliProvider`, `DailyProvider`, `MonthlyProvider`, `YearlyProvider`, `PanchangProvider`, `TransitProvider`, `LoveProvider`, `NotificationProvider`, `CardsProvider`, and `AskNowProvider` above `JyotishashaApp` (`lib/main.dart:69-96`). These are globally reachable through descendant `BuildContext`; most remain lazy until first read. `AskNowProvider` is eager.

## Static service namespaces

The codebase also uses classes as globally callable service namespaces: `AskNowService`, `NotificationService`, `BackendAuthService`, `LocationService`, `BlogService`, `ReportService`, `CardService`, `LoveApiService`, `AdService`, and `RewardedAdManager`. Their methods and base URLs are static. `UserBootstrapService`, `AuthService`, `ProfileService`, and `PersonalizedHoroscopeService` are instantiated services rather than global instances.

# SECTION 7 — Control Flow Hotspots

## `lib/main.dart`

Current responsibilities:

- Flutter/plugin binding startup.
- Global HTTP behavior.
- Firebase Core startup.
- Foreground message event handling.
- Crashlytics Flutter-error routing.
- Blocking billing availability.
- Root dependency/provider assembly.
- Eager AskNow billing-listener startup.
- Root widget launch.

It acts as a control center because process startup ordering, cross-cutting SDK wiring, event handling, and feature-provider composition all converge in the single `main()` body.

## `lib/app/routes/app_routes.dart`

Current responsibilities:

- Central path registry.
- Initial-location selection.
- Firebase-auth route policy.
- Analytics navigation observation.
- Unknown-route UI.
- Route argument extraction for astrology detail.
- Construction references to entry pages and every main feature page.

It acts as a control center because route resolution, session gating, telemetry, error handling, and page construction are all evaluated from one top-level router object. It also imports `main.dart` to obtain `analytics`, while `main.dart` reaches this router through `app.dart`.

## `lib/features/dashboard/dashboard_page.dart`

Current responsibilities:

- Authenticated shell and five-tab selection.
- Back-button/minimize policy.
- One-time post-frame startup guard.
- Profile-load kickoff.
- Auth snapshot validation.
- FCM permission, token retry, topic subscription, Firestore persistence, and backend persistence.
- Kundali, daily, and panchang sequencing.
- Delayed notification loading.
- Banner placement.

It acts as a control center because authenticated application entry, platform messaging, backend synchronization, core feature-data orchestration, and shell navigation all originate from this state object.

## `lib/features/dashboard/dashboard_home_section.dart`

Current responsibilities:

- Application lifecycle observation.
- Firebase-user polling.
- Notification count loading and resume refresh.
- Report-asset loading, localization, shuffle, and selection.
- Pull-to-refresh coordination.
- Composition of multiple feature widgets.
- Direct navigation into Cards, Muhurth, Reports, and Darshan.

It acts as a control center because dashboard presentation, lifecycle events, data refresh, asset transformation, auth-dependent polling, and feature dispatch meet in the same widget state.

## `lib/core/widgets/greeting_header_widget.dart`

Current responsibilities:

- Delayed unread-count loading.
- Greeting/zodiac/profile presentation.
- Language-change detection and daily-horoscope refetch scheduling.
- Navigation to Horoscope, Darshan, Panchang, and Cards.
- Notification badge state.
- Notification bottom-sheet opening, list loading, mark-as-read flow, and delayed count refresh.

It acts as a control center because a header/presentation widget also controls remote notification state, language-driven data refresh, four feature-entry transitions, and a notification subflow.

## `lib/features/asknow/asknow_chat_page.dart`

Current responsibilities:

- Input, focus, scrolling, and message UI state.
- Billing-listener activation.
- Rewarded-ad preload and reward flow.
- Firebase/backend user-ID resolution.
- Chat-status synchronization.
- Provider listener attachment, error debounce, pending-answer handling, and auto-scroll.
- Question submission and payment-sheet control.

It acts as a control center because chat presentation, identity lookup, billing, advertising, provider events, backend status, and modal purchase flow are coordinated by one page state.

## `lib/features/reports/pages/report_payment_page.dart`

Current responsibilities:

- Firebase/backend user lookup.
- Purchase-stream ownership.
- Product purchase state.
- Purchase verification/processing.
- Relationship-versus-ordinary report branching.
- Report generation.
- Error/snackbar state.
- Replacement navigation to success.

It acts as a control center because user identity, Play Billing events, backend report execution, product-specific branching, and navigation completion are handled together.

## `lib/features/love/pages/love_result_hub_page.dart`

Current responsibilities:

- LoveProvider payload setup and listener lifetime.
- Per-tool request/loading/result state.
- Automatic post-frame result navigation.
- Manual cached-result navigation.
- Four independent navigation guards.
- Tool hub rendering.

It acts as a control center because asynchronous provider events and user taps both drive navigation through tool-specific state flags owned by this page.

## `lib/features/profile/profile_page.dart`

Current responsibilities:

- Initial profile loading.
- Active/other profile rendering.
- Add/edit/delete/activate operations and result-driven reloads.
- Direct Google and Firebase logout.
- Delayed logout feedback.
- Navigation-stack clearing to Login.

It acts as a control center because session termination, profile CRUD orchestration, provider refresh, and navigation are combined in the Profile screen.

# SECTION 8 — ESR Candidate Components

This section identifies role resemblance only. It does not define new components.

| Architectural role | Existing code already exhibiting the role | Evidence |
|---|---|---|
| AppCoordinator | `DashboardPage` | It coordinates the authenticated shell and starts profile, FCM, kundali, daily, panchang, and notification flows in an explicit sequence (`lib/features/dashboard/dashboard_page.dart:39-209`) |
| AppCoordinator | `main()` | At process scope it sequences platform services and constructs the application dependency graph before handing control to Flutter (`lib/main.dart:41-99`) |
| Bootstrap | `main()` plus `JyotishashaApp.build()` | Together they perform executable application bootstrap: SDK readiness, providers, root context, theme, localization, and router |
| Bootstrap-named service, not current app bootstrap | `UserBootstrapService` | It wraps `POST /api/user/bootstrap` for a supplied profile (`lib/services/user_bootstrap_service.dart:4-25`), but no usage of `UserBootstrapService` appears elsewhere under `lib/` |
| Event Manager | `NotificationProvider` plus the `FirebaseMessaging.onMessage` callback | The callback translates foreground FCM events into unread-state changes; the provider publishes those changes to listeners (`lib/main.dart:50-59`, `lib/core/state/notification_provider.dart`) |
| Event Manager | `AskNowProvider` | It owns the app-scope purchase `StreamSubscription`, translates purchase statuses into state, notifies listeners, and cancels the stream on disposal (`lib/core/state/asknow_provider.dart:31-88`) |
| Event Manager | `DashboardHomeSection` | It receives app-resume events through `WidgetsBindingObserver` and translates them into notification refresh (`lib/features/dashboard/dashboard_home_section.dart:39-67`) |
| Navigation Manager | Top-level `appRouter` | It owns route names/builders, initial location, auth redirect, analytics observer, and 404 handling (`lib/app/routes/app_routes.dart:27-101`) |
| Navigation Manager, feature-local | `LoveResultHubPage` | It converts LoveProvider result events into guarded post-frame page pushes and also handles manual result-page pushes |
| Session Manager | `AuthService` | It owns Firebase Auth access, Google/Facebook credential exchange, user synchronization, and multi-provider sign-out (`lib/services/auth_service.dart:9-156`) |
| Session-policy controller | GoRouter `redirect` | It turns the current Firebase user snapshot into route-access decisions (`lib/app/routes/app_routes.dart:34-51`) |
| Session-dependent data controller | `ProfileService` | Every method derives UID from Firebase Auth and scopes profile CRUD to that session (`lib/services/profile_service.dart:6-128`) |

There is no single class named or functioning as the exclusive coordinator, bootstrapper, event manager, navigation manager, or session manager. The observed responsibilities are distributed among the entries above.

# SECTION 9 — Control Flow Diagram

```mermaid
flowchart TD
    A[main] --> B[Ensure Flutter binding]
    B --> C[Install global HttpOverrides]
    C --> D[Await Firebase Core]
    D --> E[Register foreground FCM listener]
    E --> F[Assign Crashlytics FlutterError handler]
    F --> G[Await Play Billing availability]
    G --> H[runApp MultiProvider]

    H --> I[Eager AskNowProvider purchase listener]
    H --> J[JyotishashaApp]
    J --> K[Watch LanguageProvider and start SharedPreferences load]
    K --> L[MaterialApp.router]
    L --> M[appRouter: analytics, redirects, routes]
    M --> N[/splash]

    N --> O[Wait 2 seconds]
    O --> P{Firebase currentUser?}
    P -->|null| Q[/login]
    P -->|non-null| R[/dashboard]

    Q --> S[LoginPage]
    S --> T{Google sign-in returns user?}
    T -->|No| S
    T -->|Yes| U{profiles/default exists?}
    U -->|Yes| R
    U -->|No or read error| V[/birth]
    V --> W[Save birth/profile]
    W --> R

    R --> X[DashboardPage renders Home tab]
    X --> X1[Home reports + unread count]
    X --> X2[Banner ad load]
    X --> Y[Post-frame initialization]

    Y --> Y1[Start ProfileProvider.loadProfiles]
    Y --> Z{Dashboard currentUser?}
    Z -->|null| ZA[Stop init and remain on Dashboard]
    Z -->|non-null| ZB[Start FCM permission/token/topic sync]
    Z -->|non-null| ZC[Load active profile and full kundali]

    ZC --> ZD{kundaliData exists?}
    ZD -->|No| ZE[Stop core feature load]
    ZD -->|Yes| ZF[Load Daily horoscope]
    ZF --> ZG[Load Panchang]
    ZG --> ZH[Schedule delayed unread load]

    X --> F1{Dashboard bottom tab}
    F1 -->|Home| X1
    F1 -->|Astrology| F2[Astrology feature]
    F1 -->|Reports| F3[Reports feature]
    F1 -->|Cards| F4[Cards feature initialization]
    F1 -->|Profile| F5[Profile/session controls]
```
