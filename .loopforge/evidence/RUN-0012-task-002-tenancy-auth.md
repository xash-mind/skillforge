# RUN-0012 — TASK-002 Tenancy, Authentication, and RBAC Evidence

## Verified target

- Repository: `xash-mind/skillforge`
- Pull request: [#17](https://github.com/xash-mind/skillforge/pull/17)
- Verified implementation commit: [`3c64795f4a5dbee9fd3ceac65ba23d04567b60a8`](https://github.com/xash-mind/skillforge/commit/3c64795f4a5dbee9fd3ceac65ba23d04567b60a8)
- GitHub quality run: [31483479380](https://github.com/xash-mind/skillforge/actions/runs/31483479380)
- Supabase project: `qvrqitirdxmckdqmysqu` in `ap-south-1`

## Acceptance evidence

| Check | Result | Evidence |
| --- | --- | --- |
| Explicit grants and RLS | Pass | Every exposed tenancy table has explicit grants, RLS, forced RLS, and purpose-specific policies. |
| Trusted authorization | Pass | Membership and role rows authorize access; user-editable metadata never grants permission. |
| Tenant and branch isolation | Pass | The rollback-safe adversarial suite passed 7 named assertions before and after live apply. |
| Composite integrity | Pass | Cross-tenant branch and member references fail composite foreign keys. |
| Role delegation | Pass | Teachers cannot escalate; branch managers can delegate only permitted roles in their assigned branch. |
| Audit immutability | Pass | Privileged changes produced 19 events; authenticated and database-owner update attempts failed. |
| Private helper boundary | Pass | Authenticated clients cannot call private authorization helpers directly. |
| Advisor review | Pass | Security advisor has 0 findings; no missing foreign-key index finding remains. |
| Clean install | Pass | `npm ci` installed 461 packages in a source-only directory. |
| Application verification | Pass | Format, lint, strict types, 8 files / 27 tests, and production build passed locally, clean, and in CI. |
| Dependency audit | Pass | Production dependency audit reported 0 vulnerabilities at high severity or above. |
| HTTP smoke | Pass | Home and sign-in loaded; an unauthenticated workspace request emitted the expected sign-in redirect. |

The package-lock SHA-256 was
`b1d12e065415d9f9d45cc94b08a252a06e84cb72d7d365072a5851646456b8ec`
in both the working source and clean source-only verification directory.

## Live migration and cleanup proof

The hosted migration ledger records `20260811102512 tenancy_auth_rbac_audit` and
`20260811102701 tenancy_advisor_repairs`. The adversarial suite ran inside a transaction and rolled
back its fixtures. Counts after verification were 0 Auth users, profiles, organizations, and audit
events.

## Preserved failed and inconclusive evidence

- Vercel deployment `Ed1yhdVC9cSsrtuSaWhsLfHqyCz2` failed for PR #17. Project
  `prj_IWxn6mdD5LaB9hc4KtuMujtDoNQ8` and its logs are inaccessible through the connected Vercel
  API, retained under `BLOCKER-014`.
- Checked-in Supabase Auth policy disables public sign-up, but hosted Auth settings cannot be
  inspected or pushed with the available connection. Untrusted identities still receive no tenant
  access; release reconciliation is retained under `BLOCKER-015`.
- No screenshot or runtime accessibility report is claimed. Static proxy review and configured HTTP
  smoke passed; production browser verification remains pending.

## Trace

TASK-002 supports `GOAL-004`, `REQ-001`, `REQ-002`, `REQ-003`, `REQ-019`, `REQ-022`, and
`SUCCESS-002`. All four acceptance criteria and prescribed migration, adversarial, Auth, and advisor
checks passed on the exact implementation commit above.
