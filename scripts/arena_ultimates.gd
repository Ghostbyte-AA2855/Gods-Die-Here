extends RefCounted

# A warning is committed to its world position. The renderer and resolution
# use the same shape and radius, even if the original target moves.
const SLOT := 8
const CHARGE_REQUIRED := 100.0
const CLEANSABLE := ["root", "silence", "slow", "burn", "weaken"]
const KITS := {
	"breakwater": {
		"name": "The Drowned Gate", "pattern": "bulwark", "tint": Color("86e6ff"),
		"description": "Raise a gate of abyssal iron. Shield your team, reduce incoming damage, and hurl nearby rivals back.",
		"target": "self", "side": "enemy", "windup": 0.95, "radius": 4.1, "reach": 0.0,
	},
	"threadkeeper": {
		"name": "The Last Thread", "pattern": "threads", "tint": Color("efd0ff"),
		"description": "Reweave the lives of allies in the circle. Clear harmful effects and deferred wounds, then heal them.",
		"target": "aim", "side": "ally", "windup": 0.85, "radius": 3.8, "reach": 8.0,
	},
	"echo_duelist": {
		"name": "A Thousand Final Cuts", "pattern": "echo", "tint": Color("c9efff"),
		"description": "Carve through a marked lane with a legion of afterimages. Cut and slow rivals along the path.",
		"target": "aim", "side": "enemy", "windup": 0.75, "radius": 1.35, "reach": 8.0, "shape": "line",
	},
	"forgecaller": {
		"name": "Godfall Hammer", "pattern": "meteor", "tint": Color("ffb563"),
		"description": "Call an incandescent hammer down on the marked circle. The center hits hardest and stuns. The crater keeps burning.",
		"target": "aim", "side": "enemy", "windup": 1.04, "radius": 3.2, "reach": 7.0,
	},
	"lamplighter": {
		"name": "The Last Sunrise", "pattern": "lantern", "tint": Color("ffdf90"),
		"description": "Ignite a dying sun. Heal allies on impact and leave a sanctuary that repeatedly shields your team.",
		"target": "aim", "side": "ally", "windup": 0.92, "radius": 3.9, "reach": 8.0,
	},
	"longwatch": {
		"name": "The Sky Is a Killing Field", "pattern": "volley", "tint": Color("e5ec9a"),
		"description": "Darken the sky with arrows. The volley slows all rivals hit and tears deeper into your marked quarry.",
		"target": "aim", "side": "enemy", "windup": 0.96, "radius": 3.4, "reach": 10.0,
	},
	"sluicecaller": {
		"name": "Drown the Court", "pattern": "vortex", "tint": Color("72fff0"),
		"description": "Open a churning whirlpool that drags rivals inward. Floodwater slows anyone on the opposing team who stays in it.",
		"target": "aim", "side": "enemy", "windup": 0.94, "radius": 4.0, "reach": 7.5,
	},
	"glassmage": {
		"name": "Cathedral of Shards", "pattern": "prism", "tint": Color("c9fbff"),
		"description": "Build a cathedral of a thousand blades, then shatter it. Rivals near the center take heavier damage and are rooted briefly.",
		"target": "aim", "side": "enemy", "windup": 1.0, "radius": 3.6, "reach": 8.0,
	},
	"blood_cantor": {
		"name": "Red Communion", "pattern": "blood", "tint": Color("ff739c"),
		"description": "Harvest the blood of rivals inside the ring. Restore health to nearby allies based on the damage you actually deal.",
		"target": "aim", "side": "enemy", "windup": 0.87, "radius": 3.4, "reach": 7.5,
	},
	"bellwarden": {
		"name": "The Ninth Toll", "pattern": "bell", "tint": Color("ffe4a3"),
		"description": "Ring a bell that sunders the court. Damage and silence rivals while your allies move faster.",
		"target": "self", "side": "enemy", "windup": 0.92, "radius": 4.6, "reach": 0.0,
	},
	"ash_dancer": {
		"name": "Dance of the Black Sun", "pattern": "inferno", "tint": Color("ffac61"),
		"description": "Spin through an eclipse of fire. Carve through rivals around you, set them burning, and accelerate out of the flames.",
		"target": "self", "side": "enemy", "windup": 0.78, "radius": 4.4, "reach": 0.0,
	},
	"winter_scribe": {
		"name": "The Last Winter", "pattern": "frost", "tint": Color("bcf4ff"),
		"description": "Inscribe a frost rune that roots and wounds rivals. The ruined rune leaves a lingering field of ice that slows them.",
		"target": "aim", "side": "enemy", "windup": 0.97, "radius": 3.9, "reach": 8.5,
	},
	"dream_shepherd": {
		"name": "Throne Beyond Sleep", "pattern": "dream", "tint": Color("decaff"),
		"description": "Raise the throne of the sleeping king. Wake allies from stuns, root, and silence, then shield them and blunt incoming damage.",
		"target": "aim", "side": "ally", "windup": 0.83, "radius": 4.0, "reach": 8.0,
	},
	"chainrunner": {
		"name": "The Gallows Choir", "pattern": "chains", "tint": Color("e1b7ff"),
		"description": "Drop a cage of chains over the marked ground. Briefly root rivals and drag them toward you.",
		"target": "aim", "side": "enemy", "windup": 0.88, "radius": 3.8, "reach": 7.0,
	},
	"coilwright": {
		"name": "Thunder the Dead", "pattern": "lightning", "tint": Color("a5d8ff"),
		"description": "Split the sky with branching lightning. Rivals you have polarized take a stronger strike. Every hit polarizes its target.",
		"target": "aim", "side": "enemy", "windup": 0.82, "radius": 3.6, "reach": 8.5,
	},
	"duskmoth": {
		"name": "A Sky of Hungry Wings", "pattern": "swarm", "tint": Color("ffb2d9"),
		"description": "Unleash a swarm that wounds, weakens, and dusts rivals. Slip through incoming attacks as the swarm opens.",
		"target": "aim", "side": "enemy", "windup": 0.85, "radius": 3.8, "reach": 7.5,
	},
}


