# Agent 6 — Online Services and Release Infrastructure Builder

Task count: 16

## Milestone classification

`6.16` is Agent 6's boss task: prove that the Windows game can be built and packaged reproducibly, communicate with deployed MVP services, survive outages and abuse attempts safely, and produce release evidence without making online services a dependency for ordinary gameplay.

Agent 6 starts lightly in Wave 0 with the project skeleton, CI, export scaffolding, backend skeleton, and shared fixtures. Substantial service implementation begins only after Agent 4's scoring, progression, eligibility, and compact run-record semantics stabilize.

## 6.1 Create Godot project skeleton, repository conventions, and development/release feature boundaries

**Purpose**

Create the root Godot project and shared repository structure required before Agents 1–5 can implement their modules. Define autoload/entry-point conventions, test roots, configuration loading, development-versus-release feature boundaries, and safe placeholder startup behavior.

**Likely files**

- `project.godot`
- `src/**` root directories only
- `tests/**` root directories only
- `tools/build/**`
- `docs/deployment/PROJECT_STRUCTURE.md`
- development/release configuration files

Agent 6 may create empty lane directories and root configuration, but must not implement lane-owned gameplay, world, run, or UI behavior.

**Depends on**

`[1.1, 1.2]`

**Outputs**

- loadable Godot project;
- root directory conventions;
- development/release feature flags;
- startup scene or safe bootstrap shell;
- test and configuration conventions;
- documented ownership boundaries.

**Acceptance criteria**

- The project opens in the selected Godot version without missing root configuration.
- Lane modules can be added without editing the same root files repeatedly.
- Debug and cheat capabilities have explicit development-only boundaries.
- Release configuration defaults safe when a setting is absent.
- Agent 6 does not implement lane-owned product logic.
- Tasks `2.1`, `3.1`, `4.1`, and `5.1` may depend on `6.1`.

## 6.2 Establish baseline CI, schema validation, and test orchestration

**Purpose**

Create the first automated checks for contract fixtures, Godot project loading, unit-test discovery, backend test discovery, formatting/static checks where supported, and artifact/evidence retention.

**Likely files**

- `.github/workflows/**`
- `tools/build/run_checks.*`
- `tools/validation/**`
- CI documentation

**Depends on**

`[1.1, 6.1]`

**Outputs**

- pull-request CI workflow;
- contract-fixture validation step;
- Godot smoke-test step;
- backend test placeholder step;
- clear pass/fail reporting;
- retained logs/artifacts for failed checks.

**Acceptance criteria**

- CI fails on invalid contract fixtures or a project that cannot load.
- Missing test suites fail clearly rather than silently passing once implementation is expected.
- CI commands are runnable locally through documented wrappers.
- Secrets are not required for ordinary pull-request checks.
- No deployment occurs from untrusted pull-request code.

## 6.3 Configure reproducible Windows export and local packaging skeleton

**Purpose**

Define Godot Windows export presets, build metadata injection, version naming, output layout, release/development separation, and a local packaging command early enough that export problems do not arrive at the end.

**Likely files**

- `export_presets.cfg`
- `tools/build/export_windows.*`
- `tools/release/package_windows.*`
- `docs/deployment/WINDOWS_BUILD.md`

**Depends on**

`[1.2, 6.1]`

**Outputs**

- Windows export preset;
- reproducible export command;
- build/version metadata;
- package layout convention;
- development and release package distinction.

**Acceptance criteria**

- A minimal Windows build can be exported from a clean checkout with documented prerequisites.
- Build output contains explicit product and version metadata.
- Development builds are visibly distinct from public release builds.
- Export does not require backend availability.
- Debug symbols/logs are handled deliberately rather than accidentally bundled.

## 6.4 Create backend service skeleton, persistence conventions, and local test environment

**Purpose**

Create the backend application structure, configuration model, database/migration convention, test environment, local service startup, and health/version endpoints without implementing final business behavior yet.

