# DECISION-0003 — Billing Activation, Retention Control, and AI Ownership

Status: human-provided discovery decision  
Source: explicit human answers on 2026-08-10

## Decisions

- A student becomes billable only when an authorized organization user manually marks the student active.
- Learning-evidence retention is organization-configurable, bounded by platform-enforced limits.
- Each organization supplies and owns its phase-1 AI provider configuration.

## Implementation consequences

- Manual activation and deactivation must be authorized, timestamped, audited, and reflected in immutable monthly usage snapshots.
- Changing a student's active status must not silently rewrite a closed billing period.
- Retention settings must be versioned, tenant-scoped, auditable, and enforced through scheduled deletion or archival workflows.
- AI credentials must be encrypted or stored in an approved secret boundary, remain server-only and tenant-scoped, and never appear in logs, browser payloads, or evidence.
- AI processing must expose provider, request state, failure, retry, and teacher-review status without exposing sensitive prompts or credentials.
