# ADR 0002: Supabase tenancy and authorization foundation

- Status: Accepted
- Date: 2026-08-11
- Decision owners: SkillForge engineering

## Context

SkillForge stores identity and student-adjacent operational data for multi-tenant, multi-branch
institutions. Six product roles must coexist without trusting editable profile metadata, and every
privileged access change must remain attributable. The first market is India, while the schema must
support later regional policy modules without changing the tenant boundary.

## Decision

Use Supabase Auth for identity and PostgreSQL rows for all authorization:

- `profiles` projects a minimal display identity from `auth.users` but is never an authorization
  source;
- `organizations` are the tenant root and `branches` are constrained children;
- organization and branch memberships record trusted access scope;
- role assignments record organization-owner, branch-manager, teacher, student, and parent grants;
- platform-owner grants live in the non-exposed `private` schema;
- composite foreign keys reject cross-tenant branch and membership references;
- every public table has explicit Data API grants, RLS, forced RLS, and purpose-specific policies;
- database triggers append privileged mutations to `audit_events`; client roles cannot update or
  delete those events.

Supabase SSR clients use publishable keys only. The root Next.js proxy refreshes sessions and calls
`getClaims()` before producing a response. Protected pages verify identity with `getClaims()` and
then load database memberships under RLS. `getSession()` and user-editable metadata are not used to
authorize access.

## Role boundaries

- Platform owners provision organizations through privileged operations.
- Organization owners manage their organization, branches, members, and tenant role grants.
- Branch managers manage only their assigned branches and may delegate teacher, student, and parent
  roles there.
- Teachers, students, and parents receive workflow capabilities but cannot manage access.

Public self-registration is disabled. Users are created or invited through an authorized
administrative workflow. No platform owner is seeded in source control; the first grant requires an
identified Auth user and a deliberate privileged bootstrap operation.

## Verification

The migration was first executed inside a rolled-back transaction. The committed adversarial SQL
suite then passed before and after the live migration. It proves tenant isolation, branch isolation,
forged-metadata denial, delegation limits, composite tenant integrity, private-helper isolation, and
append-only audit history. Supabase's security advisor reports no findings. Performance-advisor
foreign-key findings were repaired; remaining informational notices are unused indexes on an empty
database and must be reassessed after representative traffic exists.

## Consequences

- Authorization remains fresh because policy decisions query trusted rows instead of stale JWT role
  claims.
- RLS helpers are security-definer functions in a non-exposed schema. Only exact policy helper
  signatures have `EXECUTE`; authenticated users have no schema `USAGE`, so direct calls remain
  unavailable.
- Tenant identifiers use database identities for index locality; RLS and composite constraints,
  rather than identifier obscurity, enforce isolation.
- Regional consent and retention configuration remains a later governance migration built on the
  stable organization boundary.
