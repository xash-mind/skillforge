# SkillForge

## Vision

SkillForge is a mobile-first, multi-tenant AI-powered Learning Operating System for tuition centres and coaching institutes. It organizes the complete class lifecycle and turns lesson activity into structured, traceable, teacher-governed learning evidence.

The product should make the next required action obvious for each role while preserving a trustworthy chain from source evidence to every published learning claim.

## Users

- Platform Owner
- Organization Owner
- Branch Manager
- Teacher
- Student
- Parent

## Goals

- `GOAL-001`: Guided class lifecycle over disconnected menus.
- `GOAL-002`: A continuously evolving Learning Graph built from complete learning evidence.
- `GOAL-003`: AI assistance with teacher-controlled publication.
- `GOAL-004`: Secure multi-tenant, multi-branch, multi-subject operations.
- `GOAL-005`: Clear next actions on mobile and desktop.
- `GOAL-006`: Per-active-student commercial operation.

## Core teacher journey

Start Class -> Mark Attendance -> Upload Transcript -> Upload Resources -> Assign Homework -> Review AI -> Publish Class

## Required capabilities

Authentication; six roles; organizations and branches; RBAC and audit; students, teachers, parents and relationships; syllabuses, subjects, classes, enrollment and timetable; attendance and lesson sessions; assignments, homework, assessments, observations and uploads; transcript and note ingestion; evidence normalization; Learning Graph lineage; phase-1 gap and progress drafts; teacher approval; organization/teacher/student/parent dashboards; manual billable activation; plans, usage snapshots and invoices; regional consent and retention policies; export and deletion; one Supabase backend; one canonical Vercel production identity.

The full requirement, constraint and acceptance catalogue is maintained in `docs/PRODUCT_SPEC.md`.

## Teacher authority

AI output is always a draft. It cannot publish progress, gaps, grades or another academic decision without an authorized teacher approval action.

## Governance

India is the first launch policy, implemented through versioned regional configuration. There is no universal consent or retention default. Every organization must select an allowed consent basis and retention policy before activating minors or ingesting their learning evidence.

## Billing

Authorized organization users manually activate billable students. Changes are audited. Closed monthly usage snapshots are immutable except through explicit authorized adjustments. The MVP includes plan and invoice tracking, not live payment collection.

## AI

Organizations supply their own provider configuration. Multiple adapters implement one provider-independent plug-in contract. Secrets remain tenant-scoped and server-only. At least two adapters must pass the common contract suite before the AI milestone is accepted.

## Architecture and delivery

A modular Next.js App Router application uses one Supabase project for Postgres, Auth and Storage and one canonical Vercel project for previews/production. RLS, server authorization, audit events, durable jobs, migrations and provider boundaries protect sensitive operations. See `docs/ARCHITECTURE.md`, `ROADMAP.md` and `IMPLEMENTATION_PLAN.md`.

## Product principles

- Organize the experience around workflows, not menus.
- Show every user what they need to do next.
- Treat complete learning evidence as the primary source of truth.
- Preserve traceability from progress claims back to source evidence.
- AI recommends; teachers decide and publish.
- Design for mobile use during real classes.
- Prefer extensible modules over speculative rewrites.

## Non-goals

- Traditional LMS-first delivery.
- Automatic AI publication of grades, progress, gaps or other academic decisions.
- Phase-2 worksheet/lesson-plan/quiz/homework generation in the MVP.
- Phase-3 personalized tutoring/adaptive revision in the MVP.
- Live payment collection in the MVP.
- Duplicate production projects or aliases created merely for testing.

## Definition of complete

SkillForge is complete when every mandatory requirement and success criterion in `docs/PRODUCT_SPEC.md` is satisfied with evidence appropriate to its risk; required owner acceptance is recorded for the teacher lifecycle, role-dashboard clarity and governance behavior; the exact accepted release commit passes the full clean verification gate; and the canonical production URL `https://skillforge-xash-mind0.vercel.app` serves that accepted commit with a documented rollback path.
