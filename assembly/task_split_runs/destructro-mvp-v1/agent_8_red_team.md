# Agent 8 — Red Team Verifier

Task count: 12

## Role boundary

Agent 8 performs adversarial review of selected completed work, integration boundaries, backlog items, and release candidates. It records findings durably, assigns fixes back to owning lanes, and re-verifies fixes. It does not approve merges, rewrite implementation freely, invent requirements, or mark findings resolved without evidence.

## Milestone classification

`8.12` is Agent 8's boss task: conduct the final adversarial release-candidate review and provide the critical-finding closure evidence required by `7.15`.

## 8.1 Initialize red-team review workflow and durable ledger usage

**Purpose**

Define review IDs, severity levels, evidence requirements, review selection rules, follow-up references, and re-verification states using `assembly/generated/red_team_review_index.json` and `docs/red_team/reviews/**`.

**Depends on**

`[]`

**Outputs**

- review template;
- severity and outcome definitions;
- backlog-crawl procedure;
- re-verification procedure;
- example non-product review entry if needed for schema validation only.

**Acceptance criteria**

- Every review can identify the exact task, PR, commit, files, contracts, evidence, findings, owner, and re-verification state.
- Empty/no-finding reviews are still recorded durably.
- Findings cannot be marked resolved without a separate re-verification event.
- Agent 8 cannot silently fix or waive its own findings.

## 8.2 Review shared contracts and repository boundaries for ambiguity and scope leakage

**Purpose**

Adversarially review the shared contract spine, serialization/versioning, ownership boundaries, debug/release separation, and potential contract bypasses before broad implementation depends on them.

**Depends on**

`[1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 6.1, 7.1]`

**Focus**

- ambiguous optional/default fields;
- unbounded values or arrays;
- version confusion;
- mutable references crossing lanes;
- UI/backend becoming sources of truth;
- debug or cheat state leaking toward release;
- oversized shared-domain ownership.

**Acceptance criteria**

- Critical contract ambiguities and boundary violations are recorded before dependent high-risk work proceeds.
- Findings name the owning agent and exact follow-up scope.
- No product behavior is invented during review.

## 8.3 Review grey-box physics/world loop for exploits and misleading proof

**Purpose**

Attack the first integrated physical loop for duplicate contacts, momentum amplification, infinite bounce/nudge energy, stop-detection evasion, stale restart state, visual debris influence, and evidence that passes only under hand-picked conditions.

**Depends on**

`[2.12, 3.12, 7.3, 7.6]`

**Acceptance criteria**

- Repeated collision callbacks, corner contacts, inverted landings, rapid resets, and extreme accepted inputs are tested.
- Any route to unbounded energy, duplicate world effects, or never-ending invalid runs is documented.
- Grey-box acceptance evidence is checked for reproducibility rather than trusted at face value.

## 8.4 Review deterministic scoring, rewards, progression, and save integrity

**Purpose**

Attack Agent 4's deterministic domain for duplicate reward processing, score/money mismatch, combo inflation, transaction replay, purchase bypass, temporary/permanent state confusion, save rollback abuse, corruption handling, and eligibility inconsistencies.

**Depends on**

`[4.14, 4.16, 7.7, 7.9]`

**Acceptance criteria**

- Duplicate and reordered events/transactions are exercised.
- Save/backup manipulation and rollback scenarios are reviewed.
- Stock/Progression and boost/equipment rules are checked for bypasses.
- Findings distinguish local integrity issues from server-validation issues.

## 8.5 Review UI/input boundaries, accessibility claims, and deceptive state presentation

**Purpose**

Attack input, focus, results, radar, purchases, queue status, and accessibility behavior for stuck controls, hidden selection paths, stale state, misleading eligibility/online state, high-tier radar leakage, and settings that claim to work but do not affect all adapters.

**Depends on**

`[5.15, 7.2, 7.5, 7.9]`

**Acceptance criteria**

- Keyboard/gamepad switching, disconnects, rapid restart, and focus traps are exercised.
- UI cannot bypass domain validation through hidden or repeated commands.
- Radar and results do not reveal or invent authoritative state.
- Reduced shake/flash, scaling, and non-color/non-audio alternatives are verified in real integrated paths.

## 8.6 Review compact run-record validation, leaderboard tampering, duplicates, and replay

**Purpose**

Attack the competitive path using malformed, oversized, contradictory, replayed, duplicated, unsupported-version, impossible-movement, impossible-resource, impossible-loadout, and arithmetic-tampered submissions.

**Depends on**

`[4.14, 4.15, 6.7, 6.8, 6.9, 7.10]`

**Acceptance criteria**

