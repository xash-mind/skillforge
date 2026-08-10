# SkillForge

> LoopForge discovery draft. Product decisions in `.loopforge/decisions/DECISION-0001-product-directive.md` are human-locked; this generated charter is not yet protocol-approved or hash-locked.

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

- `GOAL-001`: Center work on a guided class lifecycle rather than disconnected menus.
- `GOAL-002`: Build an evolving Learning Graph from complete learning evidence.
- `GOAL-003`: Let AI assist while teachers retain final academic authority.
- `GOAL-004`: Support secure multi-tenant, multi-branch, multi-subject operations.
- `GOAL-005`: Make the next action immediately clear on mobile and desktop.
- `GOAL-006`: Support per-active-student commercial operation.

## Required teacher workflow

Start Class → Mark Attendance → Upload Transcript → Upload Resources → Assign Homework → Review AI → Publish Class

## Required capabilities

### Foundation

Authentication, organizations, branches, roles, students, teachers, parents, RBAC, tenant isolation, and audit logging.

### Academic

Syllabus library, custom syllabuses, subjects, classes, and timetable.

### Teaching

Attendance, lesson sessions, assignments, homework, evidence capture, and file uploads.

### Learning engine

Transcript ingestion, student notes, evidence normalization, Learning Graph, phase-1 AI analysis, gap detection, progress drafts, and teacher approval.

### Dashboards

Organization, teacher, student, and parent experiences organized around role-specific workflows and next actions.

## Non-goals for phase 1

- Traditional LMS-first course delivery
- Automatic AI publication of academic decisions
- Phase-2 content generation
- Phase-3 personalized tutoring
- Duplicate production projects

## Constraints

- Multi-tenant and branch isolation
- Mobile-first and accessible
- Teacher-controlled academic publication
- Modular domain boundaries and extensible AI pipeline
- Reproducible database, storage, jobs, and configuration
- One canonical Vercel project at https://skillforge-bay-three.vercel.app
- Human-approved student-data governance before production

## Product principles

- Workflows over menus
- The next action is always obvious
- Complete evidence over isolated grades
- Trace every conclusion to its evidence
- AI recommends; teachers decide
- Design for real classroom use

## Definition of complete

All mandatory requirements and success criteria in `.loopforge/charter.json` pass with bound evidence, required human acceptance is recorded, and the exact accepted commit is verified at the canonical production URL.
