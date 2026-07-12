# Agent 7 — Integration and Verification Agent

Task count: 15

## Role boundary

Agent 7 owns cross-lane verification, integration harnesses, performance scenes, build verification, evidence review, wave-level acceptance, and release acceptance. It may wire approved components and make only tiny, explicitly assigned integration-only fixes. It must not become a catch-all owner for incomplete feature work.

## Milestone classification

`7.15` is the project-wide final boss task. It proves the full release candidate across every lane, including offline play, progression, saves, online submission, outages, accessibility, performance, packaging, and public-build safety.

## 7.1 Verify repository foundation, contracts, and lane-module smoke integration

**Purpose**

Confirm that the Godot project skeleton, shared contracts, CI, and the first lane module skeletons coexist without ownership violations or load failures.

**Depends on**

`[1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 6.1, 6.2, 2.1, 3.1, 4.1, 5.1]`

**Outputs**

- cross-lane project-load test;
- contract fixture validation report;
- module ownership review;
- CI evidence;
- integration issue list.

**Acceptance criteria**

- The project loads with all first-wave module skeletons present.
- Canonical contract fixtures validate in CI and locally.
- No lane imports another lane's internal nodes or mutable state.
- Root files do not require routine conflicting edits by multiple lanes.
- Debug/release boundaries are visible and testable.
- Failures are returned to the owning agent rather than absorbed by Agent 7.

## 7.2 Verify player-command path from keyboard/gamepad into gameplay

**Purpose**

Prove that Agent 5 input mappings emit Agent 1 commands which Agent 2 consumes correctly for launch, rotation, and nudge.

**Depends on**

`[1.3, 2.3, 2.7, 2.8, 5.2, 5.3]`

**Outputs**

- keyboard command-path tests;
- gamepad command-path tests;
- press/release and axis evidence;
- conflict/device-switch evidence;
- latency/order observations.

**Acceptance criteria**

- Keyboard and gamepad reach the same accepted gameplay commands.
- Launch press/release, aerial rotation, and nudge operate through the real path.
- Raw device events do not leak into gameplay.
- Device switching and reconnect do not create duplicate or stuck commands.
- UI animation or frame rate does not change accepted command semantics.

## 7.3 Verify gameplay/world contact, destruction, wreck, and momentum integration

**Purpose**

Prove the central physical boundary:

`truck contact → normalized event → building destruction → wreck replacement → fixed momentum exchange → wreck/ground bounce`

**Depends on**

`[1.4, 1.5, 2.4, 2.5, 2.6, 3.3, 3.4, 3.5]`

**Outputs**

- real building-contact integration scene;
- destruction and duplicate-callback evidence;
- wreck classification/bounce evidence;
- momentum before/after evidence;
- reset/restart evidence.

**Acceptance criteria**

- A valid contact destroys one building exactly once.
- The intact collider is replaced by the correct wreck collider.
- Agent 2 classifies the wreck correctly and applies bounded bounce behavior.
- Agent 3 requests momentum changes only through the accepted interface.
- Speed loss or impulse occurs once and matches configured values.
- Visual debris cannot affect competitive physics.
- Reset restores the full chain cleanly.

## 7.4 Verify gameplay and run-domain event consumption

**Purpose**

Confirm that real Agent 2 and Agent 3 producers drive Agent 4 lifecycle, score, money, combo, and stop handling correctly.

**Depends on**

`[2.3, 2.5, 2.6, 2.10, 3.3, 3.7, 3.9, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7]`

**Outputs**

- producer-to-consumer event harness;
- ordered-event evidence;
- duplicate-event tests;
- mode-specific result checks;
- score/money breakdown comparison.

**Acceptance criteria**

- Real launch, destruction, balloon, bounce, pickup, and stop events reach Agent 4.
- Duplicate callbacks do not duplicate score, money, combo, or run completion.
- Survival and Timed Efficiency apply their distinct end rules correctly.
- Agent 4 never inspects physics or world nodes directly.
- Result breakdown matches the accepted ordered event stream.

