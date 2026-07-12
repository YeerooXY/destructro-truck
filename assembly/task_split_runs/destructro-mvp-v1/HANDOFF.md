# Destructro Truck Task Splitter Handoff

## Status

Task Splitting for planning run `destructro-mvp-v1` is complete and ready for review.

## Deliverables

Detailed task definitions:

1. `agent_1_contract_steward.md` — 13 tasks
2. `agent_2_core_gameplay_physics.md` — 13 tasks
3. `agent_3_world_level_runtime.md` — 14 tasks
4. `agent_4_run_rules_scoring_progression.md` — 16 tasks
5. `agent_5_ui_input_presentation.md` — 15 tasks
6. `agent_6_online_release_infrastructure.md` — 16 tasks
7. `agent_7_integration_verification.md` — 15 tasks
8. `agent_8_red_team.md` — 12 tasks

Machine-readable execution data:

- `assembly/generated/task_backlog.json`
- `assembly/generated/task_batch_index.json`

Audit:

- `DEPENDENCY_AUDIT.md`

## Totals

- 114 tasks
- 27 topological dependency levels
- 0 missing references
- 0 circular dependencies
- 7 major boss tasks, ending with `7.15`

## First development work

The dependency graph begins with:

- `1.1` — establish contract conventions and fixtures
- `8.1` — initialize the Red Team review workflow and ledger usage

After `1.1`, the next contract and project-foundation work unlocks incrementally. Task prefixes identify ownership; they do not require one entire agent lane to finish before another begins.

## Development operating rules

- Start a task only after every listed dependency is accepted.
- Work normally with 2–5 active agents.
- Use 4–6 only when dependencies are ready and file ownership is disjoint.
- Do not manufacture parallel work to keep agents busy.
- Integration failures return to the owning implementation lane unless the fix is tiny and explicitly assigned to Agent 7.
- Red Team findings create owning-lane follow-up tasks and require re-verification before closure.
- Shared contract changes after consumers exist require explicit reviewed migration/compatibility work.
- Public release acceptance is impossible until critical Red Team findings are resolved and re-verified.

## Milestone path

- `7.1` — foundation smoke integration
- `7.6` — first project-wide grey-box playable
- `3.14` — three fixed MVP levels
- `4.16` — complete deterministic offline game-state loop
- `5.15` — complete player-facing flow
- `7.9` — integrated complete offline game
- `6.16` — online services and reproducible release infrastructure proof
- `8.12` — final adversarial release-candidate review
- `7.15` — complete MVP release acceptance

## Next lifecycle action

Review and merge the Task Splitter pull request. After merge, development may begin from the canonical backlog, starting only dependency-ready tasks.
