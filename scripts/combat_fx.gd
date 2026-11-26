extends Node3D

# Each entry follows its class spellbook in slot order. Team color stays in
# the impact accent while the class supplies the spell's color and silhouette.
const STYLES = {
	"breakwater": ["a7c6d9", "plate", ["cut","ward","thread","interrupt","dash","sweep","crush","rally"]],
	"threadkeeper": ["cd95f4", "thread", ["needle","heal","ward","heal","thread","dash","thread","rally"]],
	"echo_duelist": ["62d9ff", "echo", ["cut","dash","sweep","ward","dash","cut","interrupt","sweep"]],
	"forgecaller": ["ff9356", "ember", ["bolt","brand","chain","ward","field","wave","ward","crush"]],
	"lamplighter": ["ffd16a", "flame", ["bolt","heal","field","ward","wave","thread","dash","rally"]],
	"longwatch": ["92db87", "fletch", ["needle","brand","needle","dash","interrupt","volley","field","needle"]],
	"sluicecaller": ["51dce0", "water", ["wave","field","wave","field","dash","wave","field","field"]],
	"glassmage": ["a4f7ea", "prism", ["bolt","field","dash","ward","brand","ward","thread","burst"]],
	"blood_cantor": ["f16b92", "blood", ["thread","heal","thread","ward","interrupt","rally","sweep","heal"]],
	"bellwarden": ["f2ca83", "bell", ["crush","ward","wave","wave","dash","interrupt","ward","rally"]],
	"ash_dancer": ["ff8548", "ember", ["cut","dash","cut","sweep","interrupt","ward","dash","sweep"]],
	"winter_scribe": ["aecdfc", "frost", ["needle","field","burst","dash","ward","brand","interrupt","field"]],
	"dream_shepherd": ["deb2ff", "dream", ["bolt","heal","ward","dash","cleanse","brand","field","rally"]],
	"chainrunner": ["b5b9dd", "links", ["cut","chain","dash","chain","sweep","dash","thread","crush"]],
	"coilwright": ["f5da73", "spark", ["zap","brand","zap","zap","dash","ward","interrupt","field"]],
	"duskmoth": ["f0a6e5", "moth", ["cut","swarm","dash","ward","needle","swarm","cleanse","burst"]],
}
const TEAM_ACCENTS = [Color("74f4ef"), Color("ff9070")]
const MAX_TRANSIENTS := 42


