# SkillForge

> LoopForge discovery draft. Product decisions in `.loopforge/decisions/` are human-provided and authoritative; this generated charter is not yet protocol-approved or hash-locked.

## Vision

SkillForge is a mobile-first, multi-tenant AI-powered Learning Operating System for tuition centres and coaching institutes. It organizes the complete class lifecycle and converts lesson activity into structured, traceable learning evidence.

## Users

- Platform Owner
- Organization Owner
- Branch Manager
- Teacher
- Student
- Parent

## Goals

- Run daily work through a guided class lifecycle.
- Build an evolving Learning Graph from complete learning evidence.
- Let AI assist while teachers retain final academic authority.
- Support secure multi-tenant, multi-branch, multi-subject operations.
- Make the next action clear on mobile and desktop.
- Support a per-active-student commercial model.

## Required teacher workflow

Start Class → Mark Attendance → Upload Transcript → Upload Resources → Assign Homework → Review AI → Publish Class

## Required capabilities

### Foundation

Authentication, organizations, branches, roles, students, teachers, parents, RBAC, tenant isolation, and audit logging.

### Academic and teaching

Syllabuses, subjects, classes, timetables, attendance, lesson sessions, assignments, homework, evidence capture, and uploads.

### Learning engine

Transcript ingestion, student notes, evidence normalization, Learning Graph, phase-1 AI analysis, gap detection, progress drafts, and teacher approval.

### Dashboards

Organization, teacher, student, and parent workflows with role-specific information and next actions.

### Billing

Reproducible active-student metering plus plan, usage, and invoice tracking. Live payment collection is outside the current MVP.

## Governance and infrastructure

- India-first student-data governance with configurable controls for later regions
- One new Supabase project after charter approval, explicit organization selection, and cost confirmation
- One canonical Vercel project at https://skillforge-bay-three.vercel.app
- Versioned migrations, RLS, storage policies, authentication integration, and auditability

## Non-goals for phase 1

Traditional LMS-first delivery, automatic AI academic publication, phase-2 content generation, phase-3 tutoring, live payment collection, and duplicate production projects.

## Definition of complete

All mandatory requirements and success criteria in `.loopforge/charter.json` pass with bound evidence, required human acceptance is recorded, and the exact accepted commit is verified at the canonical production URL.
