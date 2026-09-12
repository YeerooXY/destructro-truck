# First-playable run domain

`RunSession` consumes the shared gameplay and truck-snapshot contracts. It does not
load scenes, query nodes, simulate physics, or contact services. This is a bounded
prototype subset of tasks 4.1–4.7, with no progression or save implementation.

Call `prepare(run_id, ruleset)` to create a ready run. Supply a truck snapshot in
the ready state to establish its starting position. The first gameplay event must
be `launch`, sequence zero, at run time zero. Later events require a contiguous
sequence and a timestamp at or after the authoritative run clock. Integration
normalizes physics and world envelopes into that one sequence before submission.
It also timestamps truck snapshots with the authoritative run clock while
preserving their positions and resources. The physics publication clock can lead
by one fixed tick when a queued launch event is delivered; it does not own run time.

`advance(delta)` owns the active timer. `set_paused(bool)` freezes and restores
either the ready or running state. No preparation or pause time enters a result.
Survival has no time cap. Timed Efficiency lasts 60 seconds in this tuning version;
events at or after that cutoff cannot award points or money. An accepted
`viability_lost` event ends either mode once. Truck snapshot viability never ends a
run. Completed output is immutable until explicit preparation resets the session.

The versioned `scoring_debug_v1` formula is intentionally simple:

- Every world source awards its supplied destruction value, rounded down, and its
  separate integer money value once. Only building events increment destruction
  count. A different event type cannot award the same source again.
- Distance awards ten points per metre at 100 pixels per metre. It measures maximum
  forward displacement from the initial snapshot, so reversing cannot earn it
  twice. Score rounds down from total distance, not individual movement samples.
- Launch accuracy awards up to 500 points, rounded down.
- Buildings and aerial targets each have a separate three-second chain. Every
  successive qualifying contact adds 0.25 to that chain's multiplier, capped at
  3.0. The base value belongs to `destruction`; only the extra amount belongs to
  `building_chain` or `aerial_chain`. A positive content `combo_value` qualifies
  one contact; it never lets a single object count as multiple contacts.
- A clean bounce awards 50 points with its own four-second chain and the same
  multiplier cap. A rough bounce awards 25 and resets that bounce chain and the
  current combo. Any landing resets the aerial chain. Landing callbacks less than
  0.18 seconds apart share one physical landing and award once.
- The displayed combo counts qualifying world contacts and clean bounces within
  three seconds. Counts saturate at 1,000, independently of multiplier caps.
  A contact exactly at a chain deadline still qualifies.

Malformed input, stale input, invalid transitions, excessive rewards, and sequence
gaps reject before any mutation. A valid fresh envelope that repeats a consumed
world source is accepted as a no-op and consumes its sequence, allowing the next
event to proceed. Such duplicates never extend a combo. Valid events at the timed
cutoff can complete the clock but cannot contribute their payload.

All numbers are finite. Individual destruction and money inputs are bounded at
1,000,000. Total points and total money saturate at 1,000,000,000,000; point
saturation preserves the sum of the published breakdown. These numeric bounds
never end Survival. Snapshot distance is derived from bounded contract positions.
Results carry the contract's default `debug_build` ineligibility marker; there is
no eligibility engine, leaderboard submission, permanent reward credit, or save.

`tests/unit/run/test_run_session.gd` replays identical fixtures through both modes
and checks hand-calculated results, duplicate rewards, reset, pause, timer
boundaries, long Survival, numeric rejection and malformed-input atomicity.