func play_cast(event: Dictionary, pawns: Dictionary) -> void:
	var slot: int = event.slot
	var style: Array = STYLES.get(event.class_id, [])
	if slot < 0 or slot >= 8 or style.is_empty():
		return
	var motif: String = style[1]
	var pattern: String = style[2][slot]
	var caster: Dictionary = pawns.get(event.source_id, {})
	var strong := slot == 7
	if not caster.is_empty():
		caster["fx_action"] = pattern
		caster["fx_action_left"] = 0.42 if strong else 0.30
		caster["fx_action_duration"] = caster.fx_action_left
		caster["fx_hand"] = -float(caster.get("fx_hand", -1.0))
	# Six bots can trade abilities in a single frame. Keep the newest significant
	# actions readable while earlier flourishes complete at their natural rate.
	if get_child_count() >= MAX_TRANSIENTS:
		if not strong:
			return
		var oldest := get_child(0)
		remove_child(oldest)
		oldest.queue_free()

	var cast := Node3D.new()
	add_child(cast)
	var tint := Color(str(style[0]))
	var accent: Color = TEAM_ACCENTS[clampi(event.team, 0, 1)]
	var ink := _ink(tint.lerp(accent, 0.10), 0.87)
	var rim := _ink(accent, 0.68)
	var origin := _floor_point(event.origin)
	var landing := _floor_point(event.source_after)
	var destination := _floor_point(event.destination)
	var direction := destination - origin
	if direction.length_squared() < 0.001:
		var facing: Vector2 = event.get("facing", Vector2.UP)
		direction = Vector3(facing.x, 0.0, facing.y)
	direction.y = 0
	direction = direction.normalized()
	var chest := Vector3.UP * 0.91
	var strength := 1.36 if strong else 1.0
	var duration := 0.52 if strong else 0.36
	match pattern:
		"cut", "sweep", "crush":
			_weapon_arc(cast, origin, direction, pattern, strength, ink)
			if pattern == "crush":
				_sigil(cast, destination, 0.74 * strength, motif, rim)
		"dash":
			var distance := origin.distance_to(landing)
			if distance > 0.12:
				var side := (landing - origin).normalized().cross(Vector3.UP) * 0.18
				for offset in [-side, side]:
					_ribbon(cast, PackedVector3Array([origin + offset + Vector3.UP * 0.19, landing + offset + Vector3.UP * 0.08]), 0.055, ink)
				_sigil(cast, landing, 0.46, motif, rim)
			else:
				_sigil(cast, destination, 0.64, motif, ink)
		"bolt", "needle", "volley":
			var shots := 3 if pattern == "volley" else 1
			for n in shots:
				var spread := direction.cross(Vector3.UP) * (n - (shots - 1) * 0.5) * 0.48
				_projectile(cast, origin + chest, destination + chest + spread, direction, motif, pattern, strength, ink)
		"zap", "chain", "thread":
			_tether(cast, origin + chest, destination + chest, pattern, motif, strength, ink)
			if event.class_id == "coilwright" and slot == 2:
				for fighter_id in event.get("affected_positions", {}):
					if fighter_id != event.target_id:
						var hit := _floor_point(event.affected_positions[fighter_id])
						_tether(cast, destination + chest, hit + chest, pattern, motif, strength, ink)
		"wave":
			var wave := Node3D.new()
			cast.add_child(wave)
			wave.position = origin + Vector3.UP * 0.33
			wave.rotation.y = atan2(-direction.x, -direction.z)
			_ribbon(wave, _arc(Vector3.ZERO, 0.7 * strength, -1.21, 1.21, 12), 0.14, ink)
			if motif == "bell" or motif == "water":
				_ribbon(wave, _arc(Vector3(0, 0.12, 0.21), 0.65 * strength, -1.05, 1.05, 10), 0.065, rim)
			wave.create_tween().tween_property(wave, "position", destination + Vector3.UP * 0.35, 0.19)
		"ward":
			_ward(cast, destination, motif, strength, ink)
		"heal", "cleanse", "rally":
			if pattern == "heal" and origin.distance_squared_to(destination) > 0.15:
				_tether(cast, origin + chest, destination + chest, "thread", motif, 0.72, ink)
			var healing := Node3D.new()
			cast.add_child(healing)
			healing.position = destination
			var radius := 0.57 * strength
			for n in 3:
				var angle := n * TAU / 3
				var offset := Vector3(cos(angle), 0, sin(angle)) * radius
				var rise := PackedVector3Array([offset + Vector3.UP * 0.14, offset.rotated(Vector3.UP, 0.42) + Vector3.UP * 0.58, offset.rotated(Vector3.UP, 0.91) * 0.58 + Vector3.UP * 1.15])
				_ribbon(healing, rise, 0.067, ink)
			healing.create_tween().tween_property(healing, "position:y", 0.48, duration)
			_sigil(cast, destination, 1.15 if pattern == "rally" else 0.50, motif, rim)
		"field", "brand", "burst", "interrupt", "swarm":
			var radius := 0.46 if pattern == "brand" else 0.92
			_sigil(cast, destination, radius * strength, motif, ink)
			match pattern:
				"interrupt":
					var impact := destination + Vector3.UP * 1.0
					for sign_x in [-1.0, 1.0]:
						_ribbon(cast, PackedVector3Array([impact + Vector3(sign_x * 0.44, -0.25, 0.04), impact + Vector3(-sign_x * 0.44, 0.34, 0.04)]), 0.1, rim)
				"swarm", "burst":
					var swarm := Node3D.new()
					cast.add_child(swarm)
					swarm.position = destination + Vector3.UP * 0.60
					for n in 5:
						var angle := TAU * n / 5
						var outward := Vector3(cos(angle), 0.20 + 0.23 * (n % 2), sin(angle))
						_ribbon(swarm, PackedVector3Array([outward * 0.28, outward * 0.65 + Vector3.UP * 0.20, outward * 0.95]), 0.078, ink)
					swarm.create_tween().tween_property(swarm, "scale", Vector3.ONE * (1.22 * strength), duration)
				"brand":
					_diamond(cast, destination + Vector3.UP * 1.23, 0.20, ink)
	if strong:
		_ribbon(cast, _arc(destination + Vector3.UP * 0.08, 1.04, -PI, PI, 24), 0.045, rim)
	var fade := cast.create_tween()
	fade.tween_interval(0.14)
	fade.set_parallel(true)
	fade.tween_property(ink, "albedo_color:a", 0.0, duration - 0.14)
	fade.tween_property(rim, "albedo_color:a", 0.0, duration - 0.14)
	fade.chain().tween_callback(cast.queue_free)


