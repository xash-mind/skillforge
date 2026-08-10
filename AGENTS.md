# Project Agent Instructions

This project is governed by the pinned LoopForge protocol recorded in `.loopforge/protocol-lock.json`.

## Read order

1. `.loopforge/protocol-lock.json`
2. `.loopforge/charter.json`
3. `.loopforge/charter.lock.json`
4. `PROJECT.md`
5. `STATUS.md`
6. `.loopforge/state.json`
7. active task or change request
8. recent runs and blockers
9. relevant source and tests

## Boundaries

- Do not modify the locked charter or approved change request.
- Do not modify the LoopForge repository during this project's execution.
- Store all project-specific truth and evidence here.
- Follow repository-specific commands and standards documented by the project.
- Never claim completion without the LoopForge completion gate.

## Vercel deployment hygiene

- Keep LoopForge work on `agent/*` branches. Vercel intentionally does not auto-deploy those branches, so fine-grained protocol commits remain safe and cheap.
- Continue running local and GitHub verification at the normal risk-appropriate boundaries.
- When a coherent bundle needs a hosted exact-head preview, create or update `preview/<bundle>` to the candidate SHA only after the relevant checks pass. Do not advance a preview branch for protocol-only state or evidence commits.
- Merge an approved candidate to `main`; that merge remains the normal production deployment.
- For any other deploy-enabled branch, batch pushes at coherent verification boundaries and avoid protocol-only pushes.
