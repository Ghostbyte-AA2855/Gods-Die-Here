extends RefCounted

const KITS = {
	"breakwater": {
		"name": "Breakwater", "role": "Shield tank", "archetype": "guard",
		"resource": "Resolve", "max_health": 140.0, "speed": 4.45,
		"passive": "Strike, Brace, Take the Weight and Shield Check build Resolve. Keelbreaker hits harder while your guard tether is in range.",
		"counterplay": "Flank Brace or draw the tank away from its guarded ally. Step outside Holdfast and re-engage when its ward expires.",
		"priority": [2, 6, 3, 5, 4, 7, 1, 0],
		"abilities": [
			{"name":"Strike", "target":"enemy", "description":"Strike an enemy within 3 m for 18 damage.", "cooldown":0.8, "cost":0, "gain":10},
			{"name":"Brace", "target":"self", "description":"Guard your front for 1 s. The opening 0.4 s stops 80% of damage. The remaining guard stops 45%.", "cooldown":5.0, "cost":0, "gain":6},
			{"name":"Take the Weight", "target":"ally", "description":"Guard another ally within 6 m for 4 s. While in range, redirect 35% of their direct damage to yourself.", "cooldown":10.0, "cost":0, "gain":8},
			{"name":"Shield Check", "target":"enemy", "description":"Bash an enemy within 3 m for 11 damage, interrupting their cast and stunning them briefly.", "cooldown":7.0, "cost":0, "gain":6},
			{"name":"Interpose", "target":"ally", "description":"Rush up to 4 m toward another ally within 7 m. On arriving within 2 m, shield them for 12 damage for 3 s.", "cooldown":9.0, "cost":15, "gain":0},
			{"name":"Shield Sweep", "target":"enemy", "description":"Hit a foe within 3 m for 9 damage, pushing them 2 m and slowing them 30% for 2 s.", "cooldown":8.0, "cost":12, "gain":0},
			{"name":"Keelbreaker", "target":"enemy", "description":"Hit a foe within 3 m for 18 damage, or 30 while another living ally is within your active guard tether.", "cooldown":6.0, "cost":25, "gain":0},
			{"name":"Holdfast", "target":"self", "description":"Raise a 3.5 m ward at your feet for 4 s, granting 12-point shields to nearby allies.", "cooldown":19.0, "cost":40, "gain":0},
		],
	},
	"threadkeeper": {
		"name":"Threadkeeper", "role":"Ranged healer", "archetype":"healer",
		"resource":"Thread", "max_health":100.0, "speed":4.7,
		"passive":"Needle Bolt and Stitch wind Thread. Spend it to reposition an ally, heal through an enemy line, or establish a group healing zone.",
		"counterplay":"Interrupt Mend the Break before deferred damage expires. Force allies off the healing spindle and avoid standing between healer and patient.",
		"priority":[3, 1, 2, 6, 5, 4, 7, 0],
		"abilities":[
			{"name":"Needle Bolt", "target":"enemy", "description":"Strike a visible enemy within 8.5 m for 13 damage.", "cooldown":0.95, "cost":0, "gain":9},
			{"name":"Stitch", "target":"ally", "description":"Heal yourself or another injured ally within 8.5 m for 30 health.", "cooldown":3.7, "cost":0, "gain":12},
			{"name":"Borrowed Time", "target":"ally", "description":"Delay 45% of an ally's incoming direct damage for 4 s. Cast within 8.5 m.", "cooldown":10.0, "cost":0, "gain":0},
			{"name":"Mend the Break", "target":"ally", "description":"Cast for 0.7 s to clear deferred damage. Keep the ally within 8.5 m and in sight until completion.", "cooldown":7.0, "cost":0, "gain":0},
			{"name":"Loose End", "target":"enemy", "description":"Deal 8 damage to a foe within 8.5 m and weaken their outgoing damage by 25% for 2.5 s.", "cooldown":8.0, "cost":14, "gain":0},
			{"name":"Slipskein", "target":"ally", "description":"Shield an ally within 8.5 m for 12 damage for 3 s and increase their speed 35% for 2 s.", "cooldown":9.0, "cost":18, "gain":0},
			{"name":"Throughstitch", "target":"ally", "description":"Heal an injured ally within 8.5 m for 22. Deal 14 damage to each visible enemy within 1 m of the thread between you.", "cooldown":7.0, "cost":25, "gain":0},
			{"name":"Spool of Hours", "target":"ally", "description":"Plant a spindle under an ally within 8.5 m. Its 3 m circle restores 5 health per second for 5 s.", "cooldown":18.0, "cost":40, "gain":0},
		],
	},
	"echo_duelist": {
		"name":"Echo Duelist", "role":"Mobile melee damage", "archetype":"melee",
		"resource":"Cadence", "max_health":108.0, "speed":4.95,
		"passive":"Slash, Tracecut and Afterstroke build Cadence. A live trail gives a choice between an offensive repeat and a return path. Reprise refreshes your dash and feint.",
		"counterplay":"Step off the trail, hold damage during Feint, and turn to face the Duelist before Offbeat lands. The trail's start marks their retreat.",
		"priority":[2, 6, 1, 5, 3, 7, 0, 4],
		"abilities":[
			{"name":"Slash", "target":"enemy", "description":"Strike an enemy within 3 m for 21. A successful Feint raises your next hit to 34.", "cooldown":0.75, "cost":0, "gain":9},
			{"name":"Tracecut", "target":"aim", "description":"Dash up to 4 m along your aim. Hit enemies for 15 along the trail, which lasts for 3 s.", "cooldown":5.8, "cost":0, "gain":7},
			{"name":"Afterstroke", "target":"self", "description":"Consume your active trail to strike enemies along it again for 25 damage.", "cooldown":4.8, "cost":0, "gain":8},
			{"name":"Feint", "target":"self", "description":"Evade for 0.55 s. Avoiding an attack empowers a Slash for up to 3 s.", "cooldown":6.0, "cost":0, "gain":0},
			{"name":"Retrace", "target":"self", "description":"Consume your active trail and rush up to 6 m toward its start. Pillars block passage.", "cooldown":7.0, "cost":12, "gain":0},
			{"name":"Half Beat", "target":"enemy", "description":"Throw a blade at a foe within 6 m for 10 damage, slowing them 35% for 2 s.", "cooldown":7.0, "cost":12, "gain":0},
			{"name":"Offbeat", "target":"enemy", "description":"Lunge at a foe within 3 m for 17 damage. From behind their shoulder, the hit deals 31.", "cooldown":7.0, "cost":22, "gain":0},
			{"name":"Reprise", "target":"self", "description":"Refresh Tracecut and Feint. Requires at least one of those abilities to be on cooldown.", "cooldown":20.0, "cost":50, "gain":0},
		],
	},
	"forgecaller": {
		"name":"Forgecaller", "role":"Armored area control", "archetype":"guard",
		"resource":"Heat", "max_health":127.0, "speed":4.35,
		"passive":"Hot Rivet and Heat Brand build Heat. Brand an enemy, then spend Heat on personal armor, a team ward, or a Hammerfall that consumes the brand.",
		"counterplay":"Break sight before a branded Hammerfall, leave the furnace bed, and pull the fight out of Foldwall. Quench spends Heat that could power their finisher.",
		"priority":[1, 7, 2, 4, 3, 6, 5, 0],
		"abilities":[
			{"name":"Hot Rivet", "target":"enemy", "description":"Fire a heated rivet at an enemy within 7 m for 12 damage.", "cooldown":1.0, "cost":0, "gain":12},
			{"name":"Heat Brand", "target":"enemy", "description":"Sear an enemy within 7 m for 8 damage. On hit, mark them for your Hammerfall for 6 s.", "cooldown":6.0, "cost":0, "gain":10},
			{"name":"Winch", "target":"enemy", "description":"Catch a foe within 6 m for 6 damage and pull them up to 2.4 m toward you.", "cooldown":8.0, "cost":15, "gain":0},
			{"name":"Quench", "target":"self", "description":"Temper your armor into a 27-point shield for 4 s.", "cooldown":9.0, "cost":28, "gain":0},
			{"name":"Furnace Bed", "target":"aim", "description":"Place hot slag up to 5 m ahead. It burns a 2.8 m area for 7 damage per second for 4 s.", "cooldown":9.0, "cost":20, "gain":0},
			{"name":"Bellows", "target":"enemy", "description":"Blast a foe within 3 m for 10, interrupt their active cast and push them 2.5 m.", "cooldown":8.5, "cost":12, "gain":0},
			{"name":"Foldwall", "target":"ally", "description":"Deploy a ward at an ally within 6 m. For 4 s its 2.5 m field grants 15-point shields.", "cooldown":15.0, "cost":32, "gain":0},
			{"name":"Hammerfall", "target":"enemy", "description":"Hit a foe within 5 m for 20. A landed hit consumes your Heat Brand to add 18 damage.", "cooldown":12.0, "cost":40, "gain":0},
		],
	},
}


