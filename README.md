# SkillForge

SkillForge is an AI-powered Learning Operating System for tuition centres and coaching institutes.
It organizes work around the complete class lifecycle and turns lessons, notes, assessments,
attendance, and teacher observations into structured learning evidence. AI can recommend; teachers
remain the final academic authority.

This repository contains the reproducible production scaffold, Supabase tenancy and authorization
foundation, and cookie-based authentication boundary.

## Prerequisites

- Node.js 24.14.x (`.nvmrc` is included)
- npm 11.9.x (pinned through `packageManager`)

## Clean setup

```bash
nvm use
npm ci
cp .env.example .env.local
npm run dev
```

The Supabase variables must be supplied as a pair for authentication routes. Only the public URL and
publishable key belong in `NEXT_PUBLIC_*` variables. Never expose a service-role or secret key to
the browser.

The checked-in example points to the single authorized SkillForge project in `ap-south-1` and uses
its browser-safe publishable key. Local `.env*` files remain ignored.

## Verification

Run the same deterministic gate used before a change is accepted:

```bash
npm run verify
```

The gate checks formatting, ESLint rules, TypeScript, unit and component tests, and the production
Next.js build. GitHub Actions runs the same command for every pull request and `main` push. Each
step can also be run independently:

```bash
npm run format:check
npm run lint
npm run typecheck
npm run test
npm run build
```

The build preparation step clears only Next.js's disposable `.next/dev` type cache. This prevents an
interrupted development server from contaminating the deterministic production route-type check.

## Architecture

The application starts as a modular monolith. Product capabilities live under `src/modules`, while
the App Router in `src/app` is the delivery layer. Domain entry points are framework-independent;
both ESLint and a unit test prevent them from importing Next.js, React, UI components, or provider
implementations.

See [ADR 0001](docs/adr/0001-modular-nextjs-foundation.md) for the decision, boundary map, and
tradeoffs.

See [ADR 0002](docs/adr/0002-supabase-tenancy-and-authorization.md) for the trusted-membership,
role, RLS, audit, and authentication design.

Global loading, error, not-found, sign-in-required, and access-restricted experiences are present.
Supabase's SSR client refreshes sessions in the Next.js proxy. Protected pages verify the token with
`getClaims()` and rely on database membership rows under RLS for authorization.

## Database workflow

The committed Supabase directory contains local configuration, ordered migrations, and a rollback-
safe adversarial SQL suite:

```text
supabase/
├── config.toml
├── migrations/
│   ├── 20260811102512_tenancy_auth_rbac_audit.sql
│   └── 20260811102701_tenancy_advisor_repairs.sql
└── tests/001_tenancy_rbac_rls.sql
```

Create migration filenames with the pinned/current Supabase CLI, then review and apply SQL through a
controlled migration workflow. Against a disposable or approved database, the adversarial suite can
be executed with `psql -v ON_ERROR_STOP=1 -f supabase/tests/001_tenancy_rbac_rls.sql`; it opens a
transaction and rolls back every fixture.

The live project has both migrations recorded. Its security advisor is clean. Performance-advisor
foreign-key findings are repaired; unused-index notices are expected while every product table is
empty and should be re-evaluated after representative traffic exists.

## Authentication trust model

- Public self-registration and anonymous sign-in are disabled in checked-in configuration.
- Accounts are created or invited by an authorized administrator.
- User-editable metadata may supply a display name, but never a permission.
- Organization and branch memberships plus role assignments are the authorization source of truth.
- Platform-owner grants are private and require deliberate privileged bootstrap for an identified
  Auth user; no account or credential is seeded.
- Audit events are append-only, including for privileged database roles.

## Environment contract

| Variable                               | Required          | Purpose                          |
| -------------------------------------- | ----------------- | -------------------------------- |
| `NEXT_PUBLIC_SUPABASE_URL`             | Together with key | Public Supabase project endpoint |
| `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` | Together with URL | Browser-safe project key         |
| `NEXT_PUBLIC_RELEASE_SHA`              | No                | Deployment traceability          |

Environment values are validated with Zod when the root layout loads. A partial Supabase public
configuration fails fast rather than reaching a broken runtime state.