## 7.5 Verify gameplay/run state into HUD, radar, and results presentation

**Purpose**

Prove the read-only presentation boundary from Agents 2 and 4 into Agent 5.

**Depends on**

`[1.7, 2.11, 4.2, 4.5, 4.7, 4.10, 4.11, 5.7, 5.8, 5.9, 5.10]`

**Outputs**

- HUD state integration tests;
- launch feedback evidence;
- radar tier tests;
- results-screen comparison;
- missing/offline-state evidence.

**Acceptance criteria**

- HUD values match authoritative Agent 2/4 state.
- UI cannot mutate score, resources, equipment, radar capability, or results.
- Launch feedback reflects actual gameplay timing state without calculating it.
- Lower radar tiers cannot reveal higher-tier data.
- Results display exactly the authoritative score, money, unlock, and eligibility state.
- Missing optional state fails safely.

## 7.6 Accept the complete grey-box vertical slice

**Purpose**

Prove the first project-wide playable loop with real lane implementations:

`menu/start → launch → destroy building → fixed speed loss → wreck/ground bounce → aerial rotation/nudge → hit balloon → score update → eventual stop → results → restart`

**Depends on**

`[2.12, 3.12, 4.2, 4.3, 4.5, 4.6, 5.2, 5.7, 5.8, 5.10, 7.2, 7.3, 7.4, 7.5]`

**Outputs**

- integrated grey-box scene/build;
- keyboard and gamepad walkthrough;
- gameplay recording;
- contract/event trace;
- known feel/usability defects;
- accept/reject decision.

**Acceptance criteria**

- The entire loop works with placeholder assets and no manual state editing.
- Keyboard and gamepad both complete the loop.
- Restart clears world, physics, run, and UI transient state.
- Score and money are generated only by Agent 4.
- The loop is understandable enough to justify progression/content expansion.
- Blocking feel or architecture defects prevent acceptance rather than being deferred invisibly.

## 7.7 Verify upgrades, equipment, progression transactions, and save recovery end to end

**Purpose**

Prove that a real completed run updates progression exactly once, purchases/equipment obey rules, and profile state survives atomic save/reload and corruption recovery.

**Depends on**

`[4.6, 4.9, 4.10, 4.11, 4.12, 4.13, 5.6, 5.11, 5.13, 7.6]`

**Outputs**

- completed-run-to-profile test;
- purchase/equip integration tests;
- save/reload evidence;
- interrupted-write test;
- current-save corruption and backup-recovery evidence;
- duplicate-processing checks.

**Acceptance criteria**

- Run rewards and progression apply exactly once.
- Invalid purchases or equipment activations cannot bypass Agent 4 rules through UI.
- Atomic save preserves the last valid profile under interrupted writes.
- One valid backup recovers a corrupt current save.
- Settings, upgrades, equipment, unlocks, achievements, and statistics reload correctly.
- No online service is required.

## 7.8 Verify both modes across the three fixed MVP levels

**Purpose**

Validate the completed fixed content with both Survival and Timed Efficiency, Stock and Progression categories, representative routes, resets, and content schedules.

**Depends on**

`[3.14, 4.3, 4.4, 4.8, 4.10, 4.11, 5.5, 5.6, 7.6, 7.7]`

**Outputs**

- level/mode/category test matrix;
- route and object coverage report;
- deterministic schedule reset evidence;
- Stock/Progression separation evidence;
- balance/tuning issue list.

**Acceptance criteria**

- All three levels load, reset, and validate correctly.
- Both modes operate on each level without bespoke duplicated runtime.
- Stock runs reject temporary boosts and remain distinct from Progression.
- Required buildings, balloons, rare targets, pickups, and schedules behave as defined.
- No runtime procedural generation occurs.
- Level-specific defects are assigned to the owning lane.

