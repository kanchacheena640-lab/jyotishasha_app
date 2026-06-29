# ESR-002 — User, Session and Profile Contracts

## Slice

ESR-002 Slice-3

## Scope

This slice introduces immutable, application-owned contracts for user, session,
and profile data. The contracts are additive and are not connected to existing
providers, services, repositories, widgets, routes, or feature logic.
It builds on the shared foundation contracts completed in ESR-002 Slice-2.

The contracts preserve the current flat Firestore user/profile wire names,
accept the aliases identified by the data-contract audit, and tolerate nullable
values. Backend numeric identifiers and coordinates accept number or numeric
string input.

## User contracts

### `UserIdentity`

File: `lib/core/models/user/user_identity.dart`

| Field | Type | Canonical JSON key | Accepted aliases |
|---|---|---|---|
| `firebaseUid` | `String?` | `uid` | `firebase_uid`, `firebaseUid` |
| `name` | `String?` | `name` | `displayName`, `display_name` |
| `email` | `String?` | `email` | — |
| `phone` | `String?` | `phone` | `phoneNumber`, `phone_number` |
| `photoUrl` | `String?` | `photo` | `photoURL`, `photoUrl`, `photo_url` |
| `provider` | `String?` | `provider` | — |

### `UserPreferences`

File: `lib/core/models/user/user_preferences.dart`

| Field | Type | Canonical JSON key | Accepted aliases |
|---|---|---|---|
| `activeProfileId` | `String?` | `activeProfileId` | `active_profile_id` |
| `language` | `String?` | `language` | `lang` |
| `fcmToken` | `String?` | `fcm_token` | `fcmToken` |
| `fcmUpdatedAt` | `Object?` | `fcm_updated_at` | `fcmUpdatedAt` |

`fcmUpdatedAt` remains opaque so Firestore timestamp objects and existing
serialized timestamp values are retained without conversion.

### `User`

File: `lib/core/models/user/user.dart`

| Field | Type | Canonical JSON key | Accepted aliases |
|---|---|---|---|
| `identity` | `UserIdentity?` | Flattened identity keys | Nested `identity` is also accepted |
| `preferences` | `UserPreferences?` | Flattened preference keys | Nested `preferences` is also accepted |
| `backendUserId` | `int?` | `backend_user_id` | `backendUserId`, `backendUserID`, `user_id` |
| `createdAt` | `Object?` | `createdAt` | `created_at` |
| `updatedAt` | `Object?` | `updatedAt` | `updated_at` |
| `lastLogin` | `Object?` | `lastLogin` | `last_login` |

`User.toJson()` emits the current flat root-user document shape used by
Firestore. Timestamp fields remain opaque for wire compatibility.

## Profile contracts

### `BirthDetails`

File: `lib/core/models/profile/birth_details.dart`

| Field | Type | Canonical JSON key | Accepted aliases |
|---|---|---|---|
| `dateOfBirth` | `String?` | `dob` | `date_of_birth`, `dateOfBirth` |
| `timeOfBirth` | `String?` | `tob` | `time_of_birth`, `timeOfBirth` |
| `placeOfBirth` | `String?` | `pob` | `place_name`, `placeName`, `place_of_birth` |
| `latitude` | `double?` | `lat` | `latitude` |
| `longitude` | `double?` | `lng` | `longitude`, `lon` |
| `placeId` | `String?` | `place_id` | `placeId` |
| `timezone` | `String?` | `timezone` | `tz` |

Date and time strings are preserved as received. The contract performs no date,
time, timezone, or location derivation.

### `ProfileSettings`

File: `lib/core/models/profile/profile_settings.dart`

| Field | Type | Canonical JSON key | Accepted aliases |
|---|---|---|---|
| `language` | `String?` | `language` | `lang` |
| `gender` | `String?` | `gender` | — |
| `ayanamsa` | `String?` | `ayanamsa` | — |
| `isActive` | `bool?` | `isActive` | `is_active` |
| `isComplete` | `bool?` | `profile_complete` | `profileComplete`, `is_complete` |

Boolean input accepts booleans, zero/one numbers, and the strings `true`,
`false`, `1`, and `0`.

### `Profile`

File: `lib/core/models/profile/profile.dart`

| Field | Type | Canonical JSON key | Accepted aliases |
|---|---|---|---|
| `id` | `String?` | `id` | `profile_id`, `profileId` |
| `name` | `String?` | `name` | — |
| `birthDetails` | `BirthDetails?` | Flattened birth/location keys | Nested `birth_details` is also accepted |
| `settings` | `ProfileSettings?` | Flattened settings keys | Nested `settings` is also accepted |
| `lagna` | `String?` | `lagna` | — |
| `moonSign` | `String?` | `moon_sign` | `moonSign` |
| `nakshatra` | `String?` | `nakshatra` | — |
| `backendUserId` | `int?` | `backend_user_id` | `backendUserId`, `backendUserID` |
| `backendProfileId` | `int?` | `backend_profile_id` | `backendProfileId`, `backendProfileID` |
| `createdAt` | `Object?` | `createdAt` | `created_at` |
| `updatedAt` | `Object?` | `updatedAt` | `updated_at` |

