# SkillForge — Current Status

**Updated:** 14 August 2026  
**Repository:** `xash-mind/skillforge`  
**Project status:** active, pre-release  
**Last accepted product milestone:** TASK-003 — academic structure and enrollment  
**Current product objective:** Issue #10 / TASK-004 — reconcile and complete the guided teacher class lifecycle  
**Delivery-foundation recovery:** Issue #22 — provider repair completed except for the account-level GitHub Actions blocker  
**Current implementation PR:** draft PR #21 at `0829a8591628a2a7f53fd2e21664403eae80dd3a`; unaccepted and outside the Issue #22 provider repair

## Executive state

SkillForge remains pre-release. This run repaired the Vercel delivery foundation without changing product behavior, Supabase schema/data, RLS, Storage policy, AI behavior, billing, governance, dashboards or Learning Graph behavior, and without creating a production release.

The next product run remains Issue #10 / TASK-004 and must freshly reconcile draft PR #21. TASK-009 / Issue #15 remains the only production-release boundary.

## Canonical provider identities

- **Supabase:** exactly one authorized SkillForge project remains: `qvrqitirdxmckdqmysqu` in `ap-south-1`, status `ACTIVE_HEALTHY`. It was inspected only far enough to preserve identity and was not mutated.
- **Vercel:** exactly one canonical project remains: `prj_IWxn6mdD5LaB9hc4KtuMujtDoNQ8` under team `team_BPsOfcrNMh4WJBgbw8eMcXuN`. No replacement or duplicate project was created.
- **Canonical Vercel URL:** repository truth is now `https://skillforge-xash-mind0.vercel.app`, which is a current domain of the existing canonical project. The former documented `https://skillforge-bay-three.vercel.app` was verified unattached and returned Vercel `404 NOT_FOUND`; it is no longer the canonical contract.

## Vercel delivery repair

The root cause of the long-lived failed deployments was provider configuration, not a Next.js source regression. Before repair, the existing project reported `framework: null`, `live: false`, and sampled deployments failed after a successful application build because Vercel expected a static output directory named `public`.

Commit `3c60aceb6af2eb11ccc41088862580f1b55ee922` added the minimal repository-level provider override in `vercel.json`:

- framework preset: `nextjs`;
- output directory override: `null`, returning output handling to the framework default instead of `public`;
- Git deployment policy: `deploymentEnabled: false`.

Vercel's project metadata still reports its stored dashboard framework value as `null`, but file-based Vercel configuration overrides those build settings for deployments. The deliberate preview below proved the effective configuration: Vercel detected Next.js 16.3.0, ran the repository's `npm run build`, completed the Next.js build into `/vercel/output`, deployed Lambda/static outputs, and did not emit the former `STATIC_BUILD_NO_OUT_DIR` / `public` failure.

## Deployment-trigger discipline

Automatic Git deployment churn is now disabled in repository-controlled Vercel configuration.

Verified evidence:

- the required config commit on `agent/restore-delivery-foundation` created zero Vercel deployments;
- fast-forwarding `main` to that same commit created zero Vercel deployments;
- subsequent canonical-identity/tracking commits on the safe branch created zero Vercel deployments;
- resetting the one-off preview branch back to the safe config created zero additional deployments.

Ordinary implementation/docs commits therefore no longer automatically consume preview or production deployments. Deliberate preview/release work must intentionally opt into a deployment and must restore the safe policy afterward.

## One deliberate preview

Exactly one hosted preview was created for this run:

- Vercel deployment: `dpl_Bzt1iQq6gGT2x9XFbMR4UmKEPYbw`;
- preview URL: `https://skillforge-afdjbg7l9-xash-mind0.vercel.app`;
- source branch: `preview/issue-22-delivery-foundation`;
- exact source SHA: `6e24ae89ffecebe83bbf4bedadb8ffb28194a16b`;
- target: preview (`target: null`), not production;
- final state: `READY`;
- build: Next.js 16.3.0 detected, `npm run build` succeeded, TypeScript completed, routes were generated, and Vercel reported `Build Completed in /vercel/output`;
- runtime fetch: HTTP 200 served the expected current SkillForge landing surface, including `Every class becomes a clear next step.` and the teacher-authority statement `AI assists. Teachers decide.`.

The preview-only SHA differs from the safe delivery config only by intentionally setting `git.deploymentEnabled` to `true` long enough to create this single preview. After verification, the preview branch ref was reset to the safe `3c60aceb...` configuration, so it cannot become a continuing deployment loophole.

The served page includes the expected mobile viewport contract, and the exact candidate stylesheet remains mobile-first with larger-layout breakpoints beginning at 48rem and 68rem. A direct 390x844 headless Chromium screenshot could not be captured from the execution container because that container had no external DNS; this limitation is recorded rather than being misrepresented as visual product acceptance. Issue #22 used the hosted render only to prove provider delivery. TASK-004 still requires its own exact-route mobile/browser acceptance later.

## GitHub Actions blocker

GitHub Actions remains an account/provider blocker and must not be interpreted as a code-quality failure.

After the required delivery-config commit reached main, Quality gate run `31784022557` / job `94715794114` again:

- obtained no runner (`runner_id: 0`);
- executed zero steps;
- concluded failure before repository verification began;
- was annotated by GitHub: `The job was not started because recent account payments have failed or your spending limit needs to be increased. Please check the 'Billing & plans' section in your settings`.

The canonical quality workflow is unchanged. No check was removed, weakened, bypassed or faked. Fresh GitHub-hosted quality evidence remains blocked until the account billing/spending-limit condition is fixed by a human/provider setting.

## Product and safety boundary

This delivery run did not absorb TASK-004 work from Issue #10 / PR #21. The known migration-history reconciliation, upload-finalization recovery, CI branch cleanup, authenticated teacher-route verification, adversarial tenant/branch/Storage evidence and owner acceptance remain TASK-004 work.

Teacher authority, tenant isolation, branch isolation and governance constraints are unchanged. No real minor learning evidence was introduced. No sensitive learning data was placed in logs, screenshots, fixtures or provider metadata.

## Roadmap

1. TASK-001 — reproducible application foundation — complete.
2. TASK-002 — tenancy, Auth, RBAC and audit — complete.
3. TASK-003 — academic structure and enrollment — complete and accepted.
4. Issue #22 — delivery foundation repaired; GitHub Actions remains a documented human/provider blocker.
5. TASK-004 / Issue #10 — next product recovery objective; draft PR #21 remains unaccepted.
6. TASK-005 through TASK-008 — remain downstream of accepted earlier boundaries.
7. TASK-009 / Issue #15 — full release verification and production promotion; **no production release occurred in this run**.

## Next action

First fix the GitHub account billing/spending-limit condition so the canonical Quality gate can obtain a runner. Then, in a fresh TASK-004 run, return to Issue #10 / draft PR #21 and reconcile migration identity, remove self-mutating CI machinery, repair pending-upload recovery, verify tenant/branch/session boundaries and prove the real authenticated teacher lifecycle with synthetic evidence.

Production remains deferred to TASK-009. The canonical release URL is `https://skillforge-xash-mind0.vercel.app`, but it must not be promoted until the full release gate passes.

**Deployment discipline:** automatic Git deployments are disabled; deliberate runs remain limited to at most one preview and one production deploy when genuinely required.
