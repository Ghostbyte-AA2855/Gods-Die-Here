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
const ZONE_PATTERNS = {"vent": 0, "wind": 1, "rise": 2, "veil": 3, "tide": 4}
const ACTIVE_TINTS = {"vent": Color("ff743e"), "wind": Color("a1e9d4"), "rise": Color("eee2b2"), "veil": Color("bf9cff"), "tide": Color("65bfdc")}

const COURT_SHADER := preload("res://scripts/stage/court_surface.gdshader")
const SURROUND_SHADER := preload("res://scripts/stage/surroundings.gdshader")
const ZONE_SHADER := preload("res://scripts/stage/hazard.gdshader")

var _map_id := ""
var _scenery: Node3D
var _covers: Dictionary = {}
var _zone_nodes: Dictionary = {}
var _materials: Dictionary = {}


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
		cover.scale = Vector3(obstacle.radius, obstacle.height, obstacle.radius)
	_retire_absent(_covers, present_cover)
	var present_zones: Dictionary = {}
	for zone: Dictionary in environment_zones:
		var id: String = zone.id
		present_zones[id] = true
		if not _zone_nodes.has(id):
			_zone_nodes[id] = _make_zone(id, zone.kind)
		_update_zone(_zone_nodes[id], zone)
	_retire_absent(_zone_nodes, present_zones)


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
	var ground := ShaderMaterial.new()
	ground.shader = SURROUND_SHADER
	ground.set_shader_parameter("base", Color(palette[4]))
	ground.set_shader_parameter("design", STYLES[selected])
	var outskirts := PlaneMesh.new()
	outskirts.size = Vector2(92, 96)
	_mesh(_scenery, Vector3(0, -0.83, 0), outskirts, ground).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var perimeter: PackedVector2Array = ArenaMaps.outline(selected)
	_build_platform(perimeter, base, _mat(palette[2]), _mat(palette[3]))
	match selected:
		"lockwater": _gatehouse()
		"kiln": _furnaces()
		"orchard": _orchard()
		"quarry": _quarry()
		"observatory": _observatory()
	_build_perimeter_props(perimeter, palette)
	_batch_props(_scenery)


# All court footprints are convex and counterclockwise in simulation XY.
# Mapping simulation Y onto Godot Z gives the clockwise top faces Godot uses.
func _build_platform(perimeter: PackedVector2Array, floor_material: Material, side_material: Material, trim_material: Material) -> void:
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
		var lower_a := Vector3(a.x, -0.63, a.z)
		var lower_b := Vector3(b.x, -0.63, b.z)
		_quad_strip(side_mesh, a, lower_a, lower_b, b, normal)

		# A narrow inlaid band leaves the exact edge of the court visible.
		var inner_a := Vector3(a.x * 0.977, 0.012, a.z * 0.977)
		var inner_b := Vector3(b.x * 0.977, 0.012, b.z * 0.977)
		var outer_a := Vector3(a.x * 0.985, 0.012, a.z * 0.985)
		var outer_b := Vector3(b.x * 0.985, 0.012, b.z * 0.985)
		_quad_strip(trim_mesh, inner_a, outer_a, outer_b, inner_b, Vector3.UP)
	_mesh(_scenery, Vector3.ZERO, floor_mesh.commit(), floor_material).name = "CourtFloor"
	_mesh(_scenery, Vector3.ZERO, side_mesh.commit(), side_material).name = "CourtFoundation"
	_mesh(_scenery, Vector3.ZERO, trim_mesh.commit(), trim_material).name = "CourtTrim"


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
		if not material is StandardMaterial3D or String(part.name).begins_with("Court"):
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
		_mesh(parent, Vector3.ZERO, batch.commit(), material)
	for part in unbaked:
		part.free()


func _gatehouse() -> void:
	var stone := _mat("2b3945")
	var trim := _mat("546972", false, 0.34)
	var wood := _mat("4e3831")
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
	_box(_scenery,Vector3(0,3.05,-17.0),Vector3(11.0,0.48,1.6),wood)
	for tooth in range(-8,9):
		_box(_scenery,Vector3(tooth*0.57,1.4,-17.0),Vector3(0.15,2.95,0.18),iron)
	_box(_scenery,Vector3(0,1.5,-16.88),Vector3(10.5,0.17,0.26),trim)
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
	for angle_index in 8:
		var angle := angle_index*TAU/8.0
		var axis := Vector3(sin(angle),0,cos(angle))
		_box(_scenery,axis*8.1+Vector3.UP*0.007,Vector3(0.105,0.019,4.3),_mat("95745d")).rotation.y = angle


