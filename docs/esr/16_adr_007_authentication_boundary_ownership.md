# ADR-007: Authentication Boundary Ownership

## Status

Accepted for ESR-003 Slice-4 Part-2.

---

## Decision

1. `FirebaseSessionRepository` must not depend on `AuthService`.

2. `AuthService` remains the production compatibility layer during ESR-003.

3. Firestore user synchronization remains in `AuthService` until a later explicitly approved migration.

4. `BackendAuthService.registerFirebaseUser(...)` remains coordinated by `AuthService` until a later explicitly approved migration.

5. This decision changes dependency direction only.

6. This decision does not authorize production runtime rewiring.

7. This decision does not authorize modification of repository contracts.

8. This decision does not authorize modification of repository implementations beyond whatever future separately approved work is required to enforce the dependency direction.

---

## Ownership

`AuthService` is the current production compatibility owner for:

* Google sign-in behavior
* Facebook sign-in behavior
* Firestore root-user synchronization
* backend user registration coordination
* logout cleanup ordering
* compatibility-preserving error propagation

`SessionRepository` remains the canonical session boundary, but its current implementation must not depend upward on `AuthService`.

`FirebaseSessionRepository` belongs to the repository boundary and must not import, construct, or call the production compatibility service layer once dependency direction is corrected by separately approved work.

---

## Scope Constraint

This ADR is architectural only.

It records ownership and dependency direction for ESR-003 Slice-4 Part-2.

It does not approve:

* production runtime rewiring
* service migration by itself
* repository redesign
* new interfaces
* public API changes

---

## Rationale

The current source shape places `FirebaseSessionRepository` below the service layer while also making it depend on `AuthService`.

That dependency prevents safe migration of `AuthService` toward the repository boundary, because any future `AuthService -> SessionRepository` delegation would create a cycle:

`AuthService -> SessionRepository implementation -> AuthService`

At the same time, `AuthService` still owns runtime compatibility behavior that is outside the current repository migration scope, including Firestore synchronization and backend registration coordination.

Those behaviors therefore remain in `AuthService` until a later migration is explicitly approved.

The immediate architectural correction is dependency direction only: the repository boundary must not depend on the service compatibility layer.

---

## Consequences

* `AuthService` remains the active production compatibility layer during ESR-003.
* `FirebaseSessionRepository` cannot be treated as an authorized runtime replacement for `AuthService` in its current dependency shape.
* Future migration work must preserve current runtime behavior while removing the upward repository-to-service dependency.
* Any later movement of Firestore synchronization or backend registration out of `AuthService` requires separate approval.
