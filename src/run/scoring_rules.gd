extends RefCounted
## Versioned first-playable balance. All score arithmetic remains in the run lane.

const Game = preload("res://src/core/contracts/game_contracts.gd")

const VERSION := "scoring_debug_v1"
const TIMED_DURATION_S := 60.0
const PIXELS_PER_METRE := Game.PIXELS_PER_METRE
const DISTANCE_POINTS_PER_METRE := 10.0
const LAUNCH_MAX_POINTS := 500.0
const BOUNCE_POINTS := 25.0
const CLEAN_BOUNCE_POINTS := 50.0
const COMBO_WINDOW_S := 3.0
const BOUNCE_WINDOW_S := 4.0
const BOUNCE_MIN_GAP_S := 0.18
const MULTIPLIER_STEP := 0.25
const MAX_MULTIPLIER := 3.0
const MAX_COMBO := 1000
const MAX_EVENT_VALUE := 1000000.0
const MAX_EVENT_MONEY := 1000000
const MAX_EVENT_COMBO := 10.0
const MAX_SCORE := 1000000000000
const MAX_MONEY := 1000000000000


static func multiplier(chain_length: int) -> float:
	return minf(MAX_MULTIPLIER, 1.0 + maxf(0.0, float(chain_length - 1)) * MULTIPLIER_STEP)


static func points(value: float) -> int:
	# Every component rounds down. Bounds apply before conversion to integer.
	if not is_finite(value) or value <= 0.0:
		return 0
	return int(floor(minf(value, float(MAX_SCORE))))


static func distance_points(distance_px: float) -> int:
	return points(distance_px / PIXELS_PER_METRE * DISTANCE_POINTS_PER_METRE)
