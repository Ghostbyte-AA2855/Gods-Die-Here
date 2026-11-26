extends Node3D

const JOINT_LAYOUT := {
	"pelvis": ["", Vector3(0, 0.87, 0)],
	"spine": ["pelvis", Vector3(0, 1.04, 0)],
	"head": ["spine", Vector3(0, 1.58, 0)],
	"mantle": ["spine", Vector3(0, 1.36, 0.16)],
	"ornament": ["spine", Vector3(0, 1.44, 0)],
	"upper_l": ["spine", Vector3(-0.34, 1.38, 0)],
	"fore_l": ["upper_l", Vector3(-0.52, 1.08, 0)],
	"hand_l": ["fore_l", Vector3(-0.60, 0.87, -0.025)],
	"upper_r": ["spine", Vector3(0.34, 1.38, 0)],
	"fore_r": ["upper_r", Vector3(0.52, 1.08, 0)],
	"hand_r": ["fore_r", Vector3(0.60, 0.87, -0.025)],
	"thigh_l": ["pelvis", Vector3(-0.17, 0.85, 0)],
	"shin_l": ["thigh_l", Vector3(-0.18, 0.51, 0)],
	"foot_l": ["shin_l", Vector3(-0.18, 0.19, 0)],
	"thigh_r": ["pelvis", Vector3(0.17, 0.85, 0)],
	"shin_r": ["thigh_r", Vector3(0.18, 0.51, 0)],
	"foot_r": ["shin_r", Vector3(0.18, 0.19, 0)],
}
const Anatomy = preload("res://scripts/champions/anatomy.gd")
const Finish = preload("res://scripts/champions/surface_finish.gd")
const Animations = preload("res://scripts/champions/animations.gd")
const GROUPS := {
	"breakwater":0, "threadkeeper":0, "echo_duelist":0, "forgecaller":0,
	"lamplighter":1, "longwatch":1, "sluicecaller":1, "glassmage":1,
	"blood_cantor":2, "bellwarden":2, "ash_dancer":2, "winter_scribe":2,
	"dream_shepherd":3, "chainrunner":3, "coilwright":3, "duskmoth":3,
}
const SCULPTS := [
	preload("res://scripts/champions/drowned.gd"), preload("res://scripts/champions/hollow.gd"),
	preload("res://scripts/champions/ash.gd"), preload("res://scripts/champions/crypt.gd")
]
static var _model_cache: Dictionary = {}
static var _materials: Dictionary = {}

var joints: Dictionary = {}
var player: AnimationPlayer
var champion: String
var _parts: Dictionary = {}
var _build_type: String
var _locomotion := "idle"
var _previous_position := Vector2.ZERO
var _motion_velocity := Vector2.ZERO
var _initialized_motion := false
var _previous_health := 0.0
var _previous_stun := false


func build(class_id: String, archetype: String) -> void:
	name = "ChampionRig"
	champion = class_id
	_build_type = archetype
	for key in JOINT_LAYOUT:
		var parent_name: String = JOINT_LAYOUT[key][0]
		var node := Node3D.new()
		node.name = key
		var rest := _proportioned(JOINT_LAYOUT[key][1], key)
		if parent_name.is_empty():
			add_child(node)
			node.position = rest
		else:
			joints[parent_name].add_child(node)
			node.position = rest - _proportioned(JOINT_LAYOUT[parent_name][1], parent_name)
		joints[key] = node
	if not _model_cache.has(class_id):
		Anatomy.dress(self, class_id, archetype)
		SCULPTS[GROUPS[class_id]].build(self, class_id)
		_model_cache[class_id] = _bake()
		_parts.clear()
	var meshes: Dictionary = _model_cache[class_id]
	for joint in meshes:
		var piece := MeshInstance3D.new()
		piece.name = "Sculpt"
		piece.mesh = meshes[joint]
		joints[joint].add_child(piece)
	player = AnimationPlayer.new()
	player.name = "Motion"
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	add_child(player)
	player.add_animation_library("", Animations.library(champion, archetype, self))
	player.play("idle")
	player.advance(0.0)


func reset_motion() -> void:
	_initialized_motion = false
	_motion_velocity = Vector2.ZERO
	_previous_stun = false
	_locomotion = "idle"
	player.play("idle")
	player.seek(0.0, true)