**Likely files**

- `backend/**`
- `tests/backend/**`
- `docs/deployment/BACKEND_LOCAL.md`
- backend container or environment files

**Depends on**

`[1.1, 1.2, 1.11, 6.2]`

Task `1.11` may initially be consumed through preliminary fixtures and finalized before substantial endpoint behavior.

**Outputs**

- backend application skeleton;
- configuration and secret-loading model;
- persistence/migration foundation;
- isolated backend tests;
- health and service-version endpoints;
- local development startup instructions.

**Acceptance criteria**

- Service starts locally with no production secrets.
- Tests use isolated disposable persistence.
- Configuration fails safely when required production values are absent.
- Health/version endpoints expose no sensitive internals.
- Database migrations are versioned and reversible where practical.
- No local gameplay/scoring/progression logic is duplicated.

## 6.5 Build shared API fixture and compatibility test suite

**Purpose**

Turn Agent 1's run-record, leaderboard, identity, reconciliation, recovery, and crash DTO fixtures into executable backend compatibility tests.

**Likely files**

- `tests/backend/contracts/**`
- `tests/backend/fixtures/**`
- backend schema/adaptor code
- compatibility documentation

**Depends on**

`[1.9, 1.10, 1.11, 6.4]`

Later portions extend after `1.12` and `1.13` stabilize.

**Outputs**

- request/response round-trip tests;
- unknown-version fixtures;
- invalid/missing-field fixtures;
- compatibility matrix;
- canonical reason-code assertions.

**Acceptance criteria**

- Backend accepts every canonical valid fixture and rejects every canonical invalid fixture as specified.
- Unknown versions receive explicit machine-readable outcomes.
- Server adapters do not silently discard security-relevant fields.
- Client and server representations preserve IDs and numeric values exactly within contract rules.
- Contract drift fails CI visibly.

## 6.6 Implement leaderboard persistence and query service

**Purpose**

Persist accepted leaderboard entries and provide filtered, paginated queries by level, mode, ruleset/category, with stable ordering and compact approved rows.

**Likely files**

- `backend/leaderboards/**`
- `tests/backend/leaderboards/**`
- database migrations/indexes

**Depends on**

`[1.11, 6.4, 6.5]`

Final acceptance also depends on validated submissions from `6.8`; direct insertion is allowed only in backend tests/administrative fixtures.

**Outputs**

- leaderboard persistence model;
- query/filter service;
- stable rank ordering and tie rules;
- pagination;
- query tests and indexes.

**Acceptance criteria**

- Filters use contract IDs, not display text.
- Ordering and tie behavior are deterministic.
- Only approved public fields are returned.
- Unvalidated public submissions cannot create leaderboard rows.
- Queries remain bounded and paginated.
- Service outage has no effect on local gameplay.

## 6.7 Implement compact run-record structural and arithmetic validator

**Purpose**

Validate the record envelope before deeper plausibility checks: schema/version compatibility, required fields, bounded arrays, ordering, score-breakdown arithmetic, resource deltas, mode/category consistency, and progression/loadout snapshots.

**Likely files**

- `backend/validation/run_record_validator.*`
- `backend/validation/reason_codes.*`
- `tests/backend/validation/**`

**Depends on**

`[1.9, 1.11, 4.14, 6.5]`

**Outputs**

- structural validator;
- arithmetic cross-checks;
- bounded-input enforcement;
- machine-readable rejection reasons;
- valid/tampered test corpus.

**Acceptance criteria**

- Oversized or malformed records reject before expensive processing.
- Score arithmetic is cross-checked against the submitted breakdown and accepted tuning version.
- Stock/Progression, boost, equipment, and ruleset metadata are internally consistent.
- Complete save files or forbidden payloads reject.
- Validation never claims authoritative deterministic physics replay.
- Rejection reasons are stable enough for client presentation and tests.

