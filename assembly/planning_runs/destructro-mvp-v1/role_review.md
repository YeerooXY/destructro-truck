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

### UI, Input, and Presentation Builder

**Approved scope:** Option B — complete player-facing layer.

The UI, Input, and Presentation Builder owns keyboard/gamepad action mapping, mobile-aware input abstraction, menus, HUD, launch timing feedback, nudge and equipment meters, radar presentation, contextual hints, settings, accessibility, localization-ready text, player-facing presentation models, audio/VFX adapters, and final UI asset integration. It consumes read-only state and emits commands. It may transform state for display but must never become the source of truth for gameplay, scoring, upgrades, radar detection, world behavior, or leaderboard rules. This role is expected to receive many small tasks across several waves rather than one oversized implementation block.

### Online Services and Release Infrastructure Builder

**Approved scope:** Option B — online services plus release infrastructure.

The Online Services and Release Infrastructure Builder owns leaderboard query/submission services, compact run-record plausibility validation, duplicate/replay/version checks, anonymous device-bound identity, progression-ledger reconciliation, one-time recovery-code transfer, crash-report intake, backend persistence and deployment, CI, Godot Windows export configuration, packaging, and release-build checks. It validates and persists accepted local results but does not own local score calculations, progression rewards, or run-eligibility rules. This lane begins lightly with contracts and fixtures, then becomes substantially active after run-record, scoring, and progression contracts stabilize.

### Integration and Verification Agent

**Approved scope:** Option B — verification owner with tightly scoped integration work.

The Integration and Verification Agent owns cross-lane contract checks, integration harnesses, cross-lane tests, performance scenes, build verification, evidence review, wave-level acceptance checks, and the release acceptance checklist. It may wire approved components together and make tiny integration-only fixes when explicitly assigned, but it must not freely rewrite lane-owned implementation or become a catch-all feature owner. It is expected to receive many verification tasks throughout the project, especially at dependency-wave boundaries and release gates.

### Red Team Verifier

**Approved scope:** Option B — full adversarial reviewer across any selected lane or completed task.

The Red Team Verifier may inspect any selected task, pull request, integration boundary, or completed backlog item for scope drift, cheating paths, nondeterminism, save/progression abuse, leaderboard exploits, privacy violations, misleading proof, weak tests, fragile architecture, performance failures, and competitive unfairness. It may create attack fixtures or tests when explicitly assigned, but it cannot rewrite implementation freely, approve merges, change requirements, or invent new MVP features.

Red-team work must be durable and auditable. The planning package will reserve:

- `assembly/generated/red_team_review_index.json` as the machine-readable review ledger,
- `docs/red_team/reviews/<review-id>.md` for individual human-readable reports,
- `tests/red_team/**` for approved attack fixtures or tests.

Each review record must include at minimum: review ID, reviewed task/PR/commit, scope, reviewer identity, start and completion timestamps, reviewed files/contracts, outcome, severity summary, critical findings, follow-up task references, and re-verification status.

The agent may be launched in a backlog-crawl mode after task decomposition exists. In that mode it reads the canonical backlog and the review index, selects completed but unreviewed eligible tasks in topological/chronological order, skips trivial tasks unless explicitly requested, and records every review. It must not mark a finding resolved without re-verifying the fixing change.

## Pending roles

None.