func watch(fighter: Dictionary, delta: float) -> void:
	var at: Vector2 = fighter.position
	var health: float = fighter.health
	if not _initialized_motion:
		_previous_position = at
		_previous_health = health
		_initialized_motion = true
	if delta <= 0.0:
		return
	var distance := at - _previous_position
	var velocity := distance / delta if distance.length_squared() < 7.0 else Vector2.ZERO
	_motion_velocity = _motion_velocity.lerp(velocity, 1.0 - exp(-18.0 * delta))
	var facing: Vector2 = fighter.facing
	var stunned: bool = fighter.stun > 0.0
	_locomotion = "idle"
	var cadence := 1.0
	if _motion_velocity.length_squared() > 0.43:
		var forward := facing.dot(_motion_velocity.normalized())
		if forward < -0.45:
			_locomotion = "backpedal"
		elif forward >= 0.5:
			_locomotion = "run"
		else:
			_locomotion = "strafe_right" if facing.cross(_motion_velocity) >= 0 else "strafe_left"
		cadence = clampf(_motion_velocity.length() / 4.5, 0.55, 1.4)
	if stunned and not _previous_stun:
		player.play("stagger", 0.035)
	elif fighter.mend_time > 0 and not stunned:
		if player.current_animation != "channel" and not str(player.current_animation).begins_with("cast_"):
			player.play("channel", 0.07)
	elif player.current_animation == "channel":
		player.play(_locomotion, 0.07)
	elif health <= _previous_health - 4.0 and str(player.current_animation) in ["idle","run","strafe_left","strafe_right","backpedal"]:
		player.play("hit", 0.035)
	elif player.current_animation.is_empty() or (str(player.current_animation) in ["idle","run","strafe_left","strafe_right","backpedal"] and player.current_animation != _locomotion):
		player.play(_locomotion, 0.10)
	var moving := str(player.current_animation) in ["run","strafe_left","strafe_right","backpedal"]
	player.speed_scale = cadence if moving else 1.0
	player.advance(delta)
	_previous_stun = stunned
	_previous_position = at
	_previous_health = health


func cast(slot: int) -> void:
	var name_of_clip := "cast_%d" % (slot + 1)
	player.play(name_of_clip, 0.045)
	player.speed_scale = 1.0
	# The rules have already accepted the spell. Show its contact promptly.
	var seconds := 0.0 if champion == "threadkeeper" and slot == 3 else Animations.visible_start(champion, slot)
	player.seek(seconds, true)


func release_point(slot: int) -> Vector3:
	return joints[Animations.release_hand(champion, slot)].global_position


func react(name_of_clip: String) -> void:
	player.play(name_of_clip, 0.035)
	player.speed_scale = 1.0
	player.seek(0.028, true)


func _proportioned(point: Vector3, joint: String) -> Vector3:
	# All authored pieces keep their original rest coordinates. This remaps
	# length and stance together with the attachment joints.
	var result := point
	if point.y <= 0.87:
		result.y = point.y * 1.30
	elif point.y <= 1.58:
		result.y = 1.131 + (point.y - 0.87) * 1.06
	else:
		result.y = 1.8836 + (point.y - 1.58) * 0.96
	var breadth := 1.12 if _build_type == "guard" else (1.035 if _build_type == "melee" else 0.97)
	result.x *= breadth
	if joint.begins_with("head"):
		result.x *= 0.88
	elif joint.begins_with("upper_") or joint.begins_with("fore_") or joint.begins_with("hand_"):
		var side := -1.0 if joint.ends_with("_l") else 1.0
		result.x -= side * 0.148 * (1.0 if joint.begins_with("hand_") else 1.0 - smoothstep(0.87, 1.37, point.y))
	result.z *= 1.05 if _build_type == "guard" else 1.0
	return result


func _section_scale(center: Vector3, joint: String) -> Vector3:
	var width := 1.12 if _build_type == "guard" else (1.035 if _build_type == "melee" else 0.97)
	if joint == "head":
		width *= 0.88
	var height := 1.30 if center.y < 0.87 else (1.06 if center.y < 1.58 else 0.96)
	return Vector3(width, height, 1.05 if _build_type == "guard" else 1.0)


func box(joint: String, center: Vector3, size: Vector3, color: String, rotation: Vector3 = Vector3.ZERO) -> void:
	var cut := minf(size.x, size.y) * 0.13
	var corners := PackedVector3Array([
		Vector3(-size.x / 2 + cut, -size.y / 2, 0), Vector3(size.x / 2 - cut, -size.y / 2, 0),
		Vector3(size.x / 2, -size.y / 2 + cut, 0), Vector3(size.x / 2, size.y / 2 - cut, 0),
		Vector3(size.x / 2 - cut, size.y / 2, 0), Vector3(-size.x / 2 + cut, size.y / 2, 0),
		Vector3(-size.x / 2, size.y / 2 - cut, 0), Vector3(-size.x / 2, -size.y / 2 + cut, 0)
	])
	var basis := Basis.from_euler(rotation)
	for i in corners.size():
		corners[i] = center + basis * corners[i]
	plate(joint, corners, size.z, color)


