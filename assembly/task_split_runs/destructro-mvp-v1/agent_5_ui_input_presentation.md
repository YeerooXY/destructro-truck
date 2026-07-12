# Agent 5 — UI, Input, and Presentation Builder

Task count: 15

## Milestone classification

`5.15` is Agent 5's boss task: prove the complete player-facing journey from startup through menu selection, gameplay control and HUD, results, progression screens, settings, accessibility, and restart, while all gameplay state remains read-only.

## 5.1 Create UI module skeleton, screen router, and UI test harness

**Purpose**

Create the common UI framework: `src/ui/**`, screen routing, modal/back-navigation rules, focus ownership, reusable controls, fixture-driven UI test scenes, loading/error/empty-state conventions, and localization hooks.

**Depends on**

`[1.1, 1.2, 1.7]` plus the later project-skeleton task.

**Outputs**

- UI directory structure;
- screen router;
- focus and navigation helpers;
- fixture-based screen harness;
- UI smoke tests.

**Acceptance criteria**

- Screens render from fixtures without physics, world, run, or backend internals.
- UI state never becomes gameplay truth.
- Back navigation is consistent.
- Missing/loading data has a defined state.
- Controller focus works from startup.
- Localization keys are supported for all user-facing text.

## 5.2 Implement unified keyboard/gamepad action abstraction

**Purpose**

Map keyboard and gamepad input into Agent 1's device-neutral commands for launch, rotation, nudge, equipment, pause, restart, confirm, back, and menu navigation.

**Depends on**

`[1.3, 5.1]`

**Outputs**

- keyboard mapping;
- gamepad mapping;
- device-neutral command emitter;
- simultaneous-input handling;
- command fixtures and tests.

**Acceptance criteria**

- Keyboard and gamepad provide functional parity.
- Raw key/button codes do not leak into gameplay.
- Press/release and axis semantics are preserved.
- Conflicting input resolves predictably.
- Later mobile controls can target the same command layer.

## 5.3 Implement input rebinding, device switching, and controller focus behavior

**Purpose**

Provide essential action remapping, conflict detection, defaults reset, active-device prompt switching, controller disconnect/reconnect recovery, menu focus restoration, and deadzone/sensitivity settings where required.

**Depends on**

`[5.2]`

**Outputs**

- rebinding model and screen;
- control-conflict handling;
- active-device switching;
- focus recovery;
- settings persistence commands.

**Acceptance criteria**

- Keyboard-only and gamepad-only navigation both work.
- Players cannot accidentally create an unrecoverable binding set.
- Disconnecting a controller does not trap the player.
- Reconnecting restores usable focus.
- Remapping never changes gameplay mechanics.

## 5.4 Implement main menu and navigation shell

**Purpose**

Provide quick access to Play, Upgrades, Customization, Statistics, Leaderboards, Settings, Help, and Exit without cinematic or garage scope.

**Depends on**

`[1.7, 5.1, 5.3]`

**Outputs**

- main menu scene;
- navigation routes;
- profile/network summary presentation;
- loading/offline states;
- keyboard/gamepad focus behavior.

**Acceptance criteria**

- Every main destination is reachable by keyboard and gamepad.
- Navigation is quick and predictable.
- Offline state never disables local gameplay.
- Profile/network summaries are read-only.
- No animated garage, story, or cutscene scope is introduced.

## 5.5 Implement mode, level, and category selection screen

**Purpose**

Present Survival, Timed Efficiency, three fixed levels, Stock/Progression categories, locked/unlocked state, and local/online best-score placeholders.

**Depends on**

`[1.2, 1.7, 3.11, 4.3, 4.4, 4.12, 5.4]`

**Outputs**

- mode/level selection scene;
- category explanation;
- locked-level presentation;
- local/online best placeholders;
- selection commands.

**Acceptance criteria**

- UI cannot unlock levels or alter eligibility.
- Locked levels cannot be selected through focus or hidden input.
- Stock boost restrictions are explained clearly.
- Service failure does not block local selection.
- Mode/level IDs come from contracts, not scene names.

## 5.6 Implement pre-run loadout and temporary-boost selection

**Purpose**

Present selected mode/level/category, equipped rear module, upgrade and radar summary, available temporary boosts, Stock restrictions, and final run confirmation.

**Depends on**

