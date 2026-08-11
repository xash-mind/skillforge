# DECISION-0009 — Trusted Supabase Tenancy and Authorization

Status: verified architectural decision  
Source: [PR #17](https://github.com/xash-mind/skillforge/pull/17), implementation commit [`3c64795f4a5dbee9fd3ceac65ba23d04567b60a8`](https://github.com/xash-mind/skillforge/commit/3c64795f4a5dbee9fd3ceac65ba23d04567b60a8)

## Decision

Supabase Auth establishes identity. PostgreSQL organization memberships, branch memberships, and
scoped role assignments are the only application authorization source of truth. User-editable Auth
metadata may provide display information but never permissions.

Platform-owner grants and security-definer RLS helpers live in a non-exposed `private` schema.
Public tenant tables use explicit column grants, RLS with forced enforcement, purpose-specific
policies, and composite foreign keys that make tenant identity part of cross-table integrity.

Privileged changes append audit events. Audit history cannot be updated or deleted, including by the
database owner through ordinary DML.

## Authentication boundary

The Next.js proxy refreshes Supabase SSR cookies and verifies token claims. Protected pages verify
identity and then load trusted membership and role records under RLS. Public self-registration is
absent from the application and disabled in checked-in configuration; hosted Auth configuration must
be reconciled before release because the current connection cannot inspect or push that setting.

## Verification

Both migrations were transaction-tested and applied to the single authorized live project. The
rollback-safe suite passed 7 named adversarial assertions before and after apply, produced 19 audit
events before rollback, and left no fixture users or tenant rows. Supabase security advisor reports
0 findings. GitHub quality run 31483479380 passed for the exact implementation commit.

## Consequences

- Permission changes take effect from trusted rows rather than stale or forgeable role claims.
- Organization and branch isolation is enforced in both constraints and policies.
- Exact helper execution grants are necessary for policies; authenticated clients still lack private
  schema usage and cannot call helpers directly.
- Regional consent, retention, academics, and billing can extend the stable organization boundary
  without weakening identity controls.
