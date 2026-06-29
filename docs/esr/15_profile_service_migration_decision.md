# Profile Service Migration Architecture Decision

## Decisions

1. `ProfileRepository` remains the canonical typed repository.

2. No raw Firestore compatibility methods will be added to `ProfileRepository`.

3. A temporary `ProfileRepositoryAdapter` will be introduced for use only during ESR-003 service migration.

4. `ProfileRepositoryAdapter` is responsible for:

   * preserving raw Firestore maps
   * preserving unknown fields
   * preserving partial update semantics
   * preserving document IDs
   * preserving existing exceptions
   * preserving existing return values
   * preserving runtime behavior

5. `ProfileRepositoryAdapter` may delegate to `ProfileRepository` only where no information is lost.

6. A synchronous identity boundary named `CurrentUserIdentityPort` will be introduced. This abstraction owns retrieval of the current Firebase UID. Services must depend on this port instead of depending on `FirebaseAuth` directly.

7. `ProfileRepositoryAdapter` is temporary and may be used only by migrated services. Providers, widgets, repositories, `AppCoordinator`, bootstrap code, and feature modules must never depend on it.

8. The `ProfileRepositoryAdapter` is a temporary migration component.

   It must be removed only after all legacy raw-map consumers have been migrated to the canonical typed repository architecture and no production runtime path depends upon it.

   Its removal is scheduled for the architecture cleanup phase (currently planned as ESR-030), but the removal criterion is the elimination of all legacy runtime dependencies rather than the phase number itself.

---

## Additional Architecture Decisions

### 9. Migration-only Component

`ProfileRepositoryAdapter` is a migration artifact.

It is **not** part of the long-term application architecture.

Its only purpose is to preserve legacy runtime behavior while services migrate from direct Firestore access to the typed repository boundary.

No new production feature may depend on this adapter.

---

### 10. Ownership

`ProfileRepositoryAdapter` is owned exclusively by the ESR-003 Service Migration phase.

It may be referenced only by migrated services.

It must never become a shared dependency.

Its removal follows the runtime-dependency criterion and architecture-cleanup schedule defined in Decision 8.

---

## Rationale

The temporary `ProfileRepositoryAdapter` exists solely to preserve existing runtime behavior while migrating from legacy Firestore map-based persistence to the canonical typed repository architecture.

Without this compatibility layer, the migration would require either:

* weakening the canonical `ProfileRepository` by exposing raw Firestore semantics, or
* changing existing runtime behavior.

Neither option is acceptable under the ESR principles.

The adapter therefore provides an isolated compatibility boundary that:

* preserves runtime behavior,
* protects the typed repository abstraction,
* limits legacy behavior to a single migration component, and
* provides a well-defined removal path once all runtime consumers have migrated.
