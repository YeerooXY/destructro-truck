# Agent 4 — Run Rules, Scoring, and Progression Builder

Task count: 16

## Milestone classification

`4.16` is Agent 4's boss task: prove the complete deterministic offline game-state loop from run start through scoring, rewards, save persistence, progression, local queueing, and restart, using only accepted contracts and without online services.

## 4.1 Create run-domain module skeleton and deterministic test harness

**Purpose**

Create the isolated deterministic environment Agent 4 uses to replay gameplay events and verify domain results without launching real physics scenes.

The harness must support ordered event fixtures, ruleset/profile snapshots, run-relative time, expected-result comparison, reset, both modes, and save/load boundaries.

**Likely files**

- `src/run/**`
- `tests/unit/run/**`
- `tests/fixtures/run/**`
- `tests/integration/save/**`

**Depends on**

`[1.1, 1.2, 1.6]` plus the later project-skeleton task.

**Outputs**

- run-domain directory structure;
- deterministic fixture runner;
- builders for rulesets, profiles, and events;
- equality/comparison helpers;
- smoke tests.

**Acceptance criteria**

- Identical fixtures produce identical results.
- Tests require no physics or world scenes.
- Tests require no network connection.
- Run logic receives contract objects, not Godot nodes.
- Test helpers do not silently alter business rules.
- Both modes use the same harness.

## 4.2 Implement the core run-lifecycle state machine

**Purpose**

Define the authoritative lifecycle of one run, including preparation, launch, active play, ending, completion, abort, and restart/reset.

**Depends on**

`[1.4, 1.6, 4.1]`

**Outputs**

- deterministic lifecycle state machine;
- legal transition rules;
- run-start and run-end hooks;
- transition tests.

**Acceptance criteria**

- Illegal transitions reject explicitly.
- A run cannot start or complete twice.
- Stop/viability events arrive through contracts.
- Agent 4 never checks truck velocity or scene nodes directly.
- Restart clears transient run state.
- Completion does not automatically imply leaderboard eligibility.

## 4.3 Implement Survival mode orchestration

**Purpose**

Implement no-hard-cap Survival rules, continuation while physically viable, accepted end reasons, and mode-specific result metadata.

**Depends on**

`[4.2, 2.10]`

**Outputs**

- Survival mode controller;
- mode-specific result metadata;
- Survival fixtures;
- continuation and end-condition tests.

**Acceptance criteria**

- Survival has no hidden hard cap.
- Long expert runs remain possible.
- A brief slowdown does not end the run.
- One accepted stop signal ends the run once.
- Survival works fully offline.
- No UI timer or leaderboard service is implemented here.

## 4.4 Implement Timed Efficiency mode orchestration

**Purpose**

Implement the timed competitive mode while reusing the same physics, world content, and core event stream.

**Depends on**

`[4.2]`

**Outputs**

- timed-mode controller;
- explicit expiry behavior;
- mode fixtures;
- exact-timeout boundary tests.

**Acceptance criteria**

- Timed Efficiency uses the same gameplay/world events as Survival.
- Expiry semantics are deterministic.
- Events after the accepted cutoff cannot alter the final result.
- Timer rules do not live in UI.
- The mode produces separate result and leaderboard-category metadata.
- Physics behavior does not change merely because the mode is timed.

## 4.5 Implement deterministic score-input accumulation and score breakdown

**Purpose**

Create the authoritative scoring accumulator for destruction value, distance, launch accuracy, chains, combos, bounces, aerial targets, and other explicitly approved components.

**Depends on**

`[1.4, 1.5, 1.6, 3.3, 3.7, 4.2]`

**Outputs**

- score-input accumulator;
- versioned formula configuration;
- score breakdown;
- deterministic fixtures;
- rounding and overflow rules.

**Acceptance criteria**

- Identical ordered events and tuning versions produce identical scores.
- Duplicate destruction events cannot inflate score.
- Score is explainable through its breakdown.
- World objects provide values and IDs but do not calculate totals.
- Physics does not calculate score.
- UI cannot override or recalculate score.
- Numeric overflow and invalid values are handled explicitly.

## 4.6 Implement money and destruction-reward calculation

**Purpose**

Calculate money earned during a run, tied primarily to destruction value, while keeping money distinct from score.

**Depends on**

`[1.5, 1.6, 4.5]`

**Outputs**

- money/reward calculator;
- deterministic reward breakdown;
- reward fixtures;
- versioned tuning data.

**Acceptance criteria**