static func warning(game, fighter: Dictionary, target_id: int) -> Dictionary:
	var spec: Dictionary = KITS[fighter.class_id]
	var origin: Vector2 = fighter.position
	var heading: Vector2 = fighter.facing
	var destination := origin
	var chosen := -1
	var shape: String = spec.get("shape", "circle")
	if spec.target == "aim":
		var ally: bool = spec.side == "ally"
		var mode := "injured" if ally and target_id < 0 else "nearest"
		var target: Dictionary = game._target(fighter, target_id, ally, spec.reach, mode)
		if target.is_empty() and target_id != -1:
			target = game._target(fighter, -1, ally, spec.reach, "injured" if ally else "nearest")
		var distance: float = spec.reach
		if not target.is_empty():
			chosen = target.id
			var offset: Vector2 = target.position - origin
			if offset.length_squared() > 0.001:
				heading = offset.normalized()
			if shape != "line":
				distance = offset.length()
		elif ally:
			distance = 0.0
		destination = game.aim_point({"position": origin, "facing": heading}, distance)
	return {
		"source_id": fighter.id, "class_id": fighter.class_id, "team": fighter.team,
		"name": spec.name, "pattern": spec.pattern, "tint": spec.tint,
		"slot": SLOT, "ultimate": true, "origin": origin, "destination": destination,
		"radius": spec.radius, "facing": heading, "remaining": spec.windup, "duration": spec.windup,
		"windup": spec.windup, "target_id": chosen, "target_kind": spec.side, "shape": shape,
		"width": spec.radius * 2.0, "length": origin.distance_to(destination),
	}


static func contains(cast: Dictionary, point: Vector2, padding: float = 0.0) -> bool:
	var radius: float = cast.radius + padding
	return point.distance_squared_to(closest_point(cast, point)) <= radius * radius


static func closest_point(cast: Dictionary, point: Vector2) -> Vector2:
	if cast.shape == "line" and cast.length > 0.001:
		return Geometry2D.get_closest_point_to_segment(point, cast.origin, cast.destination)
	return cast.destination


static func can_usefully_resolve(game, cast: Dictionary) -> bool:
	var spec: Dictionary = KITS[cast.class_id]
	if spec.side == "ally":
		for ally in _units(game, cast, cast.team):
			if ally.health < ally.max_health * 0.83 or ally.stun > 0.0 or game.has_status(ally, "silence"):
				return true
		return false
	return not _units(game, cast, 1 - int(cast.team)).is_empty()


