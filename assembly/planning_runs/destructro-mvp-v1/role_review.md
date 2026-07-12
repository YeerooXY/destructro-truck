# Destructro Truck Planning Role Review

This file records project-owner approvals made during the planning consultation. Draft generated prompts remain provisional until all roles are reviewed and the planning PR is opened.

## Approved roles

### Contract Steward

**Approved scope:** Option B — contracts plus deterministic shared domain types.

The Contract Steward owns shared schemas, versioned events, DTOs, serialization formats, value objects, and small deterministic calculations genuinely shared by multiple lanes. It does not own lane-specific gameplay, scoring formulas, world behavior, UI behavior, or backend service implementation. It must define shared interfaces before dependent implementation and must not silently change accepted product rules.

### Core Gameplay and Physics Builder

**Approved scope:** Option B — complete moment-to-moment truck runtime.

The Core Gameplay and Physics Builder owns the truck body and wheel behavior, timing-based launch, ground and wreck bounce response, capped mid-air rotation, directional nudge impulses, momentum tracking, normalized contact signals, run-viability/stop detection, gameplay camera behavior, physics debug tooling, and the grey-box feel-tuning environment. It publishes normalized events and must not own scoring, money, progression, achievements, world-object rewards, UI, or leaderboard decisions.

### World Objects and Level Runtime Builder

**Approved scope:** Option B — interactive world objects plus complete fixed-level runtime, with no player-facing UI ownership.

The World Objects and Level Runtime Builder owns data-driven buildings and wrecks, special momentum-granting structures, balloons, plane/satellite-like targets, recharge objects and pickups, deterministic movement schedules, fixed shipped level definitions, level loading, development-time level-candidate generation, and world debug/test scenes. It may expose debug-only labels or diagnostics but does not own HUD, radar presentation, menus, icons, tooltips, or final player-facing presentation. It emits normalized object and route events and must not calculate score, money, achievements, unlocks, or progression.

### Run Rules, Scoring, and Progression Builder

**Approved scope:** Option B — complete deterministic game-state layer above physics/world and below UI/backend.

The Run Rules, Scoring, and Progression Builder owns Survival and Timed Efficiency orchestration, run lifecycle, score and money calculations, combos, temporary boosts, permanent upgrades, rear-equipment state, radar capability progression, level unlocks, achievements, statistics, atomic save/load and backup recovery, leaderboard eligibility, compact run-record assembly, and local offline submission-queue state. It consumes normalized gameplay events and must not inspect physics/world nodes directly, render UI, or implement online services.

## Pending roles

- UI, Input, and Presentation Builder
- Online Services and Release Infrastructure Builder
- Integration and Verification Agent
- Red Team Verifier
