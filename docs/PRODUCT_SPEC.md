# SkillForge Product Specification

**Status:** owner-approved durable product specification  
**Repository:** `xash-mind/skillforge`

This document preserves the product requirements, constraints and acceptance criteria independently of any particular project-management workflow. `PROJECT.md` is the concise vision; this file is the detailed acceptance contract.

## Product summary

SkillForge is a mobile-first, multi-tenant AI-powered Learning Operating System for tuition centres and coaching institutes. It makes the complete class lifecycle operationally simple while turning lesson artifacts into structured, teacher-governed learning evidence that improves decisions for institutions, teachers, students and parents.

## Primary users

Platform Owner; Organization Owner; Branch Manager; Teacher; Student; Parent.

## Goals

- `GOAL-001` — Center daily use on a guided end-to-end class lifecycle rather than disconnected menus.
- `GOAL-002` — Build a continuously evolving Learning Graph from complete student learning evidence rather than isolated grades.
- `GOAL-003` — Use AI to assist teachers while keeping teachers the final authority over all published academic decisions.
- `GOAL-004` — Support secure multi-tenant organizations with multiple branches, subjects and role-specific operations.
- `GOAL-005` — Make the next required action immediately clear on mobile and desktop for every role.
- `GOAL-006` — Support a commercial model based on active students.

## Mandatory requirements

- `REQ-001` — Provide authentication for Platform Owner, Organization Owner, Branch Manager, Teacher, Student and Parent roles.
- `REQ-002` — Enforce strong role-based permissions, tenant isolation, branch scoping and auditable privileged actions at trusted boundaries.
- `REQ-003` — Manage organizations, branches, role assignments, students, teachers, parents and their permitted relationships.
- `REQ-004` — Manage syllabus libraries, custom syllabuses, subjects, classes and timetables across branches.
- `REQ-005` — Guide teachers through Start Class, Mark Attendance, Upload Transcript, Upload Resources, Assign Homework, Review AI and Publish Class.
- `REQ-006` — Record attendance, lesson sessions, assignments, homework, worksheets, quizzes, exams, teacher observations and file uploads.
- `REQ-007` — Ingest lesson transcripts and student notes with visible processing, failure, retry and recovery states.
- `REQ-008` — Normalize learning evidence and connect it to students, lessons, syllabus objectives, subjects, classes, branches and organizations.
- `REQ-009` — Maintain a Learning Graph that traces progress and gaps back to source evidence.
- `REQ-010` — Analyze transcripts, compare notes, detect potential learning gaps and draft progress summaries during AI roadmap phase 1.
- `REQ-011` — Require explicit teacher review and approval before AI-derived academic findings or progress updates are published.
- `REQ-012` — Provide an organization dashboard for institutional analytics, branch management, teacher oversight, curriculum progress, billing and permissions.
- `REQ-013` — Provide a teacher dashboard for daily work, student management, attendance, uploads, assignments, AI review and approvals.
- `REQ-014` — Provide a student dashboard for lessons, homework, notes, feedback and approved progress.
- `REQ-015` — Provide a parent dashboard for approved progress summaries, homework, attendance, teacher updates and suggested support.
- `REQ-016` — Allow authorized organization users to manually activate/deactivate billable students, preserve an audit trail and generate immutable monthly usage snapshots for plan/invoice tracking.
- `REQ-017` — Use modular domain boundaries and an extensible AI pipeline so roadmap modules can be added without major rewrites.
- `REQ-018` — Provide a mobile-first, responsive, accessible interface with clear next actions and usable failure recovery.
- `REQ-019` — Version database schema, tenant policies, storage rules, background processing and configuration in the repository.
- `REQ-020` — Deploy one canonical production identity at `https://skillforge-bay-three.vercel.app` when the release gate passes.
- `REQ-021` — Support India-first, global-ready governance through versioned regional policy definitions; require every organization to select an allowed retention policy and consent basis before minor accounts or learning-evidence processing are enabled; provide export, deletion, residency and audit controls.
- `REQ-022` — Use one Supabase backend with versioned Postgres migrations, RLS, storage policies, authentication integration and tenant-aware server boundaries.
- `REQ-023` — Provide a stable AI adapter plug-in contract with multiple contract-tested adapters, tenant-scoped organization configuration, server-side secret references, capability metadata, observability, retries, normalized failures and teacher-controlled publication.
- `REQ-024` — Block minor-student activation and learning-evidence ingestion until the organization records a consent method allowed by the active regional policy, with versioned evidence, revocation and audit history.

## Constraints