func ellipsoid(joint: String, center: Vector3, size: Vector3, color: String, rotation: Vector3 = Vector3.ZERO) -> void:
	var mesh := SphereMesh.new()
	mesh.radial_segments = 12
	mesh.rings = 7
	mesh.radius = 0.5
	mesh.height = 1.0
	_add(joint, center, Basis.from_euler(rotation) * Basis.from_scale(size), mesh, color)


func tube(joint: String, start: Vector3, finish: Vector3, start_radius: float, end_radius: float, color: String, sides: int = 8) -> void:
	var direction := finish - start
	if direction.length_squared() < 0.000001:
		return
	var mesh := CylinderMesh.new()
	mesh.radial_segments = maxi(sides, 3)
	mesh.rings = 0
	mesh.bottom_radius = maxf(start_radius, 0.0)
	mesh.top_radius = maxf(end_radius, 0.0)
	mesh.height = direction.length()
	_add(joint, start.lerp(finish, 0.5), Basis(Quaternion(Vector3.UP, direction.normalized())), mesh, color)


func band(joint: String, center: Vector3, radius: float, thickness: float, color: String, start: float = 0.0, span: float = TAU, tilt: Vector3 = Vector3.ZERO) -> void:
	var basis := Basis.from_euler(tilt)
	var steps := maxi(3, ceili(absf(span) * 3.1))
	var first := center + basis * Vector3(cos(start),sin(start),0) * radius
	for i in range(1, steps + 1):
		var a := start + span * i / steps
		var next := center + basis * Vector3(cos(a),sin(a),0) * radius
		tube(joint, first, next, thickness, thickness, color, 5)
		first = next


func loft(joint: String, rings: Array, color: String, sides: int = 12) -> void:
	if rings.size() < 2:
		return
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	builder.set_smooth_group(0)
	for row in range(rings.size() - 1):
		var lower: Array = rings[row]
		var upper: Array = rings[row + 1]
		for i in sides:
			var a := float(i) / sides
			var b := float(i + 1) / sides
			var p0 := _loft_point(lower, a)
			var p1 := _loft_point(lower, b)
			var p2 := _loft_point(upper, b)
			var p3 := _loft_point(upper, a)
			_uv_tri(builder, p0, p2, p1, Vector2(a,row),Vector2(b,row+1),Vector2(b,row))
			_uv_tri(builder, p0, p3, p2, Vector2(a,row),Vector2(a,row+1),Vector2(b,row+1))
	for end in [0, rings.size()-1]:
		builder.set_smooth_group(-1)
		var cap: Array = rings[end]
		for i in sides:
			var a := _loft_point(cap, float(i) / sides)
			var b := _loft_point(cap, float(i + 1) / sides)
			_flat_tri(builder, cap[0], a if end == 0 else b, b if end == 0 else a)
	builder.generate_normals()
	builder.generate_tangents()
	_add(joint, Vector3.ZERO, Basis.IDENTITY, builder.commit(), color, true)


func _loft_point(ring: Array, turn: float) -> Vector3:
	return ring[0] + Vector3(cos(turn * TAU) * ring[1], 0.0, -sin(turn * TAU) * ring[2])


