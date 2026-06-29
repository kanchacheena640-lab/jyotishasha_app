# ESR-001 — Regression Baseline Report (Slice 1)

## Scope and method

This report records the testing baseline visible in the repository before ESR implementation begins. The inspection covered `test/`, the presence of `integration_test/`, `pubspec.yaml`, test-runner configuration, mock and fake usage, test utilities, golden artifacts, and repository CI configuration. Production source code was inspected only to verify whether the disabled test still targets the current application root.

Repository state at inspection:

- `test/` exists and contains one file: `test/widget_test.dart`.
- `integration_test/` does not exist.
- `flutter_test_config.dart` does not exist.
- `dart_test.yaml` does not exist.
- No repository CI configuration was found for GitHub Actions, GitLab CI, Codemagic, Bitrise, CircleCI, Azure Pipelines, or Jenkins.
- `pubspec.yaml` declares `flutter_test` and `flutter_lints` as its only development dependencies.
- No mock, fake, golden-test, coverage, or test code-generation package is declared.

## A. Current Test Infrastructure

### Test inventory

| Test category | Active test files | Active test cases | Current state |
|---|---:|---:|---|
| Unit tests | 0 | 0 | No unit test declarations were found. |
| Widget tests | 0 | 0 | The only `testWidgets` declaration is commented out. |
| Integration tests | 0 | 0 | No `integration_test/` directory or `integration_test` SDK dependency exists. |
| Golden tests | 0 | 0 | No golden test declarations, baselines, or golden tooling were found. |
| Total active tests | 0 | 0 | There is no active regression suite. |

### Existing test file

`test/widget_test.dart` is a disabled copy of Flutter's generated counter smoke test. All imports, `main()`, and the `testWidgets` body are commented out. It references `MyApp`, while the current application root is `JyotishashaApp` in `lib/app/app.dart`; no `MyApp` class exists in `lib/`.

The file also contains a non-comment Dart line stating that tests are temporarily disabled. That line is not a Dart declaration, so the file is not a valid active test source in its current form.

### Existing test utilities

None were found:

- No shared test harness or app pump helper.
- No fixtures, builders, factories, or test data directory.
- No Firebase test setup or emulator configuration.
- No HTTP fakes or request-recording utilities.
- No fake platform-service adapters.
- No custom matchers.
- No mock or fake classes.
- No global Flutter test configuration.

### Test dependencies

| Capability | Repository support |
|---|---|
| Flutter widget/unit testing | `flutter_test` is declared. |
| Integration testing | Missing; `integration_test` is not declared. |
| Mocking | Missing; neither Mockito nor Mocktail is declared or used. |
| Generated mocks | Missing; no `build_runner` or mock generator is declared. |
| Time control | Missing; no explicit fake-clock or `fake_async` test dependency is declared. |
| Golden testing | Only Flutter's base test SDK is available; no baselines or project configuration exist. |
| Coverage policy | Missing; no coverage configuration, threshold, report, or CI enforcement was found. |

### Test execution result

`flutter test` was invoked from the repository root. It produced no output and did not reach visible test discovery within approximately 70 seconds, so the process was terminated. A targeted `flutter test --no-pub test/widget_test.dart --reporter expanded` invocation likewise produced no output within approximately 20 seconds and was terminated. `dart analyze test/widget_test.dart` also produced no output within its validation window.

These executions do not establish a toolchain or dependency root cause. Independently of that execution limitation, static inspection establishes that there are zero active tests and that `test/widget_test.dart` contains a non-Dart marker line.

## B. Current Coverage

Classification rules used here:

- **Present**: active tests exercise the module's material current behavior.
- **Partial**: active tests exercise some, but not all, material current behavior.
- **Missing**: no active test exercises the module.

| Module | Coverage | Evidence |
|---|---|---|
| Startup | **Missing** | No active test covers binding setup, Firebase initialization, billing readiness, messaging setup, Provider composition, `runApp()`, or initial landing. |
| Authentication | **Missing** | No active test covers Google/Facebook sign-in, Firebase Auth, Firestore user synchronization, backend registration, or sign-out. |
| Session | **Missing** | No active test covers `currentUser`, session transitions, logout cleanup, or user-scoped state retention. |
| Routing | **Missing** | No active test covers GoRouter redirects, Splash exemptions, authenticated/unauthenticated routes, unknown routes, or mixed Navigator transitions. |
| Dashboard | **Missing** | No active test covers Dashboard initialization, tab state, refresh behavior, back handling, or dependent feature loading. |
| Profile | **Missing** | No active test covers profile loading, CRUD, sole-profile activation, active-profile selection, normalization, or profile forms. |
| Notifications | **Missing** | No active test covers FCM foreground events, token registration, unread counts, list loading, mark-read behavior, lifecycle refresh, or notification navigation. |
| Billing | **Missing** | No active test covers billing availability, product lookup, purchase streams, verification, completion, or cancellation/error states. |
| Purchases | **Missing** | No active test covers AskNow pack purchase or report purchase state and backend completion behavior. |
| Panchang | **Missing** | No active test covers fetching, cache keys, coordinates, reset behavior, periodic clock notifications, or derived values. |
| Horoscope | **Missing** | No active test covers daily, monthly, or yearly requests, sign/language cache behavior, resets, or rendering state. |
| Kundali | **Missing** | No active test covers Firebase-profile, bootstrap, manual, or direct-form kundali request/result paths. |
| Love | **Missing** | No active test covers payload ownership, tool execution, loading/result versions, error state, or report transitions. |
| Reports | **Missing** | No active test covers catalog loading, localization, checkout data, billing, webhook payloads, or success state. |
| AskNow | **Missing** | No active test covers entitlement/status, chat answers, token use, rewarded ads, purchases, or Provider stream behavior. |