## 7.9 Verify deterministic offline game-state loop and player-facing journey together

**Purpose**

Combine Agent 4's offline boss task and Agent 5's player-facing boss task with real gameplay/world execution.

**Depends on**

`[4.16, 5.15, 7.7, 7.8]`

**Outputs**

- full offline playthrough evidence;
- both-mode restart/reload proof;
- keyboard/gamepad navigation proof;
- accessibility/settings evidence;
- deterministic result comparison;
- offline acceptance decision.

**Acceptance criteria**

- A player can complete the entire offline journey without developer tools.
- Both modes, Stock/Progression, progression purchases, saves, settings, and rapid restart work together.
- Repeating the same accepted event fixture yields identical domain results.
- UI remains read-only throughout.
- Offline play is feature-complete for the MVP apart from online-only leaderboard functions.

## 7.10 Verify compact run record through backend validation and leaderboard presentation

**Purpose**

Prove the end-to-end competitive path:

`completed run → local eligibility → compact record → queue → submission API → structural/plausibility validation → durable decision → leaderboard row → UI presentation`

**Depends on**

`[4.14, 4.15, 5.12, 6.6, 6.7, 6.8, 6.9, 7.9]`

**Outputs**

- accepted submission proof;
- ineligible run proof;
- tampered/duplicate/replay cases;
- queue state transitions;
- leaderboard query/UI comparison;
- reason-code verification.

**Acceptance criteria**

- An accepted record appears exactly once on the correct leaderboard.
- Ineligible local runs are not submitted as valid entries.
- Tampered, malformed, duplicate, replayed, unsupported, and impossible records receive correct outcomes.
- Retryable failures remain queued; permanent rejections do not retry forever.
- UI accurately distinguishes pending, accepted, rejected, and offline states.
- Backend never changes local score or progression.

## 7.11 Verify anonymous identity, progression reconciliation, and recovery transfer

**Purpose**

Prove the narrow online identity and transfer path with real client/profile state.

**Depends on**

`[1.12, 4.9, 4.13, 5.13, 6.10, 6.11, 6.12]`

**Outputs**

- identity issuance/rotation proof;
- reconciliation success/failure cases;
- duplicate/out-of-order ledger tests;
- recovery-code issue/redeem proof;
- one-active-restored-identity evidence;
- secret/log inspection report.

**Acceptance criteria**

- No email/password or full-account flow appears.
- Duplicate/out-of-order/impossible progression ledgers reject safely.
- Recovery codes are single-use/rotated as contracted and not exposed in logs.
- Successful recovery enforces one active restored identity.
- Identity/reconciliation failure does not block local play or progression.
- No cloud-save behavior is introduced.

## 7.12 Verify service outage, retry, degraded-mode, and privacy behavior

**Purpose**

Test the game and services under unavailable, slow, failing, and privacy-sensitive conditions.

**Depends on**

`[4.15, 5.10, 5.12, 5.13, 6.9, 6.10, 6.11, 6.12, 6.13, 6.14, 7.10, 7.11]`

**Outputs**

- backend-offline playthrough;
- timeout/retry tests;
- queue recovery evidence;
- crash-consent and forbidden-payload tests;
- UI degraded-state evidence;
- operational log privacy review.

**Acceptance criteria**

- Backend loss never blocks launch, gameplay, progression, save, results, or local navigation.
- Retryable operations recover without duplication when service returns.
- Permanent rejection is not misrepresented as temporary outage.
- Crash reports require consent and reject forbidden data.
- UI surfaces failures clearly without trapping the player.
- Logs do not expose tokens, recovery codes, saves, or sensitive payloads.

## 7.13 Verify performance, stability, controls, and accessibility budgets

**Purpose**

Run cross-lane performance and stability scenes on representative content and settings, including high-object/action moments, long runs, repeated restarts, UI scaling, controller behavior, reduced effects, and cosmetic-quality degradation.

