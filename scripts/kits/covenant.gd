extends RefCounted

const KITS = {
	"blood_cantor": {
		"name": "Blood Cantor",
		"role": "Sacrificial healer",
		"archetype": "healer",
		"resource": "Fervor",
		"passive": "Siphon Note restores health and leaves a blood sample. Spend your health to build Fervor through Blood Offering or Votive Knot. Reap the sample to replenish your health before the next sacrifice.",
		"counterplay": "Pressure the Cantor after a sacrifice, break sight before Red Refrain, and force the team apart during Fervent Chorus.",
		"max_health": 110.0,
		"speed": 4.6,
		"priority": [7, 1, 6, 2, 3, 5, 4, 0],
		"abilities": [
			{"name": "Siphon Note", "description": "Deal 11 damage within 8 m. A hit restores 4 health and samples the target for 6 s.", "cooldown": 1.1, "target": "enemy", "cost": 0, "gain": 8},
			{"name": "Blood Offering", "description": "Pay 8 health to heal a wounded ally within 8 m for 28. You can sing it on yourself.", "cooldown": 3.8, "target": "ally", "cost": 0, "gain": 10},
			{"name": "Kindred Pulse", "description": "Restore 5 health per second to a wounded ally within 8 m for 4 s.", "cooldown": 6.5, "target": "ally", "cost": 14, "gain": 0},
			{"name": "Votive Knot", "description": "Pay 7 health to shield an ally within 7 m for 22 damage over 4 s.", "cooldown": 7.5, "target": "ally", "cost": 0, "gain": 8},
			{"name": "Cut the Verse", "description": "Interrupt an enemy within 6 m and silence them for 1.2 s.", "cooldown": 10.0, "target": "enemy", "cost": 16, "gain": 0},
			{"name": "Fervent Chorus", "description": "Place a 3.5 m chorus at your feet that heals allies for 6 per second for 4 s.", "cooldown": 13.0, "target": "self", "cost": 24, "gain": 0},
			{"name": "Red Refrain", "description": "Reap your sample on an enemy within 8 m. Deal 16 damage and restore 18 health on a hit.", "cooldown": 6.0, "target": "enemy", "cost": 10, "gain": 0},
			{"name": "Last Measure", "description": "Pay 12 health and heal a wounded ally within 7 m for 22 plus half their missing health (up to 52 total).", "cooldown": 16.0, "target": "ally", "cost": 40, "gain": 0},
		],
	},
	"bellwarden": {
		"name": "Bellwarden",
		"role": "Resonance guardian",
		"archetype": "guard",
		"resource": "Resonance",
		"passive": "Tonguehammer leaves a ringing note on hit. Tocsin can cash it in for a silence. Build Resonance with hammer strikes and Dampen, then spend it to protect allies.",
		"counterplay": "Pull the fight away from allied wards, kite Tonguehammer, and wait out the ringing note to deny the silence.",
		"max_health": 142.0,
		"speed": 4.4,
		"priority": [7, 4, 2, 3, 5, 6, 1, 0],
		"abilities": [
			{"name": "Tonguehammer", "description": "Deal 15 melee damage and leave a ringing note for 5 s.", "cooldown": 1.1, "target": "enemy", "cost": 0, "gain": 10},
			{"name": "Shelterbell", "description": "Give an ally within 7 m an 18-point shield for 4 s.", "cooldown": 5.5, "target": "ally", "cost": 12, "gain": 0},
			{"name": "Tocsin", "description": "Sound a 12-damage note within 6 m. Cash in a ringing note on hit to interrupt and silence for 1.4 s.", "cooldown": 6.0, "target": "enemy", "cost": 14, "gain": 0},
			{"name": "Bellwake", "description": "Deal 9 damage and knock enemies within 3.5 m away from you by 2 m.", "cooldown": 9.0, "target": "self", "cost": 12, "gain": 0},
			{"name": "Intercede", "description": "Move toward another ally within 6 m. While close, redirect 35% of their incoming direct damage for 3 s.", "cooldown": 9.0, "target": "ally", "cost": 12, "gain": 0},
			{"name": "Dampen", "description": "Weaken an enemy within 5 m, reducing outgoing damage by 28% for 2.5 s.", "cooldown": 8.0, "target": "enemy", "cost": 0, "gain": 8},
			{"name": "Tempered Footing", "description": "Clear your root and slow, then gain a 16-point shield for 3 s.", "cooldown": 11.0, "target": "self", "cost": 18, "gain": 0},
			{"name": "Grand Toll", "description": "Shield nearby allies for 26 over 4 s and deal 18 damage to nearby enemies. The toll reaches 4 m.", "cooldown": 17.0, "target": "self", "cost": 45, "gain": 0},
		],
	},
	"ash_dancer": {
		"name": "Ash Dancer",
		"role": "Mobile melee striker",
		"archetype": "melee",
		"resource": "Embers",
		"passive": "Flint Heel brands a target for 5 s. Rake the Ember spends the brand on sustained damage, while Furnace Turn spends it on a burst. Build Embers by staying in reach.",
		"counterplay": "Keep the Dancer at range, separate before Furnace Turn, or evade the follow-up after a brand.",
		"max_health": 106.0,
		"speed": 5.15,
		"priority": [7, 2, 4, 1, 5, 6, 3, 0],
		"abilities": [
			{"name": "Flint Heel", "description": "Deal 14 melee damage. A hit brands the target for 5 s.", "cooldown": 0.95, "target": "enemy", "cost": 0, "gain": 10},
			{"name": "Cross the Coals", "description": "Rush up to 4 m toward a foe within 6 m. Strike for 11 damage if you reach melee range.", "cooldown": 5.5, "target": "enemy", "cost": 0, "gain": 6},
			{"name": "Rake the Ember", "description": "Consume your brand on a melee target on hit, dealing 6 damage and burning for 5 per second over 4 s.", "cooldown": 5.0, "target": "enemy", "cost": 12, "gain": 0},
			{"name": "Cinderwheel", "description": "Dash 2.5 m in your aim direction and gain 30% move speed for 1.5 s.", "cooldown": 7.0, "target": "aim", "cost": 10, "gain": 0},
			{"name": "Snuff", "description": "Deal 7 melee damage. A hit interrupts and silences for 1.2 s.", "cooldown": 9.0, "target": "enemy", "cost": 15, "gain": 0},
			{"name": "Firebreak", "description": "Leave a 2.6 m patch of fire at your feet for 4 s. Enemies inside take 5 damage per second.", "cooldown": 9.0, "target": "self", "cost": 15, "gain": 0},
			{"name": "Backdraft", "description": "Kick a melee target for 9 damage and knock it back 2 m on hit. Recoil 2 m away.", "cooldown": 8.0, "target": "enemy", "cost": 0, "gain": 5},
			{"name": "Furnace Turn", "description": "Strike a melee target and foes within 2 m of them for 24. Consume each branded target's brand on hit for 12 extra damage.", "cooldown": 14.0, "target": "enemy", "cost": 40, "gain": 0},
		],
	},
	"winter_scribe": {
		"name": "Winter Scribe",
		"role": "Frost control caster",
		"archetype": "ranged",
		"resource": "Ink",
		"passive": "Cold Quill builds Ink and hits harder inside your active seal. Inscribe one seal at a time. Keep it to improve control, step to it, or spend it on an eruption.",
		"counterplay": "Leave the seal before the Scribe can break it. Use cover to interrupt sightlines and pressure the Scribe after its return point is spent.",
		"max_health": 103.0,
		"speed": 4.6,
		"priority": [7, 5, 2, 1, 6, 4, 3, 0],
		"abilities": [
			{"name": "Cold Quill", "description": "Deal 12 damage within 8.5 m, plus 7 if the target stands in your seal.", "cooldown": 0.95, "target": "enemy", "cost": 0, "gain": 9},
			{"name": "Lay the Seal", "description": "Inscribe a 2.8 m seal in front of you for 7 s. Enemies inside are slowed by 30%. Replaces your previous seal.", "cooldown": 5.0, "target": "aim", "cost": 0, "gain": 8},
			{"name": "Break the Seal", "description": "Shatter your occupied seal for 24 damage to enemies inside. Requires sight of the seal.", "cooldown": 6.5, "target": "self", "cost": 18, "gain": 0},
			{"name": "Margin Step", "description": "Return up to 8 m toward your seal, stopping at cover. This consumes the seal.", "cooldown": 9.0, "target": "self", "cost": 12, "gain": 0},
			{"name": "Vellum Ward", "description": "Shield an ally within 8 m for 15 over 4 s, increased to 27 inside your seal.", "cooldown": 7.0, "target": "ally", "cost": 15, "gain": 0},
			{"name": "Crosshatch", "description": "Deal 7 damage within 8 m. On hit, slow by 35% for 2.5 s or root a target inside your seal for 1.2 s.", "cooldown": 8.0, "target": "enemy", "cost": 14, "gain": 0},
			{"name": "Blot", "description": "Weaken a foe within 8 m by 22% for 3 s. Also interrupt its cast if it stands in your seal.", "cooldown": 9.0, "target": "enemy", "cost": 0, "gain": 5},
			{"name": "Final Impression", "description": "Transform your visible seal into a 2.8 m frost storm dealing 8 damage per second for 5 s.", "cooldown": 14.0, "target": "self", "cost": 42, "gain": 0},
		],
	},
}


