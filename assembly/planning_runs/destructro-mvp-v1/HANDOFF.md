# Destructro Truck Planning Handoff

## Planning run

- Run ID: `destructro-mvp-v1`
- Branch: `ai/planning-destructro-mvp-v1`
- Requirements source: merged PR #1 on `main`
- Lifecycle output: planning package only
- Final executable task decomposition is intentionally deferred to a fresh Task Splitter after the planning PR is reviewed and merged.

## Accepted architecture summary

Use one repository with strict internal ownership boundaries and contract-first dependency ordering.

Primary implementation lanes:

1. Core Gameplay and Physics
2. World Objects and Level Runtime
3. Run Rules, Scoring, and Progression
4. UI, Input, and Presentation
5. Online Services and Release Infrastructure

Cross-cutting roles:

- Contract Steward: creates shared interfaces before consumers.
- Integration and Verification Agent: checks cross-lane behavior and evidence where risk justifies it.
- Red Team Verifier: floating adversarial reviewer for any selected task; not counted as a normal implementation lane and not mandatory for trivial work.

## Architectural boundaries

### Shared contracts and deterministic domain

`src/core/contracts/**` and `src/core/domain/**` define versioned rulesets, gameplay events, player commands, presentation models, world-object data, save/profile/progression formats, compact run records, API DTOs, reason codes, and deterministic calculations.

### Physics boundary

`src/gameplay/**` owns Godot physics nodes and converts engine behavior into normalized events and snapshots. Scoring, progression, saves, UI, and backend logic must not inspect physics nodes or scene paths directly.

### World boundary

`src/world/**` owns objects, level loading, deterministic schedules, building destruction, wreck replacement, pickups, and aerial interactions. It emits accepted events but does not calculate final score, progression, achievements, or leaderboard validity.

### Run-domain boundary

`src/run/**` consumes normalized events and owns modes, scoring, rewards, upgrades, radar capability, achievements, statistics, saves, and compact run-record production.

### Presentation boundary

`src/ui/**` renders read-only presentation models and emits accepted commands through the input/action abstraction. It must not duplicate gameplay-domain rules.

### Online boundary

`backend/**` validates and persists submitted contracts. It must never become a dependency for ordinary gameplay or local progression.

## Topological implementation waves

Wave numbers indicate dependency order, not mandatory calendar sprints.

### Wave 0 — Repository foundation and contracts

Expected useful concurrency: 2–3 agents.

Create first:

- Godot project skeleton and directory conventions.
- Development-versus-release feature flags.
- Core typed/value-object conventions.
- Gameplay event and player-command contracts.
- Ruleset/version identifiers.
- World-object, building, level, and deterministic schedule formats.
- Presentation-model boundaries.
- Save/profile/progression transaction contracts.
- Compact run-record and API contracts.
- Test harness and fixture conventions.
- Basic CI/schema validation.

No lane should build large consumer features against invented interfaces before the relevant contract exists.

### Wave 1 — Grey-box playable loop

Expected useful concurrency: 2–3 agents.

Primary work:

- Core Gameplay: truck body, launch, camera, ground interaction, rotation, nudge, momentum accounting, and stop detection.
- World Runtime: one debug building, deterministic intact-to-wreck replacement, fixed speed cost, one balloon target, and a minimal debug level.
- UI/Input: keyboard/gamepad action abstraction and minimal debug HUD.

Acceptance milestone:

`launch → destroy building → fixed speed loss → bounce from wreck/ground → hit balloon → regain momentum → eventually stop → results/restart`

Do not expand content or polish until this loop is understandable and fun with placeholders.

### Wave 2 — Complete local run loop

Expected useful concurrency: 3–4 agents.

After the grey-box loop and event contracts stabilize:

- Survival orchestration.
- Timed Efficiency strategy using the same runtime.
- Deterministic scoring, money, combo, and result calculation.
- Basic profile/save with atomic replacement and backup.
- Run Results screen and normal/Instant Restart flow.
- Second building type and shared special-building impulse variant.
- Deterministic compact run-record assembly without online submission.

### Wave 3 — Progression and route depth

Expected useful concurrency: 4–5 agents.

- Permanent upgrades and prerequisites.
- Rear equipment state and activation models.
- Temporary pre-run boosts and fixed-layout pickups.
- Radar progression from vague warning to planning support.
- Achievements, statistics, and level unlocks.
- Balloon chains, satellite-like targets, plane interception, recharge objects, and deterministic schedules.
- Three fixed levels and development-time candidate generation/tuning tools.
- Menus, settings, accessibility, contextual hints, and localization-ready text.

### Wave 4 — Online services and content completion

Expected useful concurrency: 4–5 agents.

Begin substantial online implementation only after score, progression, save, and compact-run-record semantics are stable.

- Leaderboard query/submission service.
- Plausibility validator and machine-readable rejection reasons.
- Offline submission queue integration.
- Anonymous identity and progression reconciliation.
- Recovery-code rotation and one-active-identity behavior.
- Opt-in crash-report intake.
- Final level/content balancing and presentation integration.
- Build/export automation and cross-lane integration tests.

### Wave 5 — Release candidate

Expected useful concurrency: 2–4 agents.

- Bug fixing and regression verification.
- Performance scenes and cosmetic quality scaling.
- Windows export and installation checks.
- Release-build exclusion of debug/cheat tools.
- Accessibility and controller pass.
- Backend abuse and outage testing.
- Recorded gameplay proof and manual acceptance checklist.
- Red-team review of high-risk systems and the release candidate.

More agents are not automatically better here because fixes increasingly touch shared behavior.

## Dependency guidance for the Task Splitter

The later task graph must be acyclic and topologically ordered.

Key dependency rules:

- Project skeleton and test harness precede implementation consumers.
- Shared contracts precede every lane that consumes them.
- Normalized contact/gameplay events precede building, scoring, HUD, and run-record consumers.
- Grey-box loop acceptance precedes broad progression, content, and presentation polish.
- Score/progression/run-record semantics precede serious backend validation implementation.
- Presentation screens depend on stable read-only presentation models, not internal nodes.
- Release automation may start early, but final release checks depend on integrated gameplay, backend, and settings behavior.
- Red-team review can target any high-risk task after implementation proof exists; it is not a dependency for every trivial task.

Tasks should contain explicit `depends_on`, file boundaries, acceptance criteria, verification, proof, and non-goals. Do not create work solely to keep all lanes occupied.

## Critical path

The likely critical path is:

`foundation/contracts → playable truck/contact loop → complete local run/scoring/save → progression and level content → stable compact run records → backend validation/integration → release acceptance`

UI, world-object expansion, backend contract design, and build automation may proceed in parallel where their prerequisites are genuinely satisfied.

## Planning risks

- Arcade physics feel may require iteration that cannot be fully automated.
- Godot physics output is not assumed deterministic enough for server replay; deterministic domain logic and plausibility validation must remain separate.
- Shared contract churn can block several lanes; keep Wave 0 small and reviewable.
- Backend complexity must not pull account/cloud/live-service scope into the MVP.
- Content polish before grey-box acceptance is prohibited by the design principles.
- Two humans working concurrently require clear ownership and integration review rather than last-writer-wins decisions.

## Open questions

No product blocker remains. The Task Splitter may create prototype/tuning tasks for exact physics values, score weights, prices, thresholds, durations, and content quantities inside accepted caps, but must not silently make new product decisions.

## Next lifecycle action

Review and merge the planning PR. Then start a fresh Task Splitter context from merged repository files to create topologically ordered batches and the canonical backlog.
