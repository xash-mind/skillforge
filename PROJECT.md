# SkillForge

> Complete LoopForge charter draft. Review the canonical machine-readable charter in `.loopforge/charter.json`. This document is not immutable until explicit human approval creates `.loopforge/charter.lock.json`.

## Source boundary

Human-provided decisions: product identity, market, roles, class lifecycle, evidence model, dashboards, AI roadmap, MVP scope, teacher authority, mobile-first posture, billing direction, India-first/global-ready governance, Supabase authorization, canonical Vercel URL, manual billable activation, organization-selected retention and consent, and organization-owned multi-adapter AI.

Implementation-derived proposals for approval: modular-monolith shape, Next.js App Router boundary, detailed domain modules, task order, database entities, verification methods, and evidence requirements.

## Vision

SkillForge is a mobile-first, multi-tenant AI-powered Learning Operating System for tuition centres and coaching institutes. It organizes the complete class lifecycle and turns lesson activity into structured, traceable, teacher-governed learning evidence.

## Users

Platform Owner, Organization Owner, Branch Manager, Teacher, Student, and Parent.

## Goals

- `GOAL-001`: Guided class lifecycle over disconnected menus
- `GOAL-002`: Continuously evolving Learning Graph from complete evidence
- `GOAL-003`: AI assistance with teacher-controlled publication
- `GOAL-004`: Secure multi-tenant, multi-branch, multi-subject operations
- `GOAL-005`: Clear next actions on mobile and desktop
- `GOAL-006`: Per-active-student commercial operation

## Core teacher journey

Start Class → Mark Attendance → Upload Transcript → Upload Resources → Assign Homework → Review AI → Publish Class

## Required capabilities

Authentication; six roles; organizations and branches; RBAC and audit; students, teachers, parents, and relationships; syllabuses, subjects, classes, enrollment, and timetable; attendance and lesson sessions; assignments, homework, assessments, observations, and uploads; transcript and note ingestion; evidence normalization; Learning Graph lineage; phase-1 gap and progress drafts; teacher approval; four role dashboards; manual billable activation; plans, usage snapshots, and invoices; regional consent and retention policies; export and deletion; one Supabase backend; one canonical Vercel deployment.

## Teacher authority

AI output is always a draft. It cannot publish progress, gaps, grades, or another academic decision without an authorized teacher approval action.

## Governance

India is the first launch policy, implemented through versioned regional configuration. There is no universal consent or retention default. Every organization must select allowed consent and retention policies before activating minors or ingesting their learning evidence.

## Billing

Authorized organization users manually activate billable students. Changes are audited. Closed monthly usage snapshots are immutable except through explicit adjustments. The MVP includes plan and invoice tracking, not live payment collection.

## AI

Organizations supply their own provider configuration. Multiple adapters implement one plug-in contract. Secrets remain tenant-scoped and server-only. At least two adapters must pass the common contract suite.

## Architecture and delivery

A modular Next.js App Router application uses one Supabase project for Postgres, Auth, and Storage and one Vercel project for previews and production. RLS, server authorization, audit events, durable jobs, migrations, and provider boundaries protect sensitive operations. See `docs/ARCHITECTURE.md`, `ROADMAP.md`, and `IMPLEMENTATION_PLAN.md`.

## Non-goals

Traditional LMS-first delivery; automatic AI publication; phase-2 content generation; phase-3 tutoring; live payment collection; duplicate production projects.

## Definition of complete

All 24 mandatory requirements and 11 success criteria in `.loopforge/charter.json` pass with exact-commit evidence. Required human acceptance passes for the teacher lifecycle, dashboard clarity, and governance behavior. The accepted commit is verified at https://skillforge-bay-three.vercel.app with rollback documented.
