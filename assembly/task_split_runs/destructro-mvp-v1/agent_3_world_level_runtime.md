# Agent 3 — World Objects and Level Runtime Builder

Task count: 14

## 3.1 Create world module skeleton and debug scene
- Depends on: `[1.1, 1.2, 1.5]` plus the later project-skeleton task.
- Purpose: create `src/world/**`, `levels/**`, `tools/level_generation/**`, world test scenes, and a minimal world sandbox.
- Acceptance: world scenes load without UI, scoring, progression, or backend dependencies.

## 3.2 Implement generic world-object runtime adapter
- Depends on: `[1.4, 1.5, 3.1]`
- Purpose: instantiate versioned world definitions, expose object IDs/types, validate configuration, and emit accepted interaction events.
- Acceptance: no score, money, unlock, or UI logic; invalid definitions fail clearly.

## 3.3 Implement intact building runtime and one-time destruction transition
- Depends on: `[1.4, 1.5, 2.5, 3.2]`
- Purpose: create data-driven intact buildings that react once to accepted truck contact and emit destruction events.
- Acceptance: any valid truck contact destroys exactly once; collision callback spam cannot duplicate destruction.

## 3.4 Implement deterministic wreck replacement
- Depends on: `[1.5, 3.3]`
- Purpose: replace destroyed buildings with one simple collidable wreck shape and visual-only debris hooks.
- Acceptance: replacement is deterministic; debris cannot affect gameplay; wreck identity/profile is exposed to Agent 2.

## 3.5 Integrate fixed speed-cost and optional momentum-impulse requests
- Depends on: `[1.4, 1.5, 2.4, 3.3, 3.4]`
- Purpose: request configured fixed speed loss or optional impulse through Agent 2's accepted momentum interface.
- Acceptance: Agent 3 never mutates truck velocity directly; application occurs once per valid interaction.

## 3.6 Implement second building type and special momentum-building variant
- Depends on: `[3.3, 3.4, 3.5]`
- Purpose: prove shared data-driven behavior supports two building types and a special momentum-granting variant.
- Acceptance: variants reuse shared runtime; no bespoke scoring/progression logic.

## 3.7 Implement balloon target runtime and chains
- Depends on: `[1.4, 1.5, 2.5, 3.2]`
- Purpose: implement aerial balloon contacts, one-time consumption, optional chain/group metadata, and normalized events.
- Acceptance: targets trigger once, use stable IDs, and calculate no score/combo themselves.

## 3.8 Implement rare aerial moving targets
- Depends on: `[1.5, 3.2, 3.10]`
- Purpose: add compact plane/satellite-like targets using deterministic schedules.
- Acceptance: movement repeats for the same level/ruleset version; no runtime randomness or UI ownership.

## 3.9 Implement pickup and recharge-object runtime
- Depends on: `[1.4, 1.5, 2.5, 3.2]`
- Purpose: implement one-time or configured recharge/pickup interactions and normalized resource-request events.
- Acceptance: world objects request effects through contracts and do not own progression, equipment rules, or HUD.

## 3.10 Implement deterministic movement schedules
- Depends on: `[1.2, 1.5, 3.1]`
- Purpose: implement versioned path/timing schedules for moving world objects.
- Acceptance: same definition/version yields the same motion; reset/restart returns to initial state; no uncontrolled runtime randomness.

## 3.11 Implement fixed level-definition loader and validator
- Depends on: `[1.2, 1.5, 3.2, 3.10]`
- Purpose: load fixed shipped levels, instantiate objects/schedules, validate IDs/references, and expose level metadata.
- Acceptance: malformed levels reject clearly; no runtime procedural generation; no UI or unlock decisions.

## 3.12 Build minimal grey-box world level
- Depends on: `[3.3, 3.4, 3.5, 3.7, 3.11]`
- Purpose: build the first contract-compatible level containing ground, one building/wreck path, and one balloon opportunity.
- Acceptance: supports launch-to-destruction-to-bounce-to-aerial-opportunity flow using placeholder assets.

## 3.13 Build development-time level-candidate generator and review export
- Depends on: `[1.5, 3.10, 3.11]`
- Purpose: generate candidate layouts offline for human review, then export fixed versioned definitions.
- Acceptance: generator is never used during shipped runs; candidates are reproducible from seed/config; only reviewed exports become shipped levels.

## 3.14 Create and validate the three fixed MVP levels
- Depends on: `[3.6, 3.7, 3.8, 3.9, 3.11, 3.12, 3.13]` plus later grey-box integration acceptance.
- Purpose: author/tune three distinct fixed levels with ground and aerial route opportunities.
- Acceptance: each level validates, uses accepted object types, remains fixed/versioned, supports both modes, and contains no copied proprietary layouts.

## Explicit non-goals
- No player-facing HUD, radar, menus, icons, tooltips, or final presentation.
- No score, money, combo, achievement, unlock, progression, or leaderboard decisions.
- No runtime procedural level generation.
- No direct mutation of truck physics internals.