No module qualifies as **Present** or **Partial** because the repository contains no active test case.

## C. Existing Problems

| Problem category | Finding | Evidence / impact |
|---|---|---|
| Duplicate tests | None detected | Only one test file exists and it contains no active test. |
| Obsolete tests | Present | The disabled counter template targets `MyApp` and counter UI that do not exist in the current application. |
| Broken tests | Present | `test/widget_test.dart` contains an uncommented status marker that is not a valid Dart declaration. Its actual test body is fully disabled. |
| Flaky tests | Not measurable | No test can be repeatedly executed to assess flakiness. The observed CLI non-response is an execution-environment limitation, not evidence that a particular test is flaky. |
| Missing mocks | Present | No mock framework, mock classes, Firebase fakes, HTTP fakes, billing fakes, ads fakes, SharedPreferences harness, or messaging fakes were found. |
| Dependency gaps | Present | `integration_test` and test-double tooling are absent. Only `flutter_test` is available for testing. |
| Missing test configuration | Present | No `flutter_test_config.dart`, `dart_test.yaml`, coverage policy, fixture convention, tag convention, or suite configuration exists. |
| Missing CI enforcement | Present | No CI workflow or test command configuration was found in the repository. |
| External-system isolation | Missing | Current behavior reaches Firebase, HTTP APIs, Google/Facebook authentication, Google Play Billing, Mobile Ads, SharedPreferences, and platform plugins, but no controlled test substitutes are present. |
| Timer/lifecycle control | Missing | Startup delays, periodic timers, purchase streams, FCM listeners, lifecycle listeners, and post-frame callbacks have no test clock or deterministic event harness. |

## D. Minimum Regression Recommendation Before ESR-002

ESR-002 changes application data contracts. Before that work begins, the minimum useful baseline is a small characterization suite that locks the current externally visible decisions and the dynamic data shapes that ESR-002 will type.

### Required characterization suites

| Priority | Characterization suite | Minimum behavior to lock |
|---|---|---|
| 1 | Test harness and smoke discovery | A valid test entry point; one passing Flutter test; deterministic setup for Firebase/plugin-dependent code; proof that the entire suite is discovered and terminates. |
| 2 | Startup and landing | Pre-`runApp` initialization order, root Provider registration/creation behavior, Splash delay, unauthenticated landing at Login, and authenticated landing at Dashboard. |
| 3 | Router and session matrix | Root route, Splash route, authenticated and unauthenticated redirects, unknown route behavior, sign-in transition, sign-out transition, and retained user-scoped Provider state as it behaves today. |
| 4 | Authentication synchronization | Google/Facebook success, cancellation/error, Firebase user result, Firestore user update, backend registration/ID persistence, and logout calls. |
| 5 | Profile ownership | Empty, single, and multiple profile loads; sole-profile activation; root `activeProfileId` versus per-profile `isActive`; backend profile-ID normalization; add/update/delete/activate behavior. |
| 6 | Dashboard initialization | Current ordering and trigger counts for profile, FCM, Firebase kundali, daily horoscope, Panchang, transit, and notification initialization/refresh. |
| 7 | Notification behavior | Backend unread load, foreground increment, reset/reload after mark-read, lifecycle resume refresh, FCM token persistence to Firestore/backend, and notification destination parsing. |
| 8 | Commerce state machines | AskNow billing availability/product lookup/purchase/verification/completion and Report purchase/generation guards for purchased, pending, cancelled, error, duplicate-event, and restored states. |
| 9 | Data-contract fixtures | Representative current payloads and round-trip expectations for user/profile, kundali, daily/monthly/yearly horoscope, Panchang, transit, notifications, Cards/Muhurth, AskNow, Love, and Reports. Preserve missing, optional, camelCase, snake_case, numeric, and string variants observed by current code. |
| 10 | Provider state characterization | For each root Provider affected by ESR-002, lock initial state, loading/success/error transitions, cache-hit behavior, reset behavior, listener notifications, and any constructor-started fetch or timer. |

### Minimum infrastructure needed by those suites

- Activate a valid `test/` entry point and remove the obsolete generated counter-test assumptions.
- Add one test-double approach for HTTP, Firebase/Firestore/Auth, SharedPreferences, billing streams, messaging, ads, and social sign-in boundaries used by the characterized paths.
- Add `integration_test` only for behaviors that require the assembled application or platform/plugin boundary; keep deterministic state transitions in unit/widget tests.
- Add reusable fixtures for the dynamic payloads that ESR-002 will convert into typed contracts.
- Add deterministic controls for timers, delayed work, streams, lifecycle events, and post-frame callbacks.
- Execute the suite in CI and fail the job when a test fails or the runner does not terminate.

The baseline gate for starting ESR-002 should be: the characterization suite is discoverable, repeatable, green, and covers every contract or state owner that ESR-002 will change. No coverage-percentage threshold currently exists, so readiness must initially be determined by the behavioral matrix above rather than a repository coverage target.
