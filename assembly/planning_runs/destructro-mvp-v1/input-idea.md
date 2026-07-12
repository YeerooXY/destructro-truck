# Planning Run Input — destructro-mvp-v1

## Accepted sources

- `project_workspace.json` on `main`
- `assembly/intake/project_intake.json` on `main`
- `assembly/requirements/REQUIREMENTS.md` on `main`
- `assembly/design/MVP_VISION.md` on `main`
- `assembly/design/DESIGN_PRINCIPLES.md` on `main`
- merged requirements PR #1

## Planning objective

Convert the accepted Destructro Truck requirements into a planning-only package containing:

- product interpretation and MVP/non-goal boundary,
- architecture and module boundaries,
- concrete repository/file ownership,
- shared contracts and interfaces defined before consumers,
- frontend screens and user flows,
- backend/service responsibilities,
- verification strategy,
- implementation lanes and role boundaries,
- planned slot scaffold,
- risks, assumptions, and Task Splitter guidance.

## Concurrency guidance

- Optimize for approximately 4–6 concurrent implementation agents when the dependency graph genuinely permits it.
- Do not manufacture lanes to fill capacity.
- Expect about five primary ownership lanes with dynamic concurrency, plus floating integration/red-team review roles.
- Shared contracts and critical foundations must precede dependent implementation.
- Later task batches must be topologically ordered and acyclic.

## Candidate ownership areas to validate during planning

1. Core Gameplay and Physics
2. World Objects and Level Runtime
3. Run Rules, Scoring, and Progression
4. UI, Input, and Presentation
5. Online Services and Release Infrastructure
6. Verification/Integration as a cross-cutting role or temporary lane rather than mandatory permanent implementation ownership

These are hypotheses, not accepted architecture. The Planning Agent must refine or replace them based on coherent file ownership, interfaces, and verification.

## Scope guardrails

- Planning only; do not create executable task IDs or a task backlog.
- Preserve the accepted MVP exactly.
- Prototype-first and placeholder-first sequencing is mandatory.
- No replay, photo mode, gameplay analytics, live ops, modding, cloud save, multiple profiles, or full account system in the MVP.
- The initial playable milestone is the grey-box loop: launch → destroy building → fixed momentum loss → bounce/wreck → aerial recovery → eventual stop → results/restart.
