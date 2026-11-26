extends RefCounted

const ArenaMatch = preload("res://scripts/arena_match.gd")
const CLASS_IDS := [
	"breakwater", "threadkeeper", "echo_duelist", "forgecaller",
	"lamplighter", "longwatch", "sluicecaller", "glassmage",
	"blood_cantor", "bellwarden", "ash_dancer", "winter_scribe",
	"dream_shepherd", "chainrunner", "coilwright", "duskmoth",
]

var check: Callable


func run(record: Callable) -> void:
	check = record
	check.call(ArenaMatch.CLASS_INFO.size() == 16, "Exactly sixteen kits are offered")
	for class_id in CLASS_IDS:
		if not ArenaMatch.CLASS_INFO.has(class_id):
			check.call(false, "Required class %s registered" % class_id)
			continue
		_check_class(class_id)
		_check_actions(class_id)
		_check_masteries(class_id)
		_check_signature(class_id)
	_check_effect_ownership_and_expiry()
	_check_cleanses_and_return()


func _check_class(class_id: String) -> void:
	var arena = ArenaMatch.new()
	arena.start_match(class_id, 701)
	var kit: Dictionary = ArenaMatch.CLASS_INFO[class_id]
	var fighter: Dictionary = arena.fighters[0]
	check.call(fighter.class_id == class_id, "%s is selected in a match" % class_id)
	check.call(kit.abilities.size() == 8 and fighter.cooldowns.size() == 8, "%s has eight unlocked slots" % class_id)
	for detail in ["resource", "passive", "counterplay"]:
		check.call(not str(kit.get(detail, "")).is_empty(), "%s has %s guidance" % [class_id, detail])
	var names: Array[String] = []
	for ability in kit.abilities:
		check.call(not names.has(ability.name) and not ability.name.is_empty(), "%s has a distinct action named %s" % [class_id, ability.name])
		check.call(not ability.description.is_empty() and ability.cooldown > 0, "%s has a description and recovery time" % ability.name)
		names.append(ability.name)

	var initial_meter: float = fighter.meter
	var initial_team: Array = arena.fighters.map(func(f): return f.class_id)
	fighter.cooldowns.fill(10.0)
	fighter.meter = 0.0 if initial_meter != 0.0 else 100.0
	# Simulate an elimination through the round result path to exercise real reset code.
	for enemy in arena.fighters.slice(3):
		enemy.health = 0.0
		enemy.alive = false
	arena.step(1.0 / 60.0, Vector2.ZERO, Vector2.ZERO)
	arena.next_round()
	fighter = arena.fighters[0]
	check.call(arena.round_number == 2 and fighter.class_id == class_id, "%s survives the round transition" % class_id)
	check.call(fighter.cooldowns.all(func(remaining): return remaining == 0), "%s begins the next round with every slot ready" % class_id)
	check.call(is_equal_approx(fighter.meter, initial_meter), "%s resource resets between rounds" % class_id)
	check.call(initial_team == arena.fighters.map(func(f): return f.class_id), "%s keeps the same lineups between rounds" % class_id)


# A close-range scrum through the center lane. The friendly target stands
# behind the primary enemy, giving beam and ricochet attacks a second target.
func _encounter(class_id: String, mastery: int = -1):
	var arena = ArenaMatch.new()
	arena.start_match(class_id, 701, mastery)
	var positions := [
		Vector2.ZERO, Vector2(2.9, 0), Vector2(0, -1.0),
		Vector2(1.6, 0), Vector2(1.6, 0.8), Vector2(1.6, -1.1),
	]
	for fighter in arena.fighters:
		fighter.position = positions[fighter.id]
		fighter.health = fighter.max_health * 0.65
		fighter.bot_wait = 20.0
	arena.fighters[0].facing = Vector2.RIGHT
	arena.fighters[0].meter = 100.0
	return arena


