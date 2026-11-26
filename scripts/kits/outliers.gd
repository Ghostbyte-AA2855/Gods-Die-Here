extends RefCounted

const KITS = {
	"dream_shepherd": {
		"name": "Dream Shepherd", "role": "Preventive healer", "archetype": "healer",
		"resource": "Reverie",
		"passive": "Pillow Ward on an ally at 75% health or higher grants Well Rested for 6s. Your next Soft Landing on them consumes it for 12 extra healing. Nightlight and Soft Landing build Reverie.",
		"counterplay": "Switch pressure after Pillow Ward lands. Separate the Shepherd from their sleeping circle and save a slow for after Daybreak.",
		"max_health": 98.0, "speed": 4.75, "priority": [1, 4, 7, 2, 5, 3, 6, 0],
		"abilities": [
			{"name": "Nightlight", "description": "Deal 10 damage to a foe within 8m.", "cooldown": 1.0, "target": "enemy", "cost": 0, "gain": 9},
			{"name": "Soft Landing", "description": "Heal an injured ally within 8m for 18, or 30 with Well Rested.", "cooldown": 2.6, "target": "ally", "cost": 0, "gain": 6},
			{"name": "Pillow Ward", "description": "Shield an ally within 8m for 20 damage for 4s. Healthy targets gain Well Rested.", "cooldown": 6.0, "target": "ally", "cost": 12, "gain": 0},
			{"name": "Sleepwalk", "description": "Travel up to 4m toward another ally in sight, stopping just short of them.", "cooldown": 6.5, "target": "ally", "cost": 0, "gain": 0},
			{"name": "Daybreak", "description": "Clear roots and slows from an ally within 8m and grant 25% haste for 2s.", "cooldown": 11.0, "target": "ally", "cost": 14, "gain": 0},
			{"name": "Night Terrors", "description": "Deal 6 damage and weaken a foe within 7m by 30% for 3s.", "cooldown": 8.0, "target": "enemy", "cost": 8, "gain": 0},
			{"name": "Dream Hollow", "description": "Lay a 3m circle up to 5m ahead. It restores 6 health per second to allies inside for 4s.", "cooldown": 10.0, "target": "aim", "cost": 23, "gain": 0},
			{"name": "Dawn Chorus", "description": "Shield each visible ally within 6m for 16 damage for 4s and restore 4 health per second for 4s.", "cooldown": 15.0, "target": "self", "cost": 40, "gain": 0},
		],
	},
	"chainrunner": {
		"name": "Chainrunner", "role": "Hook skirmisher", "archetype": "melee",
		"resource": "Tension",
		"passive": "Hookline marks its victim as Hooked for 5s. A Backhand against that victim deals 5 extra damage. Last Link consumes the hook for its strongest hit. Build Tension through close-range blows and hooks.",
		"counterplay": "Break sight before the hook lands. Step away after the pull, and use a dodge during Last Link's melee window.",
		"max_health": 116.0, "speed": 5.0, "priority": [7, 1, 6, 3, 4, 2, 0, 5],
		"abilities": [
			{"name": "Backhand", "description": "Deal 14 melee damage, or 19 to a Hooked foe.", "cooldown": 0.85, "target": "enemy", "cost": 0, "gain": 12},
			{"name": "Hookline", "description": "Hook a visible foe within 8m for 8 damage. Pull them up to 3m and mark them for 5s.", "cooldown": 6.0, "target": "enemy", "cost": 0, "gain": 8},
			{"name": "Hitch Ride", "description": "Close up to 4m toward a foe within 7m. Gain a 10-point shield for 2s on arrival.", "cooldown": 6.5, "target": "enemy", "cost": 10, "gain": 0},
			{"name": "Ankle Loop", "description": "Deal 6 damage to a foe within 4m and root them for 0.8s.", "cooldown": 8.0, "target": "enemy", "cost": 15, "gain": 0},
			{"name": "Chain Sweep", "description": "Strike each visible foe within 3.4m for 12 damage and push them back 1.4m.", "cooldown": 6.0, "target": "self", "cost": 8, "gain": 0},
			{"name": "Pay Out", "description": "Spring 3m backward from your facing and evade for 0.2s.", "cooldown": 7.0, "target": "self", "cost": 0, "gain": 0},
			{"name": "Tug Clear", "description": "Pull another ally in sight up to 2m toward you and shield them for 15 damage for 3s.", "cooldown": 10.0, "target": "ally", "cost": 15, "gain": 0},
			{"name": "Last Link", "description": "Deal 23 melee damage. Consume your Hooked mark on a landed hit for 15 extra damage.", "cooldown": 8.0, "target": "enemy", "cost": 32, "gain": 0},
		],
	},
	"coilwright": {
		"name": "Coilwright", "role": "Chain lightning caster", "archetype": "ranged",
		"resource": "Flux",
		"passive": "Pole Tag polarizes a target for 6s. Fork Spark can arc from a polarized target to a second rival in sight, while Ground Fault can spend the mark to pin the first. Spark Pin and Pole Tag recharge Flux.",
		"counterplay": "Space teammates over 4m apart and use pillars to interrupt the chain. Pressure the Coilwright once Phase Return has been used.",
		"max_health": 100.0, "speed": 4.65, "priority": [1, 2, 7, 3, 5, 6, 0, 4],
		"abilities": [
			{"name": "Spark Pin", "description": "Deal 13 damage to a foe within 9m.", "cooldown": 0.95, "target": "enemy", "cost": 0, "gain": 9},
			{"name": "Pole Tag", "description": "Deal 5 damage to a foe within 8m and polarize them for 6s.", "cooldown": 5.0, "target": "enemy", "cost": 0, "gain": 6},
			{"name": "Fork Spark", "description": "Deal 17 damage within 9m. A polarized victim arcs 12 damage to the closest visible rival within 4m of them.", "cooldown": 4.0, "target": "enemy", "cost": 14, "gain": 0},
			{"name": "Ground Fault", "description": "Deal 9 damage within 7m. Consume polarization to root the target for 1.1s.", "cooldown": 7.5, "target": "enemy", "cost": 13, "gain": 0},
			{"name": "Phase Return", "description": "First press stakes your position for 5s. Press again to return up to 6m along a clear path. The return has a 9s cooldown.", "cooldown": 0.4, "target": "self", "cost": 0, "gain": 0},
			{"name": "Insulation", "description": "Give a visible ally within 7m an 18-point shield for 3s.", "cooldown": 8.0, "target": "ally", "cost": 12, "gain": 0},
			{"name": "Open Circuit", "description": "Interrupt a foe within 7m and silence them for 0.7s on a 4-damage hit.", "cooldown": 10.0, "target": "enemy", "cost": 10, "gain": 0},
			{"name": "Thunder Cage", "description": "Place a 3m storm up to 6m ahead for 4s. It deals 10 damage per second to rivals in its area.", "cooldown": 12.0, "target": "aim", "cost": 36, "gain": 0},
		],
	},
	"duskmoth": {
		"name": "Duskmoth", "role": "Venom skirmisher", "archetype": "melee",
		"resource": "Nectar",
		"passive": "Night Dust poisons and marks a rival for 5s. Fang Cut is stronger against Dusted targets. Scatter Scales spreads the poison, while Moon Harvest cashes in the mark for damage and healing. Fang Cut builds Nectar.",
		"counterplay": "Spread out after Night Dust lands. Kite the Dusted player away from the moth's 5m harvest range and pressure after Gale Flit.",
		"max_health": 101.0, "speed": 5.25, "priority": [1, 7, 5, 2, 4, 3, 0, 6],
		"abilities": [
			{"name": "Fang Cut", "description": "Deal 13 melee damage, or 18 against a Dusted foe.", "cooldown": 0.8, "target": "enemy", "cost": 0, "gain": 12},
			{"name": "Night Dust", "description": "Strike within 6m for 4 damage. Mark the foe and poison them for 4 damage per second for 5s.", "cooldown": 5.5, "target": "enemy", "cost": 0, "gain": 5},
			{"name": "Gale Flit", "description": "Dash up to 3.5m toward your aim and evade for 0.25s.", "cooldown": 6.0, "target": "aim", "cost": 8, "gain": 0},
			{"name": "Shed Husk", "description": "Clear your slow and gain a 14-point shield for 3s.", "cooldown": 9.0, "target": "self", "cost": 12, "gain": 0},
			{"name": "Soporific Prick", "description": "Sting a foe within 4m for 5 damage and slow them by 40% for 2.5s.", "cooldown": 6.5, "target": "enemy", "cost": 8, "gain": 0},
			{"name": "Scatter Scales", "description": "Strike a Dusted foe within 7m for 8. Each visible rival within 3.5m of them takes 4 and gains a 3s poison and dust mark.", "cooldown": 7.0, "target": "enemy", "cost": 13, "gain": 0},
			{"name": "Moonwing", "description": "Regenerate 4 health per second and gain 27% movement haste for 3s.", "cooldown": 10.0, "target": "self", "cost": 18, "gain": 0},
			{"name": "Moon Harvest", "description": "Consume a Dusted foe's mark within 5m on a 26-damage hit and heal yourself for 15.", "cooldown": 8.5, "target": "enemy", "cost": 30, "gain": 0},
		],
	},
}