- Money is primarily derived from destruction value.
- Score and money remain separate fields and calculations.
- Duplicate events cannot duplicate rewards.
- Negative or impossible rewards reject or clamp explicitly.
- World objects do not directly credit the profile.
- Money is not persisted until the local run result is accepted.

## 4.7 Implement combo and chain state

**Purpose**

Implement deterministic combo windows, destruction streaks, balloon chains, bounce chains, multipliers, timeouts, and resets above raw world events.

**Depends on**

`[1.4, 1.6, 3.7, 4.5]`

**Outputs**

- combo state machine;
- chain tracker;
- timeout/reset rules;
- combo score inputs;
- duplicate-protection tests.

**Acceptance criteria**

- Callback duplication cannot inflate combo state.
- Chain order and timing are deterministic.
- World objects do not own combo rules.
- UI only displays combo state.
- Combo multipliers are bounded.
- Restart clears combo history.
- Exact tuning remains versioned.

## 4.8 Implement temporary run boosts

**Purpose**

Implement temporary pre-run boosts, their run snapshot, activation conditions, duration/use count, effect modifiers, expiry, and cleanup.

**Depends on**

`[1.6, 1.8, 4.2, 4.5]`

**Outputs**

- boost definitions and state;
- selection and expiry rules;
- mode eligibility handling;
- boost fixtures.

**Acceptance criteria**

- Boosts are disabled in Stock attempts.
- Temporary boosts never become permanent ownership.
- Boost state resets after each run.
- Boosts cannot activate outside accepted conditions.
- Physical effects occur through contracts, not direct physics mutation.
- Boost selection is recorded in the run snapshot.

## 4.9 Implement permanent upgrades and purchase transactions

**Purpose**

Implement profile-owned permanent upgrades, prerequisites, prices, purchase validation, balance deduction, transaction creation, duplicate prevention, and run snapshots.

**Depends on**

`[1.8, 4.6]`

**Outputs**

- upgrade catalogue;
- prerequisite checking;
- atomic purchase transaction;
- run-ready upgrade snapshot;
- invalid and duplicate purchase fixtures.

**Acceptance criteria**

- Purchases are atomic.
- Insufficient balance rejects without partial changes.
- Missing prerequisites reject clearly.
- Duplicate or replayed transaction IDs reject.
- Upgrade effects are captured in the run snapshot.
- Progression expands planning and control rather than replacing skill.
- No branching-tree UI requirement is introduced.

## 4.10 Implement rear-equipment state and activation rules

**Purpose**

Implement the one swappable rear-equipment slot, including ownership, equipped module, run snapshot, eligibility, charge/cooldown state, use count, recharge, and invalid activation.

**Depends on**

`[1.3, 1.8, 2.11, 4.2, 4.9]`

**Outputs**

- equipment definitions;
- equipped-state management;
- activation rules;
- charge/cooldown state;
- read-only presentation state.

**Acceptance criteria**

- Only owned equipment can be equipped.
- One rear module is active at a time.
- Invalid activation cannot consume charge.
- Charge and cooldown remain deterministic.
- Agent 4 never applies physics directly.
- UI cannot grant charge or bypass cooldown.
- Equipment state is included in eligibility and run-record data.

## 4.11 Implement radar capability progression and detection state

**Purpose**

Implement progression-dependent radar capability, from crude warnings to useful route-planning information.

**Depends on**

`[1.7, 1.8, 3.11, 4.9]`

**Outputs**

- radar capability tiers;
- detection filtering;
- presentation-safe radar model;
- upgrade-to-capability mapping;
- radar fixtures.

**Acceptance criteria**

- Lower tiers cannot access higher-tier information.
- Agent 5 receives only a filtered read-only model.
- Radar does not reveal hidden data merely because UI asks for it.
- World objects do not decide player capability.
- Radar progression remains offline.
- Radar information is deterministic for the same world/run state.

## 4.12 Implement level unlocks, achievements, and statistics

**Purpose**

Implement compact local progression outcomes outside purchases: level unlocks, up to 10 achievements, one-time completion, and single-screen statistics data.

**Depends on**

`[1.8, 4.3, 4.4, 4.5, 4.6]`

**Outputs**

- unlock evaluator;
- achievement catalogue and state;
- compact statistics updater;
- deterministic fixtures.

**Acceptance criteria**

- Achievements unlock once.
- Duplicate run processing cannot duplicate progress.
- The achievement cap is respected.
- Statistics remain compact and locally stored.
- No continuous behavior tracking or analytics pipeline exists.
- Level unlocks work offline.
- UI only renders results.

## 4.13 Implement atomic profile save, backup, migration, and recovery

**Purpose**

Implement safe persistence for one local profile using temporary writes, validation, atomic replacement, one automatic backup, migration, and corruption recovery.