static func cast(game, f: Dictionary, slot: int, target_id: int) -> bool:
	match f.class_id:
		"breakwater":
			return _breakwater(game, f, slot, target_id)
		"threadkeeper":
			return _threadkeeper(game, f, slot, target_id)
		"echo_duelist":
			return _echo_duelist(game, f, slot, target_id)
		"forgecaller":
			return _forgecaller(game, f, slot, target_id)
	return false


static func _breakwater(game, f: Dictionary, slot: int, target_id: int) -> bool:
	if slot < 4:
		return game._use_breakwater(f, slot, target_id)
	match slot:
		4:
			var ally: Dictionary = game._target(f, target_id, true, 7.0, "ally_other")
			if ally.is_empty():
				return false
			var offset: Vector2 = ally.position - f.position
			game._move(f, offset.normalized() * clampf(offset.length() - 1.0, 0.0, 4.0), false)
			if (ally.position as Vector2).distance_to(f.position) <= 2.0:
				game.shield(ally, 12.0, 3.0)
			return true
		5, 6:
			var enemy: Dictionary = game._target(f, target_id, false, 3.0)
			if enemy.is_empty():
				return false
			game._face(f, enemy.position)
			if slot == 5:
				if game._deal_damage(f, enemy, 9.0) and enemy.alive:
					var away: Vector2 = enemy.position - f.position
					game._move(enemy, away.normalized() * 2.0, false)
					game.afflict(enemy, "slow", 2.0, 0.30, f.id)
			else:
				var damage := 18.0
				if f.guard_time > 0.0 and f.guard_target >= 0:
					var ward: Dictionary = game.fighters[f.guard_target]
					if ward.alive and (ward.position as Vector2).distance_to(f.position) <= 6.0:
						damage = 30.0
				game._deal_damage(f, enemy, damage)
			return true
		7:
			game.place_field(f, "ward", f.position, 3.5, 4.0, 12.0)
			return true
	return false


