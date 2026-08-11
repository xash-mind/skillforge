# DECISION-0008 — Verified Modular Next.js Foundation

Status: verified architectural decision  
Source: [PR #16](https://github.com/xash-mind/skillforge/pull/16), implementation commit [`cfc36b43236cff80ceb189a6f97f673777fab74d`](https://github.com/xash-mind/skillforge/commit/cfc36b43236cff80ceb189a6f97f673777fab74d)

## Decision

SkillForge begins as one production Next.js App Router deployable organized as a modular monolith. Eleven domain entry points remain framework-independent; lint and architecture tests prohibit dependencies on Next.js, React, UI components, and provider implementations.

The initial authorization fallback experiences are ordinary `/unauthorized` and `/forbidden` routes until TASK-002 installs real authentication. This keeps the production foundation off experimental authorization interrupts.

## Reproducibility

Node.js, npm, application dependencies, verification scripts, and the dependency graph are pinned. A source-only `npm ci` followed by the complete verification gate passed, as did GitHub Actions run 31479682532.

## Release boundary

TASK-001 excludes cloud deployment. The GitHub-connected Vercel project emitted failed preview deployments whose logs cannot be accessed through the current Vercel connection. That failure is preserved under BLOCKER-014 and does not weaken the exact local and GitHub CI evidence for this architectural increment.
