extends SceneTree

const ArenaMatch = preload("res://scripts/arena_match.gd")
const RosterChecks = preload("res://tests/roster_checks.gd")
const ArenaModesChecks = preload("res://tests/arena_modes_checks.gd")
const TICK := 1.0 / 60.0

var checks := 0
var failures := 0


func _initialize() -> void:
	_test_match_setup_and_isolation()
	_test_combat_inputs()
	_test_break_free()
	_test_eliminations_and_match_win()
	_test_end_zone_and_timeout()
	RosterChecks.new().run(_check)
	ArenaModesChecks.new().run(_check)
	print("Arena rules: %d/%d checks passed" % [checks - failures, checks])
	quit(1 if failures > 0 else 0)


func _test_match_setup_and_isolation() -> void:
	var first = ArenaMatch.new()
	var second = ArenaMatch.new()
	first.start_match("breakwater")
	second.start_match("threadkeeper")
	_check(first.fighters.size() == 6 and second.fighters.size() == 6, "Each arena starts with six fighters")
	_check(first.fighters[0]["class_id"] == "breakwater" and second.fighters[0]["class_id"] == "threadkeeper", "Each arena honors its class pick")
	for index in range(first.fighters.size()):
		var fighter: Dictionary = first.fighters[index]
		var expected_team := 0 if index < 3 else 1
		_check(fighter["id"] == index and fighter["team"] == expected_team and fighter["alive"], "Fighter %d starts alive on the expected team" % index)
	_check(first.phase == "active" and first.round_number == 1, "A match opens in round one")
	_check(is_equal_approx(first.round_time, 60.0) and is_equal_approx(first.safe_radius, ArenaMatch.ARENA_RADIUS), "Round one starts with full time and a full safe area")
	var second_spawn: Vector2 = second.fighters[0]["position"]
	first.step(TICK, Vector2.RIGHT, Vector2.RIGHT)
	_check(first.try_ability(1), "The opening Brace cast is available")
	_check(second.fighters[0]["position"] == second_spawn and second.fighters[0]["cooldowns"][1] == 0.0, "Another instance keeps its own position and cooldowns")
	_check(is_equal_approx(second.round_time, 60.0), "Another instance keeps its own timer")


func _test_combat_inputs() -> void:
	var arena = ArenaMatch.new()
	arena.start_match("breakwater")
	var spawn: Vector2 = arena.fighters[0]["position"]
	arena.step(TICK, Vector2.RIGHT, Vector2.RIGHT)
	var moved: Vector2 = arena.fighters[0]["position"]
	_check(moved.x > spawn.x and arena.fighters[0]["facing"] == Vector2.RIGHT, "Movement and facing follow human input")
	_check(not arena.try_ability(-1) and not arena.try_ability(8), "Ability slots outside the kit are rejected")
	_check(not arena.try_ability(0, 1), "Hostile abilities reject an allied target")
	_check(arena.try_ability(1) and arena.fighters[0]["cooldowns"][1] > 0.0, "A successful ability starts its cooldown")
	_check(not arena.try_ability(1), "An ability in cooldown cannot cast again")
	var ability_cooldown: float = arena.fighters[0]["cooldowns"][1]
	arena.step(TICK, Vector2.ZERO, Vector2.ZERO)
	_check(arena.fighters[0]["cooldowns"][1] < ability_cooldown, "Combat ticks advance ability cooldowns")
	_check(arena.try_dodge(Vector2.RIGHT) and arena.fighters[0]["dodge_cooldown"] > 0.0, "Dodge starts its cooldown")
	_check(not arena.try_dodge(Vector2.RIGHT), "Dodge cannot repeat during its cooldown")


