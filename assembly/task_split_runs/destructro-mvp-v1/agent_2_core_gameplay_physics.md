# Agent 2 — Core Gameplay and Physics Builder

Task count: 13

## MVP truck-body clarification

For the MVP, the truck uses one primary rectangular collision body. Wheels are cosmetic or mostly visual child elements and must not require suspension, axle, wheel-joint, tire-friction, or independent wheel-physics simulation. A more detailed wheel model is explicitly deferred to a possible post-MVP task.

## 2.1 Create gameplay module skeleton and physics debug scene
- Purpose: create the gameplay directory structure and an isolated physics laboratory scene.
- Depends on: `[1.1, 1.2]` plus the later project-skeleton task.
- Acceptance: the rectangular truck body loads without UI, run, world, or backend dependencies; cosmetic wheels may be attached visually only.

## 2.2 Implement configurable rectangular truck-body baseline
- Purpose: implement one stable rigid rectangular body with configurable mass, center of mass, friction, damping, collision dimensions, and safe simulation bounds.
- Depends on: `[1.2, 2.1]`
- Acceptance: the body rests and moves predictably, configuration changes require no runtime rewrite, and no independent wheel physics exists.

## 2.3 Implement timing-based launch mechanics
- Purpose: implement command-driven charging/release, bounded launch force, accuracy output, duplicate prevention, and reset behavior.
- Depends on: `[1.3, 1.4, 2.2]`
- Acceptance: launch occurs once, is bounded, emits normalized events, and calculates no score.

## 2.4 Implement gameplay momentum model and resource-change interface
- Purpose: distinguish raw velocity from normalized gameplay momentum and provide bounded speed-cost/impulse application.
- Depends on: `[1.2, 1.4, 2.2]`
- Acceptance: external lanes cannot mutate physics directly; invalid values reject; no score or money logic.

## 2.5 Implement normalized contact classification and event publication
- Purpose: convert engine collisions into stable ground, intact-building, wreck, aerial-target, pickup, and unknown contact events.
- Depends on: `[1.4, 1.5, 2.2, 2.4]`
- Acceptance: consumers receive contracts, not collision objects; duplicate callbacks are controlled; no world destruction or rewards are decided here.

## 2.6 Implement ground and wreck bounce response
- Purpose: implement bounded, tunable arcade bounce behavior for rectangular-body contacts with ground and wreck colliders.
- Depends on: `[2.4, 2.5]`, with later real-wreck integration dependency on Agent 3.
- Acceptance: distinct ground/wreck tuning, no infinite energy loops, tiny resting contacts do not retrigger, no bounce score.

## 2.7 Implement capped mid-air rotation
- Purpose: implement command-driven clockwise/counterclockwise aerial control with bounded angular acceleration and velocity.
- Depends on: `[1.3, 2.2, 2.5]`
- Acceptance: rotation remains stable and independent of cosmetic wheel visuals.

## 2.8 Implement directional nudge energy and impulse behavior
- Purpose: implement bounded directional impulses and local nudge-energy consumption.
- Depends on: `[1.3, 1.4, 2.2, 2.4]`
- Acceptance: energy stays in bounds; upgrades are read-only configuration snapshots; no UI/progression rules.

## 2.9 Implement gameplay camera behavior
- Purpose: provide readable follow, look-ahead, smoothing, bounce/aerial framing, shake hooks, and reset behavior.
- Depends on: `[2.2, 2.4]`
- Acceptance: camera changes no gameplay physics and respects reduced-shake input later.

## 2.10 Implement run viability and eventual-stop detection
- Purpose: identify temporary stalls versus true stop using speed, angular speed, grounded state, dwell time, and remaining recovery capability.
- Depends on: `[1.4, 2.4, 2.5, 2.6, 2.8]`
- Acceptance: one eventual-stop event, no false immediate stops, correct reset, no final RunResult creation.

## 2.11 Implement truck-state snapshots for presentation and run recording
- Purpose: publish bounded read-only snapshots of position, velocity, orientation, grounded state, momentum, resources, viability, and time.
- Depends on: `[1.4, 1.7, 2.4, 2.5, 2.8, 2.10]`
- Acceptance: no mutable physics references; bounded frequency; debug-only state separated.

## 2.12 Build and accept the complete Agent 2 grey-box physics loop
- Purpose: combine launch, travel, contacts, momentum loss, bounce, aerial rotation, nudge, camera, and eventual stop using contract-compatible mocks where needed.
- Depends on: `[2.3, 2.4, 2.5, 2.6, 2.7, 2.8, 2.9, 2.10, 2.11]`
- Acceptance: repeatable restartable loop, expected events/snapshots, placeholder rectangle and cosmetic wheels sufficient, known feel risks documented.

## 2.13 Add physics regression, stability, and performance coverage
- Purpose: cover extreme velocities, inverted landing, collision spam, long rotation, depleted nudge, repeated restart, malformed momentum requests, and long simulations.
- Depends on: `[2.12]`
- Acceptance: no NaN/infinite state, uncontrolled energy, stale restart state, or unbounded event spam.

## Explicit non-goal

Independent wheel physics, suspension, axle simulation, tire deformation, wheel-specific traction, and detailed wheel-ground interaction are outside the MVP. Cosmetic wheel rotation/placement may be implemented by the presentation layer or as a lightweight visual child of the truck scene, provided it cannot alter competitive physics.