static func _threadkeeper(game, f: Dictionary, slot: int, target_id: int) -> bool:
	if slot < 4:
		return game._use_threadkeeper(f, slot, target_id)
	if slot == 4:
		var enemy: Dictionary = game._target(f, target_id, false, 8.5)
		if enemy.is_empty():
			return false
		if game._deal_damage(f, enemy, 8.0) and enemy.alive:
			game.afflict(enemy, "weaken", 2.5, 0.25, f.id)
		return true
	var mode := "injured" if slot == 6 else "nearest"
	var ally: Dictionary = game._target(f, target_id, true, 8.5, mode)
	if ally.is_empty():
		return false
	match slot:
		5:
			game.shield(ally, 12.0, 3.0)
			game.afflict(ally, "haste", 2.0, 0.35, f.id)
		6:
			game.heal(f, ally, 22.0)
			var start: Vector2 = f.position
			var end: Vector2 = ally.position
			for rival in game.fighters:
				if not rival.alive or rival.team == f.team:
					continue
				var nearest := start
				if start.distance_squared_to(end) > 0.0001:
					nearest = Geometry2D.get_closest_point_to_segment(rival.position, start, end)
				if nearest.distance_to(rival.position) <= 1.0 and game._has_sight(nearest, rival.position):
					game._deal_damage(f, rival, 14.0)
		7:
			game.place_field(f, "heal", ally.position, 3.0, 5.0, 5.0)
		_:
			return false
	return true