static func resolve(game, source: Dictionary, cast: Dictionary) -> void:
	var allies := _units(game, cast, source.team)
	var rivals := _units(game, cast, 1 - int(source.team))
	var center: Vector2 = cast.destination
	match source.class_id:
		"breakwater":
			for ally in allies:
				game.shield(ally, 95.0, 5.0)
				_status(game, source, ally, "fortify", 5.0, 0.24)
			for rival in rivals:
				if game._deal_damage(source, rival, 63.0):
					game._move(rival, center.direction_to(rival.position) * 2.5, false)
		"threadkeeper":
			for ally in allies:
				game.cleanse(ally, CLEANSABLE)
				ally.stun = 0.0
				ally.wound_time = 0.0
				ally.wound_damage = 0.0
				game.heal(source, ally, 118.0)
				_status(game, source, ally, "regen", 4.0, 8.0)
		"echo_duelist":
			for rival in rivals:
				if game._deal_damage(source, rival, 112.0):
					_status(game, source, rival, "slow", 2.25, 0.45)
			var start: Vector2 = source.position
			game._move(source, center - start, false)
			source.echo_start = start
			source.echo_end = source.position
			source.echo_time = 3.0
		"forgecaller":
			for rival in rivals:
				var inner := center.distance_squared_to(rival.position) <= 2.25
				if game._deal_damage(source, rival, 126.0 if inner else 88.0) and inner:
					rival.stun = maxf(rival.stun, 0.85)
					game.interrupt(rival)
			game.place_field(source, "damage", center, cast.radius, 4.0, 12.0)
		"lamplighter":
			for ally in allies:
				game.heal(source, ally, 92.0)
			game.place_field(source, "ward", center, cast.radius, 5.0, 44.0)
		"longwatch":
			for rival in rivals:
				var marked: bool = game.marked(source, rival, "quarry")
				if game._deal_damage(source, rival, 137.0 if marked else 102.0):
					_status(game, source, rival, "slow", 2.0, 0.35)
		"sluicecaller":
			for rival in rivals:
				if game._deal_damage(source, rival, 86.0):
					game._move(rival, ((rival.position as Vector2) - center).limit_length(2.3) * -0.78, false)
					game.mark(source, rival, "undertow", 4.0)
			game.place_field(source, "slow", center, cast.radius, 4.0, 0.45)
		"glassmage":
			for rival in rivals:
				var inner := center.distance_squared_to(rival.position) <= 2.56
				if game._deal_damage(source, rival, 132.0 if inner else 93.0) and inner:
					_status(game, source, rival, "root", 1.15)
		"blood_cantor":
			var drained := 0.0
			for rival in rivals:
				var previous: float = rival.health
				if game._deal_damage(source, rival, 101.0):
					drained += maxf(0.0, previous - float(rival.health))
					game.mark(source, rival, "blood_sample", 6.0)
			if drained > 0.0:
				var recipients := cast.duplicate()
				recipients.destination = cast.origin
				recipients.radius = 4.8
				for ally in _units(game, recipients, source.team):
					game.heal(source, ally, minf(112.0, drained * 0.48))
		"bellwarden":
			for rival in rivals:
				if game._deal_damage(source, rival, 69.0):
					_status(game, source, rival, "silence", 1.55)
			for ally in allies:
				_status(game, source, ally, "haste", 3.0, 0.30)
		"ash_dancer":
			for rival in rivals:
				if game._deal_damage(source, rival, 96.0):
					_status(game, source, rival, "burn", 3.0, 14.0)
					game.mark(source, rival, "ash_brand", 5.0)
			_status(game, source, source, "haste", 3.5, 0.36)
		"winter_scribe":
			for rival in rivals:
				if game._deal_damage(source, rival, 74.0):
					_status(game, source, rival, "root", 1.45)
			game.place_field(source, "slow", center, cast.radius, 5.0, 0.42)
		"dream_shepherd":
			for ally in allies:
				game.cleanse(ally, ["root", "silence"])
				ally.stun = 0.0
				game.shield(ally, 110.0, 5.0)
				_status(game, source, ally, "fortify", 5.0, 0.32)
		"chainrunner":
			for rival in rivals:
				if game._deal_damage(source, rival, 84.0):
					var from: Vector2 = rival.position
					game._move(rival, ((cast.origin as Vector2) - from).limit_length(2.75), false)
					_status(game, source, rival, "root", 0.9)
					game.mark(source, rival, "hooked", 5.0)
		"coilwright":
			for rival in rivals:
				var polarized: bool = game.marked(source, rival, "polarized")
				if game._deal_damage(source, rival, 145.0 if polarized else 103.0):
					game.mark(source, rival, "polarized", 7.0)
		"duskmoth":
			for rival in rivals:
				if game._deal_damage(source, rival, 82.0):
					_status(game, source, rival, "weaken", 5.0, 0.26)
					game.mark(source, rival, "dusted", 7.0)
			source.evade = maxf(source.evade, 0.6)


static func _status(game, source: Dictionary, target: Dictionary, kind: String, seconds: float, power: float = 0.0) -> void:
	if target.alive:
		game._note_affected(target)
		game.afflict(target, kind, seconds, power, source.id)


static func _units(game, cast: Dictionary, team: int) -> Array[Dictionary]:
	var units: Array[Dictionary] = []
	for fighter: Dictionary in game.fighters:
		if fighter.team != team or not fighter.alive:
			continue
		var point: Vector2 = fighter.position
		if contains(cast, point) and game._has_sight(closest_point(cast, point), point):
			units.append(fighter)
	return units