func plate(joint: String, points: PackedVector3Array, depth: float, color: String) -> void:
	if points.size() < 3:
		return
	var start := points[0]
	var normal := Vector3.ZERO
	var center := Vector3.ZERO
	for pt in points:
		center += pt
	center /= points.size()
	for i in range(1, points.size() - 1):
		normal += (points[i] - start).cross(points[i+1] - start)
	if normal.length_squared() < 0.00000001:
		return
	normal = normal.normalized()
	var u := (points[1] - start).normalized()
	var v := normal.cross(u).normalized()
	var polygon := PackedVector2Array()
	for pt in points:
		polygon.append(Vector2((pt-start).dot(u),(pt-start).dot(v)))
	var triangles := Geometry2D.triangulate_polygon(polygon)
	if triangles.is_empty():
		return
	var face_offset := normal * depth * .5
	var bevel_width := minf(.025, absf(depth) * .28)
	var wall_offset := normal * (depth * .5 - bevel_width)
	var inset := PackedVector3Array()
	for pt in points:
		var amount := minf(.15, bevel_width / maxf(.02, pt.distance_to(center)))
		inset.append(pt.lerp(center, amount))
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	builder.set_smooth_group(-1)
	for i in range(0, triangles.size(), 3):
		var a := inset[triangles[i]]
		var b := inset[triangles[i+1]]
		var c := inset[triangles[i+2]]
		_flat_tri(builder, a + face_offset, c + face_offset, b + face_offset)
		_flat_tri(builder, a - face_offset, b - face_offset, c - face_offset)
	for i in points.size():
		var next := (i+1) % points.size()
		var a := points[i]
		var b := points[next]
		_flat_quad(builder, a + wall_offset,b + wall_offset,b - wall_offset,a - wall_offset)
		_flat_quad(builder, inset[i] + face_offset,inset[next] + face_offset,b + wall_offset,a + wall_offset)
		_flat_quad(builder, a - wall_offset,b - wall_offset,inset[next] - face_offset,inset[i] - face_offset)
	builder.generate_normals()
	builder.generate_tangents()
	_add(joint, Vector3.ZERO, Basis.IDENTITY, builder.commit(), color, true)


func _flat_quad(builder: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_flat_tri(builder,a,b,c)
	_flat_tri(builder,a,c,d)


func _flat_tri(builder: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var axis := (b - a).cross(c - a).abs()
	if axis.y >= axis.x and axis.y >= axis.z:
		_uv_tri(builder,a,b,c,Vector2(a.x,a.z)*3,Vector2(b.x,b.z)*3,Vector2(c.x,c.z)*3)
	elif axis.x >= axis.z:
		_uv_tri(builder,a,b,c,Vector2(a.z,a.y)*3,Vector2(b.z,b.y)*3,Vector2(c.z,c.y)*3)
	else:
		_uv_tri(builder,a,b,c,Vector2(a.x,a.y)*3,Vector2(b.x,b.y)*3,Vector2(c.x,c.y)*3)


func _uv_tri(builder: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, uv_a: Vector2, uv_b: Vector2, uv_c: Vector2) -> void:
	builder.set_uv(uv_a)
	builder.add_vertex(a)
	builder.set_uv(uv_b)
	builder.add_vertex(b)
	builder.set_uv(uv_c)
	builder.add_vertex(c)


func _add(joint: String, center: Vector3, basis: Basis, mesh: Mesh, color: String, absolute: bool = false) -> void:
	var key := joint + "/" + color
	if not _parts.has(key):
		var buffer := SurfaceTool.new()
		buffer.begin(Mesh.PRIMITIVE_TRIANGLES)
		_parts[key] = buffer
	var section: SurfaceTool = _parts[key]
	var rest := _proportioned(JOINT_LAYOUT[joint][1], joint)
	if absolute:
		var data := mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = data[Mesh.ARRAY_VERTEX]
		for i in vertices.size():
			vertices[i] = _proportioned(vertices[i], joint) - rest
		data[Mesh.ARRAY_VERTEX] = vertices
		var shape := ArrayMesh.new()
		shape.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, data)
		section.append_from(shape, 0, Transform3D.IDENTITY)
	else:
		var scaled := Basis.from_scale(_section_scale(center, joint)) * basis
		section.append_from(mesh, 0, Transform3D(scaled, _proportioned(center, joint) - rest))


func _bake() -> Dictionary:
	var result := {}
	for key in _parts:
		var names: PackedStringArray = key.split("/", false, 1)
		var joint := names[0]
		if not result.has(joint):
			result[joint] = ArrayMesh.new()
		var mesh: ArrayMesh = result[joint]
		var buffer: SurfaceTool = _parts[key]
		var flat: Array = buffer.commit_to_arrays()
		if flat[Mesh.ARRAY_VERTEX] == null or flat[Mesh.ARRAY_VERTEX].size() == 0:
			continue
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, flat)
		mesh.surface_set_material(mesh.get_surface_count()-1, _material(names[1]))
	return result


static func _material(code: String) -> StandardMaterial3D:
	if _materials.has(code):
		return _materials[code]
	var split := code.split(":", false, 1)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(split[-1])
	material.roughness = 0.81
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	if split.size() == 2:
		match split[0]:
			"m":
				material.metallic = 0.64
				material.roughness = 0.56
			"e":
				material.emission_enabled = true
				material.emission = material.albedo_color
				material.emission_energy_multiplier = 0.72
	if split[0] != "e":
		Finish.weather(material, split.size() == 2 and split[0] == "m")
	_materials[code] = material
	return material