func _orchard() -> void:
	var timber := _mat("464035")
	for index in 12:
		var angle := deg_to_rad(71.0 + index * 21.0)
		var point := Vector3(sin(angle), -0.04, cos(angle)) * (16.5 + float(index % 2) * 1.9)
		var foliage := _mat(["414c39", "5f563d", "624a35"][index % 3])
		_ironwood(_scenery, point, 2.7 + float(index % 4) * 0.40, timber, foliage)
	var rotor := Vector3(-1.5,4.0,-17.4)
	_cone(_scenery,rotor-Vector3.UP*2.4,0.67,1.25,4.8,_mat("8e7758"),6)
	var hub := Node3D.new()
	_scenery.add_child(hub)
	hub.position = rotor + Vector3(0,0,0.7)
	for i in 4:
		var arm := Node3D.new()
		hub.add_child(arm)
		arm.rotation.z = 0.54 + i*PI/2
		_box(arm,Vector3(0,1.2,0),Vector3(0.09,2.35,0.13),timber)
		_box(arm,Vector3(0.20,1.55,0),Vector3(0.45,1.35,0.1),_mat("dbc99d"))
	for i in 28:
		var angle := i*2.39996
		var r := 3.2 + fmod(i*1.75,7.5)
		var leaf := _cone(_scenery,Vector3(cos(angle)*r,0.015,sin(angle)*r),0.12,0.12,0.018,_mat("a88f57"),4)
		leaf.scale.z = 0.48
		leaf.rotation.y = angle


func _quarry() -> void:
	var face := _mat("434742")
	for tier in range(3):
		var distance := 17.4 + tier*2.0
		for cut in range(-3,4):
			var point := Vector3(cut*4.6, tier*0.91,-distance-absf(cut)*0.18)
			_box(_scenery,point,Vector3(4.56,1.8+tier*0.72,3.5),face)
			_box(_scenery,point+Vector3.UP*(0.77+tier*0.36),Vector3(4.59,0.16,3.53),_mat("716953"))
	var wood := _mat("755943")
	for side: float in [-1.0,1.0]:
		_box(_scenery,Vector3(8.0+side*1.25,2.3,-15.5),Vector3(0.43,5.0,0.5),wood)
	_box(_scenery,Vector3(8.0,4.65,-15.5),Vector3(4.8,0.48,0.55),wood)
	_box(_scenery,Vector3(6.15,3.2,-15.48),Vector3(0.08,2.6,0.08),_mat("403c37"))
	_box(_scenery,Vector3(6.15,1.83,-15.48),Vector3(1.05,0.72,0.85),_mat("62574a"))
	for i in 7:
		var mark := _box(_scenery,Vector3(-5.7+i*1.45,0.012,4.0+i*0.52),Vector3(0.05,0.022,1.2),_mat("9a9784"))
		mark.rotation.y = -0.47


func _observatory() -> void:
	var brass := _mat("8c714e", false, 0.51)
	var indigo := _mat("34394b")
	var armillary := Vector3(0,4.0,-17.5)
	_cone(_scenery,armillary-Vector3.UP*2.66,1.55,2.4,2.8,indigo,12)
	for i in 3:
		var hoop := _ring(_scenery,armillary,2.7-i*0.25,2.83-i*0.25,brass)
		hoop.rotation = Vector3(0.28+i*0.54,0.4+i*0.83,0.25+i*0.46)
	_cone(_scenery,armillary,0.12,0.38,0.9,_mat("9982d0",true),6)
	for i in 8:
		var angle := i * TAU / 8.0
		var p := armillary + Vector3(cos(angle) * 2.7, 0.07, sin(angle) * 2.7)
		_cone(_scenery, p, 0.048, 0.091, 0.20, brass, 6)
	for side: float in [-1.0,1.0]:
		var p := Vector3(side*9.2,0,-17.7)
		_cone(_scenery,p+Vector3.UP*1.2,1.95,2.35,2.75,indigo,12)
		_cone(_scenery,p+Vector3.UP*2.87,0.48,2.1,1.25,_mat("737694"),12)
		_cone(_scenery,p+Vector3.UP*3.91,0.0,0.36,1.05,brass,8)
	for i in 22:
		var angle := i*2.39996
		var radius := 2.75 + fmod(i*1.6,9.75)
		var p := Vector3(cos(angle)*radius,0.014,sin(angle)*radius)
		_cone(_scenery,p,0.08 if i%3 else 0.12,0.08,0.024,_mat("d3c7a3"),4)


