extends Node3D

const ArenaMaps = preload("res://scripts/arena_maps.gd")

# Court tint, tile seams, substructure, trim, surrounding terrain.
const PALETTES = {
	"lockwater": ["39494c", "1b2428", "293b41", "877050", "1c343e"],
	"kiln": ["4d3936", "211d22", "3e2d30", "976c48", "302329"],
	"orchard": ["424b39", "262c2b", "37382d", "807655", "27362c"],
	"quarry": ["504e43", "272723", "42433e", "988560", "373932"],
	"observatory": ["38394f", "202234", "2e2c43", "a68b64", "23263a"],
}
const STYLES = {"lockwater": 0, "kiln": 1, "orchard": 2, "quarry": 3, "observatory": 4}
const FLOOR_BOUNCE = {
	"lockwater": [Color("4d8994"), Vector2(-10.4, -8.2), Vector2(10.8, 4.0)],
	"kiln": [Color("c57945"), Vector2(-8.9, -7.1), Vector2(8.8, 7.8)],
	"orchard": [Color("ab8a51"), Vector2(-8.8, -8.9), Vector2(10.1, -6.1)],
	"quarry": [Color("a5855e"), Vector2(-7.3, -7.4), Vector2(8.1, 6.5)],
	"observatory": [Color("827ab6"), Vector2(-9.9, -6.4), Vector2(9.9, -6.7)],
}
const ZONE_PATTERNS = {"vent": 0, "wind": 1, "rise": 2, "veil": 3, "tide": 4}
const ZONE_GUIDE = {
	"vent": {
		"name": "Fire vent", "effect": "10 damage / sec", "active_tint": Color("ff8058"),
		"tip": "Step out before the heat ignites.",
	},
	"wind": {
		"name": "Crosswind", "effect": "Pushes both teams", "active_tint": Color("94eee2"),
		"tip": "The arrow shows where the wind will carry you.",
	},
	"rise": {
		"name": "Rising slab", "effect": "Blocks movement and sight", "active_tint": Color("f0dd9d"),
		"tip": "Clear the outline as it rises, then use the slab as cover.",
	},
	"veil": {
		"name": "Eclipse veil", "effect": "Blocks targeting across edge", "active_tint": Color("d0adff"),
		"tip": "Step inside to target a fighter within the same veil.",
	},
	"tide": {
		"name": "High tide", "effect": "40% slower movement", "active_tint": Color("8bdbff"),
		"tip": "Cross around the floodwater when you need to move quickly.",
	},
}
const ZONE_PHASES = {"idle": 0, "warning": 1, "active": 2}

const COURT_SHADER := preload("res://scripts/stage/court_surface.gdshader")
const SURROUND_SHADER := preload("res://scripts/stage/surroundings.gdshader")
const ZONE_SHADER := preload("res://scripts/stage/hazard.gdshader")
const VEIL_SHADER := preload("res://scripts/stage/veil_curtain.gdshader")
const ARCHITECTURE_SHADER := preload("res://scripts/stage/architecture.gdshader")
const MOTE_SHADER := preload("res://scripts/stage/scenery_motes.gdshader")
const SPILLWAY_SHADER := preload("res://scripts/stage/spillway.gdshader")
const ObjectiveRelic := preload("res://scripts/stage/objective_relic.gd")
enum Finish { BLOCK, METAL, TIMBER, ROUGH }

var _map_id := ""
var _scenery: Node3D
var _covers: Dictionary = {}
var _zone_nodes: Dictionary = {}
var _materials: Dictionary = {}
var _architectural_materials: Dictionary = {}
var _objective: Node3D
var _moving_props: Array[Node3D] = []


func _process(delta: float) -> void:
	for prop in _moving_props:
		var angular_velocity: Vector3 = prop.get_meta("angular_velocity")
		prop.rotation += angular_velocity * delta


func set_map(map_id: String, terrain: Array, environment_zones: Array) -> void:
	var selected := map_id if PALETTES.has(map_id) else "lockwater"
	if selected != _map_id:
		_change_scenery(selected)
	var present_cover: Dictionary = {}
	for obstacle: Dictionary in terrain:
		var id: String = obstacle.id
		present_cover[id] = true
		if not _covers.has(id):
			_covers[id] = _make_cover(id, obstacle.style)
		var cover: Node3D = _covers[id]
		var at: Vector2 = obstacle.position
		cover.position = Vector3(at.x, 0, at.y)
		var raised_fraction := float(cover.get_meta("height_fraction", 1.0))
		cover.scale = Vector3(obstacle.radius, obstacle.height * raised_fraction, obstacle.radius)
	_retire_absent(_covers, present_cover)
	var present_zones: Dictionary = {}
	for zone: Dictionary in environment_zones:
		var id: String = zone.id
		present_zones[id] = true
		if not _zone_nodes.has(id):
			_zone_nodes[id] = _make_zone(id, zone.kind)
		_update_zone(_zone_nodes[id], zone)
	_retire_absent(_zone_nodes, present_zones)


func set_objective(state: Dictionary) -> void:
	if state.is_empty():
		if is_instance_valid(_objective) and _objective.visible:
			_objective.reset()
		return
	var arena_id: String = state.get("map_id", _map_id)
	if not is_instance_valid(_objective) or arena_id != _objective.arena_id:
		if is_instance_valid(_objective):
			_objective.hide()
			_objective.queue_free()
		_objective = ObjectiveRelic.new()
		_objective.name = "ArenaObjective"
		add_child(_objective)
		_objective.build(arena_id)
	_objective.set_capture(state)


func _retire_absent(nodes: Dictionary, present: Dictionary) -> void:
	for id in nodes.keys():
		if not present.has(id):
			var node: Node3D = nodes[id]
			node.hide()
			node.queue_free()
			nodes.erase(id)


func _change_scenery(selected: String) -> void:
	if _scenery:
		_scenery.hide()
		_scenery.queue_free()
	_retire_absent(_covers, {})
	_retire_absent(_zone_nodes, {})
	_moving_props.clear()
	_map_id = selected
	_scenery = Node3D.new()
	_scenery.name = "Scenery_" + selected
	add_child(_scenery)
	var palette: Array = PALETTES[selected]
	var base := ShaderMaterial.new()
	base.shader = COURT_SHADER
	base.set_shader_parameter("base", Color(palette[0]))
	base.set_shader_parameter("seam", Color(palette[1]))
	base.set_shader_parameter("inlay", Color(palette[3]))
	base.set_shader_parameter("design", STYLES[selected])
	var bounce: Array = FLOOR_BOUNCE[selected]
	base.set_shader_parameter("bounce", bounce[0])
	base.set_shader_parameter("lamp_a", bounce[1])
	base.set_shader_parameter("lamp_b", bounce[2])
	var ground := ShaderMaterial.new()
	ground.shader = SURROUND_SHADER
	ground.set_shader_parameter("base", Color(palette[4]))
	ground.set_shader_parameter("design", STYLES[selected])
	var outskirts := PlaneMesh.new()
	outskirts.size = Vector2(184, 192)
	_mesh(_scenery, Vector3(0, -0.83, 0), outskirts, ground).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var perimeter: PackedVector2Array = ArenaMaps.outline(selected)
	_build_platform(perimeter, base, _mat(palette[2]), _mat(palette[3], false, 0.35))
	match selected:
		"lockwater": _gatehouse()
		"kiln": _furnaces()
		"orchard": _orchard()
		"quarry": _quarry()
		"observatory": _observatory()
	_build_perimeter_props(perimeter, palette)
	_batch_props(_scenery)
	_build_scenery_motes()


