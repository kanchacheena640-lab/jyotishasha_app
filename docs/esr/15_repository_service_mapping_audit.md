# ESR-003 — Repository-to-Service Mapping Audit

## Scope

This is a documentation and analysis report only. It compares the existing
`UserRepository`, `SessionRepository`, and `ProfileRepository` contracts with
the current service layer. No repository contract, repository implementation,
service, caller, or production path is changed.

`UserBootstrapService` is treated as a separate bootstrap boundary. It is not
treated or renamed as `UserService`.

## Mapping summary

| Repository | Existing Service | Status |
| ---------- | ---------------- | ------ |
| `UserRepository` | No single matching service. Responsibilities are distributed across private logic in `AuthService`, `BackendAuthService`, and direct Firestore code; `UserBootstrapService` is adjacent but not equivalent. | Partial |
| `SessionRepository` | `AuthService` plus `BackendAuthService` | Partial |
| `ProfileRepository` | `ProfileService` | Partial |

No existing service is a full behavioral and type-compatible counterpart to
its repository contract.

## UserRepository mapping

### Method comparison

| Repository method | Existing service capability | Difference |
|---|---|---|
| `getUser(String firebaseUid) -> Future<User?>` | No public service method. `AuthService._createOrUpdateUser()` privately reads the root user document during sign-in. | The service operation is private, sign-in-coupled, and returns `void`, not `User?`. |
| `saveUser(User user) -> Future<User>` | No public service method. `AuthService._createOrUpdateUser()` performs create/update writes. | The service accepts a Firebase SDK user plus provider name, applies timestamps and create/update branching, swallows sync failures, and returns `void`. |
| `registerBackendUser(UserIdentity identity) -> Future<int?>` | `BackendAuthService.registerFirebaseUser(...) -> Future<int?>` | Closest direct match. The service accepts scalar fields rather than `UserIdentity` and converts HTTP/backend failure to `null`. |
| `bootstrapProfile(Profile profile) -> Future<int?>` | No equivalent User service method. `UserBootstrapService.syncProfile(Map<String, dynamic>) -> Future<Map<String, dynamic>>` is a separate bootstrap boundary. | Input changes from a raw wire map to `Profile`; output loses the full backend response and retains only an identifier. These APIs are not behaviorally interchangeable. |
| `updateMessagingToken(...) -> Future<void>` | No service method. `DashboardPage` writes FCM metadata directly to Firestore and separately posts the token to the backend. | The repository method represents only Firestore metadata persistence; current behavior spans presentation, Firebase Messaging, Firestore, authentication, and backend HTTP. |

### Missing methods

There is no public existing service method for typed user lookup, typed user
persistence, or messaging-token metadata persistence. There is also no
existing `UserService` class.

### Extra service responsibilities

* `AuthService` owns Google/Facebook authentication, Firebase credential
  exchange, Firestore user synchronization, backend registration, timestamps,
  and provider sign-out cleanup.
* `BackendAuthService` also owns backend-token acquisition, which belongs to the
  session boundary rather than persisted user data.
* `UserBootstrapService` owns a raw-map profile bootstrap request and returns
  the complete backend response. It remains a distinct service.

### Completeness assessment

`UserRepository` aggregates capabilities that currently have no single service
owner. Its `bootstrapProfile()` return type is insufficient to preserve the
full `UserBootstrapService.syncProfile()` result. The current service layer,
meanwhile, embeds user persistence inside authentication and presentation code.

The existing `FirebaseUserRepository` also depends on
`UserBootstrapService`. Therefore `UserBootstrapService` cannot delegate back
to that repository without creating a dependency cycle.

## SessionRepository mapping

### Method comparison

| Repository method | Existing service capability | Difference |
|---|---|---|
| `watchSession() -> Stream<Session?>` | No service method; Firebase auth state is read directly by application code. | No existing service owns the session stream or maps it to the ESR `Session` contract. |
| `getCurrentSession() -> Future<Session?>` | No service method; callers read `FirebaseAuth.instance.currentUser` directly. | The current value is a Firebase SDK user snapshot, not an ESR `Session`. |
| `signIn(provider) -> Future<Session>` | `AuthService.signInWithGoogle()` and `signInWithFacebook()` return `Future<firebase.User?>`. | Separate provider-specific methods become one string-dispatched method; SDK user/null cancellation semantics become a non-null `Session`. |
| `signOut() -> Future<void>` | `AuthService.signOut() -> Future<void>` | Return type aligns. Existing behavior additionally disconnects/signs out Google and Facebook providers and suppresses their individual cleanup errors. |
| `getBackendToken(firebaseUid) -> Future<String?>` | `BackendAuthService.getBackendToken(firebaseUid) -> Future<String?>` | Direct capability match, but it resides in a separate static HTTP service. |

### Missing methods

