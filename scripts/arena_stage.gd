extends Node3D

const ArenaMaps = preload("res://scripts/arena_maps.gd")

# Court tint, tile seams, substructure, trim, surrounding terrain.
const PALETTES = {
	"lockwater": ["515c65", "34424a", "35434c", "97805a", "193746"],
	"kiln": ["79544a", "412e2e", "402f34", "ad7054", "36292c"],
	"orchard": ["60784d", "364b36", "566047", "b49558", "425541"],
	"quarry": ["77756c", "4b504c", "575e59", "aa9772", "505a55"],
	"observatory": ["4a4a67", "30344c", "3d3b55", "bca27a", "242d43"],
}
const STYLES = {"lockwater": 0, "kiln": 1, "orchard": 2, "quarry": 3, "observatory": 4}
const ZONE_PATTERNS = {"vent": 0, "wind": 1, "rise": 2, "veil": 3, "tide": 4}
const ACTIVE_TINTS = {"vent": Color("ff743e"), "wind": Color("a1e9d4"), "rise": Color("eee2b2"), "veil": Color("bf9cff"), "tide": Color("65bfdc")}

# Patterns are drawn on the flat walkable mesh so painted floor detail cannot be
# mistaken for extra colliders. Coordinates use metres on the arena surface.
const FLOOR_SHADER = """
shader_type spatial;
uniform vec4 base : source_color;
uniform vec4 seam : source_color;
uniform int design;
varying vec2 tile_pos;
void vertex() { tile_pos = VERTEX.xz; }
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 4375.85); }
void fragment() {
	vec2 p = tile_pos;
	vec3 c = base.rgb;
	if (design < 2) {
		vec2 cell = p / (design == 0 ? vec2(2.45, 1.13) : vec2(1.55, 0.78));
		cell.x += mod(floor(cell.y), 2.0) * 0.5;
		vec2 edge = min(fract(cell), 1.0-fract(cell));
		float inset = smoothstep(0.004, 0.027, min(edge.x, edge.y));
		c = mix(seam.rgb, base.rgb * (0.91+0.18*hash(floor(cell))), inset);
	} else if (design == 2) {
		float path = min(abs(p.x*0.65+p.y*0.76+0.6*sin(p.x*0.39)), abs(-p.x*0.65+p.y*0.76-0.6*sin(p.x*0.39)));
		c = mix(base.rgb * vec3(1.32, 0.89, 0.62), base.rgb, smoothstep(0.6, 1.7, path));
		vec2 tuft = floor(p * 3.0);
		c *= 0.91 + 0.15*hash(tuft);
	} else if (design == 3) {
		float vein = abs(fract(p.y*0.37+p.x*0.18+0.07*sin(p.x*1.2)+0.12*sin(p.y*0.6))-0.5);
		c = mix(base.rgb, seam.rgb, 0.65*(1.0-smoothstep(0.005,0.022,vein)));
		c *= 0.96 + 0.09*hash(floor(vec2(p.y+p.x*0.5, p.x*0.45)));
	} else {
		vec2 cell = fract(p/vec2(3.4,3.4));
		float edge = min(min(cell.x,1.0-cell.x),min(cell.y,1.0-cell.y));
		c = mix(seam.rgb,base.rgb,smoothstep(0.0,0.008,edge));
		float r = length(p);
		float ring = min(abs(r-5.3),min(abs(r-8.0),abs(r-11.8)));
		c = mix(c, vec3(0.38,0.33,0.22), 0.8*(1.0-smoothstep(0.017,0.036,ring)));
	}
	ALBEDO = c;
	ROUGHNESS = 0.88;
}
"""

