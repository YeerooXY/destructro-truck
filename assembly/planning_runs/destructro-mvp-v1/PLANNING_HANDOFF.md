# Destructro Truck Planning Handoff

## Planning boundary

This package defines architecture, ownership, dependency waves, and verification gates. It deliberately does **not** create executable task batches, task IDs, claims, assignments, or the canonical backlog. Those belong to the later Task Splitter stage after this planning PR is reviewed and merged.

## Repository and module boundaries

Use one product repository.

- `src/core/contracts/**` and `src/core/domain/**`: shared versioned contracts and genuinely shared deterministic helpers, owned by the Contract Steward.
- `src/gameplay/**`: truck runtime, launch, bounce, aerial control, nudge, momentum, contact normalization, viability detection, camera, and grey-box tuning.
- `src/world/**`, `levels/**`, `tools/level_generation/**`: buildings, wrecks, aerial objects, pickups, deterministic schedules, fixed level runtime, and development-time candidate generation.
- `src/run/**`: run modes, lifecycle, scoring, money, combos, boosts, progression, upgrades, equipment, radar capability, achievements, statistics, saves, eligibility, run records, and local submission queue.
- `src/ui/**`: player-facing input, menus, HUD, radar presentation, hints, settings, accessibility, localization, audio/VFX adapters, and presentation integration.
- `backend/**`, build/release tools, export configuration, and CI: online services and release infrastructure.
- Integration/Verification and Red Team are cross-cutting roles, not permanent feature lanes.

No UI component is a gameplay source of truth. Run rules consume normalized events rather than scene-tree internals. Backend validates and persists accepted results but does not calculate local rewards.

## Shared contracts to establish first

The first Task Splitter wave must prioritize minimal, versioned contracts needed by multiple lanes:

1. ruleset and tuning identifiers;
2. normalized gameplay, contact, and world events;
3. command and read-only presentation models;
4. world-object and fixed-level data formats;
5. run lifecycle/result, scoring inputs, and resource deltas;
6. profile/save schema and progression transactions;
7. compact run record, submission queue, and API DTOs;
8. deterministic fixtures and compatibility/versioning rules.

Contracts must not absorb lane-specific behavior merely to centralize it.

## Topological dependency waves

### Wave 0 — contract spine and project skeleton

Contract Steward defines the smallest shared interfaces and fixtures. Online/Release may add only basic CI/export scaffolding. Integration/Verification validates schemas, ownership, and a clean project skeleton.

### Wave 1 — first grey-box playable in parallel

Core Gameplay builds launch, motion, destruction-contact normalization, fixed momentum-loss interface, bounce, aerial recovery, stop detection, camera, and a debug scene. World builds one building/wreck path and a minimal fixed test level against those contracts. Run Rules builds the minimal lifecycle and result state. UI adds only the smallest command/input and restart/result presentation needed for the loop.

Target milestone: `launch → destroy building → fixed momentum loss → wreck/bounce → aerial recovery → eventual stop → result/restart`.

### Wave 2 — complete deterministic local game

Expand world content and three fixed levels; implement both modes, scoring, money, combos, boosts, upgrades, equipment, radar capability, achievements, statistics, saves, and local queue; complete HUD, menus, settings, and accessibility. Integration gates each cross-lane boundary.

### Wave 3 — online and release expansion

After local scoring, progression, eligibility, and compact run-record contracts stabilize, activate the Online/Release lane substantially for leaderboards, validation, identity/reconciliation, crash intake, packaging, CI, and Windows release proof.

### Wave 4 — hardening and release acceptance

Performance scenes, corruption/recovery tests, offline and service-unavailable behavior, abuse fixtures, red-team reviews, build verification, recorded gameplay proof, and the manual release checklist.

## Dynamic concurrency

Run normally with 2–5 active agents. Reach 4–6 only when tasks are truly dependency-ready and file ownership is disjoint. Do not keep every role active, and do not invent work to fill slots. The Contract Steward is an early cross-cutting slot that returns only for reviewed contract changes. Integration/Verification should be activated repeatedly at wave boundaries. Red Team is selected by risk, dependency centrality, and release importance.

## Verification gates

- **Contract gate:** schemas validate, fixtures round-trip, versioning behavior is documented, and consumers do not bypass contracts.
- **Grey-box gate:** the complete first playable loop works with placeholder assets and debug tools.
- **Determinism gate:** identical accepted event streams and ruleset versions produce identical run-domain results.
- **Save gate:** atomic replacement, one backup, corruption handling, and recovery are tested.
- **Offline gate:** gameplay and local progression remain fully available without services.
- **Competitive gate:** Stock/Progression separation, eligibility, run-record arithmetic, duplicate/version checks, and obvious-impossibility rejection are tested.
- **Presentation gate:** keyboard/gamepad parity, readable HUD, accessibility settings, and no gameplay logic in UI.
- **Release gate:** Windows export succeeds, public builds exclude debug/cheat paths, evidence is complete, and critical red-team findings are re-verified.

## Task Splitter guidance

Create small, acyclic, topologically ordered batches. Every task must name its owning slot, exact allowed files, prerequisite contracts/tasks, acceptance criteria, evidence, and integration gate. Prefer contract-first vertical slices over broad subsystem epics. Reserve explicit verification tasks throughout the backlog.

Do not create tasks that require simultaneous edits to the same files by multiple lanes. Contract changes after consumers exist must be separate reviewed tasks with migration and compatibility notes.

The Red Team backlog-crawl mode should read the later canonical backlog plus `assembly/generated/red_team_review_index.json`, select completed eligible unreviewed tasks, and record durable reviews under `docs/red_team/reviews/`. No finding becomes resolved until the fixing change is re-verified.
