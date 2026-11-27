extends SceneTree

const ArenaMatch = preload("res://scripts/arena_match.gd")
const ArenaMaps = preload("res://scripts/arena_maps.gd")
const ArenaObjectives = preload("res://scripts/arena_objectives.gd")

var _checks := 0
var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_positions()
	_check_contest()
	_check_heal()
	_check_combat_buff("kiln", 1.18, 1.0)
	_check_combat_buff("quarry", 1.0, 0.76)
	_check_bots()
	_check_round_integration()
	print("Arena objectives: %d/%d checks passed" % [_checks - _failures, _checks])
	quit(1 if _failures else 0)


func _open_match(map_id: String) -> ArenaMatch:
	var game := ArenaMatch.new()
	game.mobile_mode = true
	game.start_match("breakwater", 17, -1, map_id)
	for fighter in game.fighters:
		fighter.position = Vector2(-8.0 if fighter.team == 0 else 8.0, 2.25 * float(fighter.id % 3 - 1))
	return game


func _check_positions() -> void:
	var names := {}
	for map_id: String in ArenaMaps.MAPS:
		var game := _open_match(map_id)
		var relic: Dictionary = game.objective
		var center: Vector2 = relic.position
		var radius: float = relic.radius
		_check(not names.has(relic.name) and not str(relic.effect).is_empty(), "%s has a unique named objective with an explained reward" % map_id)
		names[relic.name] = true
		_check(center.length() + radius <= 3.1, "%s objective fits inside the final safe ring" % map_id)
		for index in 32:
			var edge := center + Vector2.RIGHT.rotated(TAU * float(index) / 32.0) * radius
			_check(edge.is_equal_approx(ArenaMaps.constrain(map_id, edge, ArenaMaps.FIGHTER_PADDING)), "%s objective lies on walkable ground" % map_id)
		for obstacle in game.terrain:
			_check(center.distance_to(obstacle.position) >= radius + float(obstacle.radius), "%s objective clears hard cover" % map_id)
		for zone in game.environment_zones:
			_check(center.distance_to(zone.position) >= radius + float(zone.radius), "%s objective clears the active hazard" % map_id)


func _check_contest() -> void:
	var game := _open_match("lockwater")
	var relic: Dictionary = game.objective
	game.fighters[0].position = relic.position
	ArenaObjectives.tick(game, 8.5)
	_check(relic.phase == "arming" and is_zero_approx(relic.progress), "Standing on the dormant relic cannot start the hold")
	ArenaObjectives.tick(game, 2.5)
	_check(relic.phase == "open" and relic.team == 0 and is_equal_approx(relic.progress, 2.0), "Only time after activation counts toward capture")
	game.fighters[3].position = relic.position
	ArenaObjectives.tick(game, 5.0)
	_check(relic.phase == "contested" and relic.team == 0 and is_equal_approx(relic.progress, 2.0), "A rival inside the zone pauses either team's capture")
	game.fighters[3].alive = false
	ArenaObjectives.tick(game, 1)
	_check(relic.phase == "open" and is_equal_approx(relic.progress, 3.0), "A defeated rival cannot contest the point")
	game.fighters[0].position = Vector2(-8, 0)
	ArenaObjectives.tick(game, 1)
	_check(relic.phase == "open" and relic.team == -1 and is_zero_approx(relic.progress), "Leaving the relic empty clears accumulated progress")
	game.fighters[0].position = relic.position
	ArenaObjectives.tick(game, 2)
	game.fighters[0].position = Vector2(-8, 0)
	game.fighters[4].position = relic.position
	ArenaObjectives.tick(game, 1)
	_check(relic.team == 1 and is_equal_approx(relic.progress, 1.0), "An opposing team starts a fresh hold when it secures the circle")
	game.fighters[5].position = relic.position
	ArenaObjectives.tick(game, 1)
	_check(relic.team == 1 and is_equal_approx(relic.progress, 2.0), "Additional teammates do not accelerate capture")


func _check_heal() -> void:
	var game := _open_match("lockwater")
	var relic: Dictionary = game.objective
	var human: Dictionary = game.fighters[0]
	var distant_ally: Dictionary = game.fighters[1]
	var fallen: Dictionary = game.fighters[2]
	var rival: Dictionary = game.fighters[3]
	human.position = relic.position
	human.health = human.max_health * 0.50
	distant_ally.health = distant_ally.max_health * 0.99
	fallen.alive = false
	fallen.health = 0.0
	rival.health = rival.max_health * 0.50
	ArenaObjectives.tick(game, ArenaObjectives.ARM_SECONDS + ArenaObjectives.HOLD_SECONDS)
	_check(relic.phase == "cooldown" and relic.team == 0 and is_equal_approx(relic.time_left, ArenaObjectives.RESET_SECONDS), "A full hold pays out once and locks the relic for 24 seconds")
	_check(is_equal_approx(human.health, human.max_health * 0.64), "The holder gains fourteen percent of maximum health from Tidefont")
	_check(is_equal_approx(distant_ally.health, distant_ally.max_health), "A distant teammate also receives healing up to maximum health")
	_check(not fallen.alive and is_zero_approx(fallen.health), "Relic healing does not revive fallen champions")
	_check(is_equal_approx(rival.health, rival.max_health * 0.50), "Relic healing applies only to the winning team")
	_check(game.feed[0] == "Your team claimed Tidefont", "A capture announces the relic and the winning team")
	ArenaObjectives.tick(game, ArenaObjectives.RESET_SECONDS)
	_check(is_equal_approx(human.health, human.max_health * 0.64) and is_zero_approx(relic.progress) and relic.team == -1, "Standing through cooldown cannot stack healing or pre-capture the next relic")