func _check_actions(class_id: String) -> void:
	var kit: Dictionary = ArenaMatch.CLASS_INFO[class_id]
	for slot in range(kit.abilities.size()):
		var arena = _encounter(class_id)
		var fighter: Dictionary = arena.fighters[0]
		var action: Dictionary = kit.abilities[slot]
		var label := "%s / %s" % [kit.name, action.name]
		_prepare_cast(arena, class_id, slot)
		var target := _target_for(action)
		var cost: float = action.get("cost", 0)
		if cost > 0.0:
			fighter.meter = cost - 0.1
			check.call(not arena.try_ability(slot, target) and fighter.cooldowns[slot] == 0.0, label + " rejects an unaffordable cast")
		var meter_before := maxf(cost, 65.0)
		fighter.meter = meter_before
		var before := _combat_state(arena, slot)
		var events_before: int = arena.cast_events.size()
		var used: bool = arena.try_ability(slot, target)
		check.call(used, label + " casts through the match interface")
		if not used:
			continue
		check.call(arena.cast_events.size() == events_before + 1 and arena.cast_events[-1].class_id == class_id and arena.cast_events[-1].slot == slot, label + " emits its own cast event")
		check.call(before != _combat_state(arena, slot), label + " changes combat beyond resource and recovery")
		check.call(is_equal_approx(fighter.cooldowns[slot], action.cooldown), label + " starts its advertised cooldown")
		var remaining_meter: float = fighter.meter
		var expected_meter := clampf(meter_before - cost + float(action.gain), 0.0, 100.0)
		check.call(is_equal_approx(remaining_meter, expected_meter), label + " applies the listed cost and gain")
		check.call(not arena.try_ability(slot, target) and is_equal_approx(fighter.meter, remaining_meter) and arena.cast_events.size() == events_before + 1, label + " rejects duplicate inputs without spending or emitting effects")


func _target_for(action: Dictionary) -> int:
	match action.get("target", ""):
		"ally": return 1
		"enemy": return 3
	return -1


func _prepare_cast(arena, class_id: String, slot: int) -> void:
	match class_id:
		"threadkeeper":
			if slot == 3:
				arena.try_ability(2, 1)
				# A hit that lands inside Borrowed Time creates a recoverable wound.
				arena._deal_damage(arena.fighters[3], arena.fighters[1], 20.0)
		"echo_duelist":
			if slot in [2, 4, 7]:
				arena.try_ability(1)
		"lamplighter":
			if slot >= 3:
				arena.try_ability(2)
		"longwatch":
			if slot == 7:
				arena.try_ability(1, 3)
		"glassmage":
			if slot >= 2:
				arena.try_ability(1)
		"blood_cantor", "bellwarden", "ash_dancer":
			if slot != 0:
				arena.try_ability(0, 3)
		"winter_scribe":
			if slot in [2, 3, 7]:
				arena.fighters[3].position = Vector2(4.5, 0)
				arena.try_ability(1)
		"chainrunner", "coilwright", "duskmoth":
			if slot == 7 or (class_id == "duskmoth" and slot == 5):
				arena.try_ability(1, 3)