func _test_break_free() -> void:
	var arena = ArenaMatch.new()
	_check(not arena.try_break_free(), "Break Free cannot be used in the lobby")
	arena.start_match("breakwater")
	var fighter: Dictionary = arena.fighters[0]
	_check(fighter["break_free_available"] and not arena.try_break_free(), "Break Free starts charged and requires a control effect")
	_check(fighter["break_free_available"], "An invalid attempt does not spend Break Free")
	fighter["stun"] = 0.7
	_check(arena.try_break_free() and fighter["stun"] == 0.0, "Break Free removes a control effect immediately")
	_check(not fighter["break_free_available"], "Using Break Free spends this round's charge")
	fighter["stun"] = 0.7
	_check(not arena.try_break_free() and fighter["stun"] > 0.0, "Break Free cannot clear a second stun in the same round")
	for opponent in arena.fighters:
		if opponent["team"] == 1:
			opponent["health"] = 0.0
			opponent["alive"] = false
	arena.step(TICK, Vector2.ZERO, Vector2.ZERO)
	arena.next_round()
	fighter = arena.fighters[0]
	_check(fighter["break_free_available"], "Break Free recharges at the start of the next round")
	fighter["stun"] = 0.7
	fighter["health"] = 0.0
	fighter["alive"] = false
	_check(not arena.try_break_free(), "An eliminated fighter cannot use Break Free")


func _test_eliminations_and_match_win() -> void:
	var arena = ArenaMatch.new()
	arena.start_match("echo_duelist")
	arena.next_round()
	_check(arena.round_number == 1, "The active round cannot be skipped")
	var round_winners: Array[int] = [0, 1, 0, 1, 0]
	var expected_wins: Array[int] = [0, 0]
	for round_index in range(round_winners.size()):
		var winning_team := round_winners[round_index]
		expected_wins[winning_team] += 1
		for fighter in arena.fighters:
			if fighter["team"] != winning_team:
				fighter["health"] = 0.0
				fighter["alive"] = false
		arena.step(TICK, Vector2.ZERO, Vector2.ZERO)
		_check(arena.round_winner == winning_team and arena.wins == expected_wins, "An elimination awards one team win in round %d" % (round_index + 1))
		arena.step(TICK, Vector2.ZERO, Vector2.ZERO)
		_check(arena.wins == expected_wins, "Intermission ticks cannot award the same round twice")
		if round_index < round_winners.size() - 1:
			_check(arena.phase == "round_over" and not arena.try_dodge(Vector2.RIGHT), "The round pauses combat until the next round starts")
			arena.next_round()
			_check(arena.phase == "active" and arena.round_number == round_index + 2, "Advancing opens the next numbered round")
			_check(arena.fighters[3]["alive"] and arena.fighters[3]["health"] == arena.fighters[3]["max_health"], "The next round restores eliminated fighters")
	_check(arena.phase == "match_over" and arena.match_winner == 0, "The third round win ends the match")
	arena.next_round()
	_check(arena.phase == "match_over" and arena.round_number == 5, "A completed match cannot advance again")


func _test_end_zone_and_timeout() -> void:
	var arena = ArenaMatch.new()
	arena.start_match("breakwater")
	arena.round_time = 24.0
	arena.step(TICK, Vector2.ZERO, Vector2.ZERO)
	_check(arena.safe_radius < ArenaMatch.ARENA_RADIUS, "The safe area contracts late in the round")
	var radius: float = arena.safe_radius
	arena.round_time = 12.0
	arena.step(TICK, Vector2.ZERO, Vector2.ZERO)
	_check(arena.safe_radius < radius, "The safe area continues shrinking toward the deadline")
	# Keep the timeout fixture centered so the ring cannot change the health tiebreak.
	arena.start_match("breakwater")
	for fighter in arena.fighters:
		fighter["position"] = Vector2.ZERO
		fighter["cooldowns"].fill(10.0)
	arena.fighters[3]["health"] = 1.0
	arena.round_time = TICK
	arena.step(TICK, Vector2.ZERO, Vector2.ZERO)
	_check(arena.round_winner == 0, "Timeout favors the team with more health when survivor counts match")
	arena.start_match("breakwater")
	arena.round_time = 0.0000001
	arena.step(TICK, Vector2.ZERO, Vector2.ZERO)
	_check(arena.phase == "round_over", "A tiny remaining fraction still ends the round")


func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)