static func cast(game, f: Dictionary, slot: int, target_id: int) -> bool:
	match f.class_id:
		"dream_shepherd":
			return _dream(game, f, slot, target_id)
		"chainrunner":
			return _chain(game, f, slot, target_id)
		"coilwright":
			return _coil(game, f, slot, target_id)
		"duskmoth":
			return _moth(game, f, slot, target_id)
	return false


static func _step_toward(game, traveler: Dictionary, destination: Vector2, max_distance: float, clearance: float) -> bool:
	var offset: Vector2 = destination - (traveler.position as Vector2)
	var distance := minf(max_distance, maxf(0.0, offset.length() - clearance))
	var before: Vector2 = traveler.position
	game._move(traveler, offset.normalized() * distance, false)
	return before.distance_squared_to(traveler.position) > 0.0001


static func _nearby(game, center: Dictionary, team: int, radius: float) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var origin: Vector2 = center.position
	for member in game.fighters:
		if member.alive and member.team == team and origin.distance_to(member.position) <= radius and game._has_sight(origin, member.position):
			result.append(member)
	return result


static func _dream(game, f: Dictionary, slot: int, target_id: int) -> bool:
	match slot:
		0, 5:
			var enemy: Dictionary = game._target(f, target_id, false, 8.0 if slot == 0 else 7.0)
			if enemy.is_empty():
				return false
			var landed: bool = game._deal_damage(f, enemy, 10.0 if slot == 0 else 6.0)
			if slot == 5 and landed:
				game.afflict(enemy, "weaken", 3.0, 0.3, f.id)
		1:
			var ally: Dictionary = game._target(f, target_id, true, 8.0, "injured")
			if ally.is_empty():
				return false
			var rested: bool = game.marked(f, ally, "well_rested")
			if not game.heal(f, ally, 30.0 if rested else 18.0):
				return false
			if rested:
				game.consume_mark(f, ally, "well_rested")
		2:
			var ally: Dictionary = game._target(f, target_id, true, 8.0)
			if ally.is_empty():
				return false
			game.shield(ally, 20.0, 4.0)
			if ally.health >= float(ally.max_health) * 0.75:
				game.mark(f, ally, "well_rested", 6.0)
		3:
			var ally: Dictionary = game._target(f, target_id, true, 8.0, "ally_other")
			return not ally.is_empty() and _step_toward(game, f, ally.position, 4.0, 0.7)
		4:
			var ally: Dictionary = game._target(f, target_id, true, 8.0)
			if ally.is_empty():
				return false
			game.cleanse(ally, ["root", "slow"])
			game.afflict(ally, "haste", 2.0, 0.25, f.id)
		6:
			game.place_field(f, "heal", game.aim_point(f, 5.0), 3.0, 4.0, 6.0)
		7:
			for ally in _nearby(game, f, f.team, 6.0):
				game.shield(ally, 16.0, 4.0)
				game.afflict(ally, "regen", 4.0, 4.0, f.id)
		_:
			return false
	return true