## 6.8 Implement plausibility, duplicate, replay, and version validation pipeline

**Purpose**

Add pragmatic anti-cheat validation above structural checks: impossible movement/resource combinations, duplicate run IDs, replayed submissions, unsupported/stale versions, impossible progression/equipment states, and obvious timing violations.

This is plausibility validation, not full simulation replay.

**Likely files**

- `backend/validation/plausibility/**`
- `backend/validation/deduplication/**`
- `tests/backend/abuse/**`

**Depends on**

`[2.11, 3.11, 4.14, 6.7]`

Agent 2/3 dependencies represent stable movement bounds and level/schedule metadata exposed through accepted contracts/fixtures, not direct runtime code coupling.

**Outputs**

- plausibility rules;
- duplicate and replay protection;
- accepted version registry;
- abuse/tampering corpus;
- decision audit metadata.

**Acceptance criteria**

- Identical run submissions do not create duplicate leaderboard entries.
- Unsupported versions reject explicitly.
- Obvious impossible movement, resource, level, or loadout states reject.
- Validation thresholds are versioned and testable.
- False certainty is avoided: uncertain records may reject conservatively with a clear reason, but the service does not advertise replay-grade proof.
- Validation workload is bounded against abuse.

## 6.9 Implement leaderboard submission endpoint and idempotent decision handling

**Purpose**

Expose the authenticated/anonymous submission endpoint that accepts compact records, applies the full validation pipeline, persists accepted entries, and returns durable idempotent decisions.

**Likely files**

- `backend/api/submissions/**`
- `backend/leaderboards/submission_service.*`
- `tests/backend/api/test_submissions.*`

**Depends on**

`[1.10, 1.11, 4.15, 6.6, 6.7, 6.8]`

**Outputs**

- submission endpoint;
- idempotency handling;
- accepted/rejected/retryable responses;
- persisted decision record;
- API tests.

**Acceptance criteria**

- Retrying the same submission returns a consistent outcome.
- Accepted submissions create at most one leaderboard entry.
- Permanent validation rejection differs from temporary service failure.
- Backend never modifies the client's local score, money, or progression.
- Endpoint request size and processing time are bounded.
- Failure responses contain no sensitive server details.

## 6.10 Implement anonymous identity issuance and rotation

**Purpose**

Implement the narrow anonymous identity mechanism approved for the MVP: issue device-bound identity material, rotate credentials safely, expose a public identity reference, and avoid full account scope.

**Likely files**

- `backend/identity/**`
- `tests/backend/identity/**`
- secret/token handling configuration

**Depends on**

`[1.12, 6.4, 6.5]`

**Outputs**

- anonymous identity issuance;
- credential/token rotation;
- public/private identity separation;
- revocation/expiry behavior;
- security tests.

**Acceptance criteria**

- No email/password or social-login system is introduced.
- Secret identity material is never returned in leaderboard rows or logs.
- Rotation invalidates or supersedes old credentials according to the contract.
- Token comparison/storage uses appropriate secure handling.
- Identity service failure does not block offline gameplay or local progression.

## 6.11 Implement progression-ledger reconciliation service

**Purpose**

Validate and reconcile ordered local progression transactions for transfer/recovery support, rejecting duplicates, impossible balances, invalid prerequisites, conflicting sequences, and unsupported versions.

The service reconciles a signed/identified ledger; it does not become the ordinary source of truth required for offline play.

**Likely files**

- `backend/progression/**`
- `tests/backend/progression/**`
- persistence migrations/indexes

**Depends on**

`[1.8, 1.12, 4.9, 4.13, 6.10]`

**Outputs**

- ledger ingestion and reconciliation;
- sequence/idempotency checks;
- impossible-state rejection;
- reconciliation decision DTOs;
- abuse fixtures.

**Acceptance criteria**

