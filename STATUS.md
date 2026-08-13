# SkillForge — Current Status

**Updated:** 13 August 2026  
**Repository:** `xash-mind/skillforge`  
**Project status:** active  
**Current `main` before this status update:** `f1d987dfc250f38d9f5545ca83772bd29a4ab894`  
**Last verified application commit:** `632b418b00e7c953efb308bdc49480532a8877c7`  
**Last verified product milestone:** TASK-003 — academic structure and enrollment  
**Current objective:** Issue #10 / TASK-004 — reconcile and complete the guided teacher class lifecycle  
**Current implementation PR:** draft PR #21 at `0829a8591628a2a7f53fd2e21664403eae80dd3a`; diverged from current `main`, not accepted or merged

## Executive state

The reproducible application foundation, trusted Supabase tenancy/RBAC boundary and TASK-003 academic structure/enrollment milestone remain the last accepted product state. TASK-004 has meaningful implementation in draft PR #21, but the candidate is **not acceptance-ready** and must not be mechanically resumed as though its provider, migration or verification state were coherent.

The most important audit finding is a repository/provider migration-history divergence: the one canonical Supabase project already records TASK-004 migrations `teacher_class_lifecycle` and `teacher_class_lifecycle_hardening` as applied under versions `20260812072724` and `20260812072834`. Current `main` contains neither migration. PR #21 contains candidate files under different version identities: `20260812065000_teacher_class_lifecycle.sql` and `20260812072000_teacher_class_lifecycle_hardening.sql`. Exact hosted statements must be reconciled to repository history before any further schema mutation or merge decision.

The live TASK-004 tables currently contain zero lesson sessions, attendance records, lesson uploads and homework assignments, and the `classroom-evidence` bucket contains zero objects. This lowers data-repair risk but does not remove migration-history risk.

PR #21 final-head verification is red. GitHub Actions run `31574451675` fails during `npm run verify` because temporary self-mutating workflow `.github/workflows/task004-adversarial-test-fix2.yml` is malformed YAML; lint, typecheck, tests, build, and the teacher mobile/keyboard smoke therefore did not execute on the final head. The workflow also writes commits back to the branch and should not remain part of the accepted implementation.

Static audit also found an incomplete upload-recovery path: if Storage succeeds but the database finalization update fails, the lesson-upload record remains `pending` while the file exists in Storage; the current UI offers retry only for `failed` records. TASK-004 therefore does not yet satisfy its failure/retry/recovery boundary.

## Product and acceptance boundary

Issue #10 remains the correct current product outcome, but its scope has been reconciled:

Start Class -> complete attendance -> upload transcript/resources with recoverable failure semantics -> assign homework -> explicit AI-review placeholder -> explicit teacher review -> Publish Class.

TASK-004 owns the classroom upload/failure-recovery subset of `REQ-007`; transcript/note ingestion processing, idempotency, normalization and Learning Graph lineage remain TASK-005. Production AI inference remains TASK-006. Full regional governance remains TASK-008.

The current browser smoke for PR #21 targets `/browser-smoke/teacher-lifecycle`, which is useful proxy evidence for layout/tab order but is not sufficient evidence for `SUCCESS-001`. Acceptance requires a real authenticated teacher-route journey on the exact accepted build, representative mobile and keyboard verification, adversarial database/Storage verification, and explicit owner acceptance.

Until TASK-008 implements the required regional consent and retention gate, TASK-004 verification must use synthetic/non-sensitive evidence. Real minor learning-evidence ingestion must not be enabled before an organization has the allowed versioned consent and retention selections required by the product specification.

## Infrastructure

- **Supabase:** exactly one authorized SkillForge project, `qvrqitirdxmckdqmysqu` in `ap-south-1`; currently `ACTIVE_HEALTHY` on Postgres 17. Security advisor reports no findings.
- **Supabase performance advisor:** informational finding for an unindexed `attendance_records_enrollment_fkey`, plus expected unused-index notices on the currently empty/new schema. Reassess the attendance covering index as part of the TASK-004 database bundle.
- **Vercel identity:** GitHub's Vercel integration still identifies SkillForge as project `prj_IWxn6mdD5LaB9hc4KtuMujtDoNQ8` under team `team_BPsOfcrNMh4WJBgbw8eMcXuN` and attempted PR #21 deployments. On 12 August it rejected deployment after the account exceeded 100 free-tier deployments in the rolling/day limit. Current connected Vercel API calls return upstream 502 errors, so direct provider reconciliation is unavailable in this audit. Do **not** create a replacement project merely to bypass access uncertainty.
- **Canonical production destination:** `https://skillforge-bay-three.vercel.app`.
- **Hosted Auth:** production release still requires reconciliation of hosted Supabase Auth configuration against the repository's intended auth policy.

## Roadmap position

1. TASK-001 — reproducible application foundation — complete.
2. TASK-002 — tenancy, Auth, RBAC and audit — complete.
3. TASK-003 — academic structure and enrollment — complete and verified.
4. TASK-004 — guided teacher class lifecycle — **current recovery/reconciliation objective; not accepted**.
5. TASK-005 — evidence ingestion and Learning Graph lineage — valid, blocked on an accepted TASK-004 classroom boundary.
6. TASK-006 — provider-independent AI adapters and teacher approval — valid, remains after evidence lineage.
7. TASK-007 — role-specific dashboards — valid, after accepted underlying workflows.
8. TASK-008 — billing snapshots and regional governance — valid; governance is a mandatory gate before real minor evidence processing/release.
9. TASK-009 — release verification and operational recovery — valid; Vercel identity/access and hosted Auth reconciliation remain release blockers.

## Needs owner

No owner decision is required to perform the TASK-004 recovery/reconciliation. Owner acceptance is required only after the real teacher lifecycle passes its automated/database/mobile/accessibility verification boundary. No new Supabase or Vercel project is authorized.

## Next action

Execute one bounded TASK-004 recovery run against Issue #10 and draft PR #21:

1. Freshly reconcile current `main`, PR #21 and the exact live Supabase TASK-004 migration statements/history before editing or applying schema.
2. Remove the temporary self-mutating CI correction workflow and preserve deterministic tests/source changes normally.
3. Reconcile migration identity so repository history exactly represents the already-applied canonical Supabase state without replaying the same DDL under a second version.
4. Fix the Storage-success/database-finalization recovery gap and cover interrupted/pending/retry/idempotent recovery paths.
5. Preserve tenant/branch/class/session isolation and teacher-only publication authority.
6. Run the clean canonical quality gate, rollback-safe database/Storage adversarial checks, and a real authenticated teacher-route browser journey including 390x844 mobile, keyboard and failure/recovery evidence.
7. Use only synthetic/non-sensitive learning evidence until regional governance exists.
8. Stop at the TASK-004 acceptance boundary; do not start TASK-005, production AI, billing/governance implementation or release work in the same run.

Deployment is not required for this recovery. If hosted verification later becomes genuinely necessary, use at most one deliberate preview and one production deploy for the run; never create deployments per commit, internal checkpoint or agent branch.
