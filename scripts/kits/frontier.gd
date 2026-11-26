extends RefCounted

const KITS = {
	"lamplighter": {
		"name": "Lamplighter", "role": "Sanctuary healer", "archetype": "healer",
		"max_health": 104.0, "speed": 4.6, "resource": "Oil",
		"passive": "Hearthkeeper grants 8 extra healing from Kindle and 7 extra shield from Wardlight to targets in your lantern. Ember Dart and Kindle refill Oil.",
		"counterplay": "Split the fight around a pillar or push allies off their lantern. After First Light consumes it, the healer must establish a new sanctuary.",
		"priority": [7, 1, 2, 3, 4, 5, 6, 0],
		"abilities": [
			{"name": "Ember Dart", "description": "Fire an ember for 11 damage within 8.5 m.", "cooldown": 1.0, "target": "enemy", "cost": 0, "gain": 9},
			{"name": "Kindle", "description": "Heal an injured ally within 9 m for 20, or 28 inside your lantern.", "cooldown": 3.4, "target": "ally", "cost": 0, "gain": 12},
			{"name": "Set Lantern", "description": "Plant one lantern at your feet for 12 s. Allies within 3.3 m recover 3 health per second.", "cooldown": 6.0, "target": "self", "cost": 12, "gain": 0},
			{"name": "Wardlight", "description": "Shield an ally within 8 m for 15 damage over 4 s, or 22 damage inside your lantern.", "cooldown": 7.5, "target": "ally", "cost": 16, "gain": 0},
			{"name": "Bellows Blast", "description": "Blast a foe within 4 m for 7 damage, knocking them back 2.6 m.", "cooldown": 8.0, "target": "enemy", "cost": 4, "gain": 0},
			{"name": "Pass the Flame", "description": "Move your burning lantern beneath a teammate within 8 m, preserving its remaining fuel.", "cooldown": 4.0, "target": "ally", "cost": 5, "gain": 0},
			{"name": "Travel Wick", "description": "Give an ally within 9 m a 25% movement boost for 3 s.", "cooldown": 9.0, "target": "ally", "cost": 8, "gain": 0},
			{"name": "First Light", "description": "Consume your lantern to immediately heal each injured ally inside for 26.", "cooldown": 13.0, "target": "self", "cost": 24, "gain": 0},
		],
	},
	"longwatch": {
		"name": "Longwatch", "role": "Quarry marksman", "archetype": "ranged",
		"max_health": 102.0, "speed": 4.8, "resource": "Focus",
		"passive": "Sight Picture adds 5 damage to Reedshot against your marked quarry. Reedshot and Mark Quarry build Focus for your finishing shot.",
		"counterplay": "Break sight when marked. Approach behind cover, dodge the finishing shot, or force the marksman to spend their retreat early.",
		"priority": [7, 1, 4, 2, 5, 6, 0, 3],
		"abilities": [
			{"name": "Reedshot", "description": "Shoot a visible foe within 11 m for 12 damage, or 17 against your quarry.", "cooldown": 1.0, "target": "enemy", "cost": 0, "gain": 8},
			{"name": "Mark Quarry", "description": "Designate a foe within 12 m for 8 s. Changing quarry removes your previous mark.", "cooldown": 5.0, "target": "enemy", "cost": 0, "gain": 10},
			{"name": "Pinning Shot", "description": "Hit a foe within 9 m for 8 damage and slow them by 35% for 2.5 s.", "cooldown": 6.5, "target": "enemy", "cost": 8, "gain": 0},
			{"name": "Reel Back", "description": "Spring backward up to 3.3 m. Cover stops your retreat.", "cooldown": 7.5, "target": "self", "cost": 0, "gain": 0},
			{"name": "Bellshot", "description": "Interrupt a foe within 8 m, dealing 6 damage and silencing abilities for 1 s.", "cooldown": 10.0, "target": "enemy", "cost": 12, "gain": 0},
			{"name": "Fan Volley", "description": "Fire a spread dealing 12 damage to visible foes in a forward 70-degree cone up to 8 m.", "cooldown": 5.5, "target": "aim", "cost": 10, "gain": 0},
			{"name": "Snare Cord", "description": "Place a 2.3 m snare field up to 6 m ahead that slows enemies by 40% for 4 s.", "cooldown": 9.0, "target": "aim", "cost": 12, "gain": 0},
			{"name": "Quarry's End", "description": "Spend your mark to fire a 31-damage finishing shot at your quarry within 12 m.", "cooldown": 8.5, "target": "enemy", "cost": 26, "gain": 0},
		],
	},
	"sluicecaller": {
		"name": "Sluicecaller", "role": "Current controller", "archetype": "ranged",
		"max_health": 106.0, "speed": 4.65, "resource": "Tide",
		"passive": "Undertow marks foes hit by Crosscurrent or Maelstrom for 5 s. Riptide consumes it for stronger damage and a pull. Ripple Bolt and Crosscurrent build Tide.",
		"counterplay": "Move out of the pools and spread before Maelstrom. A pillar can stop a push or break the line needed for the follow-up pull.",
		"priority": [7, 5, 2, 6, 1, 3, 0, 4],
		"abilities": [
			{"name": "Ripple Bolt", "description": "Hit a foe within 9 m for 12 damage.", "cooldown": 1.0, "target": "enemy", "cost": 0, "gain": 9},
			{"name": "Stillwater", "description": "Place a 3 m pool up to 5 m ahead for 5 s. It slows enemies by 35%.", "cooldown": 7.0, "target": "aim", "cost": 8, "gain": 0},
			{"name": "Crosscurrent", "description": "Hit a foe within 8 m for 8 damage, push them 2.5 m away and apply Undertow.", "cooldown": 6.0, "target": "enemy", "cost": 0, "gain": 10},
			{"name": "Springline", "description": "Give an ally within 8 m a 35% speed boost for 2.5 s.", "cooldown": 7.5, "target": "ally", "cost": 8, "gain": 0},
			{"name": "Slipstream", "description": "Ride a current up to 3 m toward your aim. Leave a 2 m slowing pool at your starting point for 2.5 s.", "cooldown": 9.0, "target": "aim", "cost": 12, "gain": 0},
			{"name": "Riptide", "description": "Hit within 11 m for 12 damage. Consume Undertow for 21 damage and pull the foe 2 m closer.", "cooldown": 4.5, "target": "enemy", "cost": 12, "gain": 0},
			{"name": "Floodgate", "description": "Open a 2.4 m surge under a visible foe within 8 m. It deals 7 damage per second over 4 s.", "cooldown": 9.0, "target": "enemy", "cost": 18, "gain": 0},
			{"name": "Maelstrom", "description": "Center a vortex on a foe within 8 m. Hit rivals within 3.8 m for 14, draw them up to 2 m toward its center and apply Undertow.", "cooldown": 15.0, "target": "enemy", "cost": 35, "gain": 0},
		],
	},
	"glassmage": {
		"name": "Glassmage", "role": "Prism burst caster", "archetype": "ranged",
		"max_health": 98.0, "speed": 4.75, "resource": "Brilliance",
		"passive": "Refraction adds 7 damage when your Prism Bolt passes within 1.5 m of your live prism. Prism Bolt builds Brilliance and Hang Prism establishes your attack angle.",
		"counterplay": "Step sideways off the line between caster and prism. Pressure the caster away from the crystal and leave its short detonation radius.",
		"priority": [1, 7, 6, 4, 3, 0, 2, 5],
		"abilities": [
			{"name": "Prism Bolt", "description": "Hit a foe within 9 m for 12 damage, or 19 when fired through your prism.", "cooldown": 1.0, "target": "enemy", "cost": 0, "gain": 10},
			{"name": "Hang Prism", "description": "Place a crystal up to 4 m ahead for 10 s. It deals 3 damage per second to foes within 2 m.", "cooldown": 5.0, "target": "aim", "cost": 0, "gain": 4},
			{"name": "Mirror Step", "description": "Travel up to 5 m toward your live prism, stopping at cover.", "cooldown": 7.0, "target": "self", "cost": 8, "gain": 0},
			{"name": "Mirror Guard", "description": "Wrap yourself in glass that absorbs up to 18 damage for 4 s.", "cooldown": 9.0, "target": "self", "cost": 12, "gain": 0},
			{"name": "Splinter Cage", "description": "Root a foe within 9 m for 1.1 s if they are within 3.5 m of your prism.", "cooldown": 8.5, "target": "enemy", "cost": 12, "gain": 0},
			{"name": "Glass Double", "description": "Slip behind a glass reflection and evade attacks for 0.6 s.", "cooldown": 9.0, "target": "self", "cost": 10, "gain": 0},
			{"name": "Sun Through Glass", "description": "Scorch a foe within 8 m for 6 damage, then burn them for 4 damage per second over 3 s.", "cooldown": 6.5, "target": "enemy", "cost": 10, "gain": 0},
			{"name": "Shattercast", "description": "Consume your live prism and deal 28 damage to visible foes within 3.5 m of it.", "cooldown": 12.0, "target": "self", "cost": 28, "gain": 0},
		],
	},
}