func _weapon_arc(parent: Node3D, position: Vector3, heading: Vector3, pattern: String, strength: float, ink: Material) -> void:
	var swing := Node3D.new()
	parent.add_child(swing)
	swing.position = position + Vector3.UP * 0.90
	swing.rotation.y = atan2(-heading.x, -heading.z)
	swing.rotation.z = -0.37 if pattern == "cut" else 0.18
	var extent := 2.35 if pattern == "sweep" else 1.12
	var radius := 1.24 * strength
	_ribbon(swing, _arc(Vector3.ZERO, radius, -extent, extent, 16), 0.15 * strength, ink)
	_ribbon(swing, _arc(Vector3.UP * 0.09, radius - 0.15, -extent * 0.68, extent * 0.86, 12), 0.048, ink)
	swing.create_tween().tween_property(swing, "rotation:y", swing.rotation.y + 0.65, 0.17)


func _projectile(parent: Node3D, start: Vector3, finish: Vector3, heading: Vector3, motif: String, pattern: String, strength: float, ink: Material) -> void:
	var bolt := Node3D.new()
	parent.add_child(bolt)
	bolt.position = start
	var tip := heading * 0.28 * strength
	var tail := -heading * (0.85 if pattern == "needle" else 0.48)
	_ribbon(bolt, PackedVector3Array([tail, tip]), 0.092 * strength, ink)
	if motif in ["prism", "frost", "dream", "moth"]:
		_diamond(bolt, tip, 0.16, ink)
	elif motif in ["fletch", "ember", "flame"]:
		var wing := heading.cross(Vector3.UP) * 0.17
		_ribbon(bolt, PackedVector3Array([tail + wing, tail * 0.55, tail - wing]), 0.065, ink)
	bolt.create_tween().tween_property(bolt, "position", finish, clampf(start.distance_to(finish) / 27.0, 0.06, 0.24))


func _tether(parent: Node3D, start: Vector3, finish: Vector3, pattern: String, motif: String, strength: float, ink: Material) -> void:
	if start.distance_squared_to(finish) <= 0.016:
		_sigil(parent, finish - Vector3.UP * 0.68, 0.42, motif, ink)
		return
	var axis := (finish - start).normalized()
	var across := axis.cross(Vector3.UP).normalized()
	var path := PackedVector3Array()
	var length := start.distance_to(finish)
	var count := clampi(ceili(length * 1.8), 4, 18)
	for i in range(count + 1):
		var t := float(i) / count
		var point := start.lerp(finish, t)
		var envelope := sin(PI * t)
		match pattern:
			"zap":
				point += across * sin(i * 2.43) * envelope * 0.35
				point.y += sin(i * 1.94) * envelope * 0.32
			"chain":
				point.y -= envelope * 0.36
				if i % 2 == 1:
					_diamond(parent, point, 0.087, ink)
			"thread":
				point += across * sin(t * TAU) * envelope * 0.18
				point.y += envelope * 0.28
		path.append(point)
	_ribbon(parent, path, (0.067 if pattern == "thread" else 0.095) * strength, ink)


func _ward(parent: Node3D, at: Vector3, motif: String, strength: float, ink: Material) -> void:
	_sigil(parent, at, 0.62 * strength, motif, ink)
	for i in 3:
		var angle := TAU * i / 3.0
		var side := Vector3(cos(angle), 0, sin(angle))
		var spine := PackedVector3Array()
		for j in 9:
			var t := float(j) / 8
			spine.append(at + side * sin(t * PI) * 0.74 * strength + Vector3.UP * (0.13 + t * 1.52))
		_ribbon(parent, spine, 0.08, ink)


