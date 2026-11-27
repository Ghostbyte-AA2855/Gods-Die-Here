extends RefCounted

const ArenaMaps = preload("res://scripts/arena_maps.gd")
const ArenaObjectives = preload("res://scripts/arena_objectives.gd")
const ArenaUltimates = preload("res://scripts/arena_ultimates.gd")
const MobileKits = preload("res://scripts/mobile_kits.gd")
const ARENA_RADIUS = ArenaMaps.RADIUS
const ROUND_SECONDS = 60.0
const ROUNDS_TO_WIN = 3
const MOBILE_ROUND_SECONDS = 300.0
const MOBILE_ROUNDS_TO_WIN = 3
const MOBILE_HEALTH_MULTIPLIER = 7.5
const MOBILE_BOT_ACTION_INTERVAL = 0.43
const ULTIMATE_DEALT_CHARGE := 0.32
const ULTIMATE_RECEIVED_CHARGE := 0.19
const ULTIMATE_HEAL_CHARGE := 0.68
const ULTIMATE_PREVENTED_CHARGE := 0.47
const DODGE_COOLDOWN = 4.0
const Masteries = preload("res://scripts/arena_masteries.gd")
const KIT_MODULES = [
	preload("res://scripts/kits/vanguard.gd"), preload("res://scripts/kits/frontier.gd"),
	preload("res://scripts/kits/covenant.gd"), preload("res://scripts/kits/outliers.gd")
]
static var CLASS_INFO: Dictionary = {}
static var _modules_by_class: Dictionary = {}

static func _static_init() -> void:
	for module in KIT_MODULES:
		for class_id in module.KITS:
			var kit: Dictionary = module.KITS[class_id].duplicate()
			var choices: Array = Masteries.OPTIONS[class_id].duplicate(true)
			for option in choices:
				var skill: Dictionary = kit.abilities[option.slot]
				option.description = "%s cooldown %ss → %ss. %s cost %d → %d." % [
					skill.name, str(skill.cooldown), str(option.cooldown), kit.resource, skill.cost, option.cost
				]
			kit.masteries = choices
			CLASS_INFO[class_id] = kit
			_modules_by_class[class_id] = module

var mobile_mode: bool = false
var map_id: String = "lockwater"
var terrain: Array[Dictionary] = ArenaMaps.base_terrain("lockwater")
var environment_zones: Array[Dictionary] = []
var map_hint: String = ""
var fields: Array[Dictionary] = []
var cast_events: Array[Dictionary] = []
var ultimate_windups: Array[Dictionary] = []
var objective: Dictionary = {}
var last_cast_failure := ""
var _cast_sequence: int = 0
var _pending_cast: Dictionary = {}
var _lineup: Array[String] = []
var _mastery_choices: Array[int] = []
var fighters: Array[Dictionary] = []
var phase = "idle"
var round_number = 0
var round_time = 0.0
var wins: Array[int] = [0, 0]
var round_winner = -1
var match_winner = -1
var safe_radius = ARENA_RADIUS
var feed: Array[String] = []

var _human_class = "breakwater"


func start_match(class_id: String, lineup_seed: int = -1, mastery: int = -1, arena_id: String = "lockwater") -> void:
	map_id = arena_id if ArenaMaps.MAPS.has(arena_id) else "lockwater"
	_human_class = class_id if CLASS_INFO.has(class_id) else "breakwater"
	var rng := RandomNumberGenerator.new()
	rng.seed = lineup_seed if lineup_seed >= 0 else randi()
	_lineup.clear()
	_lineup.append(_human_class)
	var home_role := _team_role(_human_class)
	for role in ["guard", "healer", "damage"]:
		if role != home_role:
			_lineup.append(_pick_role(role, rng))
	for role in ["guard", "healer", "damage"]:
		_lineup.append(_pick_role(role, rng))
	_mastery_choices = [mastery if not mobile_mode and mastery in [0, 1] else -1]
	for index in range(1, _lineup.size()):
		_mastery_choices.append(-1 if mobile_mode else rng.randi_range(-1, 1))
	wins = [0, 0]
	round_number = 0
	match_winner = -1
	feed.clear()
	_start_round()


static func loadout(class_id: String, mastery: int = -1) -> Array:
	var kit: Dictionary = CLASS_INFO[class_id]
	var abilities: Array = kit.abilities.duplicate(true)
	if mastery >= 0 and mastery < kit.masteries.size():
		var option: Dictionary = kit.masteries[mastery]
		abilities[option.slot].cooldown = option.cooldown
		abilities[option.slot].cost = option.cost
	return abilities


func _team_role(class_id: String) -> String:
	var role: String = CLASS_INFO[class_id].archetype
	return "damage" if role in ["melee", "ranged"] else role


func _pick_role(role: String, rng: RandomNumberGenerator) -> String:
	var choices: Array[String] = []
	for class_id in CLASS_INFO:
		if _team_role(class_id) == role:
			choices.append(class_id)
	return choices[rng.randi_range(0, choices.size() - 1)]


func next_round() -> void:
	if phase == "round_over":
		_start_round()


func round_limit() -> int:
	return MOBILE_ROUNDS_TO_WIN if mobile_mode else ROUNDS_TO_WIN