func _check_signature(class_id: String) -> void:
	var arena = _encounter(class_id)
	var fighter: Dictionary = arena.fighters[0]
	var ally: Dictionary = arena.fighters[1]
	var enemy: Dictionary = arena.fighters[3]
	var neighbor: Dictionary = arena.fighters[4]
	match class_id:
		"breakwater":
			check.call(arena.try_ability(2, 1), "Breakwater can guard a teammate")
			var before: float = enemy.health
			check.call(arena.try_ability(6, 3) and before - enemy.health > 18.0, "Guarding a nearby ally enhances Keelbreaker")
		"threadkeeper":
			var ally_before: float = ally.health
			var enemy_before: float = enemy.health
			check.call(arena.try_ability(6, 1) and ally.health > ally_before and enemy.health < enemy_before, "Throughstitch heals its ally and hits the enemy standing between them")
		"echo_duelist":
			var origin: Vector2 = fighter.position
			check.call(arena.try_ability(1) and origin.distance_to(fighter.position) > 1.0, "Tracecut establishes a trail")
			check.call(arena.try_ability(4) and origin.distance_to(fighter.position) < 0.5, "Retrace returns along the previous trail")
			check.call(not arena.try_ability(2), "Retrace consumes the trail before another Afterstroke")
		"forgecaller":
			check.call(arena.try_ability(1, 3), "Heat Brand marks a target")
			var before: float = enemy.health
			check.call(arena.try_ability(7, 3) and enemy.health < before, "Hammerfall hits the branded enemy")
		"lamplighter":
			var before: float = ally.health
			check.call(arena.try_ability(2), "Lamplighter establishes a sanctuary")
			check.call(arena.try_ability(7) and ally.health > before, "Sacrificing the lantern heals a nearby ally")
		"longwatch":
			check.call(arena.try_ability(1, 3), "Longwatch marks its quarry")
			var before: float = enemy.health
			check.call(arena.try_ability(7, 3) and enemy.health < before, "Longwatch cashes in the mark for damage")
		"sluicecaller":
			var before: float = fighter.position.distance_to(enemy.position)
			check.call(arena.try_ability(2, 3) and fighter.position.distance_to(enemy.position) > before, "Crosscurrent creates space")
			var after_push: float = fighter.position.distance_to(enemy.position)
			check.call(arena.try_ability(5, 3) and fighter.position.distance_to(enemy.position) < after_push, "Riptide pulls the displaced rival back")
		"glassmage":
			enemy.position = Vector2(4, 0)
			var before: float = enemy.health
			check.call(arena.try_ability(1), "Glassmage can position a prism")
			check.call(arena.try_ability(7) and enemy.health < before, "Prism damage originates at the placed crystal")
		"blood_cantor":
			check.call(arena.try_ability(0, 3), "The cantor brands an enemy")
			var before: float = fighter.health
			check.call(arena.try_ability(6, 3) and fighter.health > before, "The cantor restores health by harvesting a marked rival")
		"bellwarden":
			check.call(arena.try_ability(0, 3), "Bellwarden sets up a resonant hit")
			enemy.mend_time = 0.6
			check.call(arena.try_ability(2, 3) and enemy.mend_time == 0.0, "Bellwarden disrupts an active enemy cast")
		"ash_dancer":
			check.call(arena.try_ability(0, 3), "Ash Dancer marks a melee rival")
			var before: float = enemy.health
			check.call(arena.try_ability(7, 3) and enemy.health < before, "Ash Dancer converts its mark into burst")
		"winter_scribe":
			enemy.position = Vector2(4.5, 0)
			var before: float = enemy.health
			check.call(arena.try_ability(1), "Winter Scribe inscribes a seal ahead")
			check.call(arena.try_ability(2) and enemy.health < before, "Triggering a seal damages enemies standing inside it")
		"dream_shepherd":
			ally.health = ally.max_health
			check.call(arena.try_ability(2, 1), "Dream Shepherd can prepare a healthy ally before the hit")
			arena._deal_damage(enemy, ally, 45.0)
			var before: float = ally.health
			check.call(arena.try_ability(1, 1) and ally.health > before, "Dream Shepherd's follow-up restores the wounded ally")
		"chainrunner":
			enemy.position = Vector2(5.0, 0.0)
			check.call(arena.try_ability(1, 3) and fighter.position.distance_to(enemy.position) < 5.0, "Hookline pulls an opponent toward the Chainrunner")
			var before: float = enemy.health
			check.call(arena.try_ability(7, 3) and enemy.health < before, "Last Link follows the hook into melee")
		"coilwright":
			check.call(arena.try_ability(1, 3), "Coilwright polarizes a rival")
			var before: float = neighbor.health
			check.call(arena.try_ability(2, 3) and neighbor.health < before, "Fork Spark chains from a polarized enemy to a neighbor")
		"duskmoth":
			check.call(arena.try_ability(1, 3), "Duskmoth coats its target")
			var before: float = fighter.health
			check.call(arena.try_ability(7, 3) and fighter.health > before, "Moon Harvest consumes the setup and heals its caster")


# Ignore the cost, the tested slot's timer, and facing so an empty action
# cannot pass merely by turning the caster and starting its own cooldown.
func _combat_state(arena, slot: int) -> Array:
	var roster: Array = arena.fighters.duplicate(true)
	roster[0].erase("meter")
	roster[0].erase("facing")
	roster[0].cooldowns[slot] = 0.0
	return [roster, arena.fields.duplicate(true)]