`[1.7, 4.8, 4.9, 4.10, 4.11, 5.5]`

**Outputs**

- loadout screen;
- boost selection UI;
- equipment summary;
- run-start command;
- Instant Restart compatibility hooks.

**Acceptance criteria**

- Only Agent 4-approved choices are shown.
- UI cannot grant ownership, charge, or resources.
- Stock mode cannot select temporary boosts.
- Invalid selections are explained.
- Commands contain IDs/selections only, not mutated domain state.

## 5.7 Implement gameplay HUD foundation

**Purpose**

Render mode/timer state, score, combo, nudge energy, equipment charge, run status, warning space, radar anchor, and hint anchor from read-only models.

**Depends on**

`[1.7, 2.11, 4.2, 4.5, 4.7, 4.10, 5.1]`

**Outputs**

- gameplay HUD scene;
- read-only adapters;
- viewport scaling behavior;
- high-speed readability fixtures;
- missing-state handling.

**Acceptance criteria**

- Score/resources are never recalculated in UI.
- HUD stays readable during fast motion.
- Important information is not color-only.
- Layout works at target Windows resolutions and mobile-aware scales.
- Missing optional data does not crash the HUD.
- HUD rendering cannot alter gameplay.

## 5.8 Implement launch timing feedback and gameplay prompts

**Purpose**

Present launch charge/timing state, release-window feedback, launch-ready state, keyboard/gamepad prompts, invalid/late/early feedback, and one-time hints without calculating launch strength or score.

**Depends on**

`[1.3, 1.7, 2.3, 5.2, 5.7]`

**Outputs**

- launch feedback widget;
- prompt switching;
- timing-state adapter;
- hint hooks;
- UI tests.

**Acceptance criteria**

- Displayed timing matches accepted gameplay state.
- UI does not calculate launch strength or launch score.
- Visual animation cannot alter input timing.
- Keyboard/gamepad prompts switch correctly.
- Feedback is understandable without color alone.

## 5.9 Implement radar presentation and route-warning UI

**Purpose**

Render Agent 4's filtered radar tiers: crude warnings, approximate direction/distance, and advanced route-planning information.

**Depends on**

`[1.7, 4.11, 5.7]`

**Outputs**

- radar HUD widget;
- tier-specific layouts;
- warning and direction indicators;
- accessible non-color cues;
- radar fixtures.

**Acceptance criteria**

- Lower tiers cannot reveal higher-tier information.
- UI never queries world objects directly.
- Radar remains readable at speed.
- Important warnings are not audio-only or color-only.
- Detection/route logic is not duplicated.

## 5.10 Implement run results and Instant Restart flow

**Purpose**

Present authoritative total score, score breakdown, money, destruction/distance/combo summaries, achievements, unlocks, eligibility, queue state, rejection reason, normal restart, and Instant Restart.

**Depends on**

`[1.6, 1.7, 4.5, 4.6, 4.12, 4.14, 5.7]`

**Outputs**

- results screen;
- score-breakdown presentation;
- unlock/achievement notifications;
- eligibility/queue state;
- restart commands.

**Acceptance criteria**

- Results match Agent 4 exactly.
- UI never recalculates score or money.
- Ineligible/pending/offline states are clear and non-blocking.
- Instant Restart follows accepted lifecycle rules.
- Rapid restart leaves no stale overlay, focus, or input state.

## 5.11 Implement upgrades, equipment, and customization screens

**Purpose**

Provide permanent upgrade cards, prices, prerequisites, ownership, purchase commands, one rear-equipment slot, equipment selection, and a compact cosmetic catalogue.

**Depends on**

`[1.7, 1.8, 4.9, 4.10, 5.4]`

**Outputs**

- upgrade screen;
- equipment screen;
- customization screen;
- purchase/equip commands;
- insufficient-funds and validation feedback.

**Acceptance criteria**

- UI cannot bypass balance or prerequisite checks.
- Purchases occur only through accepted commands.
- One rear slot is presented clearly.
- Cosmetics remain strictly visual.
- No randomized paid rewards, sprawling skill tree, or large catalogue scope.

## 5.12 Implement statistics and leaderboard screens

**Purpose**

Render the compact local statistics page and online leaderboard filters, ranked rows, pending submissions, loading, offline, retryable error, and empty states.

**Depends on**