# All court footprints are convex and counterclockwise in simulation XY.
# Mapping simulation Y onto Godot Z gives the clockwise top faces Godot uses.
func _build_platform(perimeter: PackedVector2Array, floor_material: Material, side_material: StandardMaterial3D, trim_material: StandardMaterial3D) -> void:
	var floor_mesh := SurfaceTool.new()
	var side_mesh := SurfaceTool.new()
	var trim_mesh := SurfaceTool.new()
	for surface in [floor_mesh, side_mesh, trim_mesh]:
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in perimeter.size():
		var point := perimeter[i]
		var next := perimeter[(i + 1) % perimeter.size()]
		var a := Vector3(point.x, -0.005, point.y)
		var b := Vector3(next.x, -0.005, next.y)
		_vertex(floor_mesh, Vector3(0, a.y, 0), Vector3.UP)
		_vertex(floor_mesh, a, Vector3.UP)
		_vertex(floor_mesh, b, Vector3.UP)

		var normal := Vector3(b.z - a.z, 0.0, a.x - b.x).normalized()
		# An overhanging lip and two narrower courses keep the foundation
		# legible when the phone camera looks toward the edge of the arena.
		var course_a := Vector3(a.x, -0.19, a.z)
		var course_b := Vector3(b.x, -0.19, b.z)
		var spread_a := Vector3(a.x * 1.034, -0.29, a.z * 1.034)
		var spread_b := Vector3(b.x * 1.034, -0.29, b.z * 1.034)
		var jamb_a := Vector3(a.x * 1.034, -0.50, a.z * 1.034)
		var jamb_b := Vector3(b.x * 1.034, -0.50, b.z * 1.034)
		var foot_a := Vector3(a.x * 1.082, -0.78, a.z * 1.082)
		var foot_b := Vector3(b.x * 1.082, -0.78, b.z * 1.082)
		_quad_strip(side_mesh, a, course_a, course_b, b, normal)
		_quad_strip(side_mesh, course_a, spread_a, spread_b, course_b, (normal * 0.25 + Vector3.UP).normalized())
		_quad_strip(side_mesh, spread_a, jamb_a, jamb_b, spread_b, normal)
		_quad_strip(side_mesh, jamb_a, foot_a, foot_b, jamb_b, (normal + Vector3.UP).normalized())

		# A narrow inlaid band leaves the exact edge of the court visible.
		var inner_a := Vector3(a.x * 0.977, 0.012, a.z * 0.977)
		var inner_b := Vector3(b.x * 0.977, 0.012, b.z * 0.977)
		var outer_a := Vector3(a.x * 0.985, 0.012, a.z * 0.985)
		var outer_b := Vector3(b.x * 0.985, 0.012, b.z * 0.985)
		_quad_strip(trim_mesh, inner_a, outer_a, outer_b, inner_b, Vector3.UP)
	_mesh(_scenery, Vector3.ZERO, floor_mesh.commit(), floor_material).name = "CourtFloor"
	_mesh(_scenery, Vector3.ZERO, side_mesh.commit(), _architecture_finish(side_material)).name = "CourtFoundation"
	_mesh(_scenery, Vector3.ZERO, trim_mesh.commit(), _architecture_finish(trim_material)).name = "CourtTrim"


func _vertex(surface: SurfaceTool, point: Vector3, normal: Vector3) -> void:
	surface.set_normal(normal)
	surface.set_uv(Vector2(0.5 + point.x / 32.0, 0.5 + point.z / 32.0))
	surface.add_vertex(point)


func _quad_strip(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3) -> void:
	for point: Vector3 in [a, b, c, a, c, d]:
		_vertex(surface, point, normal)


func _build_perimeter_props(outline: PackedVector2Array, palette: Array) -> void:
	var trim := _mat(palette[3], false, 0.32)
	var stone := _mat(palette[2])
	var paint := _mat(palette[1])
	var curved_boundary := _map_id in ["lockwater", "observatory"]
	var around := 16 if curved_boundary else outline.size() * 2
	var stride := outline.size() / around if curved_boundary else 1
	for index in around:
		var entry := index if curved_boundary else index / 2
		var base := outline[entry * stride]
		var next := outline[(entry * stride + 1) % outline.size()]
		if not curved_boundary and index % 2 == 1:
			base = base.lerp(next, 0.5)
		var angle := atan2(base.x, base.y)
		var radial := Vector3(sin(angle), 0, cos(angle))
		var center := Vector3(base.x, 0.0, base.y)
		var step_center := center + radial * 0.90
		step_center.y = -0.33
		var edge := _box(_scenery, step_center, Vector3(1.91, 0.34, 1.73), stone)
		edge.rotation.y = angle
		var inset := _box(_scenery, center - radial * 0.54 + Vector3.UP * 0.008, Vector3(0.38, 0.023, 0.10), trim)
		inset.rotation.y = angle
		if index % 2 != 0:
			continue
		var post_center := center + radial * 1.52 - Vector3.UP * 0.62
		_cone(_scenery, post_center + Vector3.UP * 0.36, 0.41, 0.53, 0.72, stone, 6)
		_cone(_scenery, post_center + Vector3.UP * 0.76, 0.51, 0.42, 0.15, trim, 6)
		if index % 4 == 0:
			_perimeter_beacon(post_center + Vector3.UP * 0.84, trim, paint)


func _perimeter_beacon(point: Vector3, frame: Material, body: Material) -> void:
	var color: String = {
		"lockwater": "76b7b5", "kiln": "c86c3a", "orchard": "d2a46b",
		"quarry": "c49d55", "observatory": "aa91d6",
	}[_map_id]
	var lamp := _mat(color, true)
	_cone(_scenery, point + Vector3.UP * 0.057, 0.21, 0.34, 0.12, body, 8)
	_cone(_scenery, point + Vector3.UP * 0.22, 0.23, 0.18, 0.25, lamp, 6)
	_cone(_scenery, point + Vector3.UP * 0.40, 0.12, 0.30, 0.18, frame, 6)
	for i in 3:
		var angle := i * TAU / 3.0
		var support := Vector3(cos(angle) * 0.22, 0.21, sin(angle) * 0.22)
		_box(_scenery, point + support, Vector3(0.052, 0.30, 0.052), frame)


# Architecture and covers are rigid. Combining their parts by material keeps
# the detailed geometry to a handful of draw calls on the WebGL renderer.
func _batch_props(parent: Node3D) -> void:
	var source_nodes := parent.find_children("*", "MeshInstance3D", true, false)
	var surfaces: Dictionary = {}
	var unbaked: Array[MeshInstance3D] = []
	var parent_inverse := parent.global_transform.affine_inverse()
	for source: Node in source_nodes:
		var part := source as MeshInstance3D
		var material := part.material_override
		if not material is StandardMaterial3D or String(part.name).begins_with("Court") or part.has_meta("scenery_motion"):
			continue
		if not surfaces.has(material):
			var batch := SurfaceTool.new()
			batch.begin(Mesh.PRIMITIVE_TRIANGLES)
			surfaces[material] = batch
		var batch: SurfaceTool = surfaces[material]
		for index in part.mesh.get_surface_count():
			batch.append_from(part.mesh, index, parent_inverse * part.global_transform)
		unbaked.append(part)
	for material: StandardMaterial3D in surfaces:
		var batch: SurfaceTool = surfaces[material]
		_mesh(parent, Vector3.ZERO, batch.commit(), _architecture_finish(material))
	for part in unbaked:
		part.free()