static func cast(game, f: Dictionary, slot: int, target_id: int) -> bool:
	match f.class_id:
		"blood_cantor":
			return _cantor(game, f, slot, target_id)
		"bellwarden":
			return _bellwarden(game, f, slot, target_id)
		"ash_dancer":
			return _ash_dancer(game, f, slot, target_id)
		"winter_scribe":
			return _winter_scribe(game, f, slot, target_id)
	return false


static func _nearby(game, point: Vector2, radius: float, team: int) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for fighter in game.fighters:
		if fighter.alive and fighter.team == team:
			if point.distance_squared_to(fighter.position) <= radius * radius and game._has_sight(point, fighter.position):
				found.append(fighter)
	return found


static func _cantor(game, f: Dictionary, slot: int, target_id: int) -> bool:
	if slot == 5:
		game.place_field(f, "heal", f.position, 3.5, 4.0, 6.0)
		return true
	if slot in [0, 4, 6]:
		var reach := 6.0 if slot == 4 else 8.0
		var enemy: Dictionary = game._target(f, target_id, false, reach)
		if enemy.is_empty():
			return false
		match slot:
			0:
				if game._deal_damage(f, enemy, 11.0):
					game.heal(f, f, 4.0)
					if enemy.alive:
						game.mark(f, enemy, "blood_sample", 6.0)
			4:
				if game._deal_damage(f, enemy, 0.0):
					game.interrupt(enemy)
					game.afflict(enemy, "silence", 1.2)
			6:
				if not game.marked(f, enemy, "blood_sample"):
					return false
				if game._deal_damage(f, enemy, 16.0):
					game.consume_mark(f, enemy, "blood_sample")
					game.heal(f, f, 18.0)
		return true
	var reach := 7.0 if slot in [3, 7] else 8.0
	var mode := "nearest" if slot == 3 else "injured"
	var ally: Dictionary = game._target(f, target_id, true, reach, mode)
	if ally.is_empty():
		return false
	var price: float = {1: 8.0, 2: 0.0, 3: 7.0, 7: 12.0}.get(slot, INF)
	if f.health <= price:
		return false
	var missing: float = ally.max_health - ally.health
	f.health -= price
	match slot:
		1:
			game.heal(f, ally, 28.0)
		2:
			game.afflict(ally, "regen", 4.0, 5.0, f.id)
		3:
			game.shield(ally, 22.0, 4.0)
		7:
			game.heal(f, ally, minf(52.0, 22.0 + missing * 0.5))
	return true