func _sigil(parent: Node3D, at: Vector3, radius: float, motif: String, ink: Material) -> void:
	var center := at + Vector3.UP * 0.085
	var sides := 22
	match motif:
		"frost": sides = 6
		"prism", "plate": sides = 4
		"ember", "flame": sides = 3
		"links", "spark": sides = 8
		"moth", "fletch": sides = 5
		"blood": sides = 7
	var ring := Node3D.new()
	parent.add_child(ring)
	ring.position = center
	_ribbon(ring, _arc(Vector3.ZERO, radius, -PI, PI, sides), 0.065, ink)
	if motif in ["dream", "echo", "water", "bell"]:
		_ribbon(ring, _arc(Vector3.ZERO, radius * 0.77, -1.74, 1.74, 12), 0.038, ink)
	ring.scale = Vector3.ONE * 0.76
	ring.create_tween().tween_property(ring, "scale", Vector3.ONE * 1.14, 0.24)


func _diamond(parent: Node3D, at: Vector3, radius: float, ink: Material) -> void:
	_ribbon(parent, PackedVector3Array([at + Vector3.UP * radius, at + Vector3.RIGHT * radius, at - Vector3.UP * radius, at - Vector3.RIGHT * radius, at + Vector3.UP * radius]), radius * 0.37, ink)


func _arc(center: Vector3, radius: float, start: float, finish: float, steps: int) -> PackedVector3Array:
	var points := PackedVector3Array()
	for i in range(steps + 1):
		var angle := lerpf(start, finish, float(i) / steps)
		points.append(center + Vector3(sin(angle), 0.0, -cos(angle)) * radius)
	return points


func _ribbon(parent: Node3D, points: PackedVector3Array, width: float, ink: Material) -> void:
	if points.size() < 2:
		return
	var vertices := PackedVector3Array()
	for i in range(points.size() - 1):
		var a := points[i]
		var b := points[i + 1]
		var delta := b - a
		if delta.length_squared() <= 0.000001:
			continue
		var side := delta.normalized().cross(Vector3.UP)
		if side.length_squared() < 0.06:
			side = Vector3.RIGHT
		var half := side.normalized() * width * 0.5
		vertices.append_array(PackedVector3Array([a - half, b + half, a + half, a - half, b - half, b + half]))
	if vertices.is_empty():
		return
	var surfaces := []
	surfaces.resize(Mesh.ARRAY_MAX)
	surfaces[Mesh.ARRAY_VERTEX] = vertices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surfaces)
	var strip := MeshInstance3D.new()
	strip.mesh = mesh
	strip.material_override = ink
	strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(strip)


