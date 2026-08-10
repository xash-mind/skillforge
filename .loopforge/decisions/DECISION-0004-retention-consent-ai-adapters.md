# DECISION-0004 — Retention Selection, Consent Policy, and AI Adapter Framework

Status: human-provided discovery decision  
Source: explicit human answers on 2026-08-10

## Decisions

- The platform has no universal retention default. Each organization must select an allowed retention policy before learning evidence can be ingested.
- Retention bounds are supplied by the active regional policy; the India-first policy is configurable without hard-coding a single global duration.
- Minor-student consent is configurable by region and organization.
- An organization must select and record an allowed consent basis before a minor student can be activated or evidence can be processed.
- Phase-1 AI uses a plug-in framework supporting multiple adapters. Each organization selects and configures an approved adapter with its own credentials.

## Implementation consequences

- Organization onboarding is incomplete until retention and consent policies are selected.
- Region policies define allowed consent methods, retention bounds, required evidence, and versioned legal-copy references.
- Policy changes are append-only and auditable; they do not silently rewrite the basis under which existing records were collected.
- The AI domain exposes a stable adapter contract, capability metadata, health checks, secret references, normalized job states, retries, usage metadata, and provider-specific error mapping.
- At least two adapter implementations must pass the same contract suite before the plug-in framework can be accepted.
