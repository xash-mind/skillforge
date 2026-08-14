# SkillForge — Current Status

**Updated:** 14 August 2026  
**Repository:** `xash-mind/skillforge`  
**Project status:** active, pre-release  
**Current `main` before this status update:** `2a7d8076aad996c37b7f53ac354d3a1e98be8c78`  
**Last verified application commit:** `632b418b00e7c953efb308bdc49480532a8877c7`  
**Last accepted product milestone:** TASK-003 — academic structure and enrollment  
**Current product objective:** Issue #10 / TASK-004 — reconcile and complete the guided teacher class lifecycle  
**Immediate delivery blocker:** Issue #22 — restore the one canonical delivery foundation before hosted acceptance  
**Current implementation PR:** draft PR #21 at `0829a8591628a2a7f53fd2e21664403eae80dd3a`; diverged from current `main` (`ahead 15 / behind 2`), not accepted or merged

## Executive state

SkillForge has a real application foundation, trusted Supabase tenancy/RBAC boundary, and accepted TASK-003 academic structure/enrollment work. It is **not production-ready** and currently has no working canonical Vercel production deployment.

The next product milestone remains TASK-004. Draft PR #21 contains substantial teacher-lifecycle work, but it is not acceptance-ready because repository/provider migration identity is divergent, the final PR quality gate is red, upload recovery is incomplete, and its browser evidence is a proxy rather than the real authenticated teacher workflow.

A fresh 14 August provider audit also found an earlier delivery-foundation blocker: the one existing Vercel project is visible again, but it is configured incorrectly for this Next.js repository and has never produced a working production deployment in the sampled TASK-001-through-current history. This is tracked in Issue #22 so it can be repaired without prematurely turning TASK-009 into a production release.

## Verified product/repository reality

- Current pre-status-update `main` is `2a7d8076aad996c37b7f53ac354d3a1e98be8c78`; the last two main commits after the accepted TASK-003 recovery are project-operations/status documentation changes rather than a new accepted product milestone.
- Draft PR #21 remains diverged from main and must be reconciled rather than merged mechanically.
- PR #21 final run `31574451675` genuinely fails during `npm run verify`: Prettier cannot parse temporary workflow `.github/workflows/task004-adversarial-test-fix2.yml`. The remaining lint/typecheck/tests/build and teacher mobile/keyboard steps are skipped. That branch-only workflow also grants `contents: write` and self-mutates the branch; it must not survive into an accepted candidate.
- Current main run `31693959567` is **not a code-quality failure**. GitHub starts no runner, executes zero steps, and annotates the job: recent account payments failed or the spending limit needs increasing. Treat CI as an external verification blocker until account Actions capacity is restored; do not weaken the quality gate.
- Main itself contains only the accepted workspace/academic surfaces. The real teacher lifecycle route exists only in draft PR #21 at present.
- The public home source already communicates the intended class lifecycle and teacher authority, but its Start Class control is intentionally disabled and says interactive workflows arrive in a later milestone. A working deploy would therefore still represent a pre-release foundation, not a finished product.

## TASK-004 database and failure-recovery boundary

The canonical Supabase project already records TASK-004 migrations `teacher_class_lifecycle` and `teacher_class_lifecycle_hardening` as applied under versions `20260812072724` and `20260812072834`. Current main contains neither migration. PR #21 contains candidate files under different identities: `20260812065000_teacher_class_lifecycle.sql` and `20260812072000_teacher_class_lifecycle_hardening.sql`.

Exact hosted statements must be reconciled to repository history before any further schema mutation. Replaying equivalent DDL under a second migration identity is not acceptable.

The live canonical database currently contains zero auth users, profiles, organizations, branches, subjects, classes, enrollments, class teachers, lesson sessions, attendance records, lesson uploads and homework assignments; the `classroom-evidence` bucket also contains zero objects. This makes current reconciliation low-data-risk, but it does not remove migration-history risk.

PR #21 also has a verified cross-provider recovery gap: if Storage succeeds but the database finalization update fails, the metadata row remains `pending` while the file exists in Storage. The route/UI only offers retry for rows already marked `failed`, so that path can become unrecoverable. TASK-004 must repair this before acceptance.

Supabase is otherwise healthy: the one authorized SkillForge project is `qvrqitirdxmckdqmysqu` in `ap-south-1`, security advisor reports no findings, and the performance advisor's substantive TASK-004 note is an informational unindexed `attendance_records_enrollment_fkey`.

## Delivery/runtime reality

