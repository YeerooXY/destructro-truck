# New Chat Resume — Destructro Truck Planning

## Repository checkpoint

- Repository: `YeerooXY/destructro-truck`
- Active branch: `ai/planning-destructro-mvp-v1`
- Lifecycle phase: Planning Agent run `destructro-mvp-v1`
- Requirements PR #1 has been merged into `main`.
- The role-definition consultation is complete.
- The overall Planning stage is **not yet complete** and no planning PR has been opened.

## Start the next chat with this instruction

Continue the Destructro Truck Planning Agent run from the connected GitHub repository `YeerooXY/destructro-truck`, branch `ai/planning-destructro-mvp-v1`.

Read `assembly/context/NEW_CHAT_RESUME.md` first and follow it exactly. Then read:

1. `project_workspace.json`
2. `assembly/intake/project_intake.json`
3. `assembly/requirements/REQUIREMENTS.md`
4. `assembly/design/MVP_VISION.md`
5. `assembly/design/DESIGN_PRINCIPLES.md`
6. `assembly/planning_runs/destructro-mvp-v1/input-idea.md`
7. `assembly/planning_runs/destructro-mvp-v1/role_review.md`
8. `assembly/generated/project_spec.json`
9. `assembly/generated/repo_plan.json`
10. `assembly/generated/agent_prompts.json`
11. the copied Planning Agent workflow/instructions under `assembly/`

Treat repository files as authoritative. Do not restart requirements intake or repeat the agent-scope questions already answered.

## Accepted role scopes

All role choices were explicitly approved by the project owner as Option B.

### Contract Steward

Owns shared schemas, versioned events, DTOs, serialization, value objects, and small deterministic domain calculations shared by multiple lanes. Does not own lane-specific gameplay, scoring formulas, world behavior, UI behavior, or backend implementation.

### Core Gameplay and Physics Builder

Owns the complete moment-to-moment truck runtime: body/wheel behavior, launch, ground/wreck bounce, mid-air rotation, nudge, momentum, normalized contacts, stop/viability detection, camera, physics debug tools, and grey-box feel tuning. Does not own scoring, progression, world rewards, UI, or leaderboard rules.

### World Objects and Level Runtime Builder

Owns buildings, wrecks, special momentum structures, balloons, plane/satellite-like targets, pickups/recharge objects, deterministic movement schedules, fixed level definitions/loading, development-time level candidate generation, and world debug scenes. It owns no player-facing UI and no scoring/progression decisions.

### Run Rules, Scoring, and Progression Builder

Owns Survival and Timed Efficiency rules, run lifecycle, scoring, money, combos, boosts, upgrades, equipment state, radar capability progression, level unlocks, achievements, statistics, atomic save/backup recovery, leaderboard eligibility, compact run-record assembly, and local offline submission-queue state. It consumes normalized events and does not inspect physics/world nodes directly, render UI, or implement online services.

### UI, Input, and Presentation Builder

Owns the complete player-facing layer: keyboard/gamepad mapping, mobile-aware action abstraction, menus, HUD, launch timing feedback, resource meters, radar presentation, hints, settings, accessibility, localization-ready text, presentation models, audio/VFX adapters, and final UI integration. It consumes read-only state and emits commands. It must never become the source of truth for gameplay rules.

### Online Services and Release Infrastructure Builder

Owns leaderboard services, compact run-record plausibility validation, duplicate/replay/version checks, anonymous identity, progression-ledger reconciliation, recovery-code transfer, crash intake, backend persistence/deployment, CI, Windows export configuration, packaging, and release-build checks. It starts lightly with contracts/fixtures and ramps up after local run-record/scoring/progression contracts stabilize.

### Integration and Verification Agent

Owns cross-lane checks, integration harnesses/tests, performance scenes, build verification, evidence review, wave-level acceptance checks, and release acceptance. It may wire approved components together and make tiny explicitly assigned integration-only fixes, but it cannot become a catch-all implementation owner.

### Red Team Verifier

