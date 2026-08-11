# SkillForge

SkillForge is an AI-powered Learning Operating System for tuition centres and coaching institutes.
It organizes work around the complete class lifecycle and turns lessons, notes, assessments,
attendance, and teacher observations into structured learning evidence. AI can recommend; teachers
remain the final academic authority.

This repository currently contains the reproducible production scaffold and domain boundary map.

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

The Supabase variables are optional for the foundation scaffold, but they must be supplied as a
pair. Only the public URL and publishable key belong in `NEXT_PUBLIC_*` variables. Never expose a
service-role key to the browser.

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

Global loading, error, not-found, sign-in-required, and access-restricted experiences are scaffolded
from the start. The last two are ordinary routes until authorization is implemented, avoiding an
experimental runtime dependency in the production foundation.

## Environment contract

| Variable                               | Required          | Purpose                          |
| -------------------------------------- | ----------------- | -------------------------------- |
| `NEXT_PUBLIC_SUPABASE_URL`             | Together with key | Public Supabase project endpoint |
| `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` | Together with URL | Browser-safe project key         |
| `NEXT_PUBLIC_RELEASE_SHA`              | No                | Deployment traceability          |

Environment values are validated with Zod when the root layout loads. A partial Supabase public
configuration fails fast rather than reaching a broken runtime state.