`Profile.toJson()` emits the flat profile shape used by current Firestore
documents and normalizes backend identifiers to their audited snake-case keys.

## Session contracts

### `AuthenticationState`

File: `lib/core/models/session/authentication_state.dart`

| Field | Type | Canonical JSON key | Accepted aliases |
|---|---|---|---|
| `isAuthenticated` | `bool?` | `is_authenticated` | `isAuthenticated`, `authenticated` |
| `identity` | `UserIdentity?` | `identity` | Nested `user` or flat identity fields |
| `errorMessage` | `String?` | `error` | `error_message`, `errorMessage` |

This contract records a point-in-time authentication result. It does not observe
Firebase Auth and introduces no reactive session behavior.

### `SessionState`

File: `lib/core/models/session/session_state.dart`

| Field | Type | Canonical JSON key | Accepted aliases |
|---|---|---|---|
| `status` | `String?` | `status` | `session_status` |
| `isRestoring` | `bool?` | `is_restoring` | `isRestoring`, `restoring` |
| `isBackendLinked` | `bool?` | `is_backend_linked` | `isBackendLinked`, `backend_linked` |
| `errorMessage` | `String?` | `error` | `error_message`, `errorMessage` |

Status remains a nullable string to avoid inventing state transitions or
rejecting future backend values during this behavior-preserving slice.

### `Session`

File: `lib/core/models/session/session.dart`

| Field | Type | Canonical JSON key | Accepted aliases |
|---|---|---|---|
| `user` | `User?` | `user` | Flat user fields are also accepted |
| `authentication` | `AuthenticationState?` | `authentication` | `authentication_state` |
| `state` | `SessionState?` | `state` | `session_state` |
| `backendUserId` | `int?` | `backend_user_id` | `backendUserId`, `backendUserID`, `user_id` |
| `backendToken` | `String?` | `token` | `backend_token`, `backendToken`, `jwt` |
| `createdAt` | `Object?` | `createdAt` | `created_at` |
| `expiresAt` | `Object?` | `expiresAt` | `expires_at` |

The session is a snapshot only. Token refresh, authentication observation,
session ownership, and sign-in/sign-out orchestration remain deferred to their
tracked ESR phases.

## Contract guarantees

All nine contracts:

* are immutable `final class` values with final fields;
* provide const constructors;
* provide `fromJson()` and `toJson()`;
* implement value equality and `hashCode`;
* provide `copyWith()`, including explicit clearing of nullable fields;
* tolerate absent and null values;
* contain serialization only and no business logic.

## Relationships

| Parent | Child contract | Relationship |
|---|---|---|
| `User` | `UserIdentity` | Firebase/provider identity snapshot |
| `User` | `UserPreferences` | Root user selection, language, and FCM preferences |
| `Profile` | `BirthDetails` | Birth and location wire fields |
| `Profile` | `ProfileSettings` | Profile language and persisted flags |
| `AuthenticationState` | `UserIdentity` | Identity present in an authentication snapshot |
| `Session` | `User` | Application user snapshot associated with the session |
| `Session` | `AuthenticationState` | Point-in-time authentication result |
| `Session` | `SessionState` | Point-in-time session lifecycle data |

## Migration notes for future ESR slices

1. Do not replace existing maps until the owning ESR phase adds boundary
   adapters and characterization fixtures.
2. Firestore document IDs are currently merged into profile maps. A future
   profile repository must decide whether `id` is emitted in document data or
   supplied separately to writes; this slice preserves both parsing and output.
3. Keep snake-case backend identifiers canonical while accepting the audited
   camel-case aliases during migration.
4. Preserve raw timestamp values at Firestore boundaries until a shared
   timestamp contract is available.
5. Adapt Firebase SDK `User` objects into `UserIdentity` at the authentication
   boundary; do not make core contracts depend on Firebase packages.
6. Keep session behavior snapshot-based until ESR-008 establishes the session
   owner and reactive semantics.
7. Keep active-profile resolution in existing owners until ESR-010. These
   contracts represent data and do not select or activate a profile.
8. Future typed boundaries must continue reusing the completed Slice-2 shared
   contracts wherever serialization remains wire-compatible.

## Runtime impact

None. No production consumer imports these contracts in Slice-3, and no current
runtime path is changed.
