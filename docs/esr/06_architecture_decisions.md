# Architecture Decisions

## Profile Service Migration Boundary

Reference: [Profile Service Migration Architecture Decision](15_profile_service_migration_decision.md)

* `ProfileRepository` remains the canonical typed repository.
* `ProfileRepository` must not expose legacy raw Firestore operations.
* Legacy compatibility is isolated inside `ProfileRepositoryAdapter`.
* `ProfileRepositoryAdapter` is temporary and exists only during ESR migration.
* `CurrentUserIdentityPort` is the approved synchronous identity boundary.
* Services must depend on `CurrentUserIdentityPort` instead of `FirebaseAuth`.
* `ProfileRepositoryAdapter` may be referenced only by migrated services.
* Providers, widgets, repositories, `AppCoordinator`, bootstrap code, and feature modules must never depend on `ProfileRepositoryAdapter`.
* `ProfileRepositoryAdapter` is scheduled for removal during ESR-030.