- Duplicate or out-of-order transactions do not double-credit progression.
- Impossible balances, purchases, prerequisites, or ownership states reject.
- Reconciliation decisions are machine-readable.
- Local gameplay remains available without reconciliation.
- The service does not silently rewrite accepted local run rewards.
- No general cloud-save synchronization is introduced.

## 6.12 Implement recovery-code transfer and one-active-restored-identity behavior

**Purpose**

Implement generation, secure storage/verification, redemption, rotation, expiry/use rules, and one-active-restored-identity behavior for recovery transfer.

**Likely files**

- `backend/recovery/**`
- `tests/backend/recovery/**`
- persistence migrations

**Depends on**

`[1.12, 6.10, 6.11]`

**Outputs**

- recovery-code issue and redemption;
- one-time/rotation behavior;
- active-identity transfer state;
- replay and brute-force protections;
- recovery tests.

**Acceptance criteria**

- Recovery codes are not stored or logged in recoverable plaintext.
- Used, expired, invalid, or replayed codes reject safely.
- Successful recovery enforces the contracted one-active-restored-identity rule.
- Rate limiting and bounded attempts reduce brute-force abuse.
- Recovery remains narrower than a general account/cloud-save system.

## 6.13 Implement opt-in crash-report intake and privacy enforcement

**Purpose**

Implement the crash-report endpoint, payload validation, consent requirement, storage/retention boundary, redaction, and explicit rejection of forbidden data.

**Likely files**

- `backend/crash_reports/**`
- `tests/backend/crash_reports/**`
- `docs/deployment/CRASH_REPORT_PRIVACY.md`

**Depends on**

`[1.13, 5.13, 6.4, 6.5]`

**Outputs**

- crash intake endpoint;
- consent validation;
- forbidden-field denylist;
- redaction/logging rules;
- storage/retention configuration;
- privacy tests.

**Acceptance criteria**

- Reports without explicit consent reject.
- Save files, screenshots, recordings, continuous telemetry, PII, and identity/recovery secrets reject or are removed according to the contract, with rejection preferred for unexpected sensitive structure.
- Disabling reporting has no gameplay effect.
- Service logs do not leak submitted private payloads.
- Intake has request-size and rate limits.
- No analytics pipeline is created through the back door.

## 6.14 Add service security, abuse controls, observability, backup, and deployment automation

**Purpose**

Harden and deploy the backend with bounded requests, rate limits, secure configuration, migrations, structured operational logs, health monitoring, database backups, restoration documentation, and reproducible environment deployment.

**Likely files**

- `backend/**` security/operations modules
- `tools/release/**`
- `.github/workflows/**` deployment workflows
- `docs/deployment/**`

**Depends on**

`[6.6, 6.9, 6.10, 6.11, 6.12, 6.13]`

**Outputs**

- service rate limits and request bounds;
- secure headers/configuration;
- deployment workflow;
- migration procedure;
- operational health/logging;
- backup and restore procedure;
- outage/runbook documentation.

**Acceptance criteria**

- Production secrets are not committed or exposed to pull-request workflows.
- Abuse controls cover submission, identity, recovery, reconciliation, query, and crash endpoints.
- Operational logs avoid private tokens, recovery codes, and full run/crash payloads.
- Database backup restoration is documented and tested on non-production data.
- Deployment is reproducible and rollback/migration failure behavior is documented.
- Service unavailability remains isolated from ordinary gameplay.

## 6.15 Finalize Windows release packaging, public-build exclusions, and release metadata

**Purpose**

Turn the early export skeleton into the final release package: production configuration, executable/data layout, versioning, notices/licenses, asset attributions, public-build exclusion of debug/cheat tools, clean-machine startup checks, and release manifest/checksums.

**Likely files**

- `export_presets.cfg`
- `tools/build/**`
- `tools/release/**`
- `.github/workflows/**`
- `docs/deployment/RELEASE_CHECKLIST.md`

**Depends on**

`[3.14, 4.16, 5.14, 5.15, 6.3, 6.14]` plus later Agent 7 performance/build acceptance gates.

