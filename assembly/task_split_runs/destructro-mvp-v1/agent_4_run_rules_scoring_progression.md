# Agent 4 — Run Rules, Scoring, and Progression Builder

Task count: 16

## Milestone classification

`4.16` is Agent 4's boss task: prove the complete deterministic offline game-state loop from run start through scoring, rewards, save persistence, progression, local queueing, and restart, using only accepted contracts and without online services.

## 4.1 Create run-domain module skeleton and deterministic test harness
- Depends on: `[1.1, 1.2, 1.6]` plus the later project-skeleton task.
- Purpose: create `src/run/**`, deterministic fixture playback, and isolated run-domain tests.
- Acceptance: identical fixtures produce identical results; no scene-tree or network dependency.

## 4.2 Implement core run lifecycle state machine
- Depends on: `[1.4, 1.6, 4.1]`
- Purpose: initialize, launch, active, ending, completed, aborted, and restart transitions.
- Acceptance: illegal transitions reject; stop/viability signals end runs through contracts; no UI or physics inspection.

## 4.3 Implement Survival mode orchestration
- Depends on: `[4.2, 2.10]`
- Purpose: implement no-hard-cap Survival rules, continuation, and end-reason handling.
- Acceptance: ordinary successful runs can exceed target duration; no network dependency.

## 4.4 Implement Timed Efficiency mode orchestration
- Depends on: `[4.2]`
- Purpose: implement timed mode using the same world/physics events with separate timer/end rules.
- Acceptance: mode shares content/runtime but produces distinct result semantics and leaderboard category data.

## 4.5 Implement deterministic score-input accumulator and score breakdown
- Depends on: `[1.4, 1.5, 1.6, 3.3, 3.7, 4.2]`
- Purpose: accumulate destruction value, distance, launch accuracy, bounce, chain, and other accepted score inputs.
- Acceptance: identical ordered events yield identical breakdown; no physics/world node access.

## 4.6 Implement money and destruction reward calculation
- Depends on: `[1.5, 1.6, 4.5]`
- Purpose: calculate money primarily from destruction value using versioned tuning.
- Acceptance: score and money remain distinct; no world object calculates rewards directly.

## 4.7 Implement combo and chain state
- Depends on: `[1.4, 1.6, 3.7, 4.5]`
- Purpose: implement deterministic combo windows, balloon/object chains, resets, and score inputs.
- Acceptance: callback duplicates cannot inflate combos; world supplies IDs only.

## 4.8 Implement temporary run boosts
- Depends on: `[1.6, 1.8, 4.2, 4.5]`
- Purpose: select/apply accepted temporary boosts and keep them disabled for Stock runs.
- Acceptance: boosts are run-scoped, deterministic from accepted selection, and never persisted as ownership.

## 4.9 Implement permanent upgrades and purchase transactions
- Depends on: `[1.8, 4.6]`
- Purpose: implement upgrade definitions, prerequisites, purchases, balance changes, and ordered transactions.
- Acceptance: invalid/duplicate purchases reject atomically; progression expands options without bypassing skill.

## 4.10 Implement rear equipment state and activation rules
- Depends on: `[1.3, 1.8, 2.11, 4.2, 4.9]`
- Purpose: implement owned/equipped module state, charges/cooldowns, run snapshot, and command eligibility.
- Acceptance: Agent 4 decides rules/state while Agent 2 applies accepted physical effects; UI is not source of truth.

## 4.11 Implement radar capability progression and detection state
- Depends on: `[1.7, 1.8, 3.11, 4.9]`
- Purpose: implement progression tiers from crude warnings to useful route-planning data.
- Acceptance: capability determines allowed information; Agent 5 only presents read-only radar models.

## 4.12 Implement level unlocks, achievements, and statistics
- Depends on: `[1.8, 4.3, 4.4, 4.5, 4.6]`
- Purpose: implement deterministic unlock criteria, up to 10 achievements, and compact statistics.
- Acceptance: events update once, offline; no platform achievements or analytics scope.

## 4.13 Implement atomic profile save, backup, migration, and recovery
- Depends on: `[1.8, 4.9, 4.10, 4.11, 4.12]`
- Purpose: persist one profile using atomic replacement, one automatic backup, schema migration, and corruption recovery.
- Acceptance: interrupted/corrupt writes recover safely; no cloud or multi-slot scope.

## 4.14 Implement leaderboard eligibility and compact run-record assembly
- Depends on: `[1.9, 4.3, 4.4, 4.5, 4.7, 4.8, 4.10, 4.13, 2.11]`
- Purpose: decide local eligibility and assemble bounded versioned compact run records.
- Acceptance: Stock/Progression and boost rules are explicit; no server validation or deterministic replay claim.

## 4.15 Implement local offline submission queue
- Depends on: `[1.10, 4.13, 4.14]`
- Purpose: persist pending records, retryable/permanent states, idempotency data, and queue cleanup.
- Acceptance: service absence never blocks gameplay/progression; duplicate queue entries are controlled.

## 4.16 Prove complete deterministic offline game-state loop
- Depends on: `[4.3, 4.4, 4.5, 4.6, 4.7, 4.8, 4.9, 4.10, 4.11, 4.12, 4.13, 4.14, 4.15]` plus later Agent 7 grey-box integration acceptance.
- Purpose: prove start → play events → score/rewards → result → progression transaction → atomic save → optional queue → restart/load across both modes.
- Acceptance: repeatable fixtures produce identical results; offline behavior is complete; corruption recovery and Stock/Progression separation pass; no UI/backend/physics internals are owned.

## Explicit non-goals
- No direct inspection or mutation of physics/world nodes.
- No player-facing UI rendering.
- No backend service implementation or server validation decisions.
- No cloud saves, multiple profiles, analytics, replay, live-ops, or post-MVP systems.
