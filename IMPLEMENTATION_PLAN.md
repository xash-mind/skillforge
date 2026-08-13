# SkillForge Implementation Plan

Status: approved implementation plan

## Ordering

TASK-001 establishes the supported project structure. TASK-002 establishes trusted identity and tenant boundaries before sensitive feature work. TASK-003 and TASK-004 build academic/classroom behavior. TASK-005 adds evidence lineage. TASK-006 adds AI only after evidence and approval states exist. TASK-007 exposes accepted domain behavior to each role. TASK-008 completes billing and governance. TASK-009 is the release gate.

The ordering is a dependency model, not authority to blindly resume the next numbered task. Every run must first reconcile current repository/runtime reality and may rewrite, split, merge or reprioritize tracked work when evidence shows the existing backlog is stale.

## Increment rules

- One coherent product outcome is active at a time unless tightly coupled work shares the same verification and rollback boundary.
- Each outcome traces to requirements and success criteria in `docs/PRODUCT_SPEC.md`.
- Migrations and RLS arrive with the domain behavior they protect.
- UI work includes loading, empty, invalid, denied, failure, retry and recovery states where relevant.
- Sensitive data and secrets are excluded from logs, screenshots, fixtures and evidence.
- Ordinary iterations do not require production deployment.
- Hosted verification is deliberate: at most one preview and one production deploy per run when deployment is actually needed.
- Completion is evidence-based and includes required human acceptance; passing automated checks alone is insufficient for subjective product criteria.

## Issue tracking

GitHub Issues are the current work ledger. TASK identifiers remain stable roadmap labels, while Issue bodies hold scoped acceptance criteria and links to `docs/PRODUCT_SPEC.md`, `ROADMAP.md` and current implementation PRs. The backlog is evidence, not authority: audit it against actual implementation and product behavior before work begins.

## Infrastructure sequence

1. Preserve the single authorized Supabase project and version all schema changes as migrations.
2. Keep authentication, RLS, storage and sensitive server actions behind trusted boundaries.
3. Recover/reconcile access to the canonical Vercel identity rather than creating duplicates.
4. Use deliberate previews only when hosted/browser evidence is materially required.
5. Promote only an accepted release commit to production.
6. Verify the canonical URL maps to that exact commit and preserve a rollback path.

## Release condition

The project is complete only when every mandatory success criterion in `docs/PRODUCT_SPEC.md` has the required evidence, owner acceptance is recorded where specified, no critical/high release blocker remains, and `https://skillforge-bay-three.vercel.app` serves the exact accepted commit with rollback documented.