func _make_cover(id: String, style: String) -> Node3D:
	var cover := Node3D.new()
	cover.name = "Cover_" + id
	add_child(cover)
	var body := _mat(PALETTES[_map_id][2])
	var trim := _mat(PALETTES[_map_id][3], false, 0.45)
	match style:
		"tree":
			_ironwood(cover, Vector3.ZERO, 1.0, _mat("584a37"), _mat("4d5840"))
		"rock", "slab":
			_stratified_rock(cover, body, style == "slab")
		"chimney":
			_furnace_cover(cover, body, trim)
		"lens":
			_lens_cover(cover, body, trim)
		_:
			_pier_cover(cover, body, trim)
	_batch_props(cover)
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
	var cap := _mat("62605a")
	var fissure := _mat("25272a")
	var mineral := _mat("837256" if slab else "66665c")
	var width := 1.0 if slab else 0.84
	_rock_column(cover, Vector3.ZERO, [Vector2(0.0, 1.0), Vector2(0.25, width * 0.94), Vector2(0.61, width), Vector2(0.92, width * 0.72), Vector2(1.0, width * 0.50)], face, 0.13)
	_rock_column(cover, Vector3.ZERO, [Vector2(0.21, width * 0.99), Vector2(0.245, width * 0.98)], mineral, 0.13, false)
	_rock_column(cover, Vector3.ZERO, [Vector2(0.578, width * 1.02), Vector2(0.60, width * 1.025)], fissure, 0.13, false)
	_rock_column(cover, Vector3.ZERO, [Vector2(0.606, width * 1.026), Vector2(0.638, width * 0.99)], mineral, 0.13, false)
	_rock_column(cover, Vector3.ZERO, [Vector2(0.90, width * 0.75), Vector2(0.985, width * 0.55), Vector2(1.008, width * 0.49)], cap, 0.13)


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
	var bark := _mat("353337")
	var dry := _mat("6c5740")
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
	plane.size = Vector2(2,2)
	var material := ShaderMaterial.new()
	material.shader = ZONE_SHADER
	material.set_shader_parameter("kind",ZONE_PATTERNS.get(kind,0))
	var node := _mesh(self,Vector3.ZERO,plane,material)
	node.name = "Zone_"+id
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node


func _update_zone(node: MeshInstance3D, zone: Dictionary) -> void:
	var p: Vector2 = zone.position
	node.position = Vector3(p.x,0.050,p.y)
	node.scale = Vector3(zone.radius,1,zone.radius)
	var phase: int = {"idle":0,"warning":1,"active":2}.get(zone.phase,0)
	var tint: Color = Color("f5c465") if phase == 1 else ACTIVE_TINTS.get(zone.kind,Color.WHITE)
	var material := node.material_override as ShaderMaterial
	material.set_shader_parameter("tint",tint)
	material.set_shader_parameter("phase",phase)
	material.set_shader_parameter("flow",zone.direction)
	material.set_shader_parameter("until_change",zone.phase_left)


func _lantern(parent: Node3D, p: Vector3) -> void:
	_box(parent,p+Vector3.UP*0.65,Vector3(0.16,1.4,0.16),_mat("70554a"))
	_box(parent,p+Vector3.UP*1.42,Vector3(0.33,0.09,0.33),_mat("344a50"))
	_box(parent,p+Vector3.UP*1.6,Vector3(0.22,0.29,0.22),_mat("ffd694",true))
	_box(parent,p+Vector3.UP*1.8,Vector3(0.33,0.1,0.33),_mat("344a50"))


func _mat(code: String, glow := false, metal := 0.02) -> StandardMaterial3D:
	var key := "%s/%d/%.2f" % [code, int(glow), metal]
	if not _materials.has(key):
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(code)
		material.metallic = metal
		material.roughness = lerpf(0.89, 0.43, metal)
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
