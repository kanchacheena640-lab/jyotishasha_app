# Enterprise Software Refactoring (ESR)

---

ESR Version: 1.0

Last Updated: 2026-07-03

---

## Project

Jyotishasha Flutter App

Goal:

Refactor the production Flutter application into an enterprise-grade architecture while preserving 100% runtime behavior.

---

## Project Principles

The following principles are mandatory throughout the ESR migration:

* Behavior Preserving Refactoring
* Incremental Architecture Migration
* One Data = One Owner
* One Bootstrap
* One AppCoordinator
* One Session Controller
* Dashboard = Presentation Layer
* Feature Isolation
* Enterprise Coding Standards
* Validation after every ESR slice

---

## Architecture Status

Architecture Decisions:
COMPLETE

ESR Tracker:
docs/esr/05_esr_tracker.md

Current Phase:

ESR-031

Current Status:

* ESR-000 : COMPLETE
* ESR-001 : COMPLETE
* ESR-002 : COMPLETE
* ESR-003 : COMPLETE
* ESR-010 : COMPLETE
* ESR-013 : DEFERRED
* ESR-014 : COMPLETE
* ESR-015 : COMPLETE
* ESR-018 : COMPLETE
* ESR-022 : NO MIGRATION REQUIRED
* ESR-023 : COMPLETE
* ESR-025 : NO MIGRATION REQUIRED
* ESR-030 : COMPLETE
* ESR-031 : COMPLETE

Historical ESR-003 Slice Snapshot:

* ✅ Slice-1 — Network Boundary Audit
* ✅ Slice-2 — Repository Interfaces
* ✅ Slice-3 — Repository Implementations
* ✅ Slice-4 Part-1 — ProfileService
* ✅ Slice-4 Part-2 — AuthService

Current Focus:

Final Git Commit

Remaining Work:

* Final Git Commit

---

## Repository Information

Current Branch

main

Current Commit

7d51015

Leave this field blank (or keep the placeholder) until the current ESR slice has:

* Passed flutter analyze
* Passed flutter test
* Passed flutter run
* Passed manual verification
* Been committed to Git

Only after the validated Git commit exists should this field be updated with:

`git rev-parse --short HEAD`

Do not record the SHA of a commit that predates the validated ESR slice.

The Current Commit field is the validation reference for the latest validated slice, not simply the current repository HEAD.

---

## Authoritative Documents

These documents are the only source of truth for the ESR project.

1. docs/esr/00_MASTER_CONTEXT.md
2. docs/esr/05_esr_tracker.md
3. docs/esr/06_architecture_decisions.md
4. docs/esr/08_data_contract_audit.md
5. docs/esr/10_user_session_profile_contracts.md
6. docs/esr/11_remaining_domain_contracts.md
7. docs/esr/12_network_boundary_audit.md
8. docs/esr/13_repository_interfaces.md
9. docs/esr/14_repository_implementations.md
10. docs/esr/15_profile_service_migration_decision.md
11. docs/esr/15_repository_service_mapping_audit.md
12. docs/esr/16_adr_007_authentication_boundary_ownership.md
13. docs/esr/17_adr_008_optional_constructor_injection_for_service_migration.md

This document is now considered part of the mandatory architecture documentation.

All future ESR-003 service migrations must comply with its decisions.

---

## Architecture Rules

* Never change runtime behavior.
* Never redesign the tracker.
* One ESR phase at a time.
* One owner per data source.
* Dashboard is presentation only.
* AppCoordinator controls startup.
* main.dart remains minimal.
* Validation after every slice:
  * flutter analyze
  * flutter test
  * flutter run
  * manual verification

---

## Validation Workflow

Every ESR slice must finish in the following order:

1. flutter analyze
2. flutter test
3. flutter run
4. Manual verification
5. Architecture review
6. Tracker update

Only after all six steps pass may the next ESR slice begin.

---

## Global Definition of Done (DoD)

No ESR phase is considered COMPLETE until all of the following conditions are satisfied:

Implementation

☐ Scope completed

☐ No work outside approved scope

Validation

☐ flutter analyze PASS

☐ flutter test PASS

☐ flutter run PASS

☐ Manual verification PASS

Architecture

☐ Architecture review PASS

☐ No runtime behavior changes

☐ No unintended dependency changes

Documentation

☐ Tracker updated

☐ Master Context updated

Completion

☐ Slice or Phase marked COMPLETE

☐ Next approved task identified

This Definition of Done applies to every ESR phase from ESR-003 through ESR-031 unless an Architecture Decision Record explicitly overrides it.

---

## Resume Instructions

When resuming this project:

1. Read this file.
2. Read docs/esr/05_esr_tracker.md.
3. Continue from the current ESR phase.
4. Never restart completed ESR phases.
5. Never modify production code outside the current ESR scope.

---

