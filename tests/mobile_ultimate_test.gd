extends SceneTree

const ArenaMatch = preload("res://scripts/arena_match.gd")
const ArenaUltimates = preload("res://scripts/arena_ultimates.gd")

var checks := 0
var failures := 0


func _initialize() -> void:
	var distinct_patterns := {}
	for class_id: String in ArenaMatch.CLASS_INFO:
		_check(ArenaUltimates.KITS.has(class_id), "%s has an ultimate" % class_id)
		var spec: Dictionary = ArenaUltimates.KITS[class_id]
		distinct_patterns[spec.pattern] = true
		_check_ultimate(class_id, spec)
	_check(distinct_patterns.size() == 16, "The roster has sixteen distinct ultimate presentations")
	_check_charge()
	_check_counterplay()
	_check_reset_and_desktop()
	print("Mobile ultimates: %d/%d checks passed" % [checks - failures, checks])
	quit(1 if failures else 0)


func _fixture(class_id: String, mobile: bool = true) -> ArenaMatch:
	var match_game := ArenaMatch.new()
	match_game.mobile_mode = mobile
	match_game.start_match(class_id, 701)
	match_game.terrain.clear()
	var places := [Vector2.ZERO, Vector2(1.1, 0.2), Vector2(1.8, -1), Vector2(2.0, 0), Vector2(2.5, 0.9), Vector2(2.8, -1)]
	for fighter in match_game.fighters:
		fighter.position = places[fighter.id]
		fighter.facing = Vector2.RIGHT
		fighter.stun = 25.0 if fighter.id != 0 else 0.0
		fighter.break_free_available = false
		fighter.health = fighter.max_health * 0.66
	return match_game


func _check_ultimate(class_id: String, spec: Dictionary) -> void:
	var match_game := _fixture(class_id)
	var actor: Dictionary = match_game.fighters[0]
	var ally: Dictionary = match_game.fighters[1]
	var rival: Dictionary = match_game.fighters[3]
	var rival_before: float = rival.health
	var ally_before: float = ally.health
	var rival_position: Vector2 = rival.position
	var selected := 1 if spec.side == "ally" else 3
	actor.ultimate_charge = 100.0
	_check(match_game.try_ultimate(selected), "%s can start its ultimate" % class_id)
	_check(match_game.ultimate_blocker() == "winding_up" and match_game.ultimate_windups.size() == 1, "%s exposes one live warning" % class_id)
	if match_game.ultimate_windups.is_empty():
		return
	var warning: Dictionary = match_game.ultimate_windups.front()
	_check(warning.duration >= 0.65 and warning.source_id == 0 and warning.radius == spec.radius and warning.destination.is_finite(),
		"%s exposes the committed ground geometry" % class_id)
	_check(not match_game.try_ultimate(selected) and not match_game.try_dodge(Vector2.RIGHT) and match_game.cast_events.is_empty(),
		"%s cannot double-cast or dodge while winding up" % class_id)
	match_game.step(float(spec.windup) - 0.03, Vector2.RIGHT, Vector2.RIGHT)
	_check(match_game.cast_events.is_empty() and actor.position == Vector2.ZERO and rival.health == rival_before,
		"%s deals nothing while warning and keeps the caster planted" % class_id)
	match_game.step(0.045, Vector2.ZERO, Vector2.RIGHT)
	var releases := match_game.cast_events.filter(func(event: Dictionary): return event.get("ultimate", false))
	_check(releases.size() == 1 and match_game.ultimate_windups.is_empty() and match_game.ultimate_blocker() == "used",
		"%s resolves exactly once and marks the ultimate spent" % class_id)
	if releases.is_empty():
		return
	var event: Dictionary = releases.front()
	_check(event.ultimate and event.slot == ArenaUltimates.SLOT and event.name == spec.name and event.destination == warning.destination,
		"%s publishes a dedicated release event at the marked point" % class_id)
	_check(not event.affected_positions.is_empty() and event.affected_ids.size() == event.affected_positions.size(),
		"%s reports the actual affected units to presentation" % class_id)
	match class_id:
		"breakwater":
			_check(ally.shield_hp >= 95.0 and rival.position.distance_to(rival_position) > 1.0, "The Drowned Gate guards allies and pushes rivals")
		"threadkeeper":
			_check(ally.health > ally_before and ally.stun == 0.0 and match_game.has_status(ally, "regen"), "The Last Thread restores allies and control")
		"echo_duelist":
			_check(event.shape == "line" and actor.position.x > 5.0 and rival.health < rival_before, "A Thousand Final Cuts uses a real dash lane")
		"forgecaller":
			_check(rival.health < rival_before and _named_field(match_game, event.name, "damage"), "Godfall Hammer leaves a burning crater")
		"lamplighter":
			_check(ally.health > ally_before and _named_field(match_game, event.name, "ward"), "The Last Sunrise heals and leaves a sanctuary")
		"longwatch":
			_check(rival.health < rival_before and match_game.has_status(rival, "slow"), "The Sky Is a Killing Field wounds and slows")
		"sluicecaller":
			_check(match_game.fighters[4].position.distance_to(event.destination) < 0.66 and _named_field(match_game, event.name, "slow"),
				"Drown the Court moves a second rival toward the whirlpool")
		"glassmage":
			_check(rival.health < rival_before and match_game.has_status(rival, "root"), "Cathedral of Shards roots the center")
		"blood_cantor":
			_check(rival.health < rival_before and ally.health > ally_before, "Red Communion converts real damage into nearby ally healing")
		"bellwarden":
			_check(match_game.has_status(rival, "silence") and match_game.has_status(ally, "haste"), "The Ninth Toll silences rivals and hastes allies")
		"ash_dancer":
			_check(match_game.has_status(rival, "burn") and match_game.has_status(actor, "haste"), "Dance of the Black Sun burns rivals and accelerates the caster")
		"winter_scribe":
			_check(match_game.has_status(rival, "root") and _named_field(match_game, event.name, "slow"), "The Last Winter roots and leaves ice")
		"dream_shepherd":
			_check(ally.stun == 0.0 and ally.shield_hp >= 110.0 and match_game.has_status(ally, "fortify"), "Throne Beyond Sleep wakes and guards allies")
		"chainrunner":
			_check(rival.position.distance_to(Vector2.ZERO) < 0.75 and match_game.has_status(rival, "root"), "The Gallows Choir drags rivals toward the caster")
		"coilwright":
			_check(rival.health < rival_before and match_game.marked(actor, rival, "polarized"), "Thunder the Dead primes conductors")
		"duskmoth":
			_check(actor.evade > 0.0 and match_game.has_status(rival, "weaken") and match_game.marked(actor, rival, "dusted"),
				"A Sky of Hungry Wings weakens rivals while the caster evades")