static func cast(game, f: Dictionary, slot: int, target_id: int) -> bool:
	match f.class_id:
		"lamplighter":
			return _lamplighter(game, f, slot, target_id)
		"longwatch":
			return _longwatch(game, f, slot, target_id)
		"sluicecaller":
			return _sluicecaller(game, f, slot, target_id)
		"glassmage":
			return _glassmage(game, f, slot, target_id)
	return false


static func _anchor(game, f: Dictionary, key: String) -> Dictionary:
	var field: Dictionary = f.get(key, {})
	if field.is_empty() or field.remaining <= 0.0 or not game.fields.has(field):
		return {}
	return field


static func _remove_anchor(game, f: Dictionary, key: String) -> void:
	var field := _anchor(game, f, key)
	if not field.is_empty():
		game.set_cast_destination(field.position)
		game.fields.erase(field)
	f.erase(key)


static func _inside(game, center: Vector2, point: Vector2, radius: float) -> bool:
	return center.distance_squared_to(point) <= radius * radius and game._has_sight(center, point)


static func _in_lantern(game, lantern: Dictionary, ally: Dictionary) -> bool:
	return not lantern.is_empty() and _inside(game, lantern.position, ally.position, 3.3)


static func _shift(game, fighter: Dictionary, displacement: Vector2) -> bool:
	var start: Vector2 = fighter.position
	game._move(fighter, displacement, false)
	return start.distance_squared_to(fighter.position) >= 0.0001