static func _echo_duelist(game, f: Dictionary, slot: int, target_id: int) -> bool:
	if slot < 4:
		return game._use_echo(f, slot, target_id)
	match slot:
		4:
			if f.echo_time <= 0.0:
				return false
			var start: Vector2 = f.position
			game._move(f, (f.echo_start - start).limit_length(6.0), false)
			if start.distance_squared_to(f.position) < 0.01:
				return false
			f.echo_time = 0.0
			return true
		5, 6:
			var reach := 6.0 if slot == 5 else 3.0
			var enemy: Dictionary = game._target(f, target_id, false, reach)
			if enemy.is_empty():
				return false
			game._face(f, enemy.position)
			if slot == 5:
				if game._deal_damage(f, enemy, 10.0) and enemy.alive:
					game.afflict(enemy, "slow", 2.0, 0.35, f.id)
			else:
				var incoming: Vector2 = f.position - enemy.position
				var behind := incoming.normalized().dot(enemy.facing) < -0.15
				game._deal_damage(f, enemy, 31.0 if behind else 17.0)
			return true
		7:
			if f.cooldowns[1] <= 0.0 and f.cooldowns[3] <= 0.0:
				return false
			f.cooldowns[1] = 0.0
			f.cooldowns[3] = 0.0
			return true
	return false


static func _forgecaller(game, f: Dictionary, slot: int, target_id: int) -> bool:
	match slot:
		3:
			game.shield(f, 27.0, 4.0)
			return true
		4:
			game.place_field(f, "damage", game.aim_point(f, 5.0), 2.8, 4.0, 7.0)
			return true
		6:
			var ally: Dictionary = game._target(f, target_id, true, 6.0)
			if ally.is_empty():
				return false
			game.place_field(f, "ward", ally.position, 2.5, 4.0, 15.0)
			return true
	const REACHES = [7.0, 7.0, 6.0, 0.0, 0.0, 3.0, 0.0, 5.0]
	if slot < 0 or slot >= REACHES.size():
		return false
	var enemy: Dictionary = game._target(f, target_id, false, REACHES[slot])
	if enemy.is_empty():
		return false
	game._face(f, enemy.position)
	match slot:
		0:
			game._deal_damage(f, enemy, 12.0)
		1:
			if game._deal_damage(f, enemy, 8.0) and enemy.alive:
				game.mark(f, enemy, "heat_brand", 6.0)
		2:
			if game._deal_damage(f, enemy, 6.0) and enemy.alive:
				var offset: Vector2 = f.position - enemy.position
				game._move(enemy, offset.normalized() * clampf(offset.length() - 1.0, 0.0, 2.4), false)
		5:
			if game._deal_damage(f, enemy, 10.0) and enemy.alive:
				game.interrupt(enemy)
				var away: Vector2 = enemy.position - f.position
				game._move(enemy, away.normalized() * 2.5, false)
		7:
			var branded: bool = game.marked(f, enemy, "heat_brand")
			if game._deal_damage(f, enemy, 38.0 if branded else 20.0) and branded:
				game.consume_mark(f, enemy, "heat_brand")
		_:
			return false
	return true