func round_duration() -> float:
	return MOBILE_ROUND_SECONDS if mobile_mode else ROUND_SECONDS


func step(delta: float, movement: Vector2, facing: Vector2) -> void:
	if phase != "active" or not is_finite(delta) or delta <= 0.0:
		return
	_check_round_end()
	# Resolve long frames in bounded slices. Timers, bots and displacement advance together.
	var remaining = minf(delta, round_time)
	while remaining > 0.0 and phase == "active":
		var slice = minf(remaining, 1.0 / 30.0)
		_step_slice(slice, movement, facing)
		remaining -= slice


func try_mobile_ability(button: int, target_id: int = -1) -> bool:
	if not mobile_mode or phase != "active":
		return false
	var slots := MobileKits.slots(_human_class)
	if button < 0 or button >= slots.size():
		return false
	return try_ability(slots[button], target_id)


func try_ultimate(target_id: int = -1) -> bool:
	if not ultimate_blocker().is_empty():
		return false
	var actor: Dictionary = fighters[0]
	return _begin_ultimate(actor, ArenaUltimates.warning(self, actor, target_id))


func ultimate_blocker() -> String:
	if not mobile_mode or phase != "active":
		return "inactive"
	return _ultimate_blocker_for(fighters[0])


func _ultimate_blocker_for(fighter: Dictionary) -> String:
	if not fighter.alive:
		return "eliminated"
	if fighter.ultimate_casting:
		return "winding_up"
	if fighter.ultimate_used:
		return "used"
	if fighter.stun > 0.0:
		return "stun"
	if has_status(fighter, "silence"):
		return "silence"
	if fighter.mend_time > 0.0:
		return "channel"
	if fighter.ultimate_charge < ArenaUltimates.CHARGE_REQUIRED:
		return "charge"
	return ""


func _begin_ultimate(fighter: Dictionary, preview: Dictionary) -> bool:
	fighter.ultimate_charge = 0.0
	fighter.ultimate_used = true
	fighter.ultimate_casting = true
	fighter.facing = preview.facing
	ultimate_windups.append(preview)
	return true


func _tick_ultimates(delta: float) -> void:
	# Advance a snapshot because one resolving cast can interrupt the next caster.
	for preview in ultimate_windups.duplicate():
		var caster: Dictionary = fighters[preview.source_id]
		if not caster.ultimate_casting:
			continue
		if not caster.alive or caster.stun > 0.0 or has_status(caster, "silence"):
			_cancel_ultimate(caster)
			continue
		preview.remaining = maxf(0.0, float(preview.remaining) - delta)
		if preview.remaining > 0.000001:
			continue
		caster.ultimate_casting = false
		ultimate_windups.erase(preview)
		_pending_cast = preview.duplicate()
		_pending_cast.affected_ids = []
		_pending_cast.affected_positions = {}
		ArenaUltimates.resolve(self, caster, preview)
		_record_cast(caster)
		_check_round_end()
		if phase != "active":
			break


func _cancel_ultimate(fighter: Dictionary) -> void:
	if not fighter.get("ultimate_casting", false):
		return
	fighter.ultimate_casting = false
	for preview in ultimate_windups:
		if preview.source_id == fighter.id:
			ultimate_windups.erase(preview)
			_announce("%s lost their ultimate." % _fighter_name(fighter))
			return


func _gain_ultimate(fighter: Dictionary, amount: float) -> void:
	if mobile_mode and amount > 0.0 and fighter.get("alive", false) and not fighter.get("ultimate_used", true):
		fighter.ultimate_charge = minf(ArenaUltimates.CHARGE_REQUIRED, fighter.ultimate_charge + amount)


func try_ability(slot: int, target_id: int = -1) -> bool:
	last_cast_failure = ""
	if phase != "active" or slot < 0 or slot >= fighters[0].cooldowns.size():
		return false
	if mobile_mode:
		last_cast_failure = mobile_cast_blocker(slot)
		if not last_cast_failure.is_empty():
			return false
	var used = _use_ability(fighters[0], slot, target_id)
	if used:
		last_cast_failure = ""
		_check_round_end()
	elif mobile_mode and last_cast_failure.is_empty():
		last_cast_failure = "setup"
	return used


func mobile_cast_blocker(slot: int) -> String:
	var actor: Dictionary = fighters[0]
	if not actor.alive:
		return "eliminated"
	if not MobileKits.allows(actor.class_id, slot):
		return "hidden"
	if actor.stun > 0.0:
		return "stun"
	if slot != 0 and has_status(actor, "silence"):
		return "silence"
	if actor.mend_time > 0.0 or actor.ultimate_casting:
		return "channel"
	if actor.meter < actor.abilities[slot].cost:
		return "resource"
	if actor.cooldowns[slot] > 0.0:
		return "cooldown"
	return ""


func try_dodge(direction: Vector2) -> bool:
	if phase != "active" or not direction.is_finite():
		return false
	var fighter = fighters[0]
	if not _can_act(fighter) or fighter.dodge_cooldown > 0.0 or has_status(fighter, "root"):
		return false
	var heading = direction.normalized() if direction.length_squared() > 0.0 else fighter.facing as Vector2
	_move(fighter, heading * 2.5, false)
	fighter.evade = maxf(fighter.evade, 0.22)
	fighter.dodge_cooldown = DODGE_COOLDOWN
	return true


