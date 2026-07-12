# Destructro Truck — MVP Vision

## One-sentence vision

**Destructro Truck is a score-driven arcade game about converting momentum into destruction and destruction back into momentum through increasingly skillful routing.**

## Elevator pitch

Destructro Truck is a fast, readable 2D arcade destruction game in which players launch a truck across fixed handcrafted routes, smash through ground-level buildings, use aerial targets and special structures to recover momentum, earn money, improve their vehicle and information tools, and chase better leaderboard runs.

The controls are immediately approachable, but mastery comes from planning several interactions ahead: deciding what to destroy, when to climb into the balloon layer, when to spend nudge or equipment energy, and how to intercept rare high-value opportunities.

## Core gameplay loop

1. Launch the truck through a timing challenge.
2. Destroy buildings to earn score, money, combo progress, and ability resources.
3. Pay a fixed momentum cost for every building destroyed.
4. Use bounce surfaces, balloons, special buildings, rare aerial objects, nudges, and rear equipment to preserve or restore momentum.
5. End the run when momentum becomes insufficient to continue, or when the Timed Efficiency clock expires.
6. Review results, buy permanent upgrades, adjust equipment and cosmetics, and try a better route.

## Core resource philosophy

Momentum is the central run resource.

Every gameplay object should either:

- consume momentum or another limited resource,
- restore or redirect momentum,
- reward destruction and routing skill,
- improve the player's ability to plan future decisions,
- or combine those roles in a clear risk/reward exchange.

Buildings are both cost and reward: any truck contact destroys an intact building, removes a fixed amount of speed, and grants destruction-related rewards. Skilled players extend runs by selecting routes that convert those rewards back into useful momentum and control.

## Spatial structure

The level has one ground-level building layer. Buildings are not stacked into multiple vertical city layers.

Above the ground is an aerial opportunity layer containing balloon chains and other targets. Rare high-skill objects may appear higher or require sustained altitude control:

- Balloon targets preserve or increase forward/upward momentum.
- Satellite-like targets can give stronger forward speed while directing the truck downward, preventing indefinite upward momentum.
- A rare plane-like interception can provide exceptional speed but demands maintaining a suitable altitude and timing the contact.
- Special ground structures such as a gas station or propane facility may trade destruction for forward and upward impulse.

The intended rhythm is ground destruction, aerial recovery or amplification, and a planned return to the ground route.

## MVP content

- One truck.
- Three fixed-layout levels selected and tuned from development-time generated candidates.
- Two data-driven building types.
- Binary building states: intact or destroyed.
- One simple collidable wreck shape per destroyed building; smaller debris is visual only.
- Balloon-layer targets and a compact set of rare aerial opportunities.
- At least one special momentum-granting building variant using the shared building system.
- Launch timing, mid-air rotation, limited directional nudge energy, and rear equipment.
- Compact permanent upgrades and several temporary run boosts.
- A radar upgrade path that begins with crude short-range warnings and develops into a useful route-planning aid.
- Survival and Timed Efficiency modes using the same core physics and content.
- Offline progression, local achievements and statistics, and anonymous online leaderboards.
- Keyboard and gamepad support on Windows, with mobile-aware input abstraction for later Android work.

## Progression philosophy

Progression should increasingly expand the player's decision horizon.

The radar illustrates this progression:

1. A vague warning that something rare is approaching.
2. Basic object classification.
3. Improved detection range.
4. Distance or timing information.
5. Multiple-object and moving-target planning support.

Raw upgrades may improve launch, control, resource capacity, or equipment, but they should not replace the need for skillful routing.

## Modes and run length

### Survival

A normal successful run should usually last about 5–8 minutes. There is no hard time cap: exceptionally skilled players may continue as long as they can preserve momentum and remain viable.

### Timed Efficiency

A fixed-duration competitive mode rewards maximizing destruction and score within the time limit. It uses the same levels, physics, upgrades, objects, and controls, but has separate rules and leaderboards.

## Presentation

The visual direction is bright, clean, original cartoon/vector destruction with strong silhouettes, readable collisions, satisfying impacts, and scalable effects. Early gameplay validation uses debug shapes and placeholder UI. Final art must not begin before the core interactions are proven fun.

Audio is compact and responsive: menu and gameplay music, engine, impacts, destruction, pickups, and UI feedback. Complex cinematic or adaptive systems are outside the MVP.

## Target audience

The primary audience is score-chasing arcade players who enjoy repeated attempts, route optimization, upgrade strategy, mastery, and leaderboard competition. The first run should remain approachable to casual players without weakening the skill ceiling.

## Success criteria

The MVP succeeds when:

- the core launch, bounce, destruction, recovery, and retry loop is enjoyable with placeholder assets;
- players understand why their momentum changed and can improve through practice;
- routes support meaningful ground-versus-air decisions;
- progression creates new tactical options and foresight;
- a normal run fits the intended 5–8 minute rhythm while experts can extend Survival;
- players naturally want to attempt “one more run” to improve their score or route;
- the Windows build, saves, progression, modes, leaderboards, and agreed verification evidence meet the accepted requirements.

## Scope discipline

This MVP is a complete arcade game, not a live-service platform or content ecosystem. Replays, photo mode, automatic highlight capture, runtime procedural levels, daily challenges, seasons, gameplay analytics, mod support, multiple profiles, cloud saves, full accounts, social systems, dynamic weather, and cinematic presentation remain post-MVP unless the accepted requirements are explicitly changed.
