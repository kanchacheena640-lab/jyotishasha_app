# ADR-008: Optional Constructor Injection for Service Migration

## Status

Accepted for ESR migration.

---

## Decision

1. During ESR migration, production services may introduce optional constructor injection with production defaults.

2. Existing runtime constructors must continue working unchanged.

3. Existing callers must not require modification in order to preserve runtime behavior.

4. Optional injected dependencies may default to the current production implementation.

5. This decision does not authorize production runtime rewiring.

6. This decision does not authorize service locator usage.

7. This decision does not authorize factory injection.

8. This decision exists to preserve backward compatibility while enabling repository migration and testing.

---

## Scope

This ADR applies only to ESR migration work where an existing production service must begin depending on an architectural abstraction without breaking current runtime entrypoints.

It allows constructor-based optional dependency injection only when:

* the public construction pattern remains backward-compatible
* production defaults preserve current runtime behavior
* no existing caller is forced to change

---

## Rationale

ESR migration introduces repository and identity boundaries incrementally while the application continues to run through existing production entrypoints.

Some services are instantiated directly by production callers using zero-argument constructors such as `AuthService()`.

If migration required mandatory constructor injection before runtime wiring was authorized, service migration would be blocked even when the architectural dependency direction is otherwise correct.

Optional constructor injection with production defaults provides the smallest migration mechanism that:

* preserves current runtime construction
* avoids immediate runtime rewiring
* allows services to depend on abstractions
* supports focused testing and later wiring changes under separate approval

---

## Constraints

This ADR does not permit:

* changing existing runtime call sites as part of the constructor-injection decision alone
* replacing production defaults with alternate runtime wiring without separate approval
* hiding dependencies behind service locators
* introducing factories solely to bypass ordinary constructor dependency declaration
* changing public service behavior

---

## Consequences

* Migrated services may accept optional abstraction dependencies through constructors.
* Existing production callers may continue using the same constructor shape.
* Repository migration can proceed without immediate runtime rewiring.
* Testing can supply alternate implementations explicitly through constructor parameters.
* Later runtime wiring changes, if desired, remain separate architectural and implementation decisions.