**Depends on**

`[2.13, 3.14, 5.13, 5.14, 7.8, 7.9]`

**Outputs**

- performance benchmark scenes;
- frame-time and memory evidence;
- long-run/restart stability report;
- controller/accessibility checklist;
- quality-scaling evidence;
- blocking regression list.

**Acceptance criteria**

- No NaN/infinite physics state or unbounded event/memory growth appears in tested scenarios.
- Repeated restarts leave no stale world, run, UI, or input state.
- HUD remains readable and controls usable under representative load.
- Reduced shake/flash and UI scale work across the integrated game.
- Cosmetic effects can degrade before gameplay readability or physics quality.
- Performance failures are assigned to owning lanes; Agent 7 does not redesign them wholesale.

## 7.14 Verify Windows public build on a clean supported environment

**Purpose**

Validate the final package outside the development checkout, including installation/extraction, startup, offline play, online connection, input, saves, licenses, version metadata, and development-content exclusion.

**Depends on**

`[6.15, 7.10, 7.12, 7.13]`

**Outputs**

- clean-machine test report;
- package manifest/checksum verification;
- offline and online smoke evidence;
- debug/cheat/private-config exclusion report;
- asset-license/attribution verification;
- installer/extraction notes.

**Acceptance criteria**

- Public build starts on the supported clean Windows environment.
- Keyboard/gamepad, saves, offline play, and online leaderboard smoke paths work.
- Debug scenes, cheats, test credentials, development URLs, and private diagnostics are absent.
- Version/ruleset/build metadata are correct.
- Required notices and attributions are present.
- No dependency on a developer checkout or local backend exists.

# 7.15 — Final boss task: Accept the complete MVP release candidate

## Purpose

Prove Destructro Truck as one coherent release candidate across every lane:

`clean launch → offline profile → menu/loadout → both modes across fixed levels → gameplay/world interactions → scoring/progression/save → results/restart → queued and accepted leaderboard submission → identity/recovery/privacy paths → outage recovery → accessibility/performance → clean Windows package`

This task is an acceptance gate, not a bug-fixing epic. Blocking defects must be returned to the owning agent through explicit follow-up tasks and re-verified before acceptance.

**Depends on**

`[3.14, 4.16, 5.15, 6.16, 7.6, 7.7, 7.8, 7.9, 7.10, 7.11, 7.12, 7.13, 7.14]` plus completion/re-verification of selected critical Agent 8 findings.

**Outputs**

- release-candidate acceptance matrix;
- full recorded gameplay proof;
- both-mode/three-level evidence;
- offline and online end-to-end evidence;
- save/recovery and outage proof;
- accessibility/controller/performance report;
- clean-build/public-exclusion evidence;
- unresolved-risk and known-issues list;
- final accept/reject decision.

**Acceptance criteria**

- Every accepted MVP requirement has traceable evidence.
- The complete game is playable and progressable offline.
- Both modes and all three fixed levels work through the real UI and input paths.
- Scoring, money, progression, achievements, saves, recovery, eligibility, and queue behavior are authoritative and non-duplicated.
- Online submission, validation, leaderboard query, identity, reconciliation, recovery, and crash consent work as scoped.
- Service outage cannot break ordinary play.
- Keyboard and gamepad are usable end to end; accessibility settings function.
- Performance and long-run stability meet the agreed release budget.
- The public Windows package is reproducible, clean, correctly licensed, and free of debug/cheat/private configuration.
- All critical Red Team findings are fixed and re-verified.
- No post-MVP scope has been silently introduced.

## Explicit non-goals

- Agent 7 does not take ownership of feature implementation merely because integration fails.
- Agent 7 does not approve partial evidence as complete.
- Agent 7 does not rewrite architecture, change requirements, or invent product scope.
- Tiny integration-only fixes require explicit file assignment and must not grow into lane ownership.