**Outputs**

- final Windows export/package workflow;
- release manifest and checksums;
- version/about metadata;
- asset/license notices;
- debug/cheat exclusion checks;
- clean-machine installation/startup procedure.

**Acceptance criteria**

- Public package launches on the supported clean Windows environment.
- Debug scenes, cheats, test credentials, development service URLs, and private diagnostics are absent.
- Required asset licenses and attributions are included.
- The game starts and remains playable when services are unavailable.
- Package version matches ruleset/build metadata.
- Release generation is repeatable from an approved commit.

# 6.16 — Boss task: Prove online services and reproducible release infrastructure end to end

## Purpose

Prove the entire Agent 6 lane as one deployable and shippable system:

`approved commit → CI → Windows release export/package → launch game offline → obtain/use anonymous identity when online → submit queued compact run record → validate and persist accepted score → query leaderboard → handle duplicate/rejected/retryable submissions → reconcile progression ledger → exercise recovery transfer → send opt-in safe crash report → simulate service outage → restore ordinary offline play → verify deployment, backup, and public-build exclusions`

The proof must include normal behavior, malformed and adversarial inputs, outage/retry behavior, clean-machine packaging, and operational recovery.

**Depends on**

`[6.2, 6.3, 6.5, 6.6, 6.7, 6.8, 6.9, 6.10, 6.11, 6.12, 6.13, 6.14, 6.15]` plus Agent 7's compact-record/API, outage, performance, and release-candidate integration gates.

**Outputs**

- deployed test/staging service evidence;
- end-to-end submission/query proof;
- duplicate/replay/tamper evidence;
- identity/reconciliation/recovery proof;
- privacy-safe crash intake proof;
- outage and retry proof;
- clean Windows package evidence;
- deployment, backup/restore, and rollback evidence;
- public-build exclusion report;
- documented residual operational risks.

**Acceptance criteria**

- A compact record from Agent 4 passes through the actual API and appears once on the correct leaderboard when accepted.
- Duplicate, replayed, malformed, unsupported, and obviously impossible records receive correct durable outcomes.
- Retryable service failure remains distinct from permanent rejection and works with the local queue.
- Anonymous identity works without expanding into a full account system.
- Progression reconciliation and recovery enforce ordering, idempotency, and one-active-restored-identity behavior.
- Crash intake enforces consent and privacy exclusions.
- Service outage never prevents launching, playing, progressing, saving, or viewing local results.
- The backend can be deployed, migrated, observed, backed up, and restored using documented procedures.
- The Windows public package is reproducible, starts on a clean supported environment, includes required notices, and excludes debug/cheat/private configuration.
- No backend component calculates local score, money, achievements, unlocks, or ordinary gameplay progression.

## Expected Agent 7 integration gates

1. CI/project skeleton and lane-module smoke integration.
2. Agent 4 compact run record through Agent 6 structural/plausibility validation.
3. Local queue through real submission decisions and leaderboard presentation.
4. Identity, progression reconciliation, and recovery end to end.
5. Service-outage and retry behavior across Agents 4–6.
6. Windows export, clean-machine startup, performance, and public-build exclusion checks.
7. Full release-candidate acceptance across every lane.

## Expected Agent 8 red-team focus

- leaderboard tampering, duplicates, replay, impossible records, and denial-of-service inputs;
- anonymous identity/token handling;
- progression-ledger fraud and reconciliation conflicts;
- recovery-code brute force, replay, and identity duplication;
- crash-report privacy and data leakage;
- secret handling, deployment configuration, logs, backups, and public-package leakage.

## Explicit non-goals

- No full user account system, email/password authentication, social login, cloud saves, multiple profiles, matchmaking, multiplayer, replay service, analytics platform, live-ops, monetization, anti-cheat kernel/client, or deterministic server physics replay.
- Online services must never become a dependency for ordinary gameplay or local progression.