static func _chain(game, f: Dictionary, slot: int, target_id: int) -> bool:
	match slot:
		0, 1, 2, 3, 7:
			var reach: float = [3.0, 8.0, 7.0, 4.0, 0.0, 0.0, 0.0, 3.0][slot]
			var enemy: Dictionary = game._target(f, target_id, false, reach)
			if enemy.is_empty():
				return false
			match slot:
				0:
					game._deal_damage(f, enemy, 19.0 if game.marked(f, enemy, "hooked") else 14.0)
				1:
					if game._deal_damage(f, enemy, 8.0) and enemy.alive:
						_step_toward(game, enemy, f.position, 3.0, 1.1)
						game.mark(f, enemy, "hooked", 5.0)
				2:
					if not _step_toward(game, f, enemy.position, 4.0, 0.8):
						return false
					game.shield(f, 10.0, 2.0)
				3:
					if game._deal_damage(f, enemy, 6.0) and enemy.alive:
						game.afflict(enemy, "root", 0.8, 0.0, f.id)
				7:
					var hooked: bool = game.marked(f, enemy, "hooked")
					if game._deal_damage(f, enemy, 38.0 if hooked else 23.0) and hooked:
						game.consume_mark(f, enemy, "hooked")
		4:
			var enemies := _nearby(game, f, 1 - int(f.team), 3.4)
			if enemies.is_empty():
				return false
			for enemy in enemies:
				if game._deal_damage(f, enemy, 12.0) and enemy.alive:
					var direction: Vector2 = (f.position as Vector2).direction_to(enemy.position)
					game._move(enemy, direction * 1.4, false)
		5:
			game._move(f, -(f.facing as Vector2) * 3.0, false)
			f.evade = maxf(f.evade, 0.2)
		6:
			var ally: Dictionary = game._target(f, target_id, true, 7.0, "ally_other")
			if ally.is_empty():
				return false
			_step_toward(game, ally, f.position, 2.0, 0.9)
			game.shield(ally, 15.0, 3.0)
		_:
			return false
	return true


