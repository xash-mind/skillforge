# ADR 0001: Modular Next.js foundation

- Status: Accepted
- Date: 2026-08-11
- Decision owners: SkillForge engineering

## Context

SkillForge must support six roles, multi-tenant and multi-branch isolation, evidence provenance,
teacher-controlled AI, region-aware governance, and future modules without concentrating all
business logic inside the web framework. The first production scaffold also needs a short path to a
hosted, mobile-first application.

## Decision

Use a single Next.js App Router application as the initial deployable unit, organized as a modular
monolith with explicit domain boundaries under `src/modules`.

Each feature module can grow four inward-to-outward layers:

1. `domain`: entities, value objects, invariants, policies, and domain events;
2. `application`: use cases and ports expressed in domain language;
3. `infrastructure`: Supabase, storage, AI-provider, email, and billing adapters;
4. `presentation`: route handlers, server actions, Server Components, and client interaction.

Only the domain entry points exist in this scaffold. Domain code may depend on shared domain types
or other declared domains, but never on React, Next.js, UI components, or provider implementations.
An ESLint restriction and an architecture test enforce that rule.

The initial domain map is:

- identity and access;
- organizations and branches;
- academic structure;
- class lifecycle;
- learning evidence;
- learning graph;
- privacy and governance;
- teacher-controlled intelligence;
- role workspaces;
- billing and metering;
- audit and operations.

## Consequences

- One application and one deployment keep the MVP operationally simple.
- Domain rules remain portable and testable without rendering UI or connecting to a provider.
- Cross-module work must use declared dependencies and later application-level contracts.
- A module can be extracted only when operational evidence justifies the additional
  distributed-system cost.
- Multi-tenant isolation is defense in depth: request authorization, tenant-scoped repositories, and
  PostgreSQL row-level security. The database details are intentionally deferred to the schema task.

## Alternatives considered

### Separate services from day one

Rejected for the MVP. It would add network boundaries, distributed transactions, and deployment
coordination before usage data identifies any independent scaling need.

### Organize only by Next.js route

Rejected. Route ownership alone would make domain rules depend on presentation structure and make
teacher-authority, tenancy, and evidence invariants harder to test centrally.