static func _lamplighter(game, f: Dictionary, slot: int, target_id: int) -> bool:
	var lantern := _anchor(game, f, "lantern")
	match slot:
		0:
			var enemy: Dictionary = game._target(f, target_id, false, 8.5)
			if enemy.is_empty():
				return false
			game._deal_damage(f, enemy, 11.0)
		1:
			var ally: Dictionary = game._target(f, target_id, true, 9.0, "injured")
			if ally.is_empty():
				return false
			return game.heal(f, ally, 28.0 if _in_lantern(game, lantern, ally) else 20.0)
		2:
			_remove_anchor(game, f, "lantern")
			f.lantern = game.place_field(f, "heal", f.position, 3.3, 12.0, 3.0)
		3:
			var ally: Dictionary = game._target(f, target_id, true, 8.0)
			if ally.is_empty():
				return false
			game.shield(ally, 22.0 if _in_lantern(game, lantern, ally) else 15.0, 4.0)
		4:
			var enemy: Dictionary = game._target(f, target_id, false, 4.0)
			if enemy.is_empty():
				return false
			if game._deal_damage(f, enemy, 7.0) and enemy.alive:
				_shift(game, enemy, (f.position as Vector2).direction_to(enemy.position) * 2.6)
		5:
			var ally: Dictionary = game._target(f, target_id, true, 8.0, "ally_other")
			if lantern.is_empty() or ally.is_empty() or lantern.position.distance_squared_to(ally.position) < 0.1:
				return false
			lantern.position = ally.position
		6:
			var ally: Dictionary = game._target(f, target_id, true, 9.0)
			if ally.is_empty():
				return false
			game.afflict(ally, "haste", 3.0, 0.25, f.id)
		7:
			if lantern.is_empty():
				return false
			var healed := false
			for ally in game.fighters:
				if ally.alive and ally.team == f.team and _in_lantern(game, lantern, ally):
					if game.heal(f, ally, 26.0):
						healed = true
			if not healed:
				return false
			_remove_anchor(game, f, "lantern")
		_:
			return false
	return true


static func _longwatch(game, f: Dictionary, slot: int, target_id: int) -> bool:
	match slot:
		0, 1, 2, 4, 7:
			var reach: float = [11.0, 12.0, 9.0, 0.0, 8.0, 0.0, 0.0, 12.0][slot]
			var quarry_id: int = f.get("quarry_id", -1)
			var selected := target_id
			if slot == 7 and selected == -1:
				selected = quarry_id
			var enemy: Dictionary = game._target(f, selected, false, reach)
			if enemy.is_empty():
				return false
			match slot:
				0:
					game._deal_damage(f, enemy, 17.0 if game.marked(f, enemy, "quarry") else 12.0)
				1:
					if quarry_id >= 0:
						game.consume_mark(f, game.fighters[quarry_id], "quarry")
					game.mark(f, enemy, "quarry", 8.0)
					f.quarry_id = enemy.id
				2:
					if game._deal_damage(f, enemy, 8.0) and enemy.alive:
						game.afflict(enemy, "slow", 2.5, 0.35, f.id)
				4:
					if game._deal_damage(f, enemy, 6.0) and enemy.alive:
						game.interrupt(enemy)
						game.afflict(enemy, "silence", 1.0, 0.0, f.id)
				7:
					if not game.consume_mark(f, enemy, "quarry"):
						return false
					f.quarry_id = -1
					game._deal_damage(f, enemy, 31.0)
		3:
			return _shift(game, f, -(f.facing as Vector2) * 3.3)
		5:
			var fired := false
			for enemy in game.fighters:
				if enemy.team == f.team or not enemy.alive or not _inside(game, f.position, enemy.position, 8.0):
					continue
				var heading := (f.position as Vector2).direction_to(enemy.position)
				if heading.dot(f.facing) >= cos(deg_to_rad(35)):
					game._deal_damage(f, enemy, 12.0)
					fired = true
			return fired
		6:
			game.place_field(f, "slow", game.aim_point(f, 6.0), 2.3, 4.0, 0.4)
		_:
			return false
	return true