func try_break_free() -> bool:
	return phase == "active" and _break_free(fighters[0])


func _start_round() -> void:
	ArenaMaps.prepare(self)
	ArenaObjectives.prepare(self)
	cast_events.clear()
	ultimate_windups.clear()
	fields.clear()
	fighters.clear()
	for index in _lineup.size():
		fighters.append(_make_fighter(index, 0 if index < 3 else 1, _lineup[index]))
	round_number += 1
	round_time = round_duration()
	safe_radius = ARENA_RADIUS
	round_winner = -1
	phase = "active"
	_announce("Round %d begins." % round_number)


func _make_fighter(index: int, team: int, class_id: String) -> Dictionary:
	var max_health: float = CLASS_INFO[class_id].max_health
	if mobile_mode:
		max_health = roundf(max_health * MOBILE_HEALTH_MULTIPLIER)
	var side = -1.0 if team == 0 else 1.0
	return {
		"id": index,
		"team": team,
		"class_id": class_id,
		"position": Vector2(9.0 * side, float(index % 3 - 1) * 2.25),
		"facing": Vector2(-side, 0.0),
		"health": max_health,
		"max_health": max_health,
		"alive": true,
		"cooldowns": [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
		"meter": 40.0,
		"mastery": _mastery_choices[index],
		"abilities": loadout(class_id, _mastery_choices[index]),
		"statuses": {}, "marks": {},
		"shield_hp": 0.0, "shield_time": 0.0,
		"shield_source": -1,
		"ultimate_charge": 0.0, "ultimate_used": false, "ultimate_casting": false,
		"ultimate_healable": 0.0,
		"dodge_cooldown": 0.0,
		"break_free_available": true,
		"evade": 0.0,
		"brace": 0.0,
		"stun": 0.0,
		"guard_time": 0.0,
		"guard_target": -1,
		"wound_time": 0.0,
		"wound_damage": 0.0,
		"mend_time": 0.0,
		"mend_target": -1,
		"echo_start": Vector2.ZERO,
		"echo_end": Vector2.ZERO,
		"echo_time": 0.0,
		"feint": 0.0,
		"counter_time": 0.0,
		"bot_wait": 0.15 + float(index % 3) * 0.11,
	}


func _step_slice(delta: float, movement: Vector2, facing: Vector2) -> void:
	round_time = maxf(0.0, round_time - delta)
	var former_radius = safe_radius
	safe_radius = lerpf(3.1, ARENA_RADIUS, clampf(round_time / 25.0, 0.0, 1.0))
	ArenaMaps.update(self, round_duration() - round_time, delta)
	_tick_fields(delta)
	if former_radius == ARENA_RADIUS and safe_radius < ARENA_RADIUS:
		_announce("The safe zone is closing.")
	for fighter in fighters:
		if fighter.alive:
			_tick_fighter(fighter, delta)
	_check_round_end()
	if phase != "active":
		return
	if mobile_mode and not ultimate_windups.is_empty():
		_tick_ultimates(delta)
		if phase != "active":
			return
	for fighter in fighters:
		if fighter.alive and fighter.mend_time > 0.0:
			fighter.mend_time = maxf(0.0, float(fighter.mend_time) - delta)
			if fighter.mend_time <= 0.0:
				_finish_mend(fighter)
	var human = fighters[0]
	if _can_act(human):
		if facing.is_finite() and facing.length_squared() > 0.001:
			human.facing = facing.normalized()
		if movement.is_finite() and movement.length_squared() > 0.0:
			_move(human, movement.limit_length() * float(CLASS_INFO[human.class_id].speed) * _movement_factor(human) * delta)
	for index in range(1, fighters.size()):
		var bot = fighters[index]
		_bot_break_free(bot)
		if _can_act(bot):
			_step_bot(bot, delta)
			_check_round_end()
			if phase != "active":
				break
	if mobile_mode and phase == "active":
		ArenaObjectives.tick(self, delta)
		_check_round_end()


func _tick_fighter(fighter: Dictionary, delta: float) -> void:
	_tick_effects(fighter, delta)
	for slot in fighter.cooldowns.size():
		fighter.cooldowns[slot] = maxf(0.0, float(fighter.cooldowns[slot]) - delta)
	for timer in ["dodge_cooldown", "evade", "brace", "stun", "guard_time", "echo_time", "feint", "counter_time", "bot_wait"]:
		fighter[timer] = maxf(0.0, float(fighter[timer]) - delta)
	if fighter.wound_time > 0.0:
		fighter.wound_time = maxf(0.0, float(fighter.wound_time) - delta)
		if fighter.wound_time <= 0.0:
			var wound: float = fighter.wound_damage
			fighter.wound_damage = 0.0
			_apply_damage(fighter, wound)
	if fighter.alive and (fighter.position as Vector2).length() > safe_radius:
		var ring_damage := 16.0 * (MOBILE_HEALTH_MULTIPLIER if mobile_mode else 1.0)
		_apply_damage(fighter, ring_damage * delta)


func _can_act(fighter: Dictionary) -> bool:
	return fighter.alive and fighter.stun <= 0.0 and fighter.mend_time <= 0.0 and not fighter.ultimate_casting


static func can_break_free(fighter: Dictionary) -> bool:
	return fighter.get("alive", false) and fighter.get("break_free_available", false) and (
		fighter.get("stun", 0.0) > 0.0 or has_status(fighter, "root") or has_status(fighter, "silence")
	)


func _break_free(fighter: Dictionary) -> bool:
	if not can_break_free(fighter):
		return false
	fighter.stun = 0.0
	for key in fighter.statuses.keys():
		if fighter.statuses[key].kind in ["root", "silence"]:
			fighter.statuses.erase(key)
	fighter.break_free_available = false
	_announce("%s used Break Free." % _fighter_name(fighter))
	return true


func _bot_break_free(bot: Dictionary) -> void:
	if not bot.alive or not bot.break_free_available or (bot.stun < 0.35 and not has_status(bot, "root") and not has_status(bot, "silence")) or bot.health > float(bot.max_health) * 0.45:
		return
	var threat = _closest_enemy(bot)
	if not threat.is_empty() and (bot.position as Vector2).distance_squared_to(threat.position) <= 16.0:
		_break_free(bot)


func _check_round_end() -> void:
	if phase != "active":
		return
	var living: Array[int] = [0, 0]
	var health: Array[float] = [0.0, 0.0]
	var maximum: Array[float] = [0.0, 0.0]
	for fighter in fighters:
		var team: int = fighter.team
		maximum[team] += float(fighter.max_health)
		if fighter.alive:
			living[team] += 1
			health[team] += float(fighter.health)
	if living[0] > 0 and living[1] > 0 and round_time > 0.0:
		return
	var winner = -1
	if living[0] != living[1]:
		winner = 0 if living[0] > living[1] else 1
	else:
		var percentage_difference = health[0] / maximum[0] - health[1] / maximum[1]
		if absf(percentage_difference) > 0.0001:
			winner = 0 if percentage_difference > 0.0 else 1
	round_winner = winner
	phase = "round_over"
	ultimate_windups.clear()
	for fighter in fighters:
		fighter.ultimate_casting = false
	if winner == -1:
		_announce("Round %d ended in a draw." % round_number)
		return
	wins[winner] += 1
	var team_name = "Your team" if winner == 0 else "The rival team"
	_announce("%s won round %d." % [team_name, round_number])
	if wins[winner] >= round_limit():
		match_winner = winner
		phase = "match_over"


func _use_ability(fighter: Dictionary, slot: int, target_id: int) -> bool:
	if mobile_mode and not MobileKits.allows(fighter.class_id, slot):
		return false
	if not _can_act(fighter) or fighter.cooldowns[slot] > 0.0:
		return false
	var ability: Dictionary = fighter.abilities[slot]
	if fighter.meter < ability.cost or (slot != 0 and has_status(fighter, "silence")):
		return false
	var origin: Vector2 = fighter.position
	var default_destination := aim_point(fighter, 4.0) if ability.target == "aim" else origin
	_pending_cast = {
		"class_id":fighter.class_id, "slot":slot, "name":ability.name, "team":fighter.team,
		"source_id":fighter.id, "target_id":-1, "origin":origin, "destination":default_destination,
		"facing":fighter.facing, "target_kind":ability.target, "affected_ids":[], "affected_positions":{}
	}
	if not _modules_by_class[fighter.class_id].cast(self, fighter, slot, target_id):
		_pending_cast = {}
		return false
	_record_cast(fighter)
	fighter.meter = clampf(fighter.meter - ability.cost + ability.gain, 0.0, 100.0)
	fighter.cooldowns[slot] = maxf(fighter.cooldowns[slot], ability.cooldown)
	return true


func _record_cast(fighter: Dictionary) -> void:
	_cast_sequence += 1
	_pending_cast.seq = _cast_sequence
	_pending_cast.source_after = fighter.position
	cast_events.append(_pending_cast)
	_pending_cast = {}
	if cast_events.size() > 96:
		cast_events.pop_front()


func _use_breakwater(fighter: Dictionary, slot: int, target_id: int) -> bool:
	if slot == 1:
		fighter.brace = 1.0
		return true
	if slot == 2:
		var ally = _target(fighter, target_id, true, 6.0, "ally_other")
		if ally.is_empty():
			return false
		fighter.guard_target = ally.id
		fighter.guard_time = 4.0
		return true
	var target = _target(fighter, target_id, false, 3.0)
	if target.is_empty():
		return false
	_face(fighter, target.position)
	var hit = _deal_damage(fighter, target, 18.0 if slot == 0 else 11.0)
	if slot == 3 and target.alive and hit:
		target.stun = maxf(target.stun, 0.7)
		if target.mend_time > 0.0:
			_announce("%s interrupted Mend the Break." % _fighter_name(fighter))
			target.mend_time = 0.0
			target.mend_target = -1
	return true


func _use_threadkeeper(fighter: Dictionary, slot: int, target_id: int) -> bool:
	if slot == 0:
		var enemy = _target(fighter, target_id, false, 8.5)
		if enemy.is_empty():
			return false
		_face(fighter, enemy.position)
		_deal_damage(fighter, enemy, 13.0)
		return true
	var target_mode = ["nearest", "injured", "unwounded", "deferred"][slot]
	var ally = _target(fighter, target_id, true, 8.5, target_mode)
	if ally.is_empty():
		return false
	match slot:
		1:
			heal(fighter, ally, 30.0)
		2:
			ally.wound_time = 4.0
		3:
			fighter.mend_time = 0.7
			fighter.mend_target = ally.id
	return true


func _finish_mend(fighter: Dictionary) -> void:
	var ally = _target(fighter, fighter.mend_target, true, 8.5, "deferred")
	fighter.mend_target = -1
	if not ally.is_empty():
		ally.wound_time = 0.0
		_gain_ultimate(fighter, float(ally.wound_damage) * ULTIMATE_PREVENTED_CHARGE)
		ally.wound_damage = 0.0
		var recipient = "your" if ally.id == 0 else "%s's" % _fighter_name(ally)
		_announce("%s cleared %s delayed damage." % [_fighter_name(fighter), recipient])


func _use_echo(fighter: Dictionary, slot: int, target_id: int) -> bool:
	match slot:
		0:
			var enemy = _target(fighter, target_id, false, 3.0)
			if enemy.is_empty():
				return false
			_face(fighter, enemy.position)
			var damage = 34.0 if fighter.counter_time > 0.0 else 21.0
			if _deal_damage(fighter, enemy, damage):
				fighter.counter_time = 0.0
		1:
			var enemy = _target(fighter, target_id, false, 6.0) if target_id >= 0 else {}
			if not enemy.is_empty():
				_face(fighter, enemy.position)
			var start: Vector2 = fighter.position
			_move(fighter, (fighter.facing as Vector2) * 4.0, false)
			var end: Vector2 = fighter.position
			if start.distance_squared_to(end) < 0.01:
				return false
			fighter.echo_start = start
			fighter.echo_end = end
			fighter.echo_time = 3.0
			_hit_echo(fighter, 15.0)
		2:
			if fighter.echo_time <= 0.0:
				return false
			_hit_echo(fighter, 25.0)
			fighter.echo_time = 0.0
		3:
			fighter.feint = 0.55
			fighter.evade = maxf(fighter.evade, 0.55)
	return true


func _hit_echo(fighter: Dictionary, damage: float) -> void:
	for enemy in fighters:
		if enemy.team == fighter.team or not enemy.alive:
			continue
		var position: Vector2 = enemy.position
		var closest = Geometry2D.get_closest_point_to_segment(position, fighter.echo_start, fighter.echo_end)
		if closest.distance_squared_to(position) <= 1.35 * 1.35 and _has_sight(closest, position):
			_deal_damage(fighter, enemy, damage)


func _deal_damage(source: Dictionary, target: Dictionary, damage: float) -> bool:
	if not target.alive:
		return false
	if target.evade > 0.0:
		if target.feint > 0.0:
			target.counter_time = 3.0
		return false
	_note_affected(target)
	damage *= 1.0 - clampf(_power(source, "weaken"), 0.0, 0.9)
	if mobile_mode:
		damage *= _mobile_damage_modifier(source, target)
	if target.brace > 0.0:
		var incoming = (source.position as Vector2) - (target.position as Vector2)
		if incoming.normalized().dot(target.facing) > 0.25:
			var before := damage
			damage *= 0.2 if target.brace > 0.6 else 0.55
			_gain_ultimate(target, (before - damage) * ULTIMATE_PREVENTED_CHARGE)
	for protector in fighters:
		if protector.alive and protector.guard_time > 0.0 and protector.guard_target == target.id:
			if (protector.position as Vector2).distance_squared_to(target.position) <= 36.0:
				var redirected = damage * 0.35
				damage -= redirected
				_receive_damage(protector, redirected, true, source)
				_gain_ultimate(protector, redirected * ULTIMATE_PREVENTED_CHARGE)
			break
	_receive_damage(target, damage, true, source)
	return true


func _mobile_damage_modifier(source: Dictionary, target: Dictionary) -> float:
	var relic_multiplier := ArenaObjectives.damage_multiplier(self, source, target)
	var fortified := 1.0 - clampf(_power(target, "fortify"), 0.0, 0.9)
	return minf(relic_multiplier, fortified) if relic_multiplier < 1.0 else relic_multiplier * fortified


func _receive_damage(fighter: Dictionary, damage: float, direct: bool = true, source: Dictionary = {}) -> void:
	var absorbed := minf(damage, fighter.shield_hp)
	var combat_credit: bool = mobile_mode and not source.is_empty() and fighter.team != source.team
	var effective := minf(damage, float(fighter.health) + absorbed)
	var previous_health: float = fighter.health
	if combat_credit:
		_gain_ultimate(source, effective * ULTIMATE_DEALT_CHARGE)
		_gain_ultimate(fighter, effective * ULTIMATE_RECEIVED_CHARGE)
		if absorbed > 0.0 and fighter.shield_source >= 0:
			_gain_ultimate(fighters[fighter.shield_source], absorbed * ULTIMATE_PREVENTED_CHARGE)
	fighter.shield_hp -= absorbed
	damage -= absorbed
	if direct and fighter.wound_time > 0.0:
		var deferred = damage * 0.45
		fighter.wound_damage += deferred
		damage -= deferred
	_apply_damage(fighter, damage)
	if combat_credit:
		fighter.ultimate_healable += maxf(0.0, previous_health - float(fighter.health))


func _apply_damage(fighter: Dictionary, damage: float) -> void:
	if not fighter.alive:
		return
	fighter.health = maxf(0.0, float(fighter.health) - damage)
	if fighter.health <= 0.0:
		fighter.alive = false
		_cancel_ultimate(fighter)
		_announce("You were defeated." if fighter.id == 0 else "%s was defeated." % _fighter_name(fighter))


func _target(fighter: Dictionary, target_id: int, ally: bool, reach: float, mode: String = "nearest") -> Dictionary:
	if target_id < -1 or target_id >= fighters.size():
		return {}
	var best: Dictionary = {}
	var best_score = INF
	var origin: Vector2 = fighter.position
	var targeted_side := "ally" if ally else "enemy"
	var explain: bool = mobile_mode and fighter.id == 0 and _pending_cast.get("target_kind") == targeted_side
	var filtered := false
	var beyond_reach := false
	var obstructed := false
	for candidate in fighters:
		if target_id >= 0 and target_id != candidate.id:
			continue
		if not candidate.alive or (candidate.team == fighter.team) != ally:
			continue
		if ((mode == "ally_other" and candidate.id == fighter.id)
				or (mode == "injured" and candidate.health >= candidate.max_health)
				or (mode == "unwounded" and candidate.wound_time > 0.0)
				or (mode == "deferred" and (candidate.wound_damage <= 0.0 or candidate.wound_time <= 0.0))):
			filtered = true
			continue
		var distance = origin.distance_squared_to(candidate.position)
		if distance > reach * reach:
			beyond_reach = true
			continue
		if not _has_sight(origin, candidate.position):
			obstructed = true
			continue
		var score = distance
		if ally and mode != "nearest":
			score = float(candidate.health) / float(candidate.max_health) * 1000.0 + distance
		if score < best_score:
			best = candidate
			best_score = score
	if not _pending_cast.is_empty() and not best.is_empty() and _pending_cast.target_id == -1:
		if _pending_cast.target_kind == targeted_side:
			_pending_cast.target_id = best.id
			_pending_cast.destination = best.position
	if explain:
		if not best.is_empty():
			last_cast_failure = ""
		elif obstructed:
			last_cast_failure = "sight"
		elif beyond_reach:
			last_cast_failure = "range"
		elif filtered and mode == "injured":
			last_cast_failure = "injured_ally"
		elif filtered:
			last_cast_failure = "setup"
		else:
			last_cast_failure = targeted_side
	return best


func _closest_enemy(fighter: Dictionary) -> Dictionary:
	var closest: Dictionary = {}
	var shortest = INF
	var position: Vector2 = fighter.position
	for enemy in fighters:
		if enemy.team == fighter.team or not enemy.alive:
			continue
		var distance = position.distance_squared_to(enemy.position)
		if distance < shortest:
			closest = enemy
			shortest = distance
	return closest


func _step_bot(bot: Dictionary, delta: float) -> void:
	var enemy = _closest_enemy(bot)
	if enemy.is_empty():
		return
	var origin: Vector2 = bot.position
	var toward = (enemy.position as Vector2) - origin
	var distance = toward.length()
	var heading = toward.normalized()
	_face(bot, enemy.position)
	var preferred = 2.15
	if CLASS_INFO[bot.class_id].archetype in ["healer", "ranged"]:
		preferred = 6.6
	var direction = Vector2.ZERO
	var moving_to_safety: bool = origin.length() > safe_radius - 0.5
	if moving_to_safety:
		direction = -origin.normalized()
	else:
		if distance > preferred + 0.35 or not _has_sight(origin, enemy.position):
			direction = heading
		elif distance < preferred - 0.65:
			direction = -heading if preferred > 3.0 else heading.orthogonal()
		if mobile_mode:
			var objective_direction: Variant = ArenaObjectives.bot_direction(self, bot)
			if objective_direction is Vector2:
				direction = objective_direction
		var avoidance := ArenaMaps.avoidance_direction(self, origin, direction)
		if not avoidance.is_zero_approx():
			direction = avoidance
			moving_to_safety = true
		if mobile_mode and not moving_to_safety:
			var ultimate_escape := _bot_ultimate_escape(bot)
			if not ultimate_escape.is_zero_approx():
				direction = ultimate_escape
				moving_to_safety = true
	if not moving_to_safety and bot.bot_wait <= 0.0:
		var interval := MOBILE_BOT_ACTION_INTERVAL if mobile_mode else 0.25
		bot.bot_wait = interval + float(int(bot.id) % 3) * 0.045
		if _bot_ability(bot, enemy, distance):
			return
	if _blocked(origin + direction * 1.2, 0.35):
		var turn = 1.35 if int(bot.id) % 2 == 0 else -1.35
		direction = direction.rotated(turn)
	_move(bot, direction * float(CLASS_INFO[bot.class_id].speed) * _movement_factor(bot) * 0.9 * delta)


func _bot_ability(bot: Dictionary, enemy: Dictionary, distance: float) -> bool:
	var kit: Dictionary = CLASS_INFO[bot.class_id]
	if distance > 11.0:
		return false
	if mobile_mode and _ultimate_blocker_for(bot).is_empty():
		var spec: Dictionary = ArenaUltimates.KITS[bot.class_id]
		var preview := ArenaUltimates.warning(self, bot, enemy.id if spec.side == "enemy" else -1)
		if ArenaUltimates.can_usefully_resolve(self, preview):
			return _begin_ultimate(bot, preview)
	for slot in kit.get("priority", [7, 6, 5, 4, 3, 2, 1, 0]):
		var skill: Dictionary = bot.abilities[slot]
		var target_id: int = enemy.id if skill.target == "enemy" else -1
		if _use_ability(bot, slot, target_id):
			return true
	return false


func _bot_ultimate_escape(bot: Dictionary) -> Vector2:
	var origin: Vector2 = bot.position
	for preview in ultimate_windups:
		if preview.team == bot.team or preview.target_kind == "ally" or not ArenaUltimates.contains(preview, origin, 0.45):
			continue
		# Some bots react sooner than others, giving a planted cast a fair shot.
		if preview.duration - preview.remaining < 0.20 + float(int(bot.id) % 3) * 0.12:
			continue
		var center := ArenaUltimates.closest_point(preview, origin)
		var away := (origin - center).normalized()
		return away if not away.is_zero_approx() else (bot.facing as Vector2).orthogonal()
	return Vector2.ZERO


func _face(fighter: Dictionary, point: Vector2) -> void:
	var offset = point - (fighter.position as Vector2)
	if offset.length_squared() > 0.001:
		fighter.facing = offset.normalized()


func _move(fighter: Dictionary, distance: Vector2, allow_glancing: bool = true) -> void:
	if distance.length_squared() <= 0.000001:
		return
	var increments = maxi(1, ceili(distance.length() / 0.25))
	var stride = distance / float(increments)
	var position: Vector2 = fighter.position
	for unused_index in range(increments):
		var next = ArenaMaps.constrain(map_id, position + stride, ArenaMaps.FIGHTER_PADDING)
		if not _blocked(next, 0.3):
			position = next
			continue
		if not allow_glancing:
			break
		var x_only = ArenaMaps.constrain(map_id, position + Vector2(stride.x, 0.0), ArenaMaps.FIGHTER_PADDING)
		var y_only = ArenaMaps.constrain(map_id, position + Vector2(0.0, stride.y), ArenaMaps.FIGHTER_PADDING)
		if not _blocked(x_only, 0.3):
			position = x_only
		elif not _blocked(y_only, 0.3):
			position = y_only
	fighter.position = position


func _blocked(point: Vector2, padding: float) -> bool:
	for obstacle in terrain:
		var clearance: float = obstacle.radius + padding
		if point.distance_squared_to(obstacle.position) < clearance * clearance:
			return true
	return false


func _has_sight(start: Vector2, end: Vector2) -> bool:
	if start.distance_squared_to(end) <= 0.000001:
		return true
	for obstacle in terrain:
		var closest := Geometry2D.get_closest_point_to_segment(obstacle.position, start, end)
		if closest.distance_squared_to(obstacle.position) < obstacle.radius * obstacle.radius:
			return false
	return map_id != "observatory" or not ArenaMaps.veil_blocks(environment_zones, start, end)


func _fighter_name(fighter: Dictionary) -> String:
	if fighter.id == 0:
		return "You"
	var team_name = "Allied" if fighter.team == 0 else "Rival"
	return "%s %s" % [team_name, CLASS_INFO[fighter.class_id].name]


func _announce(message: String) -> void:
	feed.push_front(message)
	if feed.size() > 6:
		feed.pop_back()


func heal(source: Dictionary, target: Dictionary, amount: float) -> bool:
	if not target.alive or amount <= 0.0 or target.health >= target.max_health:
		return false
	_note_affected(target)
	var restored := minf(amount, float(target.max_health) - float(target.health))
	if mobile_mode:
		var healable: float = target.get("ultimate_healable", 0.0)
		var combat_healed := minf(restored, healable)
		_gain_ultimate(source, combat_healed * ULTIMATE_HEAL_CHARGE)
		target.ultimate_healable = maxf(0.0, healable - combat_healed)
	target.health += restored
	return true


func shield(target: Dictionary, amount: float, seconds: float, source_id: int = -1) -> void:
	if target.alive and amount >= target.shield_hp:
		_note_affected(target)
		target.shield_hp = amount
		target.shield_time = seconds
		target.shield_source = _pending_cast.get("source_id", target.id) if source_id < 0 else source_id


func interrupt(target: Dictionary) -> void:
	_cancel_ultimate(target)
	target.mend_time = 0.0
	target.mend_target = -1


func afflict(target: Dictionary, kind: String, seconds: float, power: float = 0.0, source_id: int = -1) -> void:
	if not target.alive or seconds <= 0.0:
		return
	if kind == "silence":
		interrupt(target)
	var key := "%d/%s" % [source_id, kind]
	target.statuses[key] = {"kind":kind, "remaining":seconds, "power":power, "source":source_id}


static func has_status(fighter: Dictionary, kind: String) -> bool:
	for effect in fighter.get("statuses", {}).values():
		if effect.kind == kind:
			return true
	return false


func _power(fighter: Dictionary, kind: String) -> float:
	var strongest := 0.0
	for effect in fighter.statuses.values():
		if effect.kind == kind:
			strongest = maxf(strongest, effect.power)
	return strongest


func _movement_factor(fighter: Dictionary) -> float:
	if has_status(fighter, "root"):
		return 0.0
	var slow := maxf(_power(fighter, "slow"), ArenaMaps.tide_slow(self, fighter.position))
	return (1.0 + _power(fighter, "haste")) * (1.0 - clampf(slow, 0.0, 0.9))


func mark(source: Dictionary, target: Dictionary, key: String, seconds: float) -> void:
	target.marks["%d/%s" % [source.id, key]] = seconds


func marked(source: Dictionary, target: Dictionary, key: String) -> bool:
	return target.marks.has("%d/%s" % [source.id, key])


func consume_mark(source: Dictionary, target: Dictionary, key: String) -> bool:
	return target.marks.erase("%d/%s" % [source.id, key])


func _tick_effects(fighter: Dictionary, delta: float) -> void:
	fighter.shield_time = maxf(0.0, fighter.shield_time - delta)
	if fighter.shield_time <= 0.0:
		fighter.shield_hp = 0.0
	for key in fighter.marks.keys():
		fighter.marks[key] -= delta
		if fighter.marks[key] <= 0.0:
			fighter.marks.erase(key)
	for key in fighter.statuses.keys():
		var effect: Dictionary = fighter.statuses[key]
		var dt := minf(delta, effect.remaining)
		var source: Dictionary = fighters[effect.source] if effect.source >= 0 else fighter
		if effect.kind == "burn":
			var burn: float = dt * effect.power * (1.0 - clampf(_power(source, "weaken"), 0.0, 0.9))
			if mobile_mode:
				burn *= _mobile_damage_modifier(source, fighter)
			_receive_damage(fighter, burn, false, source)
		elif effect.kind == "regen":
			heal(source, fighter, dt * effect.power)
		effect.remaining -= dt
		if effect.remaining <= 0.0:
			fighter.statuses.erase(key)


func aim_point(source: Dictionary, reach: float) -> Vector2:
	var origin: Vector2 = source.position
	var facing: Vector2 = source.facing
	var steps := maxi(1, ceili(reach / 0.25))
	var point := origin
	for step_index in range(1, steps + 1):
		var next := ArenaMaps.constrain(map_id, origin + facing * (reach * step_index / steps), ArenaMaps.FIGHTER_PADDING)
		if _blocked(next, 0.1) or (map_id == "observatory" and not _has_sight(origin, next)):
			break
		point = next
	return point


func place_field(source: Dictionary, kind: String, point: Vector2, radius: float, seconds: float, power: float) -> Dictionary:
	var field := {
		"source":source.id, "team":source.team, "kind":kind, "position":ArenaMaps.constrain(map_id, point),
		"name":_pending_cast.get("name", ""), "radius":radius, "remaining":seconds, "power":power, "pulse":0.0
	}
	fields.append(field)
	set_cast_destination(field.position)
	return field


func set_cast_destination(point: Vector2) -> void:
	if not _pending_cast.is_empty():
		_pending_cast.destination = point


func _tick_fields(delta: float) -> void:
	for index in range(fields.size() - 1, -1, -1):
		var field := fields[index]
		if field.remaining <= 0.0:
			fields.remove_at(index)
			continue
		var dt := minf(delta, field.remaining)
		var source: Dictionary = fighters[field.source]
		field.pulse -= dt
		for fighter in fighters:
			var friendly: bool = field.team == fighter.team
			var position: Vector2 = fighter.position
			if not fighter.alive or position.distance_squared_to(field.position) > field.radius * field.radius:
				continue
			if not _has_sight(field.position, position):
				continue
			match field.kind:
				"damage":
					if not friendly:
						_deal_damage(source, fighter, field.power * dt)
				"heal":
					if friendly:
						heal(source, fighter, field.power * dt)
				"ward":
					if friendly and field.pulse <= 0.0:
						shield(fighter, field.power, 1.05, source.id)
				"slow":
					if not friendly:
						afflict(fighter, "slow", 0.15, field.power, field.source)
		if field.pulse <= 0.0:
			field.pulse += 1.0
		field.remaining -= dt
		if field.remaining <= 0.0:
			fields.remove_at(index)


func cleanse(fighter: Dictionary, kinds: Array) -> int:
	var cleared := 0
	for key in fighter.statuses.keys():
		if fighter.statuses[key].kind in kinds:
			fighter.statuses.erase(key)
			cleared += 1
	return cleared


func _note_affected(target: Dictionary) -> void:
	if not _pending_cast.is_empty() and target.id not in _pending_cast.affected_ids:
		_pending_cast.affected_ids.append(target.id)
		_pending_cast.affected_positions[target.id] = target.position