func _preserve_motion(prop: Node3D, angular_velocity: Vector3) -> void:
	_batch_props(prop)
	for child in prop.get_children():
		child.set_meta("scenery_motion", true)
		if child is MeshInstance3D:
			child.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	prop.set_meta("angular_velocity", angular_velocity)
	_moving_props.append(prop)


func _build_scenery_motes() -> void:
	var palette: Array = {
		"lockwater": [Color("7196a6"), 0.12, 0.42],
		"kiln": [Color("e27d42"), 0.31, 0.76],
		"orchard": [Color("c7af67"), 0.19, 0.55],
		"quarry": [Color("968e78"), 0.17, 0.32],
		"observatory": [Color("a396d5"), 0.16, 0.42],
	}[_map_id]
	var material := ShaderMaterial.new()
	material.shader = MOTE_SHADER
	material.set_shader_parameter("tint", palette[0])
	material.set_shader_parameter("drift", palette[1])
	material.set_shader_parameter("spark", palette[2])
	var shape := QuadMesh.new()
	shape.size = Vector2.ONE
	var motes := MultiMesh.new()
	motes.transform_format = MultiMesh.TRANSFORM_3D
	motes.mesh = shape
	motes.instance_count = 38
	for index in motes.instance_count:
		var direction := Vector2.RIGHT.rotated(float(index) * 2.39996)
		var edge := ArenaMaps.constrain(_map_id, direction * 30.0)
		var offset := edge + direction * (1.15 + fposmod(index * 1.37, 4.1))
		var scale_factor := 0.048 + fposmod(index * 0.017, 0.093)
		var at := Vector3(offset.x, 0.2 + fposmod(index * 0.817, 2.3), offset.y)
		motes.set_instance_transform(index, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * scale_factor), at))
	var node := MultiMeshInstance3D.new()
	node.name = "PerimeterAtmosphere"
	node.multimesh = motes
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_scenery.add_child(node)


func _architecture_finish(material: StandardMaterial3D) -> Material:
	if material.emission_enabled:
		return material
	if not _architectural_materials.has(material):
		var finish := ShaderMaterial.new()
		finish.shader = ARCHITECTURE_SHADER
		finish.set_shader_parameter("stone", material.albedo_color)
		finish.set_shader_parameter("plate_metal", material.metallic)
		var default_finish := Finish.METAL if material.metallic >= 0.30 else Finish.BLOCK
		finish.set_shader_parameter("finish", material.get_meta("surface_finish", default_finish))
		_architectural_materials[material] = finish
	return _architectural_materials[material]


func _gatehouse() -> void:
	var stone := _mat("2b3945")
	var trim := _mat("546972", false, 0.34)
	var wood := _mat("4e3831", false, 0.02, Finish.TIMBER)
	var iron := _mat("2a4147", false, 0.58)
	for side: float in [-1.0, 1.0]:
		var tower := Vector3(6.5*side,0,-16.5)
		_box(_scenery,tower+Vector3.UP*1.65,Vector3(3.0,3.3,2.5),stone)
		_box(_scenery,tower+Vector3.UP*3.35,Vector3(3.3,0.28,2.75),trim)
		for band_index in [0.45, 1.03, 2.71]:
			_box(_scenery, tower + Vector3.UP * band_index, Vector3(3.12, 0.075, 2.61), trim)
		for support in [-1.0, 1.0]:
			var face := tower + Vector3(support * 1.20, 0.0, 1.33)
			_box(_scenery, face + Vector3.UP * 1.14, Vector3(0.37, 2.28, 0.43), stone)
			_box(_scenery, face + Vector3.UP * 2.21, Vector3(0.41, 0.14, 0.49), trim)
		for notch in [-1,0,1]:
			_box(_scenery,tower+Vector3(notch,3.68,1.06),Vector3(0.58,0.55,0.5),stone)
		_box(_scenery,tower+Vector3(0,2.25,1.28),Vector3(0.83,1.45,0.09),_mat("447a83" if side < 0 else "976948"))
		_lantern(_scenery,tower+Vector3(-side*1.9,0,1.05))
		_box(_scenery,Vector3(side*12,0.75,-17.0),Vector3(8.0,1.85,1.5),stone)
		_box(_scenery, Vector3(side * 14.65, 1.73, -17.0), Vector3(3.24, 0.16, 1.71), trim)
		for parapet in 3:
			var ledge := Vector3(side * (13.60 + parapet * 1.19), 2.0, -16.61)
			_box(_scenery, ledge, Vector3(0.58, 0.42, 0.51), stone)
	var gateway := Vector3(0, -0.43, -16.1)
	_arch_frame(gateway, Vector2(4.15, 1.94), 1.95, 1.20, stone, trim)
	_box(_scenery, gateway + Vector3.UP * 4.67, Vector3(10.46, 0.26, 1.92), stone)
	_box(_scenery, gateway + Vector3.UP * 4.82, Vector3(10.85, 0.14, 2.11), iron)
	for i in 7:
		var parapet := gateway + Vector3((i - 3) * 1.52, 5.10, 0.66)
		_box(_scenery, parapet, Vector3(0.64, 0.45, 0.62), stone)
		_box(_scenery, parapet + Vector3.UP * 0.24, Vector3(0.71, 0.12, 0.72), trim)
	for tooth in range(-8, 9):
		var fraction := absf(tooth / 9.0)
		var height := 1.91 + sqrt(1.0 - fraction * fraction) * 1.86
		_box(_scenery, gateway + Vector3(tooth * 0.43, height * 0.5, -0.15), Vector3(0.12, height, 0.18), iron)
	_box(_scenery, gateway + Vector3(0, 1.50, -0.06), Vector3(7.95, 0.17, 0.26), trim)
	_box(_scenery, gateway + Vector3(0, 0.28, 1.1), Vector3(8.78, 0.42, 2.12), wood)
	_box(_scenery, gateway + Vector3(0, 0.12, 2.2), Vector3(9.08, 0.22, 1.72), stone)
	for side: float in [-1.0, 1.0]:
		var lock := Vector3(side * 14.6, -0.43, -3.0)
		_cone(_scenery, lock + Vector3.UP * 0.50, 0.66, 0.83, 1.10, stone, 8)
		_cone(_scenery, lock + Vector3.UP * 1.15, 0.60, 0.75, 0.24, trim, 8)
		_cone(_scenery, lock + Vector3.UP * 1.32, 0.46, 0.57, 0.18, iron, 8)
		_ring(_scenery, lock + Vector3.UP * 1.45, 0.25, 0.36, trim).rotation.x = PI * 0.5
		_spillway(Vector3(side * 9.65, 0.75, -14.25), side, stone, trim)
		for i in 9:
			var fraction := float(i) / 8.0
			var link := Vector3(side * lerpf(4.17, 7.0, fraction), 4.43 - 1.51 * sin(fraction * PI * 0.67), -14.65)
			var iron_link := _ring(_scenery, link, 0.18, 0.232, iron)
			iron_link.rotation = Vector3(PI * 0.5 + (i % 2) * PI * 0.5, 0, -side * 0.37)
			iron_link.scale.x = 1.34
	var brass := _mat("8a765a")
	_ring(_scenery,Vector3(0,0.015,0),2.65,2.70,brass)
	for index in 12:
		var angle := index*TAU/12.0
		var axis := Vector3(sin(angle),0,cos(angle))
		_box(_scenery,axis*2.0+Vector3.UP*0.01,Vector3(0.06,0.02,0.8),brass).rotation.y = angle
	for index in 18:
		var side := 1.0 if index%2 else -1.0
		var point := Vector3(side*(15.2+fmod(index*2.1,6.0)),-0.56,-13.0+fmod(index*4.9,26.0))
		_box(_scenery,point,Vector3(0.8+index%4*0.35,0.03,0.06),_mat("346477"))


