# SkillForge Implementation Plan

Status: approved implementation plan

## Ordering

TASK-001 establishes the only supported project structure. TASK-002 establishes trusted identity and tenant boundaries before any sensitive feature. TASK-003 and TASK-004 then build academic and classroom behavior. TASK-005 adds evidence lineage. TASK-006 adds AI only after evidence and approval states exist. TASK-007 exposes accepted domain behavior to each role. TASK-008 completes billing and governance. TASK-009 is the release gate.

## Increment rules

- One coherent task is active at a time.
- Each task traces to charter IDs.
- Migrations and RLS arrive with the domain behavior they protect.
- UI work includes loading, empty, invalid, denied, failure, retry, and recovery states.
- Sensitive data and secrets are excluded from logs, screenshots, fixtures, and evidence.
- No production deployment occurs during ordinary iterations.
- The completion gate is reread after every recorded iteration.

## Planned issue mapping after charter approval

Each TASK entry becomes one tracking issue or a milestone epic with bounded child issues when the task cannot fit one reviewable increment. Issue titles and acceptance criteria are generated from `.loopforge/tasks.json`; no issue is created before charter approval to avoid locking stale scope.

## Infrastructure sequence

1. Explicitly choose the Supabase organization.
2. Fetch and present the exact project cost.
3. Receive the required cost confirmation.
4. Create one Supabase project and record its non-secret reference.
5. Develop schema locally through versioned migrations and verify policies.
6. Create the single Vercel project when TASK-001 produces a deployable app.
7. Use previews for browser verification.
8. Promote only the accepted release commit to production.

## Release condition

The project is complete only when all success criteria pass with bound evidence, required actual human acceptance is recorded, integrity locks verify, and https://skillforge-bay-three.vercel.app serves the exact accepted commit.