# Fill stays translucent at all phases. Directional chevrons point along the
# shared wind vector; other patterns remain distinct when viewed in grayscale.
const ZONE_SHADER = """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform vec4 tint : source_color;
uniform int kind;
uniform int phase;
uniform vec2 flow;
uniform float until_change;
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float d = length(p);
	if (d > 1.0) { discard; }
	float rim = smoothstep(0.91, 0.97, d);
	float ink = 0.0;
	if (kind == 0) {
		ink = 1.0-smoothstep(0.03,0.09,abs(fract(3.25*p.y+0.22*sin(8.0*p.x))-0.5));
	} else if (kind == 1) {
		vec2 axis = length(flow) > 0.001 ? normalize(flow) : vec2(1.0,0.0);
		float along = dot(p, axis);
		float across = dot(p, vec2(-axis.y,axis.x));
		ink = (1.0-smoothstep(0.045,0.12,abs(fract(2.0*(along+abs(across)))-0.5))) *
			(1.0-smoothstep(0.36,0.46,abs(across)));
	} else if (kind == 2) {
		float rib = abs(fract(2.6*(p.y+abs(p.x)))-0.5);
		ink = (1.0-smoothstep(0.06,0.12,rib)) * (1.0-smoothstep(0.53,0.7,abs(p.x)));
	} else if (kind == 3) {
		ink = 1.0-smoothstep(0.025,0.05,abs(length(p-vec2(0.21,-0.10))-0.53));
	} else {
		ink = 1.0-smoothstep(0.045,0.12,abs(fract(2.2*p.y+0.22*sin(6.0*p.x))-0.5));
	}
	float warning_ring = (1.0-smoothstep(0.025,0.064,abs(d-(0.2+0.65*fract(until_change*0.7)))));
	if (phase == 1) { ink = max(ink*0.5, warning_ring); }
	float edge = smoothstep(0.0,0.03,1.0-d);
	ALBEDO = tint.rgb;
	ALPHA = edge * (phase == 0 ? (0.025+rim*0.20+ink*0.09) : (0.12+rim*0.65+ink*0.35));
}
"""

var _map_id := ""
var _scenery: Node3D
var _covers: Dictionary = {}
var _zone_nodes: Dictionary = {}
var _materials: Dictionary = {}
var _floor_shader := Shader.new()
var _zone_shader := Shader.new()


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
	else:
		_floor_shader.code = FLOOR_SHADER
		_zone_shader.code = ZONE_SHADER
	_retire_absent(_covers, {})
	_retire_absent(_zone_nodes, {})
	_map_id = selected
	_scenery = Node3D.new()
	_scenery.name = "Scenery_" + selected
	add_child(_scenery)
	var palette: Array = PALETTES[selected]
	var base := ShaderMaterial.new()
	base.shader = _floor_shader
	base.set_shader_parameter("base", Color(palette[0]))
	base.set_shader_parameter("seam", Color(palette[1]))
	base.set_shader_parameter("design", STYLES[selected])
	_box(_scenery, Vector3(0,-0.72,0), Vector3(92,0.3,90), _mat(palette[4]))
	var perimeter: PackedVector2Array = ArenaMaps.outline(selected)
	_build_platform(perimeter, base, _mat(palette[2]), _mat(palette[3]))
	match selected:
		"lockwater": _gatehouse()
		"kiln": _furnaces()
		"orchard": _orchard()
		"quarry": _quarry()
		"observatory": _observatory()


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


func _gatehouse() -> void:
	var stone := _mat("364450")
	var trim := _mat("75838a")
	var wood := _mat("70554a")
	var iron := _mat("344a50")
	for side: float in [-1.0, 1.0]:
		var tower := Vector3(6.5*side,0,-16.5)
		_box(_scenery,tower+Vector3.UP*1.65,Vector3(3.0,3.3,2.5),stone)
		_box(_scenery,tower+Vector3.UP*3.35,Vector3(3.3,0.28,2.75),trim)
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
	var iron := _mat("43383a")
	var copper := _mat("ab7459")
	var fire := _mat("ffac55",true)
	for index in range(-2,3):
		var x := index*5.8
		var z := -17.0 - absi(index%2)*0.9
		_cone(_scenery,Vector3(x,1.4,z),1.85,2.45,3.5,iron,12)
		_cone(_scenery,Vector3(x,4.65,z),1.03,1.51,3.0,_mat("634840"),12)
		_cone(_scenery,Vector3(x,6.25,z),1.17,1.17,0.38,copper,12)
		_box(_scenery,Vector3(x,1.04,z+1.84),Vector3(1.5,1.03,0.25),fire)
		for bar in [-1,0,1]:
			_box(_scenery,Vector3(x+bar*0.41,1.04,z+2.0),Vector3(0.14,1.14,0.2),iron)
	_box(_scenery,Vector3(0,3.68,-17.5),Vector3(27.0,0.45,0.62),copper)
	for angle_index in 8:
		var angle := angle_index*TAU/8.0
		var axis := Vector3(sin(angle),0,cos(angle))
		_box(_scenery,axis*8.1+Vector3.UP*0.007,Vector3(0.105,0.019,4.3),_mat("95745d")).rotation.y = angle


