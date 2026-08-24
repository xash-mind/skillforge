# Project Agent Instructions — SkillForge

## Authority and read order

SkillForge keeps current project truth inside this repository. For normal work, orient in this order:

1. the user's current scoped request and observations;
2. `PROJECT.md` — durable product vision and boundaries;
3. `STATUS.md` — current verified state, blockers and next objective;
4. the relevant GitHub Issue and Pull Request;
5. `docs/PRODUCT_SPEC.md`, `ROADMAP.md`, `IMPLEMENTATION_PLAN.md` and relevant ADRs;
6. source, migrations, tests and CI evidence for the area being changed;
7. live provider/runtime evidence when the task depends on it.

Do not treat an old task label, issue description, status sentence or previous agent conclusion as authoritative when current repository/runtime evidence contradicts it.

## Project Operations

`xash-mind/project-operations` is shared operating guidance and the portfolio control-plane source, not a runtime dependency and not a substitute for this repository's product truth.

- Use its audit, verification, status and testing guidance only where it helps the current task.
- Keep mutable SkillForge implementation state and evidence in SkillForge/GitHub.
- Notion is a derived human control view; synchronize it only when the user scopes that work or a material project snapshot changes.
- Normal work follows the Project Audit -> one coherent Next Run objective -> Project Audit loop from the Project Command Centre.

## Product boundaries

- SkillForge is a mobile-first, multi-tenant Learning Operating System for tuition centres and coaching institutes, not a traditional LMS.
- Roles are Platform Owner, Organization Owner, Branch Manager, Teacher, Student and Parent.
- Tenant isolation, branch scoping, trusted authorization and auditability are mandatory.
- Teachers remain the final authority for academic publication. AI produces drafts only.
- Student-data governance is India-first and global-ready through versioned regional policy. There is no universal retention or consent default.
- Organizations supply their own AI provider configuration through provider-independent adapters; provider secrets stay tenant-scoped and server-only.
- Billing is based on manually activated students with auditable changes and immutable closed-period snapshots.
- Use exactly one SkillForge Supabase project and one canonical Vercel production identity. Do not create duplicate provider projects to work around access problems.
- Secrets, credentials and sensitive learning evidence must not be exposed in source, logs, screenshots, fixtures or chat evidence.

## Work selection

Before editing:

1. Reconcile the requested problem with current `main`, open work, implementation, tests and relevant runtime/provider state.
2. Identify the root problem rather than simply resuming the oldest task.
3. Choose the largest safe coherent objective that materially advances the current milestone without combining unrelated risk domains.
4. Preserve accepted product constraints and explicitly record any new durable architecture decision in an ADR when needed.

A run is not successful merely because tracking files become internally consistent; the target product must become meaningfully closer to the intended outcome.

## Commands

```text
Install: npm ci
Develop: npm run dev
Verify: npm run verify
Format: npm run format:check
Lint: npm run lint
Typecheck: npm run typecheck
Test: npm run test
Build: npm run build
```

## Verification

Verification is proportional to changed risk and must be bound to the actual code under review where possible.

- Run `npm run verify` for accepted application changes.
- Add/maintain database adversarial tests for tenancy, branch isolation, role boundaries and lifecycle state transitions.
- Verify mobile and keyboard behavior for user-facing workflow changes.
- Verify loading, empty, invalid, denied, failure, retry and recovery states for affected workflows.
- For authentication, RLS, storage, billing, consent, retention or AI-provider work, include negative-path and cross-tenant tests.
- Do not claim provider, preview or production verification that was not actually performed.
- Documentation-only reconciliation does not justify a deployment.

## Deployment discipline

When a task genuinely requires hosted verification or release, use at most **one deliberate preview and one production deploy** for the run. Do not create deployments per commit, internal checkpoint or agent branch.

## Human escalation

Escalate only for a real owner decision or high-risk boundary: product/business-model changes, paid provider ownership, destructive compatibility changes, privacy/security policy changes, production cutover, or subjective acceptance criteria that explicitly require the owner. Do not stop for ordinary implementation choices that can be safely resolved from accepted project constraints and evidence.
