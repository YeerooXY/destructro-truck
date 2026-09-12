extends RefCounted
## Fixtures only build accepted contract values; they do not calculate rewards.

const Game = preload("res://src/core/contracts/game_contracts.gd")


static func launch(run_id: String, sequence: int = 0, time_s: float = 0.0, accuracy: float = 1.0) -> Dictionary:
	return Game.gameplay_event(run_id, sequence, "launch", time_s, "", {"accuracy": accuracy, "speed_px_s": 1000.0, "angle_rad": -0.3})


static func object_event(run_id: String, sequence: int, time_s: float, source: String, kind: String = "building_destroyed", value: float = 100.0, money: int = 10, combo_value: float = 1.0) -> Dictionary:
	var payload := {"definition_id": "fixture_object", "destruction_value": value, "money_value": money, "combo_value": combo_value,
		"resource_request": Game.resource_request(source, 60.0, Vector2.ZERO, 0.0)}
	return Game.gameplay_event(run_id, sequence, kind, time_s, source, payload)


static func landing(run_id: String, sequence: int, time_s: float, source: String = "yard_ground", clean: bool = true) -> Dictionary:
	var contact := Game.contact(source, "ground", Vector2(400.0, 520.0), Vector2.UP)
	return Game.gameplay_event(run_id, sequence, "landed", time_s, source, {"contact": contact, "impact_speed_px_s": 300.0, "clean": clean})


static func stop(run_id: String, sequence: int, time_s: float) -> Dictionary:
	return Game.gameplay_event(run_id, sequence, "viability_lost", time_s)


static func truck(time_s: float, x: float, viable: bool = true) -> Dictionary:
	return Game.truck_snapshot(time_s, Vector2(x, 520.0), Vector2(600.0, 0.0), 0.0, 0.0, false, 80.0, 0.0, viable)