func _spillway(at: Vector3, side: float, stone: Material, trim: Material) -> void:
	var throat := QuadMesh.new()
	throat.size = Vector2(2.64, 2.77)
	var wet := ShaderMaterial.new()
	wet.shader = SPILLWAY_SHADER
	wet.set_shader_parameter("water", Color("4b8889"))
	wet.set_shader_parameter("run", side * 0.41)
	var cascade := _mesh(_scenery, at, throat, wet)
	cascade.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_box(_scenery, at + Vector3(0, 1.42, -0.25), Vector3(3.14, 0.30, 0.88), trim)
	_box(_scenery, at + Vector3(0, -1.34, 0.26), Vector3(3.29, 0.28, 1.57), stone)
	for flank in [-1.0, 1.0]:
		_box(_scenery, at + Vector3(flank * 1.34, -0.04, -0.09), Vector3(0.31, 2.85, 0.82), stone)


func _furnaces() -> void:
	var iron := _mat("392e34", false, 0.48)
	var copper := _mat("935f45", false, 0.55)
	var fire := _mat("e58c41", true)
	for index in range(-2,3):
		var x := index*5.8
		var z := -17.0 - absi(index%2)*0.9
		_cone(_scenery,Vector3(x,1.4,z),1.85,2.45,3.5,iron,12)
		_cone(_scenery,Vector3(x,4.65,z),1.03,1.51,3.0,_mat("634840"),12)
		_cone(_scenery,Vector3(x,6.25,z),1.17,1.17,0.38,copper,12)
		_cone(_scenery, Vector3(x, 3.17, z), 1.57, 1.69, 0.16, copper, 12)
		_cone(_scenery, Vector3(x, 4.28, z), 1.40, 1.44, 0.16, copper, 12)
		for support in [-1.0, 1.0]:
			_box(_scenery, Vector3(x + support * 1.09, 1.17, z + 1.8), Vector3(0.23, 2.05, 0.42), copper)
		_box(_scenery, Vector3(x, 0.19, z + 2.31), Vector3(2.57, 0.25, 1.18), iron)
		_box(_scenery,Vector3(x,1.04,z+1.84),Vector3(1.5,1.03,0.25),fire)
		for bar in [-1,0,1]:
			_box(_scenery,Vector3(x+bar*0.41,1.04,z+2.0),Vector3(0.14,1.14,0.2),iron)
	_box(_scenery,Vector3(0,3.68,-17.5),Vector3(27.0,0.45,0.62),copper)
	var bell_gate := Vector3(0, 0.0, -14.4)
	var slag_stone := _mat("3f3134")
	_arch_frame(bell_gate, Vector2(2.53, 1.42), 3.10, 0.70, slag_stone, copper)
	_box(_scenery, bell_gate + Vector3.UP * 4.37, Vector3(5.65, 0.21, 0.94), iron)
	_box(_scenery, bell_gate + Vector3.UP * 0.22, Vector3(5.65, 0.32, 2.26), slag_stone)
	var bell := Node3D.new()
	bell.position = bell_gate + Vector3(0, 3.85, 0.71)
	_scenery.add_child(bell)
	_cone(bell, Vector3.DOWN * 0.34, 0.39, 0.60, 0.66, copper, 12)
	_cone(bell, Vector3.DOWN * 0.91, 0.60, 1.04, 0.51, iron, 14)
	_cone(bell, Vector3.DOWN * 1.16, 1.02, 1.13, 0.16, copper, 14)
	_cone(bell, Vector3.DOWN * 1.30, 0.20, 0.30, 0.26, iron, 8)
	_cone(bell, Vector3.DOWN * 1.235, 0.825, 0.98, 0.072, _mat("8c4428", true), 14)
	_branch(_scenery, bell.position + Vector3.UP * 0.70 + Vector3.LEFT * 0.62, bell.position + Vector3.LEFT * 0.32, 0.13, 0.10, iron)
	_branch(_scenery, bell.position + Vector3.UP * 0.70 + Vector3.RIGHT * 0.62, bell.position + Vector3.RIGHT * 0.32, 0.13, 0.10, iron)
	for side: float in [-1.0, 1.0]:
		var torch := Vector3(side * 10.65, -0.50, -11.5)
		_cone(_scenery, torch + Vector3.UP * 0.26, 0.83, 1.14, 0.47, iron, 10)
		_cone(_scenery, torch + Vector3.UP * 0.81, 0.54, 0.72, 0.84, iron, 10)
		_cone(_scenery, torch + Vector3.UP * 1.29, 0.89, 0.56, 0.22, copper, 10)
		_cone(_scenery, torch + Vector3.UP * 1.36, 0.57, 0.51, 0.09, fire, 8)
		var siphon := Vector3(side * 12.8, 0.38, -9.4)
		_branch(_scenery, torch + Vector3.UP * 0.85, siphon, 0.23, 0.23, copper)
		_branch(_scenery, siphon, Vector3(siphon.x, 0.38, 7.7), 0.24, 0.24, iron)
		for length in [-6.5, -2.3, 2.9, 7.4]:
			var joint := Vector3(siphon.x, 0.38, length)
			_cone(_scenery, joint, 0.32, 0.32, 0.46, copper, 10).rotation.x = PI * 0.5
			_box(_scenery, joint - Vector3.UP * 0.65, Vector3(0.86, 0.46, 0.64), iron)
		var exhaust := Vector3(side * 14.5, 0.67, -18.65)
		_branch(_scenery, exhaust, exhaust + Vector3(0, 3.74, 0), 0.42, 0.59, iron)
		_branch(_scenery, exhaust + Vector3(0, 3.54, 0), exhaust + Vector3(-side * 2.30, 3.54, 0), 0.35, 0.42, iron)
		_cone(_scenery, exhaust + Vector3(0, 3.55, 0), 0.51, 0.51, 0.19, copper, 10)
		_box(_scenery, exhaust - Vector3.UP * 0.92, Vector3(1.64, 1.04, 1.65), slag_stone)
	for angle_index in 8:
		var angle := angle_index*TAU/8.0
		var axis := Vector3(sin(angle),0,cos(angle))
		_box(_scenery,axis*8.1+Vector3.UP*0.007,Vector3(0.105,0.019,4.3),_mat("95745d")).rotation.y = angle


