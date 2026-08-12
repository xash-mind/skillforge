# RUN-0013 — TASK-003 recovery evidence

- **Task:** TASK-003
- **Verified head:** `632b418b00e7c953efb308bdc49480532a8877c7`
- **GitHub Actions:** run `31570521233` — passed
- **Browser artifact:** `9131151631`
- **Artifact digest:** `sha256:11c6a4da3617bb19551a5cc4f7d7225df0a069888d1af2d17cd0be35fb6b9243`
- **Environment:** GitHub hosted Ubuntu 24.04, Node 24.14.0, npm 11.9.0, Next.js 16.3.0, headless Google Chrome
- **Procedure:** `npm ci`, `npm run verify`, start production server with `SKILLFORGE_BROWSER_SMOKE=1`, dump the real Chrome DOM, assert required academic-admin controls and both branches, then capture the representative mobile screenshot.
- **Result:** pass

## Deterministic gate

Prettier, zero-warning ESLint, route type generation, strict TypeScript, all 31 tests across 9 files, and the production build passed. The recovery also corrected the additive adversarial-suite contract without removing any substantive security assertions.

## Browser/mobile evidence

The registered `/browser-smoke/academic` fixture passed its real Chrome journey. The artifact contains the rendered DOM and a verified `390x844` RGB screenshot. Visual inspection confirms a readable single-column mobile hierarchy with no observed horizontal clipping in the captured viewport.

## Database evidence continuity

The hosted TASK-003 database/adversarial verification from PR #19 remains the authoritative database evidence: two-branch operation, multiple subjects/classes, syllabus/objective lineage, timetable integrity, cross-branch assignment rejection, RLS behavior, and fixture cleanup all passed. This recovery did not alter TASK-003 migrations or database authorization behavior.

## Deployment limitation

Production deployment was not attempted because BLOCKER-014 remains unresolved. The historical Vercel project cannot be conclusively classified as deleted: direct lookups return 404 while deployment listing by its project ID returns 403. Creating another project would risk duplicating the intended canonical project.