- **One Vercel identity still exists:** project `prj_IWxn6mdD5LaB9hc4KtuMujtDoNQ8` under team `team_BPsOfcrNMh4WJBgbw8eMcXuN`. Do not create a replacement project.
- **Project configuration is wrong:** Vercel reports `framework: null`, `live: false`.
- **Latest current-main production attempt is broken:** deployment `dpl_HDPHFRcKx9EpkYk1k7wBahzueLyU`, source SHA `2a7d8076aad996c37b7f53ac354d3a1e98be8c78`, ends `ERROR` because Vercel expects an output directory named `public` after the build. The TASK-001 production attempt shows the same error, proving this is a long-lived project configuration fault rather than a new source regression.
- **Documented canonical URL is stale/broken:** repository truth currently names `https://skillforge-bay-three.vercel.app`, but the current Vercel project does not list that domain and the URL returns Vercel `NOT_FOUND` (404). Current listed project domains are `skillforge-xash-mind0.vercel.app` and `skillforge-git-main-xash-mind0.vercel.app`.
- **Deployment churn is structural:** Vercel history shows ordinary main commits and many implementation/agent-branch commits automatically generating deployment attempts. The written “one preview / one deploy” rule is therefore not sufficient by itself; Git/Vercel trigger configuration must also be reconciled. This behavior contributed to the earlier >100-deploy free-tier exhaustion.
- Full production release remains TASK-009. Issue #22 is only the prerequisite needed to make deliberate previews and later exact-build acceptance trustworthy.

## Product and acceptance boundary

TASK-004 remains:

Start Class -> complete attendance -> upload transcript/resources with recoverable failure semantics -> assign homework -> explicit AI-review placeholder -> explicit teacher review -> Publish Class.

TASK-004 owns only the classroom upload/failure-recovery subset of `REQ-007`. Transcript/note ingestion processing, normalization, idempotency and Learning Graph lineage remain TASK-005. Production AI adapters remain TASK-006. Teachers remain the final academic publication authority.

The current PR #21 browser smoke at `/browser-smoke/teacher-lifecycle` is useful rendering/tab-order evidence but is not `SUCCESS-001`. Acceptance requires the real authenticated teacher route on the exact candidate, representative 390x844 mobile and keyboard verification, failure/recovery paths, adversarial database/Storage isolation checks, and explicit owner acceptance.

Until regional governance is implemented, verification must use synthetic/non-sensitive evidence. Real minor learning evidence must not be enabled before allowed versioned consent and retention selections exist.

## Roadmap reconciliation

1. TASK-001 — reproducible application foundation — complete.
2. TASK-002 — tenancy, Auth, RBAC and audit — complete.
3. TASK-003 — academic structure and enrollment — complete and verified.
4. **BLOCKER #22 — canonical delivery foundation — immediate prerequisite for reliable hosted acceptance; not a production release.**
5. TASK-004 — guided teacher class lifecycle — current product recovery/reconciliation objective; not accepted.
6. TASK-005 — evidence ingestion and Learning Graph lineage — valid, blocked on accepted TASK-004 boundaries.
7. TASK-006 — provider-independent AI adapters and teacher approval — valid, after evidence lineage.
8. TASK-007 — role-specific dashboards — valid, after accepted underlying workflows.
9. TASK-008 — billing snapshots and regional governance — valid but internally dependency-sensitive: governance must be established before any real minor evidence/pilot behavior; billing does not justify delaying that safety gate.
10. TASK-009 — full release verification and operational recovery — valid; production remains deferred until the release gate.

## Needs owner / human blockers

- GitHub Actions currently cannot execute because of the account billing/spending-limit state. This is a human/provider blocker for fresh CI evidence; local verification can continue but must not be misrepresented as a passing GitHub quality gate.
- Owner acceptance is required only after the real TASK-004 teacher journey passes automated/database/mobile/accessibility verification.
- No new Supabase or Vercel project is authorized.

## Next action

Run one bounded delivery-foundation recovery against Issue #22 **before relying on hosted verification**:

1. Reconcile the existing Vercel project settings; fix the Next.js framework/output misconfiguration without creating another project.
2. Reconcile the stale documented canonical URL with the one-project identity constraint.
3. Stop automatic per-commit/agent-branch deployment churn so repository deployment discipline is actually enforceable.
4. Re-check GitHub Actions availability; do not weaken CI if billing remains blocked.
5. If provider verification requires a build, use at most one deliberate preview from an exact known main commit. Do not production-release unfinished SkillForge.
6. Stop after the delivery foundation is proven or a human billing/identity blocker is reached.

Then resume Issue #10 / PR #21 as a separate product recovery: reconcile exact Supabase migration identity, remove self-mutating CI machinery, fix pending-upload recovery, verify tenant/branch/session boundaries, and prove the real authenticated teacher lifecycle with synthetic evidence.

**Deployment discipline: only 1 preview and 1 deploy maximum for this run; do not create per-commit or agent-branch deployments.**