`AuthService` has no session stream, current-session method, backend-token
method, or ESR session mapping.

### Extra service responsibilities

`AuthService` performs root-user Firestore synchronization and backend user
registration after authentication. Those are user persistence/linkage
responsibilities, not session responsibilities. It also owns provider-specific
SDK cleanup during sign-out.

### Completeness assessment

`SessionRepository` covers more session lifecycle than `AuthService`, while
`AuthService` covers additional user persistence behavior outside the session
contract.

The existing `FirebaseSessionRepository` directly constructs and calls
`AuthService`. Migrating `AuthService` to delegate to this implementation would
create an `AuthService -> SessionRepository implementation -> AuthService`
cycle. A safe AuthService migration cannot begin while that dependency remains.

## ProfileRepository mapping

### Method comparison

| Repository method | Existing `ProfileService` method | Difference |
|---|---|---|
| `getProfiles(firebaseUid) -> Future<List<Profile>>` | `getProfiles() -> Future<List<Map<String, dynamic>>>` | Repository uses an explicit user ID and typed results; service uses current FirebaseAuth state and raw maps. |
| `getProfile(firebaseUid, profileId) -> Future<Profile?>` | None | Individual profile lookup is missing from the service. |
| `getActiveProfile(firebaseUid) -> Future<Profile?>` | `getActiveProfile() -> Future<Map<String, dynamic>?>` | Explicit versus implicit user ownership and typed versus raw-map return. |
| `createProfile(firebaseUid, Profile) -> Future<Profile>` | `addProfile(Map<String, dynamic>) -> Future<String?>` | Repository returns the complete typed profile; service returns only the generated document ID or `null`. |
| `updateProfile(firebaseUid, Profile) -> Future<Profile>` | `updateProfile(profileId, Map<String, dynamic>) -> Future<bool>` | Typed profile/explicit user ID versus ID plus raw mutation map; return changes from success flag to profile. |
| `deleteProfile(firebaseUid, profileId) -> Future<bool>` | `deleteProfile(profileId) -> Future<bool>` | Return behavior aligns, but the service derives the user from FirebaseAuth. |
| `setActiveProfile(firebaseUid, profileId) -> Future<void>` | `setActiveProfile(profileId) -> Future<void>` | Return behavior aligns, but user ownership is explicit only in the repository. |

### Missing methods

`ProfileService` lacks individual profile lookup and every method depends on the
current Firebase user rather than an explicit user identifier.

### Extra service responsibilities

* It auto-activates the first profile.
* It mutates incoming maps to normalize `backendProfileId` to
  `backend_profile_id`.
* It deactivates every profile before activating the selected profile.
* It keeps root `activeProfileId` synchronized on create, select, and delete.
* It orders profile lists by descending `createdAt`.

These behaviors are not visible in repository signatures but are mandatory
compatibility requirements for any migration.

### Completeness assessment

`ProfileRepository` is structurally broader and typed, while `ProfileService`
owns additional persistence rules. `FirestoreProfileRepository` does not depend
on `ProfileService`, so this is the only one of the three mappings without a
direct delegation cycle. Exact raw-map, nullable-return, mutation, ordering,
and activation semantics still need an adapter at the service boundary.

## Smallest behavior-preserving migration path

1. **Do not perform a UserService migration.** No `UserService` exists, and
   creating or renaming one would exceed the approved behavior-preserving
   migration. Keep `UserBootstrapService` separate.
2. **Migrate ProfileService first when implementation is authorized.** Preserve
   every existing public signature. Add repository delegation behind the
   service, converting raw maps to/from `Profile`, deriving the current UID at
   the service boundary, and preserving first-profile activation, identifier
   normalization, ordering, root active-profile updates, boolean/null returns,
   and input-mutation behavior.
3. **Resolve the AuthService dependency direction before migrating it.** A
   separately approved change must make the session implementation independent
   of `AuthService`—for example through lower-level provider adapters—before
   `AuthService` can delegate to `SessionRepository` without recursion.
4. **Split AuthService migration by responsibility without changing its public
   API.** Session operations should delegate to `SessionRepository`; existing
   Firestore user synchronization/backend registration should delegate to
   `UserRepository`. Provider cancellation and sign-out cleanup semantics must
   remain exact.
5. **Leave adjacent owners for later scoped migrations.** Backend notification
   token registration, dashboard FCM persistence, direct router/Splash auth
   reads, and `UserBootstrapService` are not safe to absorb into a nonexistent
   UserService during this step.
6. After each authorized migration step, run focused analysis, full
   `flutter analyze`, `flutter test`, `flutter run`, manual verification, and
   architecture review before proceeding.

## Audit result

The requested UserService-only migration has no valid target in the current
codebase. `ProfileService` is the closest service-to-repository match, while
`AuthService` requires dependency-direction correction before safe delegation.
No migration is performed by this audit.