func _ink(color: Color, alpha: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(color, alpha)
	return material


func _floor_point(plane: Vector2) -> Vector3:
	return Vector3(plane.x, 0.0, plane.y)


func animate_fighter(pawn: Dictionary, fighter: Dictionary, delta: float) -> void:
	var rig: Node3D = pawn.rig
	var at: Vector2 = fighter.position
	var health: float = fighter.health
	if not pawn.has("fx_parts"):
		_bind_pose(pawn, at, health)
	var previous: Vector2 = pawn.fx_position
	var travel := at.distance_to(previous)
	var dt := clampf(delta, 0.0, 0.1)
	pawn.fx_position = at
	if not fighter.alive:
		pawn.fx_action_left = 0.0
		pawn.fx_health = health
		return
	var speed := clampf(travel / maxf(0.001, dt), 0.0, 6.0) if travel < 2.5 else 0.0
	var class_id: String = fighter.class_id
	var is_heavy := class_id in ["breakwater", "forgecaller", "bellwarden"]
	var is_light := class_id in ["chainrunner", "ash_dancer", "duskmoth", "echo_duelist"]
	var gait: float = lerpf(pawn.fx_gait, speed / 6.0, minf(1.0, dt * 13.0))
	pawn.fx_gait = gait
	pawn.fx_phase += dt * (3.3 + gait * (10.5 if is_light else 7.6))
	var stride := sin(float(pawn.fx_phase))
	var breathe := sin(float(pawn.fx_phase) * 0.58)
	var lost := float(pawn.fx_health) - health
	pawn.fx_health = health
	if lost > 1.0:
		pawn.fx_flinch = minf(1.0, 0.3 + lost / 36.0)
	pawn.fx_flinch = maxf(0.0, float(pawn.fx_flinch) - dt * 4.6)
	pawn.fx_action_left = maxf(0.0, float(pawn.fx_action_left) - dt)
	var t := 1.0 - float(pawn.fx_action_left) / maxf(0.01, float(pawn.fx_action_duration))
	var strike := sin(PI * t) if t < 1.0 else 0.0
	var side: float = pawn.fx_hand
	var move_pitch := -gait * (0.09 if is_heavy else 0.15)
	var twist := 0.0
	var arm_swing := 0.16 + 0.28 * gait * stride
	var action: String = pawn.get("fx_action", "")
	var lift := 0.0
	match action:
		"cut", "crush", "sweep", "chain":
			move_pitch -= strike * 0.26
			twist = side * strike * 0.21
			arm_swing -= strike * (1.12 if action == "crush" else 0.89)
		"ward", "brand", "field":
			move_pitch += strike * 0.13
			arm_swing -= strike * 0.68
			lift = -strike * 0.055
		"rally", "cleanse", "heal", "thread", "burst":
			arm_swing -= strike * 1.04
			lift = strike * 0.09
		"dash":
			move_pitch -= strike * 0.35
			twist = side * strike * 0.12
			lift = strike * 0.10
		_:
			move_pitch += strike * 0.16
			arm_swing -= strike * 0.82
	if fighter.get("mend_time", 0.0) > 0.0:
		arm_swing = -0.8
	var flinch: float = pawn.fx_flinch
	rig.position.y = (absf(stride) * gait * (0.065 if is_heavy else 0.105)) + breathe * 0.013 + lift
	rig.rotation.x = move_pitch + flinch * 0.19
	rig.rotation.z = gait * stride * 0.045 + twist + side * flinch * 0.09
	for part: Dictionary in pawn.fx_parts:
		var angle: float
		if part.kind == "hand":
			angle = arm_swing + sin(float(pawn.fx_phase) * 0.58) * 0.035
		else:
			angle = stride * gait * float(part.side) * (0.35 if is_heavy else 0.55)
		var spin := Basis(Vector3.RIGHT, angle)
		var joint: Vector3 = part.pivot
		var body_part: Node3D = part.node
		# Rotate the whole limb around a joint in rig space, preserving the
		# original geometry and all authored class equipment orientations.
		body_part.transform = Transform3D(spin, joint - spin * joint) * (part.rest as Transform3D)


func _bind_pose(pawn: Dictionary, at: Vector2, health: float) -> void:
	var rig: Node3D = pawn.rig
	var parts: Array[Dictionary] = []
	for child in rig.get_children():
		if not child is MeshInstance3D or child == pawn.get("brace"):
			continue
		var p: Vector3 = child.position
		var sign_x := 1.0 if p.x >= 0.0 else -1.0
		if p.y < 0.58 and absf(p.x) > 0.12 and absf(p.x) < 0.34:
			parts.append({"node": child, "rest": child.transform, "kind": "leg", "side": sign_x, "pivot": Vector3(p.x, 0.55, 0.0)})
		elif p.x > 0.40 and p.z < 0.14 and p.y > 0.50:
			parts.append({"node": child, "rest": child.transform, "kind": "hand", "side": 1.0, "pivot": Vector3(0.35, 1.22, 0.0)})
	pawn["fx_parts"] = parts
	pawn["fx_gait"] = 0.0
	pawn["fx_phase"] = absf(at.x + at.y) * 0.35
	pawn["fx_position"] = at
	pawn["fx_health"] = health
	pawn["fx_flinch"] = 0.0
	if not pawn.has("fx_action_left"):
		pawn["fx_action_left"] = 0.0
		pawn["fx_action_duration"] = 1.0
		pawn["fx_hand"] = 1.0