func _orchard() -> void:
	var timber := _mat("464035", false, 0.02, Finish.TIMBER)
	for index in 12:
		var angle := deg_to_rad(71.0 + index * 21.0)
		var point := Vector3(sin(angle), -0.04, cos(angle)) * (16.5 + float(index % 2) * 1.9)
		var foliage := _mat(["414c39", "5f563d", "624a35"][index % 3], false, 0.02, Finish.ROUGH)
		_ironwood(_scenery, point, 2.7 + float(index % 4) * 0.40, timber, foliage)
	for side: float in [-1.0, 1.0]:
		for depth in 3:
			var backdrop := Vector3(side * (9.6 + depth * 3.7), -0.58, -23.6 + depth * 1.19)
			var foliage := _mat("373e36", false, 0.02, Finish.ROUGH)
			_ironwood(_scenery, backdrop, 3.8 + float(depth) * 0.37, timber, foliage)
	var cairn := _mat("464b45")
	var lichen := _mat("6b704f", false, 0.02, Finish.ROUGH)
	for side: float in [-1.0, 1.0]:
		var trail := Vector3(side * 9.3, -0.65, -11.35)
		_box(_scenery, trail + Vector3.UP * 0.53, Vector3(3.12, 0.84, 1.37), cairn).rotation.y = side * -0.29
		for stone_index in range(3):
			var step := trail + Vector3(side * float(stone_index) * 1.06, 0.97, float(stone_index) * 0.35)
			var height := 0.39 + (2 - stone_index) * 0.21
			var marker := _box(_scenery, step + Vector3.UP * height * 0.31, Vector3(0.78, height, 0.71), lichen)
			marker.rotation = Vector3(-0.07 * stone_index, side * -0.29, side * 0.08 * stone_index)
	var rotor := Vector3(-1.5,4.0,-17.4)
	_cone(_scenery,rotor-Vector3.UP*2.4,0.67,1.25,4.8,_mat("8e7758"),6)
	var hub := Node3D.new()
	hub.name = "IronleafWindmill"
	_scenery.add_child(hub)
	hub.position = rotor + Vector3(0,0,0.7)
	var brass := _mat("887955", false, 0.42)
	_cone(hub, Vector3.ZERO, 0.31, 0.31, 0.31, brass, 8).rotation.x = PI * 0.5
	for i in 4:
		var arm := Node3D.new()
		hub.add_child(arm)
		arm.rotation.z = 0.54 + i*PI/2
		_box(arm,Vector3(0,1.2,0),Vector3(0.09,2.35,0.13),timber)
		_box(arm,Vector3(0.31,1.52,0),Vector3(0.57,1.62,0.10),_mat("b1a389"))
		for slat in 4:
			_box(arm, Vector3(0.29, 0.86 + slat * 0.42, 0.071), Vector3(0.61, 0.048, 0.045), timber)
	_preserve_motion(hub, Vector3(0.0, 0.0, 0.24))
	var arch_stone := _mat("545749")
	_arch_frame(Vector3(4.5, -0.58, -13.7), Vector2(1.85, 1.04), 1.53, 0.74, arch_stone, brass)
	for flag in [-1, 1]:
		var side := float(flag)
		var shrine := Vector3(side * 9.8, -0.54, -9.6)
		_rock_column(_scenery, shrine, [Vector2(0.0, 1.09), Vector2(0.23, 0.86), Vector2(0.86, 0.39), Vector2(1.14, 0.31)], arch_stone, 0.52)
		_cone(_scenery, shrine + Vector3.UP * 1.21, 0.28, 0.20, 0.15, brass, 8)
		_cone(_scenery, shrine + Vector3.UP * 1.30, 0.045, 0.20, 0.10, _mat("a78245", true), 7)
	for i in 28:
		var angle := i*2.39996
		var r := 3.2 + fmod(i*1.75,7.5)
		var leaf := _cone(_scenery,Vector3(cos(angle)*r,0.015,sin(angle)*r),0.12,0.12,0.018,_mat("a88f57"),4)
		leaf.scale.z = 0.48
		leaf.rotation.y = angle


func _quarry() -> void:
	var face := _mat("434742", false, 0.02, Finish.ROUGH)
	var mineral := _mat("575547", false, 0.02, Finish.ROUGH)
	for tier in range(3):
		var distance := 17.4 + tier*2.0
		for cut in range(-3,4):
			var point := Vector3(cut*4.6, tier*0.91,-distance-absf(cut)*0.18)
			_box(_scenery,point,Vector3(4.56,1.8+tier*0.72,3.5),face)
			_box(_scenery,point+Vector3.UP*(0.77+tier*0.36),Vector3(4.59,0.16,3.53),_mat("716953"))
	for side: float in [-1.0, 1.0]:
		for i in 3:
			var wall := Vector3(side * (12.2 + i * 2.42), -0.65, -14.0 + i * 1.47)
			var height := 2.15 + i * 0.76
			_rock_column(_scenery, wall, [Vector2(0.0, 2.42), Vector2(height * 0.43, 2.19), Vector2(height * 0.76, 1.65), Vector2(height, 0.79)], face, side * (0.26 + 0.08 * i))
			_rock_column(_scenery, wall, [Vector2(height * 0.44, 2.25), Vector2(height * 0.53, 2.04)], mineral, side * (0.26 + 0.08 * i), false)
	var wood := _mat("755943", false, 0.02, Finish.TIMBER)
	for side: float in [-1.0,1.0]:
		_box(_scenery,Vector3(8.0+side*1.25,2.3,-15.5),Vector3(0.43,5.0,0.5),wood)
	_box(_scenery,Vector3(8.0,4.65,-15.5),Vector3(4.8,0.48,0.55),wood)
	_box(_scenery,Vector3(6.15,3.2,-15.48),Vector3(0.08,2.6,0.08),_mat("403c37"))
	_box(_scenery,Vector3(6.15,1.83,-15.48),Vector3(1.05,0.72,0.85),_mat("62574a"))
	var rail := _mat("58514d", false, 0.56)
	var hoist := Vector3(-3.9, -0.65, -12.9)
	var brass := _mat("8a6e4f", false, 0.46)
	for side: float in [-1.0, 1.0]:
		var foot := hoist + Vector3(side * 2.12, 0.0, 0.0)
		var beam_end := hoist + Vector3(side * 1.35, 4.16, -0.66)
		_branch(_scenery, foot, beam_end, 0.23, 0.34, wood)
		_branch(_scenery, foot + Vector3(0, 0.0, -2.1), beam_end, 0.17, 0.19, wood)
		_box(_scenery, foot + Vector3.UP * 0.17, Vector3(1.31, 0.34, 1.15), face)
	_box(_scenery, hoist + Vector3(0, 3.83, -0.56), Vector3(4.20, 0.38, 0.57), wood)
	var axle := hoist + Vector3(0, 3.53, -0.06)
	_ring(_scenery, axle, 0.79, 0.96, rail).rotation.x = PI * 0.5
	_ring(_scenery, axle + Vector3.BACK * 0.022, 0.70, 0.75, brass).rotation.x = PI * 0.5
	_cone(_scenery, axle, 0.23, 0.29, 0.42, wood, 9).rotation.x = PI * 0.5
	for i in 6:
		var turn := i * TAU / 6.0
		var spoke := Vector3(cos(turn), sin(turn), 0.0)
		_branch(_scenery, axle + spoke * 0.17, axle + spoke * 0.79, 0.062, 0.076, brass)
		var link := axle + Vector3(0.77, -0.26 - i * 0.26, 0.03)
		_ring(_scenery, link, 0.10, 0.135, rail).rotation = Vector3(PI * 0.5, (i % 2) * PI * 0.5, 0)
	_rock_column(_scenery, hoist + Vector3(0.75, 0.35, 0), [Vector2(0, 0.69), Vector2(0.62, 0.89), Vector2(1.08, 0.66)], face, 0.36)
	for side: float in [-1.0, 1.0]:
		var start := Vector3(side * 13.8, -0.54, -6.4)
		var finish := Vector3(side * 14.9, -0.54, 9.6)
		var sleepers := 14
		var heading := start.direction_to(finish)
		for i in sleepers:
			var beam := _box(_scenery, start.lerp(finish, float(i) / (sleepers - 1)), Vector3(1.56, 0.16, 0.26), wood)
			beam.rotation.y = atan2(heading.x, heading.z)
		for edge in [-0.53, 0.53]:
			var at := Vector3(edge, 0.15, 0.0)
			_branch(_scenery, start + at, finish + at, 0.05, 0.05, rail)
		var pallet := Vector3(side * 11.1, -0.18, 8.8)
		_rock_column(_scenery, pallet, [Vector2(0, 0.81), Vector2(0.54, 0.76), Vector2(0.77, 0.57)], face, 0.18)
		_box(_scenery, pallet - Vector3.UP * 0.18, Vector3(2.2, 0.28, 1.74), wood)
	for i in 7:
		var mark := _box(_scenery,Vector3(-5.7+i*1.45,0.012,4.0+i*0.52),Vector3(0.05,0.022,1.2),_mat("9a9784"))
		mark.rotation.y = -0.47