static func _bellwarden(game, f: Dictionary, slot: int, target_id: int) -> bool:
	var origin: Vector2 = f.position
	match slot:
		0, 2, 5:
			var reach: float = {0: 3.0, 2: 6.0, 5: 5.0}[slot]
			var foe: Dictionary = game._target(f, target_id, false, reach)
			if foe.is_empty():
				return false
			match slot:
				0:
					if game._deal_damage(f, foe, 15.0) and foe.alive:
						game.mark(f, foe, "ringing_bell", 5.0)
				2:
					if game._deal_damage(f, foe, 12.0) and foe.alive and game.consume_mark(f, foe, "ringing_bell"):
						game.interrupt(foe)
						game.afflict(foe, "silence", 1.4)
				5:
					if game._deal_damage(f, foe, 0.0):
						game.afflict(foe, "weaken", 2.5, 0.28, f.id)
		1:
			var ally: Dictionary = game._target(f, target_id, true, 7.0)
			if ally.is_empty():
				return false
			game.shield(ally, 18.0, 4.0)
		3:
			var foes := _nearby(game, origin, 3.5, 1 - int(f.team))
			if foes.is_empty():
				return false
			for foe in foes:
				if game._deal_damage(f, foe, 9.0) and foe.alive:
					game._move(foe, origin.direction_to(foe.position) * 2.0, false)
		4:
			var ally: Dictionary = game._target(f, target_id, true, 6.0, "ally_other")
			if ally.is_empty():
				return false
			game._move(f, (ally.position - origin) * 0.8, false)
			f.guard_target = ally.id
			f.guard_time = 3.0
		6:
			game.cleanse(f, ["root", "slow"])
			game.shield(f, 16.0, 3.0)
		7:
			for ally in _nearby(game, origin, 4.0, f.team):
				game.shield(ally, 26.0, 4.0)
			for foe in _nearby(game, origin, 4.0, 1 - int(f.team)):
				game._deal_damage(f, foe, 18.0)
		_:
			return false
	return true


