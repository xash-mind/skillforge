# SkillForge — Current Status

**Updated:** 13 August 2026  
**Repository:** `xash-mind/skillforge`  
**Project status:** active  
**Current `main`:** `28036ca27e8ee40a996e82b5af80857729628b10` before this operations cleanup  
**Last verified application commit:** `632b418b00e7c953efb308bdc49480532a8877c7`  
**Last verified product milestone:** TASK-003 — academic structure and enrollment  
**Current objective:** Issue #10 / TASK-004 — guided teacher class lifecycle  
**Current implementation PR:** draft PR #21 at `0829a8591628a2a7f53fd2e21664403eae80dd3a`; not accepted or merged

## Executive state

The reproducible application foundation, trusted Supabase tenancy/RBAC boundary and academic structure/enrollment milestone are accepted. The next product outcome is the end-to-end teacher class lifecycle.

TASK-003's recovery verification passed the canonical quality gate plus a real headless-Chrome academic-admin journey with 390x844 mobile evidence. The previously passed hosted two-branch database/adversarial verification remains relevant because the recovery changed no academic migration or database authorization behavior.

## Current product work

Issue #10 defines the next coherent outcome:

Start Class -> complete attendance -> enforce session state -> upload transcript/resources with retry recovery -> assign homework -> explicit AI-review placeholder -> explicit teacher review -> Publish Class.

Draft PR #21 contains an implementation candidate for that outcome. It must be reconciled against current `main`, its issue acceptance criteria and current hosted database/runtime state before it is accepted. Production AI inference remains out of scope for this milestone.

## Infrastructure

- **Supabase:** exactly one authorized SkillForge project, `qvrqitirdxmckdqmysqu` in `ap-south-1`.
- **Vercel identity/access blocker:** historical project `prj_IWxn6mdD5LaB9hc4KtuMujtDoNQ8` maps to team `team_BPsOfcrNMh4WJBgbw8eMcXuN`; the connected team currently lists zero projects, direct project/historical deployment lookups return 404, and listing deployments for the project ID returns 403. This does not prove deletion, so do **not** create a replacement project merely to bypass the uncertainty.
- **Canonical production destination:** `https://skillforge-bay-three.vercel.app`.
- **Hosted Auth:** production release still requires reconciliation of hosted Supabase Auth configuration against the repository's intended auth policy.

## Roadmap position

1. TASK-001 — reproducible application foundation — complete.
2. TASK-002 — tenancy, Auth, RBAC and audit — complete.
3. TASK-003 — academic structure and enrollment — complete and verified.
4. TASK-004 — guided teacher class lifecycle — current objective.
5. TASK-005 — evidence ingestion and Learning Graph lineage.
6. TASK-006 — provider-independent AI adapters and teacher approval.
7. TASK-007 — role-specific dashboards.
8. TASK-008 — billing snapshots and regional governance.
9. TASK-009 — release verification and operational recovery.

## Needs owner

No owner decision is required to reconcile or verify the current TASK-004 implementation candidate. Owner acceptance is required before the teacher-lifecycle success criterion is finally accepted, and later provider/cutover decisions should be escalated when they become real.

## Next action

Run a fresh Project Audit before resuming implementation. Reconcile PR #21 with Issue #10, current `main`, tests, migrations and provider reality; then choose the largest safe coherent action needed to make the guided teacher lifecycle genuinely acceptable rather than mechanically resuming an old task state.