func _observatory() -> void:
	var brass := _mat("8c714e", false, 0.51)
	var indigo := _mat("34394b")
	var armillary := Vector3(0, 3.78, -15.55)
	var blue_silver := _mat("8b8192", false, 0.43)
	_cone(_scenery,armillary-Vector3.UP*2.82,1.55,2.4,2.68,indigo,12)
	_cone(_scenery,armillary-Vector3.UP*1.57,1.71,1.55,0.31,blue_silver,12)
	var heart := Node3D.new()
	heart.name = "HollowglassArmillaryCore"
	heart.position = armillary
	_scenery.add_child(heart)
	var star := _mat("9778c8", true)
	_cone(heart, Vector3.DOWN * 0.42, 0.68, 0.10, 0.84, star, 7)
	_cone(heart, Vector3.UP * 0.42, 0.10, 0.68, 0.84, star, 7)
	_preserve_motion(heart, Vector3(0.08, 0.40, -0.05))
	for i in 3:
		var gimbal := Node3D.new()
		gimbal.name = "HollowglassGimbal%d" % i
		gimbal.position = armillary
		gimbal.rotation = Vector3(0.30 + i * 0.55, 0.37 + i * 0.63, 0.34 + i * 0.49)
		_scenery.add_child(gimbal)
		var radius := 2.75 - i * 0.28
		_ring(gimbal, Vector3.ZERO, radius - 0.16, radius, brass)
		_ring(gimbal, Vector3.UP * 0.055, radius - 0.085, radius - 0.05, blue_silver)
		for index in 10:
			var turn := index * TAU / 10.0
			var rim := Vector3(cos(turn) * (radius - 0.08), 0.096, sin(turn) * (radius - 0.08))
			_cone(gimbal, rim, 0.063, 0.12, 0.14, brass, 5)
		_preserve_motion(gimbal, Vector3(0.097 - i * 0.046, -0.19 + i * 0.17, 0.06 - i * 0.053))
	for i in 8:
		var angle := i * TAU / 8.0
		var p := armillary + Vector3(cos(angle) * 2.7, 0.07, sin(angle) * 2.7)
		_cone(_scenery, p, 0.048, 0.091, 0.20, brass, 6)
	for side: float in [-1.0,1.0]:
		var p := Vector3(side*9.2,0,-17.7)
		_cone(_scenery,p+Vector3.UP*1.2,1.95,2.35,2.75,indigo,12)
		_cone(_scenery,p+Vector3.UP*2.87,0.48,2.1,1.25,_mat("737694"),12)
		_cone(_scenery,p+Vector3.UP*3.91,0.0,0.36,1.05,brass,8)
		var ruin := Vector3(side * 14.05, -0.50, -16.98)
		_arch_frame(ruin, Vector2(1.42, 1.43), 1.91, 0.84, indigo, blue_silver)
		_box(_scenery, ruin + Vector3(0, 0.09, 0.13), Vector3(3.52, 0.18, 1.08), indigo)
		var threshold := Vector3(side * 11.0, -0.49, -11.9)
		_arch_frame(threshold, Vector2(1.33, 1.47), 1.25, 0.67, indigo, brass)
		var sapphire := _mat("7768a4", true)
		_ring(_scenery, threshold + Vector3(0.0, 1.34, 0.12), 0.64, 0.71, brass).rotation.x = PI * 0.5
		_cone(_scenery, threshold + Vector3(0.0, 1.21, 0.14), 0.24, 0.04, 0.36, sapphire, 6)
		_cone(_scenery, threshold + Vector3(0.0, 1.56, 0.14), 0.04, 0.24, 0.36, sapphire, 6)
	for i in 22:
		var angle := i*2.39996
		var radius := 2.75 + fmod(i*1.6,9.75)
		var p := Vector3(cos(angle)*radius,0.014,sin(angle)*radius)
		_cone(_scenery,p,0.08 if i%3 else 0.12,0.08,0.024,_mat("d3c7a3"),4)


func _arch_frame(at: Vector3, arch: Vector2, shoulder: float, depth: float, stone: Material, trim: Material) -> void:
	var bevel := clampf(arch.x * 0.18, 0.28, 0.58)
	for i in 13:
		var from := float(i) * PI / 13.0
		var to := float(i + 1) * PI / 13.0
		var a := Vector3(cos(from) * arch.x, shoulder + pow(sin(from), 0.76) * arch.y, 0.0)
		var b := Vector3(cos(to) * arch.x, shoulder + pow(maxf(0.0, sin(to)), 0.76) * arch.y, 0.0)
		var center := at + (a + b) * 0.5
		var joint := b - a
		var slope := atan2(joint.y, joint.x)
		var block := _box(_scenery, center, Vector3(joint.length() + 0.033, bevel, depth), stone)
		block.rotation.z = slope
		var crown := _box(_scenery, center + Vector3.FORWARD * -depth * 0.51, Vector3(joint.length() + 0.027, bevel * 0.37, 0.095), trim)
		crown.rotation.z = slope
	for side: float in [-1.0, 1.0]:
		var post := at + Vector3(side * arch.x, 0.0, 0.0)
		_box(_scenery, post + Vector3.UP * shoulder * 0.5, Vector3(bevel * 1.42, shoulder, depth), stone)
		for height in [0.14, shoulder - 0.08]:
			_box(_scenery, post + Vector3.UP * float(height), Vector3(bevel * 1.77, 0.17, depth + 0.18), trim)