## Historical Record - Last Verified State

ESR-003 Slice-4 Part-2

Status:

PASS

Validation:

* flutter analyze: PASS
* flutter test: PASS
* flutter run: PASS
* Manual verification: PASS
* Architecture review: PASS
* Code review: PASS

Ready for:

ESR-003 Slice-4 Part-3

---

## Completed ESR History

### ✅ ESR-000 — Architecture Decision Records

Completed:

* Architecture frozen
* Architecture decisions documented
* ESR workflow established

---

### ✅ ESR-001 — Regression Baseline

Completed:

* Regression baseline established
* Characterization tests completed
* Shared testing infrastructure
* Integration testing foundation
* Validation completed

---

### ✅ ESR-002 — Application Data Contracts

Completed:

* Slice-1 — Data Contract Audit
* Slice-2 — Shared Foundation Contracts
* Slice-3 — User / Session / Profile Contracts
* Slice-4 — Remaining Domain Contracts
* Final Validation — PASS

---

## ESR-003 Exit Criteria

The phase is considered COMPLETE only when all of the following are satisfied:

☐ Repository interfaces completed

☐ Repository implementations completed

☐ All planned services migrated

☐ No direct HTTP calls remain in migrated services

☐ No direct Firebase calls remain in migrated services

☐ flutter analyze PASS

☐ flutter test PASS

☐ flutter run PASS

☐ Manual verification PASS

☐ Architecture review PASS

☐ Tracker updated

☐ Master Context updated

☐ Ready for ESR-004

---

## Historical Record - Current Progress Snapshot

ESR-003

Completed

✅ Slice-1 — Network Boundary Audit

✅ Slice-2 — Repository Interfaces

✅ Slice-3 — Repository Implementations

✅ Slice-4 Part-1 — ProfileService

✅ Slice-4 Part-2 — AuthService

Current

🟡 Slice-4 Part-3 — UserBootstrapService

Upcoming

⬜ Slice-4 Part-4 — Remaining services:

* Kundali
* Horoscope
* Panchang
* Transit
* Notification
* Reports
* Love
* AskNow
* Billing
* Cards
* Muhurth

⬜ Final Validation

---

## Incremental Migration Policy

Service migration must be performed incrementally.

Each part must:

* preserve runtime behavior
* pass flutter analyze
* pass flutter test
* pass flutter run
* complete manual verification
* complete architecture review

Only after one part passes may the next part begin.

This phased migration reduces risk, simplifies debugging, and provides clean rollback points.

## Architecture Decision — User Service Boundary

There is currently no standalone UserService in the production codebase.

User persistence responsibilities are distributed across AuthService, BackendAuthService, UserBootstrapService, and direct Firestore access.

Until a future approved ESR phase explicitly consolidates those responsibilities, UserBootstrapService remains an independent bootstrap boundary and must not be renamed or treated as UserService.

---

## Appended Reconciliation — 2026-07-03

Historical archive record. The authoritative current state is reflected in `## Architecture Status` above.

Status Update

* Current Phase: ESR-031
* ESR-003: COMPLETE
* ESR-013: DEFERRED
* ESR-030: COMPLETE
* ESR-031: COMPLETE

ESR-030 Completion

* ESR-030 COMPLETE
* ProfileRepositoryAdapter removed from production runtime
* FirestoreProfileRepository is now the production runtime owner
* No public contract changes
* No ProfileProvider changes
* No runtime behavior changes
* Migration Analyzer: PASS
* Characterization: PASS
* flutter run: Not Assessable (environment)
* Manual Verification: Not Assessable (environment)

Final Reconciliation Recorded At The Time

* Completed implementation areas: Profile, Daily Horoscope, Monthly Horoscope, Yearly Horoscope, Personalized Horoscope, Panchang, Notification, Reports
* No Migration Required: Billing, Checkout, Cross Feature Integration
* Deferred: Kundali
* Remaining work only:
  * Remove unused ProfileRepositoryAdapter source file if no production references remain
  * Global Pre-Commit Validation
  * Final Git Commit

---

## Appended Validation Update — 2026-07-03

Historical archive record. The authoritative current state is reflected in `## Architecture Status` above.

Latest ESR-030 / ESR-031 Validation

* Migration Analyzer: PASS
* Characterization: PASS
* flutter run: PASS
* Manual Verification: PASS

Manual Verification Evidence

* Login: PASS
* Dashboard: PASS
* Profile CRUD: PASS
* Notifications: PASS
* Reports Purchase: PASS
* Love Report: PASS
* Horoscope: PASS
* Panchang: PASS

Closure Status

* ESR-030 validation record superseded by completed production verification
* ESR-031 final validation is now recorded as PASS for analyzer, characterization, flutter run, and manual verification

---

This document is the primary source of truth for all future ChatGPT and Codex ESR sessions.