A floating adversarial reviewer that may inspect any selected task, PR, integration boundary, or completed backlog item. It looks for scope drift, cheating, nondeterminism, save/progression abuse, leaderboard exploits, privacy issues, weak tests, misleading proof, fragile architecture, performance failures, and competitive unfairness. It may create attack fixtures/tests when explicitly assigned but cannot rewrite implementation freely, approve merges, change requirements, or add MVP features.

The red-team design requires:

- `assembly/generated/red_team_review_index.json` as the machine-readable review ledger,
- `docs/red_team/reviews/<review-id>.md` for human-readable reports,
- `tests/red_team/**` for approved attack fixtures/tests.

The later Red Team Agent should support backlog-crawl mode: read the canonical backlog and review index, identify completed but unreviewed eligible tasks, prioritize high-risk and highly depended-on work, review them in topological/chronological order, and never mark a finding resolved without re-verifying the fixing change.

## Architecture direction already established

- Use one product repository.
- Plan around five primary implementation ownership areas rather than forcing six permanent lanes:
  1. Core Gameplay and Physics
  2. World Objects and Level Runtime
  3. Run Rules, Scoring, and Progression
  4. UI, Input, and Presentation
  5. Online Services and Release Infrastructure
- Contract Steward, Integration/Verification, and Red Team are cross-cutting roles.
- Dynamic concurrency should normally be 2–5 agents and may reach 4–6 only when the dependency graph genuinely permits it.
- Do not manufacture parallel work to keep agents occupied.
- Shared contracts come first; later Task Splitter batches must be acyclic and topologically ordered.
- The first playable milestone is the grey-box loop:
  `launch → destroy building → fixed momentum loss → wreck/bounce → aerial recovery → eventual stop → result/restart`.

## Current branch files and their status

### Already drafted

- `assembly/generated/project_spec.json`
- `assembly/generated/repo_plan.json`
- `assembly/generated/agent_prompts.json`
- `assembly/planning_runs/destructro-mvp-v1/input-idea.md`
- `assembly/planning_runs/destructro-mvp-v1/role_review.md`

The draft `agent_prompts.json` was created before the full consultation. It must now be reviewed and revised so every prompt exactly matches `role_review.md`, especially:

- World agent has no player-facing UI ownership.
- Integration agent may perform tightly scoped integration work and should receive many verification tasks.
- Red Team requires a durable ledger and backlog-crawl mode.

## Next actions in the fresh chat

Continue the Planning Agent workflow without asking the user to repeat role decisions:

1. Inspect and reconcile `project_spec.json`, `repo_plan.json`, and `agent_prompts.json` against the approved role review.
2. Decide whether the Contract Steward is represented as a planned slot or as an early cross-cutting slot; do not force all roles to be simultaneously active.
3. Create `assembly/generated/slots_db.json` as a planning-stage role/lane scaffold using the slot contract.
4. Add the red-team review ledger scaffold at `assembly/generated/red_team_review_index.json` only if appropriate for the planning package; do not create fake completed reviews.
5. Write a human-readable planning handoff/architecture summary under `assembly/planning_runs/destructro-mvp-v1/` describing:
   - module boundaries,
   - shared contracts,
   - topological dependency waves,
   - dynamic concurrency expectations,
   - verification gates,
   - Task Splitter guidance.
6. Validate all planning artifacts against copied contracts and available validators.
7. Inspect the final branch diff.
8. Open one planning PR against `main`.
9. Explicitly defer executable task batches, task IDs, assignments, and the canonical backlog to the later Task Splitter stage.

## Important guardrails

- Do not implement the game in this planning run.
- Do not create `task_batch_index.json`, task-batch files, `task_backlog.json`, claims, or task assignments.
- Do not reopen accepted product requirements.
- Do not silently move post-MVP features into the MVP.
- Do not force the maximum number of lanes or agents.
- Keep Git as durable context; commit meaningful planning checkpoints.

## Expected completion response

After the planning PR is opened, report:

- repository,
- branch,
- PR number/link,
- files created or updated,
- validation results,
- blockers/open questions,
- next lifecycle action: review and merge the planning PR, then start Task Splitting in a fresh context.