func _named_field(match_game: ArenaMatch, field_name: String, kind: String) -> bool:
	return match_game.fields.any(func(field: Dictionary): return field.name == field_name and field.kind == kind)


func _check_charge() -> void:
	var match_game := _fixture("breakwater")
	var actor: Dictionary = match_game.fighters[0]
	var ally: Dictionary = match_game.fighters[1]
	var rival: Dictionary = match_game.fighters[3]
	_check(match_game.ultimate_blocker() == "charge" and not match_game.try_ultimate(), "A round begins without a ready ultimate")
	match_game.step(5.0, Vector2.ZERO, Vector2.RIGHT)
	_check(actor.ultimate_charge == 0.0, "Time alone generates no ultimate charge")
	match_game._apply_damage(actor, 16.0)
	_check(actor.ultimate_charge == 0.0, "Environmental damage does not generate ultimate charge")
	match_game.heal(actor, actor, 16.0)
	_check(actor.ultimate_charge == 0.0, "Healing environmental damage cannot farm ultimate charge")
	match_game._deal_damage(actor, rival, 20.0)
	_check(actor.ultimate_charge > 0.0 and rival.ultimate_charge > 0.0, "Real combat charges attacker and defender")
	var charge: float = actor.ultimate_charge
	match_game._deal_damage(rival, ally, 14.0)
	var ally_health: float = ally.health
	match_game.heal(actor, ally, 14.0)
	_check(actor.ultimate_charge > charge and ally.health > ally_health, "Effective ally healing generates charge")
	ally.health = ally.max_health
	charge = actor.ultimate_charge
	match_game.heal(actor, ally, 14.0)
	_check(actor.ultimate_charge == charge, "Overhealing generates no charge")
	match_game.shield(ally, 35.0, 4.0, actor.id)
	match_game._deal_damage(rival, ally, 15.0)
	_check(actor.ultimate_charge > charge, "An absorbed shield grants charge to the champion who cast it")
	match_game._gain_ultimate(actor, 1_000.0)
	_check(actor.ultimate_charge == ArenaUltimates.CHARGE_REQUIRED, "Charge cannot exceed the ready threshold")


func _check_counterplay() -> void:
	var match_game := _fixture("forgecaller")
	var actor: Dictionary = match_game.fighters[0]
	var rival: Dictionary = match_game.fighters[3]
	actor.ultimate_charge = 100.0
	match_game.afflict(actor, "silence", 1.0)
	_check(match_game.ultimate_blocker() == "silence" and not match_game.try_ultimate(3) and actor.ultimate_charge == 100.0,
		"Silence stops activation without consuming a ready ultimate")
	match_game.cleanse(actor, ["silence"])
	_check(match_game.try_ultimate(3), "Forgecaller begins the meteor warning")
	var start: Vector2 = match_game.ultimate_windups[0].destination
	var rival_health: float = rival.health
	rival.position = start + Vector2(0, 5)
	match_game.step(1.08, Vector2.ZERO, Vector2.RIGHT)
	_check(rival.health == rival_health and match_game.cast_events.front().destination == start, "Moving out dodges, and does not retarget, Godfall Hammer")

	match_game = _fixture("forgecaller")
	actor = match_game.fighters[0]
	actor.ultimate_charge = 100.0
	match_game.try_ultimate(3)
	match_game.interrupt(actor)
	match_game.step(1.08, Vector2.ZERO, Vector2.RIGHT)
	_check(match_game.ultimate_windups.is_empty() and match_game.cast_events.is_empty() and match_game.ultimate_blocker() == "used",
		"Interrupting the windup removes its warning and spends the attempt without an impact")


func _check_reset_and_desktop() -> void:
	var match_game := _fixture("breakwater")
	match_game.fighters[0].ultimate_charge = 100.0
	match_game.try_ultimate()
	for fighter in match_game.fighters.slice(3):
		fighter.alive = false
	match_game.step(0.05, Vector2.ZERO, Vector2.RIGHT)
	_check(match_game.ultimate_windups.is_empty(), "The round end clears old warnings immediately")
	match_game.next_round()
	_check(match_game.ultimate_blocker() == "charge" and not match_game.fighters[0].ultimate_used, "A new round resets the once-per-round charge")
	var desktop := _fixture("breakwater", false)
	desktop.fighters[0].ultimate_charge = 100.0
	_check(desktop.round_duration() == 60.0 and desktop.ultimate_blocker() == "inactive" and not desktop.try_ultimate(),
		"The existing desktop rules stay at sixty seconds without mobile ultimates")


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)