func _check_combat_buff(map_id: String, outgoing: float, incoming: float) -> void:
	var game := _open_match(map_id)
	var relic: Dictionary = game.objective
	var human: Dictionary = game.fighters[0]
	var rival: Dictionary = game.fighters[3]
	human.position = relic.position
	ArenaObjectives.tick(game, ArenaObjectives.ARM_SECONDS + ArenaObjectives.HOLD_SECONDS)
	_check(relic.buff_team == 0 and relic.buff_left > 0.0, "%s capture grants a timed team buff" % map_id)
	_check(is_equal_approx(ArenaObjectives.damage_multiplier(game, human, rival), outgoing), "%s outgoing multiplier matches its reward" % map_id)
	_check(is_equal_approx(ArenaObjectives.damage_multiplier(game, rival, human), incoming), "%s incoming multiplier matches its reward" % map_id)
	var rival_before: float = rival.health
	var human_before: float = human.health
	game._deal_damage(human, rival, 20.0)
	game._deal_damage(rival, human, 20.0)
	_check(is_equal_approx(rival_before - float(rival.health), 20.0 * outgoing), "%s objective affects real attacks" % map_id)
	_check(is_equal_approx(human_before - float(human.health), 20.0 * incoming), "%s objective affects real defense" % map_id)
	ArenaObjectives.tick(game, relic.buff_left)
	_check(relic.buff_team == -1 and is_zero_approx(relic.buff_left) and relic.phase == "cooldown", "%s buff expires independently of its reset timer" % map_id)
	_check(ArenaObjectives.damage_multiplier(game, human, rival) == 1.0 and ArenaObjectives.damage_multiplier(game, rival, human) == 1.0, "%s damage returns to its normal rate" % map_id)


func _check_bots() -> void:
	var game := _open_match("orchard")
	for fighter in game.fighters.slice(1):
		_check(ArenaObjectives.bot_direction(game, fighter) == null, "Bots ignore objectives while they are dormant")
	ArenaObjectives.tick(game, ArenaObjectives.ARM_SECONDS)
	var runners := [0, 0]
	for fighter in game.fighters.slice(1):
		var direction: Variant = ArenaObjectives.bot_direction(game, fighter)
		if direction == null:
			continue
		runners[fighter.team] += 1
		_check(direction.is_equal_approx((fighter.position as Vector2).direction_to(game.objective.position)), "The assigned bot steers toward the relic")
		var former_health: float = fighter.health
		fighter.position = game.objective.position
		_check(ArenaObjectives.bot_direction(game, fighter) == Vector2.ZERO, "A bot already in the capture radius holds position")
		fighter.health = fighter.max_health * 0.15
		_check(ArenaObjectives.bot_direction(game, fighter) == null, "A badly injured bot can leave the point and survive")
		fighter.health = former_health
	_check(runners == [1, 1], "One bot per team seeks the relic while the others play their combat roles")


func _check_round_integration() -> void:
	var game := _open_match("orchard")
	var human: Dictionary = game.fighters[0]
	human.position = Vector2.ZERO
	human.health = human.max_health * 0.65
	for fighter in game.fighters.slice(1):
		fighter.stun = 20.0
		fighter.break_free_available = false
	game.step(14.05, Vector2.ZERO, Vector2.ZERO)
	_check(game.objective.phase == "cooldown" and game.objective.team == 0, "The live round clock advances objective activation and capture")
	_check(is_equal_approx(human.health, human.max_health * 0.77), "The integrated Orchard objective heals the capturing side")
	game.phase = "round_over"
	game.next_round()
	_check(game.objective.phase == "arming" and game.objective.team == -1 and is_zero_approx(game.objective.buff_left), "A new round clears objective rewards and capture progress")
	var desktop := ArenaMatch.new()
	desktop.start_match("breakwater", 17, -1, "orchard")
	_check(desktop.objective.is_empty(), "Desktop match rules retain their previous arena layout")


func _check(condition: bool, detail: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(detail)
