extends RefCounted

const ARM_SECONDS := 9.0
const HOLD_SECONDS := 5.0
const RESET_SECONDS := 24.0
const EPSILON := 0.000001
const RELICS := {
	"lockwater": {
		"name": "Tidefont", "radius": 1.5, "reward": "heal", "amount": 0.14,
		"duration": 0.0, "effect": "Restores 14% max health to living allies",
	},
	"kiln": {
		"name": "Cinderheart", "radius": 1.2, "reward": "damage", "amount": 0.18,
		"duration": 11.0, "effect": "Team deals 18% more damage for 11s",
	},
	"orchard": {
		"name": "Rootwell", "radius": 1.10, "reward": "heal", "amount": 0.12,
		"duration": 0.0, "effect": "Restores 12% max health to living allies",
	},
	"quarry": {
		"name": "Oathstone", "radius": 1.35, "reward": "ward", "amount": 0.24,
		"duration": 11.0, "effect": "Team takes 24% less combat damage for 11s",
	},
	"observatory": {
		"name": "Eclipse Lens", "radius": 1.4, "reward": "damage", "amount": 0.14,
		"duration": 15.0, "effect": "Team deals 14% more damage for 15s",
	},
}


static func prepare(game) -> void:
	if not game.mobile_mode:
		game.objective = {}
		return
	var relic := (RELICS[game.map_id] as Dictionary).duplicate()
	relic.merge({
		"map_id": game.map_id, "position": Vector2.ZERO, "phase": "arming", "team": -1,
		"progress": 0.0, "hold": HOLD_SECONDS, "time_left": ARM_SECONDS,
		"buff_team": -1, "buff_left": 0.0,
	})
	game.objective = relic


static func tick(game, delta: float) -> void:
	var relic: Dictionary = game.objective
	if relic.is_empty() or game.phase != "active" or not is_finite(delta) or delta <= 0.0:
		return
	var elapsed := delta
	while elapsed > EPSILON:
		if relic.phase in ["arming", "cooldown"]:
			var waiting := minf(elapsed, relic.time_left)
			relic.time_left = maxf(0.0, float(relic.time_left) - waiting)
			_tick_reward(relic, waiting)
			elapsed -= waiting
			if relic.time_left <= EPSILON:
				_neutralize(relic)
			continue
		var presence := _teams_inside(game.fighters, relic.position, relic.radius)
		if presence == 3:
			relic.phase = "contested"
			return
		relic.phase = "open"
		if presence == 0:
			_neutralize(relic)
			return
		var team := 0 if presence == 1 else 1
		if team != relic.team:
			relic.team = team
			relic.progress = 0.0
		var progress := minf(elapsed, HOLD_SECONDS - float(relic.progress))
		relic.progress += progress
		elapsed -= progress
		if relic.progress >= HOLD_SECONDS - EPSILON:
			_capture(game, relic, team)


static func _neutralize(relic: Dictionary) -> void:
	relic.phase = "open"
	relic.team = -1
	relic.progress = 0.0
	relic.time_left = 0.0


static func _tick_reward(relic: Dictionary, delta: float) -> void:
	if relic.buff_left > 0.0:
		relic.buff_left = maxf(0.0, float(relic.buff_left) - delta)
		if relic.buff_left <= EPSILON:
			relic.buff_left = 0.0
			relic.buff_team = -1


static func _teams_inside(fighters: Array[Dictionary], point: Vector2, radius: float) -> int:
	var teams := 0
	for fighter in fighters:
		if fighter.alive and point.distance_squared_to(fighter.position) <= radius * radius:
			teams |= 1 << int(fighter.team)
			if teams == 3:
				break
	return teams


static func _capture(game, relic: Dictionary, team: int) -> void:
	relic.phase = "cooldown"
	relic.team = team
	relic.progress = HOLD_SECONDS
	relic.time_left = RESET_SECONDS
	relic.buff_team = team if relic.duration > 0.0 else -1
	relic.buff_left = relic.duration
	if relic.reward == "heal":
		for fighter: Dictionary in game.fighters:
			if fighter.alive and fighter.team == team:
				# Relic healing is environmental and does not charge a champion's ultimate.
				game.heal({}, fighter, float(fighter.max_health) * float(relic.amount))
	game._announce("%s claimed %s" % ["Your team" if team == 0 else "Rivals", relic.name])


static func damage_multiplier(game, source: Dictionary, target: Dictionary) -> float:
	var relic: Dictionary = game.objective
	if relic.is_empty() or relic.buff_left <= 0.0 or source.team == target.team:
		return 1.0
	if relic.reward == "damage" and source.team == relic.buff_team:
		return 1.0 + float(relic.amount)
	if relic.reward == "ward" and target.team == relic.buff_team:
		return 1.0 - float(relic.amount)
	return 1.0


static func bot_direction(game, bot: Dictionary) -> Variant:
	var relic: Dictionary = game.objective
	if relic.is_empty() or relic.phase not in ["open", "contested"]:
		return null
	var point: Vector2 = relic.position
	var runner := -1
	var best_role := 5
	for candidate: Dictionary in game.fighters:
		if candidate.id == 0 or candidate.team != bot.team or not candidate.alive:
			continue
		if candidate.health < float(candidate.max_health) * 0.30:
			continue
		var role: String = game.CLASS_INFO[candidate.class_id].archetype
		var priority := ["guard", "melee", "ranged", "healer"].find(role)
		if priority >= 0 and priority < best_role:
			best_role = priority
			runner = candidate.id
	if runner != bot.id:
		return null
	var origin: Vector2 = bot.position
	var toward_point := point - origin
	if toward_point.length_squared() <= pow(float(relic.radius) * 0.74, 2.0):
		return Vector2.ZERO
	return toward_point.normalized()