static func _ash_dancer(game, f: Dictionary, slot: int, target_id: int) -> bool:
	var origin: Vector2 = f.position
	if slot == 3:
		game._move(f, (f.facing as Vector2) * 2.5, false)
		game.afflict(f, "haste", 1.5, 0.30, f.id)
		return true
	if slot == 5:
		game.place_field(f, "damage", origin, 2.6, 4.0, 5.0)
		return true
	var reach := 6.0 if slot == 1 else 3.0
	var foe: Dictionary = game._target(f, target_id, false, reach)
	if foe.is_empty():
		return false
	var toward := origin.direction_to(foe.position)
	match slot:
		0:
			if game._deal_damage(f, foe, 14.0) and foe.alive:
				game.mark(f, foe, "ash_brand", 5.0)
		1:
			var travel := minf(4.0, maxf(0.0, origin.distance_to(foe.position) - 1.4))
			game._move(f, toward * travel, false)
			if (f.position as Vector2).distance_to(foe.position) <= 3.0 and game._has_sight(f.position, foe.position):
				game._deal_damage(f, foe, 11.0)
		2:
			if not game.marked(f, foe, "ash_brand"):
				return false
			if game._deal_damage(f, foe, 6.0) and foe.alive:
				game.consume_mark(f, foe, "ash_brand")
				game.afflict(foe, "burn", 4.0, 5.0, f.id)
		4:
			if game._deal_damage(f, foe, 7.0) and foe.alive:
				game.interrupt(foe)
				game.afflict(foe, "silence", 1.2)
		6:
			if game._deal_damage(f, foe, 9.0) and foe.alive:
				game._move(foe, toward * 2.0, false)
			game._move(f, -toward * 2.0, false)
		7:
			for target in _nearby(game, foe.position, 2.0, foe.team):
				var branded: bool = game.marked(f, target, "ash_brand")
				if game._deal_damage(f, target, 36.0 if branded else 24.0) and branded:
					game.consume_mark(f, target, "ash_brand")
		_:
			return false
	return true


static func _active_seal(f: Dictionary) -> Dictionary:
	var seal: Dictionary = f.get("winter_seal", {})
	return seal if seal.get("remaining", 0.0) > 0.0 else {}


static func _on_seal(game, seal: Dictionary, target: Dictionary) -> bool:
	if seal.is_empty():
		return false
	var origin: Vector2 = seal.position
	return origin.distance_squared_to(target.position) <= 2.8 * 2.8 and game._has_sight(origin, target.position)


static func _winter_scribe(game, f: Dictionary, slot: int, target_id: int) -> bool:
	var seal := _active_seal(f)
	if slot == 1:
		if not seal.is_empty():
			seal.remaining = 0.0
		var point: Vector2 = game.aim_point(f, 4.5)
		f.winter_seal = game.place_field(f, "slow", point, 2.8, 7.0, 0.30)
		return true
	if slot in [2, 3, 7]:
		if seal.is_empty():
			return false
		var point: Vector2 = seal.position
		if slot != 3 and not game._has_sight(f.position, point):
			return false
		match slot:
			2:
				var foes := _nearby(game, point, 2.8, 1 - int(f.team))
				if foes.is_empty():
					return false
				for foe in foes:
					game._deal_damage(f, foe, 24.0)
			3:
				var origin: Vector2 = f.position
				game._move(f, (point - origin).limit_length(8.0), false)
				if origin.distance_squared_to(f.position) < 0.01:
					return false
			7:
				game.place_field(f, "damage", point, 2.8, 5.0, 8.0)
		game.set_cast_destination(point)
		seal.remaining = 0.0
		f.erase("winter_seal")
		return true
	if slot == 4:
		var ally: Dictionary = game._target(f, target_id, true, 8.0)
		if ally.is_empty():
			return false
		game.shield(ally, 27.0 if _on_seal(game, seal, ally) else 15.0, 4.0)
		return true
	var range_limit := 8.5 if slot == 0 else 8.0
	var foe: Dictionary = game._target(f, target_id, false, range_limit)
	if foe.is_empty():
		return false
	var inscribed := _on_seal(game, seal, foe)
	match slot:
		0:
			game._deal_damage(f, foe, 19.0 if inscribed else 12.0)
		5:
			if game._deal_damage(f, foe, 7.0) and foe.alive:
				if inscribed:
					game.afflict(foe, "root", 1.2, 0.0, f.id)
				else:
					game.afflict(foe, "slow", 2.5, 0.35, f.id)
		6:
			if game._deal_damage(f, foe, 0.0):
				game.afflict(foe, "weaken", 3.0, 0.22, f.id)
				if inscribed:
					game.interrupt(foe)
		_:
			return false
	return true
