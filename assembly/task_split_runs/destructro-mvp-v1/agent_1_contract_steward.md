# Agent 1 — Contract Steward

Task count: 13

Numbering rule: Agent 1 tasks use `1.x`. Dependencies are explicit and may later include tasks owned by other agents.

## 1.1 Establish core contract conventions and test fixtures
- Purpose: define version naming, IDs/enums, serialization, required/optional fields, time/vector/numeric conventions, validation results, fixture naming, and compatibility expectations.
- Depends on: `[]`
- Likely files: `src/core/contracts/**`, `src/core/domain/**`, `tests/unit/core/**`, `tests/fixtures/contracts/**`, `docs/contracts/CONVENTIONS.md`.
- Outputs: documented conventions, reusable value-object patterns, fixture structure, validation-result shape, valid/invalid examples.
- Acceptance: fixture round-trip and validation-failure tests pass; no gameplay-specific rules are introduced.

## 1.2 Define global identifiers, versions, and ruleset references
- Purpose: define ruleset, physics/scoring tuning, level, mode, category, and schema identifiers.
- Depends on: `[1.1]`
- Outputs: typed/versioned references and compatibility fixtures.
- Acceptance: runs identify all governing versions without scene/file paths; unknown values reject cleanly; no balance formulas are defined.

## 1.3 Define player command and input-action contracts
- Purpose: define device-neutral commands for launch, rotation, nudge, equipment, pause, restart, confirm, and back.
- Depends on: `[1.1, 1.2]`
- Outputs: command IDs, payloads, timing/sequence conventions, keyboard/gamepad-neutral fixtures.
- Acceptance: no raw key/button codes; invalid payloads reject; later mobile mapping remains possible.

## 1.4 Define normalized truck state, contact, and gameplay-event contracts
- Purpose: create the producer/consumer boundary between physics/world and run logic.
- Depends on: `[1.1, 1.2]`
- Outputs: versioned event envelope, contact classification, truck snapshots, ordering/duplicate rules, fixtures.
- Acceptance: run logic needs no node references or scene paths; event ordering is explicit; no score/money/achievement/UI decisions are embedded.

## 1.5 Define world-object, building, wreck, and level-data contracts
- Purpose: define data-driven building, wreck, aerial target, pickup, deterministic schedule, and fixed-level formats.
- Depends on: `[1.1, 1.2]`
- Outputs: world schemas and one debug-level fixture.
- Acceptance: variants are data-driven; shipped levels are fixed/versioned; no player-facing UI or final scoring logic is owned here.

## 1.6 Define run lifecycle, run result, and scoring-input contracts
- Purpose: define run states, mode configuration, end reasons, score-input categories, result shape, and eligibility reasons without implementing formulas.
- Depends on: `[1.2, 1.4, 1.5]`
- Outputs: lifecycle vocabulary, result/breakdown contracts, eligibility reason codes.
- Acceptance: Survival and Timed Efficiency fit one lifecycle; Stock/Progression are unambiguous; network is not required.

## 1.7 Define presentation-state and read-only view-model contracts
- Purpose: define immutable HUD, launch feedback, resources, radar, results, profile, upgrade, leaderboard, queue, and settings presentation models.
- Depends on: `[1.2, 1.3, 1.4, 1.6]`
- Outputs: read-only presentation contracts and Wave 1 HUD/result fixtures.
- Acceptance: UI renders without inspecting gameplay nodes and cannot mutate domain state; presentation does not dictate visual implementation.

## 1.8 Define profile, progression transaction, equipment, and save contracts
- Purpose: define the one local profile, money, upgrades, equipment, unlocks, achievements, statistics, settings, cosmetics, ordered transactions, atomic saves, backups, migrations, and corruption results.
- Depends on: `[1.1, 1.2, 1.6]`
- Outputs: profile/save schemas, transaction contract, upgrade/equipment shared definitions, migration rules.
- Acceptance: offline save/restore works conceptually; duplicates/order are checkable; temporary boosts cannot become permanent accidentally; no cloud/multi-profile scope.

## 1.9 Define compact run-record contract
- Purpose: define bounded evidence for leaderboard plausibility validation without deterministic replay.
- Depends on: `[1.2, 1.4, 1.6, 1.8]` plus later stable Agent 4 run semantics.
- Outputs: versioned run-record schema, limits, canonical ordering, valid/tampered fixtures.
- Acceptance: score/resource history is cross-checkable; no saves/screenshots/continuous telemetry/personal data are included.

## 1.10 Define offline submission-queue contracts
- Purpose: define durable pending/in-flight/accepted/rejected/retryable/expired/duplicate states.
- Depends on: `[1.8, 1.9]`
- Outputs: queue-entry schema, retry/status reasons, idempotency keys, expiry rules.
- Acceptance: queue survives restart, distinguishes retryable/permanent failure, and never blocks local gameplay.

## 1.11 Define leaderboard API and validation-result DTOs
- Purpose: define submission, validation, rejection, query, paging, and leaderboard-row DTOs.
- Depends on: `[1.2, 1.6, 1.9, 1.10]`
- Outputs: API DTOs, machine-readable reasons, paging/filter definitions, fixtures.
- Acceptance: per-level/mode/category queries work; unknown versions are explicit; no account/cloud scope.

## 1.12 Define anonymous identity, progression reconciliation, and recovery DTOs
- Purpose: define device-bound anonymous identity, ordered ledger reconciliation, duplicate/impossible rejection, recovery-code redemption, and one-active-identity outcomes.
- Depends on: `[1.8, 1.11]`
- Outputs: identity/reconciliation/recovery DTOs and privacy/secret-handling notes.
- Acceptance: no email/password account flow; duplicate/out-of-order ledgers reject; offline gameplay/progression remains available; no cloud saves.

## 1.13 Define crash-report payload and privacy contract
- Purpose: define opt-in crash payloads and explicit forbidden fields.
- Depends on: `[1.1, 1.2]`
- Outputs: payload/result DTOs, consent representation, denylist validation, privacy fixtures.
- Acceptance: saves, screenshots, recordings, continuous telemetry, PII, and secrets reject; disabling reporting has no gameplay effect.

## Wave guidance
- First-playable contract set: `1.1–1.7`.
- `1.8` may overlap Wave 1.
- `1.9–1.13` must not block the first playable.
- Integration/Verification is added only where real producers and consumers exist across lanes.