func _make_cover(id: String, style: String) -> Node3D:
	var cover := Node3D.new()
	cover.name = "Cover_" + id
	add_child(cover)
	var finish := Finish.ROUGH if style in ["rock", "slab"] else Finish.BLOCK
	var body := _mat(PALETTES[_map_id][2], false, 0.02, finish)
	var trim := _mat(PALETTES[_map_id][3], false, 0.45)
	match style:
		"tree":
			_ironwood(cover, Vector3.ZERO, 1.0, _mat("584a37", false, 0.02, Finish.TIMBER), _mat("4d5840", false, 0.02, Finish.ROUGH))
		"rock", "slab":
			_stratified_rock(cover, body, style == "slab")
		"chimney":
			_furnace_cover(cover, body, trim)
		"lens":
			_lens_cover(cover, body, trim)
		_:
			_pier_cover(cover, body, trim)
	_batch_props(cover)
	if style == "slab":
		cover.set_meta("height_fraction", 0.63)
		var lift := cover.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		lift.tween_method(func(height: float): cover.set_meta("height_fraction", height), 0.63, 1.0, 0.18)
	return cover


func _pier_cover(cover: Node3D, body: Material, trim: Material) -> void:
	var wet_stone := _mat("374f54")
	var black_iron := _mat("252d35", false, 0.68)
	_cone(cover, Vector3.UP * 0.09, 0.97, 1.0, 0.18, wet_stone, 8)
	_cone(cover, Vector3.UP * 0.51, 0.71, 0.81, 0.86, body, 8)
	_cone(cover, Vector3.UP * 0.92, 0.88, 0.88, 0.14, trim, 8)
	_cone(cover, Vector3.UP * 0.998, 0.77, 0.88, 0.021, wet_stone, 8)
	for index in 4:
		var angle := PI * 0.5 * index + PI * 0.25
		var axis := Vector3(sin(angle), 0, cos(angle))
		var iron := _box(cover, axis * 0.67 + Vector3.UP * 0.48, Vector3(0.095, 0.67, 0.19), black_iron)
		iron.rotation.y = angle
		_cone(cover, axis * 0.66 + Vector3.UP * 1.018, 0.056, 0.080, 0.028, black_iron, 6)
	_ring(cover, Vector3.UP * 1.015, 0.30, 0.36, trim)


func _furnace_cover(cover: Node3D, body: Material, trim: Material) -> void:
	var soot := _mat("282228")
	var iron := _mat("45404a", false, 0.6)
	var core := _mat("a9632c", true)
	_cone(cover, Vector3.UP * 0.09, 0.88, 1.0, 0.18, iron, 10)
	_cone(cover, Vector3.UP * 0.51, 0.70, 0.87, 0.88, body, 10)
	_cone(cover, Vector3.UP * 0.66, 0.79, 0.82, 0.055, iron, 10)
	_cone(cover, Vector3.UP * 0.965, 0.81, 0.76, 0.11, trim, 10)
	_cone(cover, Vector3.UP * 1.022, 0.68, 0.81, 0.025, soot, 10)
	_cone(cover, Vector3.UP * 1.037, 0.46, 0.46, 0.016, core, 10)
	for n in 5:
		var chord := sqrt(0.56 * 0.56 - pow(n * 0.20 - 0.40, 2.0)) * 1.84
		_box(cover, Vector3(n * 0.20 - 0.40, 1.063, 0), Vector3(0.063, 0.036, chord), iron)
	for n in 6:
		var angle := n * TAU / 6.0
		var axis := Vector3(sin(angle), 0, cos(angle))
		var brace := _box(cover, axis * 0.75 + Vector3.UP * 0.51, Vector3(0.105, 0.61, 0.15), iron)
		brace.rotation.y = angle
		_cone(cover, axis * 0.70 + Vector3.UP * 1.054, 0.043, 0.054, 0.022, trim, 5)


func _lens_cover(cover: Node3D, body: Material, trim: Material) -> void:
	var steel := _mat("515269", false, 0.50)
	var purple := _mat("7062af", true)
	var plum := _mat("403867", false, 0.42)
	_cone(cover, Vector3.UP * 0.11, 0.94, 1.0, 0.22, steel, 10)
	_cone(cover, Vector3.UP * 0.38, 0.62, 0.84, 0.40, body, 10)
	_cone(cover, Vector3.UP * 0.58, 0.80, 0.62, 0.10, trim, 10)
	_cone(cover, Vector3.UP * 0.66, 0.50, 0.69, 0.11, steel, 10)
	_cone(cover, Vector3.UP * 0.77, 0.56, 0.29, 0.18, purple, 7)
	_cone(cover, Vector3(0.12, 0.946, 0.0), 0.06, 0.56, 0.19, plum, 7)
	_ring(cover, Vector3.UP * 0.78, 0.79, 0.84, trim).rotation = Vector3(0.40, 0, -0.24)
	for n in 4:
		var angle := n * TAU / 4.0
		var axis := Vector3(sin(angle), 0, cos(angle))
		_cone(cover, axis * 0.59 + Vector3.UP * 0.63, 0.085, 0.135, 0.21, trim, 5)
		_cone(cover, axis * 0.68 + Vector3.UP * 0.155, 0.07, 0.12, 0.10, purple, 6)


func _stratified_rock(cover: Node3D, face: Material, slab: bool) -> void:
	var cap := _mat("62605a", false, 0.02, Finish.ROUGH)
	var fissure := _mat("25272a", false, 0.02, Finish.ROUGH)
	var mineral := _mat("837256" if slab else "66665c", false, 0.02, Finish.ROUGH)
	var width := 1.0 if slab else 0.84
	_rock_column(cover, Vector3.ZERO, [Vector2(0.0, 1.0), Vector2(0.25, width * 0.94), Vector2(0.61, width), Vector2(0.92, width * 0.72), Vector2(1.0, width * 0.50)], face, 0.13)
	_rock_column(cover, Vector3.ZERO, [Vector2(0.21, width * 0.99), Vector2(0.245, width * 0.98)], mineral, 0.13, false)
	_rock_column(cover, Vector3.ZERO, [Vector2(0.578, width * 1.02), Vector2(0.60, width * 1.025)], fissure, 0.13, false)
	_rock_column(cover, Vector3.ZERO, [Vector2(0.606, width * 1.026), Vector2(0.638, width * 0.99)], mineral, 0.13, false)
	_rock_column(cover, Vector3.ZERO, [Vector2(0.90, width * 0.75), Vector2(0.985, width * 0.55), Vector2(1.008, width * 0.49)], cap, 0.13)
	if slab:
		var seam := _mat("ac8b54", true)
		_rock_column(cover, Vector3.ZERO, [Vector2(0.241, 0.984), Vector2(0.251, 0.984)], seam, 0.13, false)
		_rock_column(cover, Vector3.ZERO, [Vector2(0.890, 0.773), Vector2(0.915, 0.748)], seam, 0.13, false)


# An irregular annulus of planar faces reads as broken bedrock. Each
# Vector2 defines a section height and its approximate unit-radius outline.
func _rock_column(parent: Node3D, at: Vector3, sections: Array, material: Material, twist: float, with_cap := true) -> void:
	const EDGES := 9
	var rings: Array[PackedVector3Array] = []
	for section: Vector2 in sections:
		var ring := PackedVector3Array()
		for i in EDGES:
			var angle := i * TAU / EDGES + twist * section.x
			var fracture := 0.84 + 0.15 * sin(i * 2.1 + 0.81) * sin(i * 2.1 + 0.81)
			var offset := 0.08 * section.x
			ring.append(Vector3(cos(angle) * section.y * fracture + offset, section.x, sin(angle) * section.y * fracture - offset * 0.42))
		rings.append(ring)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	for index in rings.size() - 1:
		for i in EDGES:
			var next := (i + 1) % EDGES
			for v: Vector3 in [rings[index][i], rings[index][next], rings[index + 1][next], rings[index][i], rings[index + 1][next], rings[index + 1][i]]:
				surface.set_uv(Vector2(v.x + v.z, v.y))
				surface.add_vertex(v)
	if with_cap:
		var top := rings.back() as PackedVector3Array
		for i in EDGES:
			for v: Vector3 in [Vector3(top[0].y * 0.08, top[0].y, 0), top[i], top[(i + 1) % EDGES]]:
				surface.set_uv(Vector2(v.x, v.z))
				surface.add_vertex(v)
	surface.generate_normals()
	_mesh(parent, at, surface.commit(), material)


