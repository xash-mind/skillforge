# SkillForge

> LoopForge discovery draft. Product decisions in `.loopforge/decisions/` are human-provided and authoritative; this generated charter is not yet protocol-approved or hash-locked.

## Vision

SkillForge is a mobile-first, multi-tenant AI-powered Learning Operating System for tuition centres and coaching institutes. It organizes the complete class lifecycle and converts lesson activity into structured, traceable learning evidence.

## Users

Platform Owner, Organization Owner, Branch Manager, Teacher, Student, and Parent.

## Core workflow

Start Class → Mark Attendance → Upload Transcript → Upload Resources → Assign Homework → Review AI → Publish Class

## Learning model

Transcripts, notes, work, assessments, attendance, observations, and syllabus objectives become traceable learning evidence in a continuously evolving Learning Graph. AI drafts findings; teachers decide what is published.

## Billing

Authorized organization users manually activate or deactivate billable students. Changes are audited, monthly usage is snapshotted, and closed periods remain immutable except through authorized adjustments. The MVP includes plan and invoice tracking but not live payment collection.

## Governance

India-first controls are designed for later regional configuration. Organizations select retention within platform-enforced limits. Consent, retention, export, deletion, residency, and policy changes are versioned and auditable.

## AI

Each organization supplies its own provider configuration. Credentials remain tenant-scoped and server-only behind a provider interface. AI output remains a draft until teacher approval.

## Infrastructure

- One new Supabase project after charter approval, explicit organization selection, and cost confirmation
- Versioned migrations, RLS, storage policies, authentication integration, and background processing
- One canonical Vercel project at https://skillforge-bay-three.vercel.app

## Definition of complete

All mandatory requirements and success criteria in `.loopforge/charter.json` pass with bound evidence, required human acceptance is recorded, and the exact accepted commit is verified at the canonical production URL.
