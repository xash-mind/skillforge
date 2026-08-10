# DECISION-0002 — Governance, Backend, and Billing Direction

Status: human-provided discovery decision  
Source: explicit human answers on 2026-08-10

## Decisions

- Launch governance: India first, with controls designed so regional policy can be configured for later global operation.
- Managed backend: create exactly one new Supabase project for SkillForge after the charter is approved and the required organization and cost confirmation gates are satisfied.
- MVP billing: active-student metering plus plan and invoice tracking.
- Live subscription payment collection is not part of this decision and is outside the current MVP unless explicitly added later.

## Implementation consequences

- Model consent, retention, export, deletion, residency, and policy versioning as configurable governance capabilities rather than hard-coded India-only behavior.
- Version the Supabase database schema, RLS policies, storage policies, and supporting functions in `supabase/migrations`.
- Keep all tenant authorization at trusted database and server boundaries.
- Model billing plans, usage snapshots, invoice periods, invoice line items, adjustments, and audit history without requiring a payment processor.
