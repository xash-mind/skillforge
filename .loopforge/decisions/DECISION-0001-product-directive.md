# DECISION-0001 — SkillForge Product Directive

Status: human-locked product direction  
Source: explicit human directive on 2026-08-10  
Supersedes: the earlier skill-package creator concept recorded in Q-001 through Q-006  
Protocol note: these product decisions are authoritative, but the generated LoopForge charter remains unlocked until the mandatory charter-approval gate.

## Product

- Name: SkillForge
- Market: tuition centres and coaching institutes
- Identity: an AI-powered Learning Operating System, not a traditional LMS
- Architecture: multi-tenant, multi-branch, multi-subject
- Commercial model: per active student
- Experience: mobile-first
- AI posture: AI-assisted and teacher-controlled

## Roles

- Platform Owner
- Organization Owner
- Branch Manager
- Teacher
- Student
- Parent

## Core operating model

The class lifecycle is the central workflow. Each class should produce structured learning evidence. Teachers remain the final academic authority; AI may recommend but may not automatically publish academic decisions.

Primary learning evidence includes lesson transcripts, student notes, assignments, worksheets, homework, quizzes, exams, attendance, teacher observations, and syllabus objectives. These inputs continuously evolve a Learning Graph rather than producing isolated grades.

## Dashboards

- Organization: institution analytics, branches, teacher oversight, curriculum progress, billing, and permissions
- Teacher: daily workflow, students, assignments, attendance, transcript upload, AI review, and progress approval
- Student: lessons, homework, notes, feedback, and progress
- Parent: progress summaries, homework, attendance, teacher-approved updates, and suggested support

## AI roadmap

1. Transcript analysis, notes comparison, learning-gap detection, and teacher-reviewed progress summaries
2. Worksheet, lesson-plan, quiz, and homework generation
3. Personalized tutoring, adaptive revision, knowledge-aware tutoring, and a long-term learning companion

## MVP

- Foundation: authentication, organizations, branches, roles, students, teachers, and parents
- Academic: syllabus library, custom syllabuses, subjects, classes, and timetable
- Teaching: attendance, lesson sessions, assignments, homework, and file uploads
- Learning engine: transcript ingestion, student notes, evidence engine, Learning Graph, and teacher approval
- Dashboards: organization, teacher, student, and parent

## Required teacher journey

Start Class → Mark Attendance → Upload Transcript → Upload Resources → Assign Homework → Review AI → Publish Class

## Quality and architecture

Use modular feature boundaries, domain-driven organization, a scalable database schema, strong RBAC, audit logging, tenant isolation, responsive mobile-first UI, and an extensible AI pipeline. Future modules must plug in without major rewrites.

## Deployment authorization

Create and use exactly one Vercel project with canonical production URL:

https://skillforge-bay-three.vercel.app

Deploy to that production identity when the LoopForge completion/release gate permits it.
