# SkillForge Architecture

Status: approved implementation direction

## Shape

SkillForge begins as a modular monolith. One Next.js App Router application owns the web experience and trusted server boundary; one Supabase project provides Postgres, authentication, and storage. Domain modules communicate through explicit application services and events rather than importing provider code across boundaries.

This shape keeps the first release reproducible and reviewable while leaving clear seams for workers or services if measured load later requires them.

## Technology direction

- Current stable Next.js App Router and TypeScript, pinned during implementation
- React Server Components for authenticated reads
- Server Actions for internal mutations
- Route Handlers only for webhooks, uploads, callbacks, and external APIs
- Node.js runtime by default
- Supabase Postgres, Auth, and Storage
- Vercel previews and one production project
- Repository-versioned migrations, policies, configuration, and tests

Client Components are limited to interactive islands. Data passed from server to client is serializable. Every route group supplies appropriate loading, error, not-found, unauthorized, and forbidden experiences.

## Domain modules

1. Identity — profiles, sessions, account lifecycle
2. Tenancy — organizations, branches, memberships, roles, permissions
3. Academic — syllabuses, objectives, subjects, classes, enrollments, timetable
4. Classroom — lesson sessions, attendance, resources, homework, publish state
5. Evidence — transcripts, notes, work, assessments, observations, files
6. Learning Graph — evidence-linked nodes, edges, mastery and gap hypotheses
7. AI — adapter registry, provider configuration, jobs, drafts, review, approval
8. Dashboards — role-oriented queries and next-action models
9. Billing — billable status, monthly snapshots, plans, invoices, adjustments
10. Governance — regions, policies, consent, retention, export, deletion
11. Audit and Operations — append-only events, job state, observability, recovery

Provider implementations depend inward on domain contracts. The learning domain never imports a concrete AI provider, storage SDK, or billing integration.

## Trusted authorization boundary

- Identity establishes the authenticated user.
- Memberships and role assignments are stored in trusted tables.
- RLS and server authorization both enforce tenant and branch scope.
- User-editable metadata is never used for authorization.
- Exposed tables receive explicit grants and RLS.
- Policies combine authentication with tenant, membership, relationship, and object predicates.
- UPDATE policies use both USING and WITH CHECK.
- Views use security-invoker behavior or remain outside exposed schemas.
- Privileged functions live outside exposed schemas, validate the caller, and revoke PUBLIC execution when appropriate.
- Service-role credentials never enter browser code.

Every tenant-owned table carries an organization identifier; branch-owned records also carry branch scope. Relationships that cross scopes are rejected by constraints and tests.

## Core data model

Foundation: organizations, branches, profiles, memberships, role_assignments, students, guardians, student_guardians, teacher_profiles, audit_events.

Academic: syllabus_catalogs, syllabuses, syllabus_versions, syllabus_objectives, subjects, classes, class_enrollments, timetable_entries.

Classroom: lesson_sessions, attendance_records, lesson_resources, assignments, homework_items, submissions, publish_events.

Evidence: evidence_items, evidence_versions, file_objects, transcript_segments, student_notes, assessment_results, teacher_observations.

Learning Graph: graph_nodes, graph_edges, evidence_links, mastery_hypotheses, learning_gap_drafts, progress_summary_drafts, teacher_reviews, approvals.

AI: ai_adapter_definitions, organization_ai_configurations, ai_jobs, ai_job_attempts, normalized_ai_outputs, usage_records. Secret values are referenced from an approved server-side secret boundary rather than stored in ordinary application rows.

Billing: billing_plans, organization_plan_assignments, student_billable_status_events, monthly_usage_snapshots, invoices, invoice_lines, invoice_adjustments.

Governance: regions, regional_policy_versions, organization_policy_selections, consent_records, consent_revocations, retention_jobs, export_requests, deletion_requests.

## Teacher class state machine

draft → started → attendance_marked → evidence_uploaded → homework_assigned → ai_review_ready → teacher_reviewed → published

Required transitions are explicit. Invalid transitions fail with actionable guidance. Publishing requires an authorized teacher review; AI processing alone can never enter published.

## Learning evidence and graph

Evidence is append-oriented and versioned. Each graph node or edge records its derivation, evidence links, syllabus objective, model or rule version, confidence, and approval status. AI-generated gaps and progress remain hypotheses until teacher action.

Deletion and retention workflows preserve audit facts while removing or anonymizing governed content according to the active policy.

## AI plug-in contract

Each adapter declares capabilities, validates organization-owned configuration, submits normalized requests, streams or polls job state, maps provider errors, reports usage, and returns a normalized draft. At least two adapters share one contract suite.

The application stores secret references only. Provider calls run at a trusted boundary with tenant-scoped configuration and redacted observability.

## Billing

Authorized organization users create billable-status events. Monthly usage snapshots derive from those events and become immutable when closed. Corrections use append-only adjustments. Plans and invoices track amounts and currency configured by the platform or organization; the MVP does not collect payment.

## Regional governance

There is no global retention or consent default. A regional policy version defines allowed choices and required evidence. Organization onboarding must record permitted consent and retention selections before minor activation or learning-evidence ingestion.

## Reliability

Long-running ingestion, AI, retention, export, and deletion work uses durable job records with idempotency keys, bounded retries, terminal states, and operator-visible recovery. Logs are structured and redact student content and secrets. Risky migrations and releases require rollback procedures.

## Deployment

- Local checks first
- One coherent branch or pull-request preview per meaningful iteration
- Exactly one Vercel project: skillforge-bay-three
- One canonical production URL: https://skillforge-bay-three.vercel.app
- Exactly one Supabase production project, selected and cost-confirmed after charter approval
- Production only after preview, regression, integrity, and human-acceptance gates
