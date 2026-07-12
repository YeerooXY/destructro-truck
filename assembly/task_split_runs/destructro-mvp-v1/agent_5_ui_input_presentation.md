# Agent 5 — UI, Input, and Presentation Builder

Task count: 15

## Milestone classification

`5.15` is Agent 5's boss task: prove the complete player-facing journey from launch to menu selection, gameplay control and HUD, results, progression screens, settings, accessibility, and restart, while all gameplay state remains read-only.

## 5.1 Create UI module skeleton, screen router, and UI test harness
- Depends on: `[1.1, 1.2, 1.7]` plus the later project-skeleton task.
- Purpose: create `src/ui/**`, localization, UI assets, test scenes, screen routing, focus/navigation conventions, and fixture-driven UI harnesses.
- Acceptance: screens render from fixtures without physics, world, run, or backend internals; no gameplay source-of-truth state exists in UI.

## 5.2 Implement unified keyboard/gamepad action abstraction
- Depends on: `[1.3, 5.1]`
- Purpose: map keyboard and gamepad inputs into accepted device-neutral player commands, preserving later mobile compatibility.
- Acceptance: functional parity across devices; no raw input leaks into gameplay; simultaneous/invalid input is handled predictably.

## 5.3 Implement input rebinding, device switching, and controller focus behavior
- Depends on: `[5.2]`
- Purpose: provide essential remapping, automatic active-device prompts, deadzone/sensitivity settings where needed, menu focus, disconnect/reconnect recovery, and conflict handling.
- Acceptance: navigation remains possible with keyboard or gamepad; remaps persist through accepted settings state; no competitive rules change.

## 5.4 Implement main menu and navigation shell
- Depends on: `[1.7, 5.1, 5.3]`
- Purpose: implement fast access to Play, Upgrades, Customization, Statistics, Leaderboards, Settings, and Help.
- Acceptance: functional, quick, controller-accessible, no cinematic garage scope, and unavailable data is represented safely.

## 5.5 Implement mode, level, and category selection screen
- Depends on: `[1.2, 1.7, 3.11, 4.3, 4.4, 4.12, 5.4]`
- Purpose: present unlocked levels, both modes, Stock/Progression categories, and local/online best-state placeholders.
- Acceptance: locked content is read-only; Stock boost restrictions are explained; UI cannot unlock levels or alter eligibility.

## 5.6 Implement pre-run loadout and temporary-boost selection
- Depends on: `[1.7, 4.8, 4.9, 4.10, 4.11, 5.5]`
- Purpose: present equipped rear module, upgrade/radar summary, accepted boost options, and run snapshot confirmation.
- Acceptance: only accepted commands are emitted; Stock attempts cannot select boosts; UI does not grant ownership or resources.

## 5.7 Implement gameplay HUD foundation
- Depends on: `[1.7, 2.11, 4.2, 4.5, 4.7, 4.10, 5.1]`
- Purpose: render mode/timer state, score, combo, nudge energy, equipment charge, and run status from read-only models.
- Acceptance: readable at high speed and target viewport sizes; no duplicated scoring/resource logic; missing state fails safely.

## 5.8 Implement launch timing feedback and gameplay command presentation
- Depends on: `[1.3, 1.7, 2.3, 5.2, 5.7]`
- Purpose: provide launch timing feedback, command prompts, and controller/keyboard affordances without calculating launch strength or accuracy.
- Acceptance: displayed timing corresponds to accepted gameplay state; visual feedback cannot alter launch physics or scoring.

## 5.9 Implement radar presentation and route-warning UI
- Depends on: `[1.7, 4.11, 5.7]`
- Purpose: render progression-filtered radar warnings, approximate directions/distances, and advanced route-planning information by capability tier.
- Acceptance: lower tiers cannot infer hidden high-tier data; meaningful information is not color-only or audio-only.

## 5.10 Implement run results and Instant Restart flow
- Depends on: `[1.6, 1.7, 4.5, 4.6, 4.12, 4.14, 5.7]`
- Purpose: present score breakdown, money, unlocks, achievements, eligibility/queue state, and normal or minimal-delay restart commands.
- Acceptance: UI does not recalculate results; restart follows accepted lifecycle rules; ineligible/queued states are explained clearly.

## 5.11 Implement upgrades, equipment, and customization screens
- Depends on: `[1.7, 1.8, 4.9, 4.10, 5.4]`
- Purpose: present currency, upgrade cards/prerequisites, purchases, one rear slot, and compact cosmetic ownership/equipment.
- Acceptance: commands cannot bypass balance/prerequisites; cosmetics remain strictly non-competitive; no branching-tree or large catalogue scope.

## 5.12 Implement statistics and leaderboard screens
- Depends on: `[1.7, 1.11, 4.12, 4.15, 5.4]`
- Purpose: render the compact single-screen statistics page, local pending submissions, filters, ranked rows, loading/offline/error states.
- Acceptance: no graphs/histories/exports; only approved leaderboard fields; service outage never blocks other screens.

## 5.13 Implement settings, accessibility, contextual hints, and localization-ready text
- Depends on: `[1.7, 1.8, 5.3, 5.4]`
- Purpose: implement essential audio/display/quality/control/accessibility settings, text/UI scale, reduced shake/flash, one-time contextual hints, and English text through localization keys.
- Acceptance: settings persist through accepted state; information is not color-only/audio-only; no dedicated tutorial or advanced diagnostic UI.

## 5.14 Implement audio/VFX adapters, cosmetic wheel visuals, and asset-license ledger
- Depends on: `[1.4, 1.7, 2.11, 3.3, 3.7, 5.7, 5.13]`
- Purpose: react to accepted events/state with audio, VFX, screen feedback, and lightweight cosmetic wheel placement/rotation; record every external asset's source/license/attribution.
- Acceptance: presentation cannot change competitive physics/results; wheels remain cosmetic; reduced-flash/shake settings apply; unlicensed assets cannot enter release content.

## 5.15 Prove complete player-facing flow
- Depends on: `[5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8, 5.9, 5.10, 5.11, 5.12, 5.13, 5.14]` plus later Agent 7 grey-box and offline-loop integration gates.
- Purpose: prove menu → mode/level/category → loadout → launch/control → HUD/radar → results → progression/statistics/leaderboard/settings → restart using keyboard and gamepad.
- Acceptance: complete navigation without mouse, readable high-speed HUD, correct read-only state, offline/service-error behavior, accessibility settings, localization keys, no gameplay logic duplication, and rapid restart.

## Explicit non-goals
- No ownership of gameplay, scoring, progression, radar detection, world behavior, save truth, eligibility, or backend decisions.
- No cinematic menus, animated garage, story, cutscenes, advanced graphics settings, large cosmetic catalogue, or dedicated tutorial.
- Cosmetic wheels must not affect physics.
