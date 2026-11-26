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
var _locomotion := "idle"
var _previous_position := Vector2.ZERO
var _motion_velocity := Vector2.ZERO
var _initialized_motion := false
var _previous_health := 0.0
var _previous_stun := false


func build(class_id: String, archetype: String) -> void:
	name = "ChampionRig"
	champion = class_id
	for key in JOINT_LAYOUT:
		var parent_name: String = JOINT_LAYOUT[key][0]
		var node := Node3D.new()
		node.name = key
		var rest: Vector3 = JOINT_LAYOUT[key][1]
		if parent_name.is_empty():
			add_child(node)
			node.position = rest
		else:
			joints[parent_name].add_child(node)
			node.position = rest - JOINT_LAYOUT[parent_name][1]
		joints[key] = node
	if not _model_cache.has(class_id):
		_body(archetype)
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


func _body(archetype: String) -> void:
	var bulk := 1.12 if archetype == "guard" else (0.9 if archetype in ["ranged","healer"] else 1.0)
	var undersuit := "25202b"
	var leather := "37303b"
	var skin := "8d7775"
	ellipsoid("pelvis", Vector3(0, .89, .02), Vector3(.53 * bulk, .32, .34), undersuit)
	ellipsoid("spine", Vector3(0, 1.15, .018), Vector3(.56 * bulk, .56, .35), undersuit)
	tube("head", Vector3(0,1.52,0), Vector3(0,1.64,0), .095, .11, leather)
	ellipsoid("head", Vector3(0,1.72,-.018), Vector3(.29,.35,.30), skin)
	for side in [-1.0, 1.0]:
		var suffix := "_l" if side < 0 else "_r"
		ellipsoid("head", Vector3(side*.075,1.731,-.154), Vector3(.056,.020,.034), "120e19")
		tube("upper"+suffix,Vector3(side*.34,1.37,0),Vector3(side*.52,1.08,0),.108*bulk,.086,undersuit)
		tube("fore"+suffix,Vector3(side*.52,1.08,0),Vector3(side*.60,.87,-.025),.086,.059,leather)
		ellipsoid("hand"+suffix,Vector3(side*.615,.818,-.033),Vector3(.12,.17,.125), leather)
		tube("thigh"+suffix,Vector3(side*.17,.88,0),Vector3(side*.18,.51,0),.137*bulk,.092,undersuit)
		tube("shin"+suffix,Vector3(side*.18,.53,0),Vector3(side*.18,.19,0),.104,.066,leather)
		ellipsoid("foot"+suffix,Vector3(side*.18,.105,-.079),Vector3(.195,.178,.37), "25202b")


func box(joint: String, center: Vector3, size: Vector3, color: String, rotation: Vector3 = Vector3.ZERO) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	_add(joint, center, Basis.from_euler(rotation), mesh, color)


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


func plate(joint: String, points: PackedVector3Array, depth: float, color: String) -> void:
	if points.size() < 3:
		return
	var start := points[0]
	var normal := Vector3.ZERO
	for index in range(1, points.size() - 1):
		normal += (points[index] - start).cross(points[index+1] - start)
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
	var offset := normal * depth * 0.5
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(0, triangles.size(), 3):
		var a := points[triangles[i]]
		var b := points[triangles[i+1]]
		var c := points[triangles[i+2]]
		_triangle(builder, a + offset, c + offset, b + offset)
		_triangle(builder, a - offset, b - offset, c - offset)
	for i in points.size():
		var a := points[i]
		var b := points[(i+1) % points.size()]
		_triangle(builder, a + offset, b + offset, b - offset)
		_triangle(builder, a + offset, b - offset, a - offset)
	builder.generate_normals()
	_add(joint, Vector3.ZERO, Basis.IDENTITY, builder.commit(), color)


func _triangle(builder: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	builder.add_vertex(a)
	builder.add_vertex(b)
	builder.add_vertex(c)


func _add(joint: String, center: Vector3, basis: Basis, mesh: Mesh, color: String) -> void:
	var key := joint + "/" + color
	if not _parts.has(key):
		var buffer := SurfaceTool.new()
		buffer.begin(Mesh.PRIMITIVE_TRIANGLES)
		_parts[key] = buffer
	var section: SurfaceTool = _parts[key]
	var origin: Vector3 = JOINT_LAYOUT[joint][1]
	section.append_from(mesh, 0, Transform3D(basis, center - origin))


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
	material.roughness = 0.79
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	if split.size() == 2:
		match split[0]:
			"m":
				material.metallic = 0.64
				material.roughness = 0.39
			"e":
				material.emission_enabled = true
				material.emission = material.albedo_color
				material.emission_energy_multiplier = 0.72
	_materials[code] = material
	return material