func _ironwood(parent: Node3D, at: Vector3, scale_factor: float, timber: Material, foliage: Material) -> void:
	var tree := Node3D.new()
	tree.position = at
	tree.scale = Vector3.ONE * scale_factor
	parent.add_child(tree)
	var bark := _mat("353337", false, 0.02, Finish.TIMBER)
	var dry := _mat("6c5740", false, 0.02, Finish.ROUGH)
	_cone(tree, Vector3.UP * 0.25, 0.24, 0.44, 0.53, timber, 7).rotation.z = -0.09
	_cone(tree, Vector3(0.02, 0.66, -0.06), 0.096, 0.25, 0.51, bark, 7).rotation.z = 0.08
	for i in 5:
		var angle := i * TAU / 5.0 + 0.30
		var axis := Vector3(sin(angle), 0, cos(angle))
		_branch(tree, axis * 0.09 + Vector3.UP * 0.14, axis * 0.85 + Vector3.UP * 0.008, 0.040, 0.135, timber)
		_branch(tree, axis * 0.10 + Vector3.UP * (0.43 + float(i % 3) * 0.04), axis * 0.70 + Vector3.UP * (0.80 + float(i % 3) * 0.035), 0.038, 0.11, timber)
		if i % 2 == 0:
			var crown := axis * 0.32 + Vector3.UP * (0.78 - float(i % 3) * 0.032)
			_leaves(tree, crown, 0.43, foliage)
			_leaves(tree, crown + axis * 0.28 + Vector3.UP * 0.045, 0.27, foliage if i != 0 else dry)
	_leaves(tree, Vector3(-0.07, 0.86, 0.04), 0.40, foliage)


func _leaves(tree: Node3D, at: Vector3, width: float, foliage: Material) -> void:
	_rock_column(tree, at, [
		Vector2(0.0, width * 0.67), Vector2(0.072, width), Vector2(0.17, width * 0.74),
		Vector2(0.22, width * 0.33), Vector2(0.24, width * 0.05),
	], foliage, 0.71)


func _branch(parent: Node3D, from: Vector3, to: Vector3, top: float, bottom: float, material: Material) -> void:
	var delta := to - from
	var limb := _cone(parent, (from + to) * 0.5, top, bottom, delta.length(), material, 6)
	limb.quaternion = Quaternion(Vector3.UP, delta.normalized())


func _make_zone(id: String, kind: String) -> MeshInstance3D:
	var plane := PlaneMesh.new()
	plane.size = Vector2(2, 2)
	var material := ShaderMaterial.new()
	material.shader = ZONE_SHADER
	material.set_shader_parameter("kind", ZONE_PATTERNS.get(kind, 0))
	var node := _mesh(self, Vector3.ZERO, plane, material)
	node.name = "Zone_" + id
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if kind == "veil":
		var curtain_mesh := CylinderMesh.new()
		curtain_mesh.top_radius = 0.978
		curtain_mesh.bottom_radius = 0.978
		curtain_mesh.height = 1.15
		curtain_mesh.radial_segments = 40
		curtain_mesh.rings = 2
		curtain_mesh.cap_bottom = false
		curtain_mesh.cap_top = false
		var curtain_material := ShaderMaterial.new()
		curtain_material.shader = VEIL_SHADER
		curtain_material.set_shader_parameter("tint", ZONE_GUIDE.veil.active_tint)
		var curtain := _mesh(node, Vector3.UP * 0.575, curtain_mesh, curtain_material)
		curtain.name = "VeilCurtain"
		curtain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		curtain.hide()
	return node


func _update_zone(node: MeshInstance3D, zone: Dictionary) -> void:
	var p: Vector2 = zone.position
	node.position = Vector3(p.x, 0.050, p.y)
	node.scale = Vector3(zone.radius, 1, zone.radius)
	var phase: int = ZONE_PHASES.get(zone.phase, 0)
	var guide: Dictionary = ZONE_GUIDE.get(zone.kind, {})
	var active_tint: Color = guide.get("active_tint", Color.WHITE)
	var tint := active_tint.lerp(Color("ffd47f"), 0.71) if phase == 1 else active_tint
	var material := node.material_override as ShaderMaterial
	material.set_shader_parameter("tint", tint)
	material.set_shader_parameter("phase", phase)
	material.set_shader_parameter("flow", zone.direction)
	var warning_seconds := ArenaMaps.ACTIVE_START - ArenaMaps.WARNING_START
	material.set_shader_parameter("warning_fraction", clampf(zone.phase_left / warning_seconds, 0.0, 1.0))
	if zone.kind == "veil":
		var curtain := node.get_node("VeilCurtain") as MeshInstance3D
		curtain.visible = phase == 2


func _lantern(parent: Node3D, p: Vector3) -> void:
	_box(parent,p+Vector3.UP*0.65,Vector3(0.16,1.4,0.16),_mat("70554a"))
	_box(parent,p+Vector3.UP*1.42,Vector3(0.33,0.09,0.33),_mat("344a50"))
	_box(parent,p+Vector3.UP*1.6,Vector3(0.22,0.29,0.22),_mat("ffd694",true))
	_box(parent,p+Vector3.UP*1.8,Vector3(0.33,0.1,0.33),_mat("344a50"))


func _mat(code: String, glow := false, metal := 0.02, finish: int = -1) -> StandardMaterial3D:
	var key := "%s/%d/%.2f/%d" % [code, int(glow), metal, finish]
	if not _materials.has(key):
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(code)
		material.metallic = metal
		material.roughness = lerpf(0.89, 0.43, metal)
		if finish >= 0:
			material.set_meta("surface_finish", finish)
		if glow:
			material.emission_enabled = true
			material.emission = Color(code)
			material.emission_energy_multiplier = 0.68
		_materials[key] = material
	return _materials[key]


func _box(parent: Node3D, point: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var shape := BoxMesh.new()
	shape.size = size
	return _mesh(parent,point,shape,material)


func _cone(parent: Node3D, point: Vector3, top: float, bottom: float, height: float, material: Material, sides: int) -> MeshInstance3D:
	var shape := CylinderMesh.new()
	shape.top_radius = top
	shape.bottom_radius = bottom
	shape.height = height
	shape.radial_segments = sides
	shape.rings = 0
	return _mesh(parent,point,shape,material)


func _ring(parent: Node3D, point: Vector3, inner: float, outer: float, material: Material) -> MeshInstance3D:
	var shape := TorusMesh.new()
	shape.inner_radius = inner
	shape.outer_radius = outer
	shape.rings = 64
	shape.ring_segments = 6
	return _mesh(parent,point,shape,material)


func _mesh(parent: Node3D, point: Vector3, shape: Mesh, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.position = point
	node.mesh = shape
	node.material_override = material
	parent.add_child(node)
	return node
