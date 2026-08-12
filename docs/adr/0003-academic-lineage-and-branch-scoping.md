# ADR-0003 — Versioned academic lineage and branch-scoped classes

- **Status:** Accepted for TASK-003
- **Date:** 2026-08-11
- **Supports:** GOAL-004, REQ-003, REQ-004, SUCCESS-006

## Context

SkillForge needs organization-owned and platform-library curriculum without allowing classes to
drift away from the exact learning objectives they were configured against. Classes, teachers,
students, and timetables must also remain branch-scoped inside one multi-tenant Supabase project.

## Decision

1. `syllabuses` identify either a published platform-library syllabus or an organization-custom
   syllabus.
2. `syllabus_versions` are explicit version boundaries. Subjects may reference only a published
   syllabus/version pair.
3. `syllabus_objectives` belong to one exact syllabus version. Published objective content is
   immutable.
4. `subjects` are organization-scoped and pin one published syllabus version.
5. `classes` are branch-scoped and belong to one subject.
6. `class_objectives` preserve a composite constraint-backed path from class → subject →
   syllabus/version → objective.
7. `class_teachers`, `class_enrollments`, and `timetable_entries` repeat organization and branch
   identity so composite foreign keys and RLS can reject cross-branch assignments at the trusted
   database boundary.
8. `create_custom_syllabus_bundle` and `create_class_bundle` provide atomic organization-admin
   operations for the multi-row invariants that should not be assembled piecemeal in the browser.
9. Organization owners may manage curriculum and all branches. Branch managers may operate only
   their explicitly assigned branches. Teacher and student access is read-scoped through class
   assignment/enrollment rather than academic-administration capability.
10. Official platform-library syllabus content is not seeded by TASK-003. It remains a
    sourced-content responsibility rather than an invented fixture.

## Consequences

- Learning evidence added later can retain stable objective lineage instead of pointing at mutable
  labels.
- Branch leakage is defended by UI scope, RLS, composite foreign keys, role-validation triggers, and
  adversarial tests rather than one application-layer check.
- Replacing a published syllabus requires a new version instead of rewriting historical curriculum
  underneath existing classes.
- The schema is more explicit than a generic JSON curriculum document, but the extra keys are
  intentional traceability and authorization boundaries.

## Verification

- Rollback-safe Supabase adversarial test configures two branches, multiple subjects/classes, and
  validates objective/timetable lineage.
- Cross-syllabus objective selection and cross-branch participant assignments are rejected.
- A branch manager cannot create or read a class in another branch.
- An enrolled student reads only the class and timetable they are authorized to access.
- Application CI verifies TypeScript, unit tests, production build, and a real-headless-Chrome
  academic-admin proxy journey at desktop/mobile viewport sizes.