func _check_effect_ownership_and_expiry() -> void:
	var arena = _encounter("duskmoth")
	var player: Dictionary = arena.fighters[0]
	var enemy: Dictionary = arena.fighters[3]
	arena.mark(arena.fighters[1], enemy, "dusted", 5.0)
	check.call(not arena.try_ability(7, 3), "Moon Harvest rejects a different fighter's dust mark")
	check.call(arena.try_ability(1, 3) and arena.try_ability(7, 3), "Moon Harvest accepts the player's own dust mark")
	check.call(not arena.marked(player, enemy, "dusted") and arena.marked(arena.fighters[1], enemy, "dusted"), "Consuming a mark preserves another owner's mark")

	arena = _encounter("threadkeeper")
	var ally: Dictionary = arena.fighters[1]
	enemy = arena.fighters[3]
	for bot in arena.fighters.slice(1):
		bot.stun = 10.0
		bot.break_free_available = false
	var ally_before: float = ally.health
	var enemy_before: float = enemy.health
	check.call(arena.try_ability(7, 1), "Spool of Hours creates a field on an ally")
	arena.step(0.2, Vector2.ZERO, Vector2.ZERO)
	check.call(ally.health > ally_before and enemy.health == enemy_before, "A healing field affects only its team")
	arena.step(5.0, Vector2.ZERO, Vector2.ZERO)
	check.call(arena.fields.is_empty(), "Expired fields leave the arena")


func _check_cleanses_and_return() -> void:
	var arena = _encounter("duskmoth")
	var player: Dictionary = arena.fighters[0]
	arena.afflict(player, "slow", 3.0, 0.3, 3)
	check.call(arena.try_ability(3) and not arena.has_status(player, "slow"), "Shed Husk clears an existing hostile slow")
	arena = _encounter("coilwright")
	player = arena.fighters[0]
	var origin: Vector2 = player.position
	check.call(arena.try_ability(4), "Phase Return stakes an initial position")
	arena.step(0.5, Vector2.RIGHT, Vector2.RIGHT)
	check.call((player.position as Vector2).distance_to(origin) > 1.0 and arena.try_ability(4), "Phase Return can be activated a second time after moving")
	check.call((player.position as Vector2).distance_to(origin) < 0.05 and player.cooldowns[4] >= 9.0, "Returning to the anchor exposes the full recovery time")


func _check_masteries(class_id: String) -> void:
	var kit: Dictionary = ArenaMatch.CLASS_INFO[class_id]
	var standard: Array = kit.abilities.duplicate(true)
	check.call(kit.masteries.size() == 2, "%s offers two mastery choices" % kit.name)
	for index in kit.masteries.size():
		var option: Dictionary = kit.masteries[index]
		var arena = _encounter(class_id, index)
		var player: Dictionary = arena.fighters[0]
		var slot: int = option.slot
		var label := "%s / %s" % [kit.name, option.name]
		var customized: Array = standard.duplicate(true)
		customized[slot].cost = option.cost
		customized[slot].cooldown = option.cooldown
		check.call(player.mastery == index and player.abilities == customized, label + " changes its advertised ability while preserving the other seven")
		var recovery_difference: float = option.cooldown - standard[slot].cooldown
		var price_difference: float = option.cost - standard[slot].cost
		check.call(recovery_difference * price_difference < 0.0, label + " trades faster recovery against resource price")
		_prepare_cast(arena, class_id, slot)
		player.meter = float(option.cost)
		check.call(arena.try_ability(slot, _target_for(standard[slot])), label + " casts with its exact modified price")
		check.call(is_equal_approx(player.meter, standard[slot].gain) and is_equal_approx(player.cooldowns[slot], option.cooldown), label + " charges the modified price and applies the modified cooldown")
		for enemy in arena.fighters.slice(3):
			enemy.health = 0.0
			enemy.alive = false
		arena.step(1.0 / 60.0, Vector2.ZERO, Vector2.ZERO)
		arena.next_round()
		player = arena.fighters[0]
		check.call(player.mastery == index and player.abilities == customized and player.cooldowns[slot] == 0.0, label + " is retained and ready in round two")
		check.call(kit.abilities == standard and ArenaMatch.loadout(class_id) == standard, label + " leaves the standard kit intact")