- `CONSTRAINT-001` — All organization-scoped data/actions are isolated by tenant and, where applicable, branch.
- `CONSTRAINT-002` — The product is mobile-first and keeps the next action obvious for every role.
- `CONSTRAINT-003` — Teachers are the final authority for academic publication and progress approval.
- `CONSTRAINT-004` — Architecture uses modular feature boundaries, domain-driven organization, strong RBAC, audit logging and an extensible AI pipeline.
- `CONSTRAINT-005` — Secrets and privileged credentials remain outside source code, logs, chat and evidence.
- `CONSTRAINT-006` — Production uses exactly one Vercel project and the canonical URL `https://skillforge-bay-three.vercel.app`.
- `CONSTRAINT-007` — Student-data behavior launches India first through versioned regional policy; there is no universal retention or consent default and every organization makes an allowed, auditable selection.
- `CONSTRAINT-008` — Use exactly one authorized Supabase project for SkillForge; do not create duplicates to bypass access or workflow problems.
- `CONSTRAINT-009` — Closed billing-period usage snapshots are immutable; later activation changes affect open/future periods unless an authorized adjustment is recorded.
- `CONSTRAINT-010` — Organization-supplied AI credentials remain tenant-scoped, encrypted/provider-secret-managed, server-only and absent from browser payloads, logs and evidence.
- `CONSTRAINT-011` — An organization cannot activate a minor student or ingest learning evidence until its active regional consent and retention selections are complete.
- `CONSTRAINT-012` — AI portability is proven through one contract suite and at least two adapter implementations; provider-specific logic cannot leak into the learning domain.

## Non-goals

- `NONGOAL-001` — SkillForge is not primarily a traditional course-content LMS.
- `NONGOAL-002` — AI does not automatically publish grades, progress judgements, learning gaps or other academic decisions.
- `NONGOAL-003` — AI worksheet, lesson-plan, quiz and homework generation are outside the phase-1 MVP.
- `NONGOAL-004` — Personalized AI tutoring, adaptive revision and the long-term learning companion are outside phase 1.
- `NONGOAL-005` — The MVP does not create duplicate production projects or production aliases for testing.
- `NONGOAL-006` — Live subscription payment collection/payment-processor integration is outside the MVP.

## Product principles

- Workflows, not disconnected menus.
- Make the next action obvious.
- Complete learning evidence is the source of truth.
- Every progress/gap claim must be traceable to source evidence.
- AI recommends; teachers decide and publish.
- Design for mobile use during real classes.
- Prefer extensible modules over speculative rewrites.

## Success criteria

### `SUCCESS-001` — Guided teacher lifecycle

A teacher can complete the full guided class lifecycle from Start Class through Publish Class without leaving the workflow.

**Evidence:** state-transition tests; exact-build browser journey; representative mobile evidence; explicit owner acceptance.  
**Human acceptance required:** yes.

### `SUCCESS-002` — Tenant and branch isolation

No role can read or mutate another tenant's protected data, and branch-scoped roles cannot escape permitted branches.

**Evidence:** database-policy tests, API/server authorization tests, adversarial cross-tenant/branch denial evidence.

### `SUCCESS-003` — Learning Graph lineage

Learning evidence from transcripts, notes, attendance, work, observations and syllabus objectives can be traced into the Learning Graph and back to its source.

**Evidence:** migration/schema verification, ingestion integration tests and lineage-query results.

### `SUCCESS-004` — Portable teacher-controlled AI

At least two organization-configurable AI adapters pass one contract suite, remain tenant-isolated, normalize provider failures, produce drafts only and cannot publish an academic decision without teacher approval.

**Evidence:** adapter contract suite, tenant-config tests, secret non-exposure review, provider failure/retry evidence, unauthorized-publish rejection and teacher-approval audit record.

### `SUCCESS-005` — Role dashboards

Organization, teacher, student and parent dashboards expose only role-appropriate information and make the next action immediately understandable.

**Evidence:** four role browser journeys, role-visibility assertions and explicit owner acceptance.  
**Human acceptance required:** yes.

### `SUCCESS-006` — Multi-branch academic operation

Multi-branch, multi-subject organizations can configure syllabuses, classes, timetables, users and assignments without cross-branch leakage.

**Evidence:** multi-branch integration fixtures, admin browser journey and cross-branch denial results.

### `SUCCESS-007` — Failure and recovery behavior

Attendance, transcript ingestion, uploads and AI processing provide usable loading, empty, invalid, failure, retry and recovery states.

**Evidence:** failure-state browser journeys, upload validation, retry/idempotency tests and failure injection.

### `SUCCESS-008` — Auditable active-student billing

Authorized manual student activation produces reproducible immutable monthly usage snapshots, plans and invoices with auditable adjustments and no cross-tenant visibility.

**Evidence:** authorization/audit tests, snapshot immutability tests, invoice-calculation tests and an authorized billing journey.

### `SUCCESS-009` — Clean quality gate

The application passes relevant static analysis, automated tests, production build, accessibility checks and representative small-screen journeys from a clean setup.

**Evidence:** clean install, CI/static/test output, production build, accessibility results and mobile evidence.

### `SUCCESS-010` — Canonical release and rollback

The canonical production URL serves the exact accepted commit after preview verification and has a documented rollback path.

**Evidence:** one deliberate preview, source SHA parity, production deployment metadata, canonical URL browser verification and rollback procedure.

### `SUCCESS-011` — Regional privacy governance

The India-first regional policy engine requires each organization to select allowed consent and retention settings, blocks minor activation/evidence ingestion until selection, and verifies export, deletion, residency, revocation and audit behavior.

**Evidence:** approved policy configuration, onboarding selection journey, pre-consent denial, consent/revocation tests, retention execution, deletion/export and audit-history evidence.  
**Human acceptance required:** yes.

## Human acceptance policy

Final owner approval is required for the product release. `SUCCESS-001`, `SUCCESS-005` and `SUCCESS-011` explicitly require subjective human acceptance in addition to automated evidence.
