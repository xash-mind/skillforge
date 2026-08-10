# Completion Evidence Plan

This plan is derived from the unlocked charter and becomes binding only after charter approval.

| Criterion | Primary verification | Required bound evidence |
|---|---|---|
| SUCCESS-001 | Full teacher lifecycle on mobile and desktop | Browser recording, transition tests, owner acceptance |
| SUCCESS-002 | Tenant, branch, and RBAC adversarial tests | RLS output, permission matrix, denied-access evidence |
| SUCCESS-003 | Learning-evidence lineage | Migration tests, ingestion output, graph lineage queries |
| SUCCESS-004 | AI adapter and approval safety | Two-adapter contract suite, secret review, failure tests, publish denial, approval audit |
| SUCCESS-005 | Four role dashboards | Role journeys, visibility assertions, owner acceptance |
| SUCCESS-006 | Multi-branch academic administration | Fixture results, admin journey, cross-branch denials |
| SUCCESS-007 | Failure and recovery | Upload, queue, retry, idempotency, and failure-state journeys |
| SUCCESS-008 | Billing | Activation authorization, immutable snapshots, invoice tests, adjustment audit |
| SUCCESS-009 | Engineering and UX quality | Clean install, static checks, tests, build, accessibility, responsive evidence |
| SUCCESS-010 | Release identity | Preview URL, deployment ID, exact commit, production URL verification, rollback |
| SUCCESS-011 | Regional governance | Policy-selection journey, consent/retention tests, export, deletion, revocation, audit |

Every record must include the run ID, task ID, exact commit or working-tree state, environment, procedure, timestamp, result, and limitations. Proxy journeys must not be described as human testing.