static func _sluicecaller(game, f: Dictionary, slot: int, target_id: int) -> bool:
	match slot:
		0, 2, 5, 6, 7:
			var reach: float = 11.0 if slot == 5 else (9.0 if slot == 0 else 8.0)
			var enemy: Dictionary = game._target(f, target_id, false, reach)
			if enemy.is_empty():
				return false
			var away := (f.position as Vector2).direction_to(enemy.position)
			match slot:
				0:
					game._deal_damage(f, enemy, 12.0)
				2:
					if game._deal_damage(f, enemy, 8.0) and enemy.alive:
						_shift(game, enemy, away * 2.5)
						game.mark(f, enemy, "undertow", 5.0)
				5:
					var primed: bool = game.marked(f, enemy, "undertow")
					if game._deal_damage(f, enemy, 21.0 if primed else 12.0) and primed:
						game.consume_mark(f, enemy, "undertow")
						if enemy.alive:
							_shift(game, enemy, -away * 2.0)
				6:
					game.place_field(f, "damage", enemy.position, 2.4, 4.0, 7.0)
				7:
					var center: Vector2 = enemy.position
					for rival in game.fighters:
						if rival.team == f.team or not rival.alive or not _inside(game, center, rival.position, 3.8):
							continue
						if game._deal_damage(f, rival, 14.0) and rival.alive:
							_shift(game, rival, (center - rival.position).limit_length(2.0))
							game.mark(f, rival, "undertow", 5.0)
		1:
			game.place_field(f, "slow", game.aim_point(f, 5.0), 3.0, 5.0, 0.35)
		3:
			var ally: Dictionary = game._target(f, target_id, true, 8.0)
			if ally.is_empty():
				return false
			game.afflict(ally, "haste", 2.5, 0.35, f.id)
		4:
			var start: Vector2 = f.position
			if not _shift(game, f, (f.facing as Vector2) * 3.0):
				return false
			game.place_field(f, "slow", start, 2.0, 2.5, 0.4)
		_:
			return false
	return true


static func _glassmage(game, f: Dictionary, slot: int, target_id: int) -> bool:
	var prism := _anchor(game, f, "prism")
	match slot:
		0:
			var enemy: Dictionary = game._target(f, target_id, false, 9.0)
			if enemy.is_empty():
				return false
			var through_prism := false
			if not prism.is_empty() and (f.position as Vector2).distance_squared_to(enemy.position) > 0.01:
				var nearest := Geometry2D.get_closest_point_to_segment(prism.position, f.position, enemy.position)
				through_prism = _inside(game, nearest, prism.position, 1.5)
			game._deal_damage(f, enemy, 19.0 if through_prism else 12.0)
		1:
			_remove_anchor(game, f, "prism")
			f.prism = game.place_field(f, "damage", game.aim_point(f, 4.0), 2.0, 10.0, 3.0)
		2:
			if prism.is_empty():
				return false
			return _shift(game, f, (prism.position - f.position).limit_length(5.0))
		3:
			game.shield(f, 18.0, 4.0)
		4:
			var enemy: Dictionary = game._target(f, target_id, false, 9.0)
			if enemy.is_empty() or prism.is_empty() or not _inside(game, prism.position, enemy.position, 3.5):
				return false
			if enemy.evade <= 0.0:
				game.afflict(enemy, "root", 1.1, 0.0, f.id)
		5:
			f.evade = maxf(f.evade, 0.6)
		6:
			var enemy: Dictionary = game._target(f, target_id, false, 8.0)
			if enemy.is_empty():
				return false
			if game._deal_damage(f, enemy, 6.0) and enemy.alive:
				game.afflict(enemy, "burn", 3.0, 4.0, f.id)
		7:
			if prism.is_empty():
				return false
			var struck := false
			for rival in game.fighters:
				if rival.alive and rival.team != f.team and _inside(game, prism.position, rival.position, 3.5):
					game._deal_damage(f, rival, 28.0)
					struck = true
			if not struck:
				return false
			_remove_anchor(game, f, "prism")
		_:
			return false
	return true