static func _coil(game, f: Dictionary, slot: int, target_id: int) -> bool:
	match slot:
		0, 1, 2, 3, 6:
			var reach: float = [9.0, 8.0, 9.0, 7.0, 0.0, 0.0, 7.0][slot]
			var enemy: Dictionary = game._target(f, target_id, false, reach)
			if enemy.is_empty():
				return false
			var damage: float = [13.0, 5.0, 17.0, 9.0, 0.0, 0.0, 4.0][slot]
			if not game._deal_damage(f, enemy, damage):
				return true
			match slot:
				1:
					game.mark(f, enemy, "polarized", 6.0)
				2:
					if game.marked(f, enemy, "polarized"):
						_arc(game, f, enemy)
				3:
					if enemy.alive and game.consume_mark(f, enemy, "polarized"):
						game.afflict(enemy, "root", 1.1, 0.0, f.id)
				6:
					if enemy.alive:
						game.interrupt(enemy)
						game.afflict(enemy, "silence", 0.7, 0.0, f.id)
		4:
			# Round time counts downward and stored fighter state expires on reset.
			var remaining: float = float(f.get("phase_ends", INF))
			if f.has("phase_anchor") and game.round_time >= remaining:
				if not _step_toward(game, f, f.phase_anchor, 6.0, 0.0):
					return false
				f.erase("phase_anchor")
				f.cooldowns[slot] = 9.0
			else:
				f["phase_anchor"] = f.position
				f["phase_ends"] = game.round_time - 5.0
		5:
			var ally: Dictionary = game._target(f, target_id, true, 7.0)
			if ally.is_empty():
				return false
			game.shield(ally, 18.0, 3.0)
		7:
			game.place_field(f, "damage", game.aim_point(f, 6.0), 3.0, 4.0, 10.0)
		_:
			return false
	return true


static func _arc(game, f: Dictionary, victim: Dictionary) -> void:
	var nearest: Dictionary = {}
	var best := INF
	for other in _nearby(game, victim, victim.team, 4.0):
		var distance := (other.position as Vector2).distance_squared_to(victim.position)
		if other.id != victim.id and distance < best:
			nearest = other
			best = distance
	if not nearest.is_empty():
		game._deal_damage(f, nearest, 12.0)


static func _moth(game, f: Dictionary, slot: int, target_id: int) -> bool:
	match slot:
		0, 1, 4, 5, 7:
			var reach: float = [3.0, 6.0, 0.0, 0.0, 4.0, 7.0, 0.0, 5.0][slot]
			var victim: Dictionary = game._target(f, target_id, false, reach)
			if victim.is_empty():
				return false
			var dusted: bool = game.marked(f, victim, "dusted")
			match slot:
				0:
					game._deal_damage(f, victim, 18.0 if dusted else 13.0)
				1:
					if game._deal_damage(f, victim, 4.0) and victim.alive:
						_dust(game, f, victim, 5.0)
				4:
					if game._deal_damage(f, victim, 5.0) and victim.alive:
						game.afflict(victim, "slow", 2.5, 0.4, f.id)
				5:
					if not dusted:
						return false
					if game._deal_damage(f, victim, 8.0):
						for rival in _nearby(game, victim, victim.team, 3.5):
							if rival.id != victim.id and game._deal_damage(f, rival, 4.0) and rival.alive:
								_dust(game, f, rival, 3.0)
				7:
					if not dusted:
						return false
					if game._deal_damage(f, victim, 26.0):
						game.consume_mark(f, victim, "dusted")
						game.heal(f, f, 15.0)
		2:
			game._move(f, (f.facing as Vector2) * 3.5, false)
			f.evade = maxf(f.evade, 0.25)
		3:
			game.cleanse(f, ["slow"])
			game.shield(f, 14.0, 3.0)
		6:
			game.afflict(f, "regen", 3.0, 4.0, f.id)
			game.afflict(f, "haste", 3.0, 0.27, f.id)
		_:
			return false
	return true


static func _dust(game, source: Dictionary, target: Dictionary, seconds: float) -> void:
	game.mark(source, target, "dusted", seconds)
	game.afflict(target, "burn", seconds, 4.0, source.id)