func _orchard() -> void:
	var timber := _mat("69533e")
	for index in 13:
		var angle := deg_to_rad(74.0 + index*17.6)
		var p := Vector3(sin(angle),0,cos(angle))*(17.4+float(index%2)*1.7)
		_cone(_scenery,p+Vector3.UP*1.2,0.36,0.58,3.15,timber,7)
		var foliage := _mat(["8c9950","ba8848","aa6644"][index%3])
		_cone(_scenery,p+Vector3.UP*3.15,1.45,2.1,1.65,foliage,7)
		_cone(_scenery,p+Vector3(0.24,4.3,-0.12),0.45,1.62,1.35,foliage,7)
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
	var face := _mat("696a60")
	for tier in range(3):
		var distance := 17.4 + tier*2.0
		for cut in range(-3,4):
			var point := Vector3(cut*4.6, tier*0.91,-distance-absf(cut)*0.18)
			_box(_scenery,point,Vector3(4.56,1.8+tier*0.72,3.5),face)
			_box(_scenery,point+Vector3.UP*(0.77+tier*0.36),Vector3(4.59,0.16,3.53),_mat("939180"))
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
	var brass := _mat("ac946b")
	var indigo := _mat("43465e")
	var armillary := Vector3(0,4.0,-17.5)
	_cone(_scenery,armillary-Vector3.UP*2.66,1.55,2.4,2.8,indigo,12)
	for i in 3:
		var hoop := _ring(_scenery,armillary,2.7-i*0.25,2.83-i*0.25,brass)
		hoop.rotation = Vector3(0.28+i*0.54,0.4+i*0.83,0.25+i*0.46)
	_cone(_scenery,armillary,0.12,0.38,0.9,_mat("ccc3ef",true),6)
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
	cover.name = "Cover_"+id
	add_child(cover)
	var body := _mat(PALETTES[_map_id][2])
	var trim := _mat(PALETTES[_map_id][3])
	match style:
		"tree":
			_cone(cover,Vector3.UP*0.34,0.58,0.97,0.68,_mat("705642"),9)
			_cone(cover,Vector3.UP*0.73,0.69,1.0,0.30,_mat("7d924d"),8)
			_cone(cover,Vector3(0.13,0.91,-0.10),0.36,0.72,0.18,_mat("b69052"),8)
		"rock","slab":
			_cone(cover,Vector3.UP*0.33,0.90,1.0,0.66,body,8)
			_cone(cover,Vector3.UP*0.69,0.88,0.94,0.08,trim,8)
			_cone(cover,Vector3.UP*0.86,0.64,0.88,0.27,_mat("828279"),8)
		"chimney":
			_cone(cover,Vector3.UP*0.49,0.70,0.98,0.98,body,12)
			for y: float in [0.23,0.70]:
				_cone(cover,Vector3.UP*y,0.94-y*0.2,0.96-y*0.2,0.08,trim,12)
			_ring(cover,Vector3.UP*0.98,0.50,0.69,_mat("dc864f",true))
		"lens":
			_cone(cover,Vector3.UP*0.23,0.78,0.98,0.46,body,10)
			_cone(cover,Vector3.UP*0.52,0.64,0.87,0.13,trim,10)
			_cone(cover,Vector3.UP*0.68,0.72,0.36,0.24,_mat("9ba8c6"),6)
			_cone(cover,Vector3.UP*0.90,0.11,0.72,0.20,_mat("b6b9d8"),6)
		_:
			_cone(cover,Vector3.UP*0.13,0.98,1.0,0.26,body,12)
			_cone(cover,Vector3.UP*0.59,0.80,0.87,0.66,body,12)
			_cone(cover,Vector3.UP*0.94,0.95,0.95,0.12,trim,12)
	return cover


func _make_zone(id: String, kind: String) -> MeshInstance3D:
	var plane := PlaneMesh.new()
	plane.size = Vector2(2,2)
	var material := ShaderMaterial.new()
	material.shader = _zone_shader
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


func _mat(code: String, glow := false) -> StandardMaterial3D:
	var key := code+"+" if glow else code
	if not _materials.has(key):
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(code)
		material.roughness = 0.85
		if glow:
			material.emission_enabled = true
			material.emission = Color(code)
			material.emission_energy_multiplier = 0.48
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