**Depends on**

`[1.8, 4.9, 4.10, 4.11, 4.12]`

**Outputs**

- save repository;
- atomic writer;
- one-backup rotation;
- migration handler;
- corruption and recovery tests.

**Acceptance criteria**

- Interrupted writes do not destroy the last valid profile.
- One automatic backup is maintained.
- Current-save corruption falls back to a valid backup.
- Invalid backup does not overwrite valid current state.
- Unsupported versions fail clearly.
- No cloud-save or multiple-profile behavior is introduced.
- Save files contain no unnecessary online secrets.

## 4.14 Implement local leaderboard eligibility and compact run-record assembly

**Purpose**

Determine local eligibility and assemble a bounded compact run record containing versions, result breakdown, key events, resource changes, bounded movement samples, timestamps, and equipment/boost snapshots.

**Depends on**

`[1.9, 2.11, 4.3, 4.4, 4.5, 4.7, 4.8, 4.10, 4.13]`

**Outputs**

- local eligibility decision;
- machine-readable reason codes;
- compact run-record builder;
- valid, ineligible, and tampered fixtures.

**Acceptance criteria**

- Stock runs reject temporary boosts.
- Debug or cheat state makes a run ineligible.
- Ineligibility does not remove local rewards unless accepted rules require it.
- Record arrays are bounded.
- No complete save file is embedded.
- Agent 4 does not make the server's final validation decision.
- The record does not claim deterministic physics replay.

## 4.15 Implement the local offline submission queue

**Purpose**

Persist eligible run records until online submission is possible, including pending, in-flight, accepted, permanently rejected, retryable, expired, and duplicate states.

**Depends on**

`[1.10, 4.13, 4.14]`

**Outputs**

- persistent local queue;
- state-transition logic;
- idempotency handling;
- presentation-safe queue status;
- offline and restart fixtures.

**Acceptance criteria**

- Gameplay and progression work without services.
- Queue entries survive restart.
- Duplicate enqueue attempts are controlled.
- Retryable and permanent failures are distinct.
- Backend responses cannot rewrite local score calculations.
- Queue processing cannot corrupt profile saves.
- Rejected records retain clear reason state where appropriate.

# 4.16 — Boss task: Prove the complete deterministic offline game-state loop

## Purpose

Prove Agent 4's entire owned subsystem works as one coherent offline game:

`load profile → select mode/level/loadout → create run snapshot → start run → consume gameplay/world events → update score/combo/resources → complete run → calculate score and money → determine unlocks/achievements/statistics → create progression transactions → update profile → atomically save → determine eligibility → optionally queue compact run record → restart or reload → reproduce persisted state`

The proof must cover Survival, Timed Efficiency, Stock, Progression, eligible and ineligible runs, offline operation, save recovery, retryable queue state, and rapid restart.

**Depends on**

`[4.3, 4.4, 4.5, 4.6, 4.7, 4.8, 4.9, 4.10, 4.11, 4.12, 4.13, 4.14, 4.15]` plus the later Agent 7 grey-box integration gate.

**Outputs**

- complete offline-domain integration harness;
- Survival and Timed full-run fixtures;
- Stock and Progression cases;
- save/reload proof;
- corruption-recovery proof;
- queue proof;
- deterministic comparison evidence;
- documented invariants.

**Acceptance criteria**

- Identical event sequences and versions produce identical results.
- Both modes complete correctly.
- Stock and Progression remain separate.
- Temporary boosts invalidate Stock eligibility.
- Score, money, unlocks, achievements, and statistics update exactly once.
- Profile transactions remain ordered and atomic.
- Save/reload reproduces accepted profile state.
- Current-save corruption recovers from the one backup.
- Service absence blocks nothing except immediate online submission.
- Eligible records queue correctly.
- Ineligible runs are not queued as valid submissions.
- No UI, backend implementation, world behavior, or physics logic is duplicated.
- Restart clears transient state without losing accepted progression.
- No post-MVP cloud saves, accounts, analytics, replay, or live-ops scope is introduced.

## Expected Agent 7 integration gates

1. Gameplay/world event consumption into Agent 4 lifecycle and scoring.
2. Full grey-box vertical slice with Agents 2, 3, 4, and 5.
3. Real completed run through profile update, save, restart, and load.
4. Compact run record through Agent 6 validation.

## Explicit non-goals

- No direct inspection or mutation of physics/world nodes.
- No player-facing UI rendering.
- No backend service implementation or server validation decisions.
- No cloud saves, multiple profiles, analytics, replay, live-ops, or post-MVP systems.