`[1.7, 1.11, 4.12, 4.15, 5.4]`

**Outputs**

- statistics screen;
- leaderboard filters;
- ranked-list presentation;
- pending submission indicators;
- loading/offline/error states.

**Acceptance criteria**

- Statistics remain a single-screen summary with no graphs, exports, or detailed history.
- Leaderboards show only approved fields.
- Service failure does not block navigation or local gameplay.
- UI never invents ranks or acceptance decisions.
- Filters use contract IDs, not display strings.

## 5.13 Implement settings, accessibility, contextual hints, and localization-ready text

**Purpose**

Implement essential audio/display/quality/control/accessibility settings, text/UI scaling, reduced shake/flash, alternative cues, Instant Restart preference, one-time contextual hints, and localization-key-backed English text.

**Depends on**

`[1.7, 1.8, 5.3, 5.4]`

**Outputs**

- settings screen;
- accessibility controls;
- contextual hint system;
- English localization resources;
- settings persistence commands.

**Acceptance criteria**

- Settings persist through accepted profile/settings state.
- Reduced shake and flash are respected by presentation adapters.
- Essential information is not color-only or audio-only.
- Text/UI scaling works on key screens.
- Hints appear once unless reset.
- No dedicated tutorial, advanced enthusiast graphics settings, or public diagnostics UI.

## 5.14 Implement audio/VFX adapters, cosmetic wheel visuals, and asset-license ledger

**Purpose**

React to accepted gameplay/world/run events with audio, VFX, screen feedback, and lightweight cosmetic wheel placement/rotation. Record every external asset's source, author, license, permitted use, and attribution.

**Depends on**

`[1.4, 1.7, 2.11, 3.3, 3.7, 5.7, 5.13]`

**Outputs**

- audio event adapter;
- VFX event adapter;
- cosmetic wheel animator;
- reduced-effects behavior;
- asset license ledger.

**Acceptance criteria**

- Audio/VFX cannot change physics or score.
- Cosmetic wheels cannot affect collision, traction, or competitive results.
- Reduced shake/flash settings are respected.
- Presentation adapters consume events/state only.
- Unlicensed or unclear assets cannot enter release content.

# 5.15 — Boss task: Prove the complete player-facing flow

## Purpose

Prove the game is navigable and understandable from startup through repeated play:

`start game → main menu → mode/level/category → loadout → launch → control truck → HUD/radar → results → upgrades/equipment/statistics/leaderboards/settings → Instant Restart or normal restart`

The proof must cover keyboard-only, gamepad-only, device switching, offline mode, service errors, locked levels, Stock restrictions, accessibility settings, contextual hints, localization keys, and rapid restart.

**Depends on**

`[5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8, 5.9, 5.10, 5.11, 5.12, 5.13, 5.14]` plus later Agent 7 grey-box and offline-loop integration gates.

**Outputs**

- complete UI-flow harness;
- keyboard walkthrough proof;
- gamepad walkthrough proof;
- screenshots or video evidence;
- accessibility checklist;
- offline/error-state evidence;
- rapid-restart evidence;
- known usability issues.

**Acceptance criteria**

- Every required screen is reachable without a mouse.
- Keyboard and gamepad are functionally equivalent.
- Gameplay commands use the real accepted command path.
- HUD/radar show correct read-only state.
- UI never owns score, progression, radar detection, world state, or eligibility.
- Offline mode remains fully navigable.
- Service errors remain isolated to online surfaces.
- Reduced shake/flash and UI scaling work.
- Contextual hints behave as one-time guidance.
- Localization keys render correctly.
- Rapid restart leaves no stale focus, overlays, or commands.
- Cosmetic wheels remain purely visual.

## Expected Agent 7 integration gates

1. Input-to-gameplay command path.
2. Gameplay/run state into HUD.
3. World data through Agent 4 radar filtering into UI.
4. Results, save/reload, and restart flow.
5. Full grey-box vertical slice with Agents 2, 3, 4, and 5.

## Explicit non-goals

- No ownership of gameplay, scoring, progression, radar detection, world behavior, save truth, eligibility, or backend decisions.
- No cinematic menus, animated garage, story, cutscenes, advanced graphics settings, large cosmetic catalogue, or dedicated tutorial.
- Cosmetic wheels must not affect physics.