- Accepted records cannot create more than one leaderboard row through retry/replay.
- Expensive validation paths are bounded against denial-of-service input.
- Structural, arithmetic, plausibility, duplicate, replay, and version outcomes are distinguishable.
- The service does not overclaim deterministic physics proof.

## 8.7 Review anonymous identity, reconciliation, and recovery abuse

**Purpose**

Attack token issuance/rotation, progression-ledger reconciliation, recovery codes, identity duplication, sequence conflicts, replay, brute force, and one-active-restored-identity enforcement.

**Depends on**

`[6.10, 6.11, 6.12, 7.11]`

**Acceptance criteria**

- Tokens/recovery codes are inspected for log, response, storage, and build leakage.
- Duplicate, reordered, impossible, and conflicting ledgers are exercised.
- Recovery replay and brute-force controls are tested.
- Failure never blocks ordinary offline play.
- No full-account or cloud-save behavior is introduced as a fix.

## 8.8 Review crash privacy, logging, secrets, deployment, and backups

**Purpose**

Attack crash-report intake, consent, forbidden payload handling, operational logs, CI/deployment secrets, production configuration, backups, restore procedures, and public-package leakage.

**Depends on**

`[6.13, 6.14, 7.12]`

**Acceptance criteria**

- Saves, screenshots, recordings, telemetry, PII, tokens, and recovery codes are tested as forbidden inputs.
- Logs and retained CI artifacts are inspected for sensitive content.
- Backups and restore artifacts have appropriate access and do not leak secrets.
- Consent-disabled behavior remains fully functional offline.

## 8.9 Review performance and denial-of-service boundaries across client and service

**Purpose**

Attack high-collision scenes, event floods, long Survival runs, repeated restart, oversized UI lists, queue growth, leaderboard query bounds, submission validation cost, and endpoint rate limits.

**Depends on**

`[2.13, 6.14, 7.13]`

**Acceptance criteria**

- Client event/memory growth remains bounded under adversarial but accepted scenarios.
- Server endpoints enforce request, pagination, execution, and rate limits.
- Queue and retained decision state have cleanup/bounds.
- Cosmetic degradation does not hide gameplay or security failures.

## 8.10 Review Windows public package for development and private-data leakage

**Purpose**

Inspect the actual public package for debug scenes, cheats, test credentials, development URLs, private diagnostics, source maps/configuration, secrets, unsafe writable defaults, and missing licenses/attributions.

**Depends on**

`[6.15, 7.14]`

**Acceptance criteria**

- Package contents and runtime behavior are inspected outside the developer checkout.
- No debug/cheat/private configuration is reachable or bundled.
- No token, recovery, backend secret, or test identity material is present.
- Required third-party notices and attribution are complete.

## 8.11 Run backlog-crawl review and re-verify critical fixes

**Purpose**

Use the canonical backlog and review ledger to select completed, eligible, unreviewed high-risk/high-dependency tasks in topological then chronological order. Re-verify all critical/high findings whose owners claim resolution.

**Depends on**

`[8.2, 8.3, 8.4, 8.5, 8.6, 8.7, 8.8, 8.9, 8.10]`

**Acceptance criteria**

- Every selected review is recorded in the durable ledger.
- Critical/high findings have explicit owning follow-up tasks.
- Claimed fixes are tested against the original exploit/failure evidence.
- Unresolved critical findings remain visibly blocking.
- Trivial tasks may be skipped unless risk or dependency centrality justifies review.

# 8.12 — Boss task: Final adversarial release-candidate review

## Purpose

Attack the complete release candidate after normal verification has passed:

`public package → offline play → progression/save manipulation → input/UI edge cases → compact-record tampering → identity/recovery abuse → crash/privacy attacks → outage/retry behavior → performance/DoS → package and operational leakage`

This review challenges both the product and the adequacy of Agent 7's evidence. It does not replace `7.15`; it supplies the adversarial closure required by it.

**Depends on**

`[7.14, 8.11]`

**Outputs**

- final adversarial review report;
- critical/high/medium/low finding summary;
- exploit/reproduction evidence;
- follow-up task references by owning agent;
- re-verification evidence for resolved critical findings;
- explicit release-blocking recommendation.

**Acceptance criteria**

- Every critical release surface has been reviewed or explicitly justified as out of scope.
- No critical finding is marked resolved without reproduction-based re-verification.
- Any unresolved critical finding blocks `7.15`.
- The report distinguishes product defects, evidence gaps, operational risks, and accepted residual risks.
- Agent 8 does not waive scope, change requirements, or approve the release itself.

## Explicit non-goals

- No free-form implementation ownership.
- No requirement changes or MVP expansion.
- No merge/release approval authority.
- No silent fixes, silent waivers, or findings resolved without re-verification.
