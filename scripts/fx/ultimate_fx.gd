extends Node3D

## One authoritative ground marker per winding-up fighter. Release visuals use
## the resolver's final position and radius, with a capped pool of short scenes.
const FLOOR_SHADER := preload("res://scripts/fx/ultimate_court.gdshader")
const LIGHT_SHADER := preload("res://scripts/fx/ultimate_light.gdshader")
const FORGE_SHADER := preload("res://scripts/fx/ultimate_forge.gdshader")
const IMPACT_FLOOR_SHADER := preload("res://scripts/fx/ultimate_impact_floor.gdshader")
const PRISM_SHADER := preload("res://scripts/fx/ultimate_prism.gdshader")
const SHARD := preload("res://scripts/fx/shard.tres")
const RED := Color("ff624e")
const GOLD := Color("f8d18f")
const BLUE := Color("69e2e8")
const MAX_IMPACTS := 4
const IMPACT_TIME := 1.44
const PATTERNS := [
	"bulwark", "threads", "echo", "meteor", "lantern", "volley", "vortex", "prism",
	"blood", "bell", "inferno", "frost", "dream", "chains", "lightning", "swarm"
]
const IMPACT_FLOORS := {"meteor": 0, "inferno": 1, "prism": 2}
const FORGE_PROFILE := [
	Vector2(-1.92, 0.36), Vector2(-1.72, 0.65), Vector2(-1.30, 0.71), Vector2(-0.26, 0.72),
	Vector2(-0.16, 0.91), Vector2(-0.18, 1.33), Vector2(-0.48, 1.54), Vector2(-0.41, 1.73),
	Vector2(0.29, 1.73), Vector2(0.43, 1.55), Vector2(0.19, 1.37), Vector2(0.20, 0.87),
	Vector2(0.38, 0.73), Vector2(1.49, 0.67), Vector2(1.77, 0.47), Vector2(1.62, 0.27),
	Vector2(1.23, 0.1), Vector2(0.76, -0.04), Vector2(0.61, -0.37), Vector2(1.05, -0.51),
	Vector2(1.08, -0.80), Vector2(0.79, -0.87), Vector2(-0.86, -0.87), Vector2(-1.09, -0.77),
	Vector2(-0.99, -0.52), Vector2(-0.48, -0.34), Vector2(-0.49, -0.03), Vector2(-1.42, 0.10),
]

var _warnings: Dictionary = {}
var _releases: Array[Node3D] = []
var _quad := QuadMesh.new()
var _sphere := SphereMesh.new()
var _spike := CylinderMesh.new()
var _link := TorusMesh.new()
var _bits_material := StandardMaterial3D.new()
var _forge_mesh: ArrayMesh
var _crystal_mesh: ArrayMesh


func _ready() -> void:
	_quad.size = Vector2(2, 2)
	_sphere.radius = 0.5
	_sphere.height = 1.0
	_sphere.radial_segments = 7
	_sphere.rings = 4
	_spike.top_radius = 0.035
	_spike.bottom_radius = 0.52
	_spike.height = 1.0
	_spike.radial_segments = 5
	_link.inner_radius = 0.32
	_link.outer_radius = 0.53
	_link.rings = 12
	_link.ring_segments = 6
	_bits_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_bits_material.vertex_color_use_as_albedo = true
	_forge_mesh = _extrude(PackedVector2Array(FORGE_PROFILE), 0.53)
	_crystal_mesh = _faceted_crystal()


func update_windups(windups: Array) -> void:
	var active: Dictionary = {}
	for windup: Dictionary in windups:
		var source: int = windup.get("source_id", -1)
		if source < 0:
			continue
		active[source] = true
		if not _warnings.has(source):
			_warnings[source] = _create_warning(windup)
		var marker: Dictionary = _warnings[source]
		var center := _presentation_center(windup)
		var size: float = windup.get("radius", 3.0)
		_place_disc(marker.disk, windup, center, size, 0.112)
		var duration := maxf(0.001, float(windup.get("duration", windup.get("windup", 0.9))))
		var progress := clampf(1.0 - float(windup.get("remaining", duration)) / duration, 0.0, 1.0)
		marker.ground.set_shader_parameter("progress", progress)
		var origin: Vector2 = windup.get("origin", center)
		marker.focus.position = _point(origin, 0.15)
		marker.focus.rotation.y = progress * 1.5
		marker.focus.scale = Vector3.ONE * lerpf(0.66, 1.09, progress)
		marker.light.set_shader_parameter("phase", progress)
		marker.light.set_shader_parameter("strength", 0.30 + 0.65 * progress)
		var stamp: Node3D = marker.stamp
		var falling: bool = windup.get("pattern", "") == "meteor"
		if falling:
			var descent := pow(smoothstep(0.44, 1.0, progress), 2.08)
			stamp.position = _point(center, lerpf(5.8, 0.88, descent)) + Vector3(0.0, 0.0, -0.61 * (1.0 - descent))
			stamp.rotation = Vector3(-0.17 * (1.0 - descent), marker.heading, 0.32 * (1.0 - descent))
			stamp.scale = Vector3.ONE * lerpf(0.42, 1.0, smoothstep(0.18, 0.65, progress))
			stamp.visible = progress > 0.19
		else:
			stamp.position = _point(center, 0.15 + sin(progress * PI) * 0.64)
			stamp.rotation.y = progress * 1.1
			stamp.scale = Vector3.ONE * (0.80 + 0.24 * progress)
		marker.stamp_light.set_shader_parameter("strength", 0.27 + 0.55 * progress)

	for source in _warnings.keys():
		if not active.has(source):
			_remove(_warnings[source].root)
			_warnings.erase(source)


func play_impact(event: Dictionary) -> void:
	if not is_inside_tree():
		return
	while _releases.size() >= MAX_IMPACTS:
		_remove(_releases.pop_front())
	var release := Node3D.new()
	release.name = str(event.get("pattern", "divine")).capitalize() + "Release"
	add_child(release)
	_releases.append(release)
	var center := _presentation_center(event)
	release.position = _point(center, 0.0)
	var radius := clampf(float(event.get("radius", 3.0)), 1.0, 8.4)
	var tint := _tint(event)
	var base: ShaderMaterial = _light(tint, 0.94)
	var edge: ShaderMaterial = _light(tint.lerp(_side(event), 0.47).lightened(0.19), 0.74)
	var white: ShaderMaterial = _light(tint.lightened(0.38), 0.78)
	var impact := _construction(release, event, radius, base, edge, white)
	var mark := _disc(release, event, 0.0)
	_place_disc(mark, event, Vector2.ZERO, radius, 0.113)
	var ground: ShaderMaterial = mark.material_override
	var motif: int = IMPACT_FLOORS.get(event.get("pattern", ""), -1)
	var ground_opacity := 1.0
	if motif >= 0:
		_impact_floor(release, radius, tint, motif)
		ground_opacity = 0.36
		ground.set_shader_parameter("strength", ground_opacity)
	var path := _floor_marks(event, center, radius, motif < 0)
	_stroke(release, path, 0.086, white)
	_scatter(release, event, radius, tint)

	var phase := release.create_tween().set_parallel(true)
	phase.tween_method(func(t: float): ground.set_shader_parameter("progress", t), 0.0, 1.0, 0.59).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	for ink: ShaderMaterial in [base, edge, white]:
		phase.tween_method(func(t: float): ink.set_shader_parameter("phase", t), 0.0, 1.3, IMPACT_TIME)
	var fade := release.create_tween().set_parallel(true)
	var inks: Array[ShaderMaterial] = [base, edge, white, ground]
	var strengths := [0.94, 0.74, 0.78, ground_opacity]
	for index in inks.size():
		var ink := inks[index]
		fade.tween_method(func(t: float): ink.set_shader_parameter("strength", t), strengths[index], 0.0, 0.69).set_delay(0.57)
	fade.tween_property(impact, "scale", impact.scale * Vector3(1.04, 0.72, 1.04), 0.67).set_delay(0.39)
	fade.chain().tween_callback(func():
		_releases.erase(release)
		release.queue_free()
	)


func clear() -> void:
	for marker: Dictionary in _warnings.values():
		_remove(marker.root)
	_warnings.clear()
	for release in _releases:
		_remove(release)
	_releases.clear()


func _create_warning(event: Dictionary) -> Dictionary:
	var root := Node3D.new()
	root.name = str(event.get("pattern", "divine")).capitalize() + "Warning"
	add_child(root)
	var disk := _disc(root, event, 1.0)
	var tint := _tint(event)
	var focus := _pivot(root, Vector3.ZERO)
	var light := _light(tint.lightened(0.22), 0.36)
	var scrolls := _pivot(root, Vector3.ZERO)
	var stamp_light := _light(tint.lerp(_side(event), 0.24), 0.32)
	var segments: Array = []
	for index in 4:
		var start := index * TAU / 4.0
		segments.append(_arc(Vector3.ZERO + Vector3.UP * 0.07, 0.82, start, start + 0.88, 8))
		var vector := Vector3(cos(start), 0.0, sin(start))
		segments.append(PackedVector3Array([vector * 0.62, vector * 0.78 + Vector3.UP * 0.9, vector * 0.32 + Vector3.UP * 1.48]))
	_stroke(focus, segments, 0.16, light)
	var pattern: String = event.get("pattern", "")
	var direction := _heading(event)
	var heading := atan2(-direction.x, -direction.y)
	if pattern == "meteor":
		heading = _forge_angle()
		_forge_head(scrolls, tint, stamp_light)
	else:
		var sides := 4 + maxi(0, PATTERNS.find(pattern)) % 5
		var stamp_radius := minf(1.07, float(event.get("radius", 3.0)) * 0.33)
		var stamp: Array = []
		for index in sides:
			var angle := index * TAU / sides
			var inner := Vector3(cos(angle), 0, sin(angle)) * stamp_radius * 0.66
			var outer := Vector3(cos(angle + 0.3), 0, sin(angle + 0.3)) * stamp_radius
			var tip := inner * 0.42 + Vector3.UP * (0.52 + 0.37 * (index % 2))
			stamp.append(PackedVector3Array([inner, outer, tip, inner]))
		_stroke(scrolls, stamp, 0.099, stamp_light)
	return {"root": root, "disk": disk, "ground": disk.material_override, "focus": focus,
		"light": light, "stamp": scrolls, "stamp_light": stamp_light, "heading": heading}


func _construction(release: Node3D, event: Dictionary, radius: float, base: ShaderMaterial, edge: ShaderMaterial, light: ShaderMaterial) -> Node3D:
	var shape := _pivot(release, Vector3.ZERO)
	var tint := _tint(event)
	var direction := _heading(event)
	shape.rotation.y = atan2(-direction.x, -direction.y)
	var pattern: String = event.get("pattern", "")
	match pattern:
		"bulwark": _bulwark(shape, radius, tint, base, edge)
		"threads": _threads(shape, radius, tint, base, light)
		"echo": _echo(shape, radius, maxf(1.0, float(event.get("length", 5.0))), tint, base, edge)
		"meteor":
			shape.rotation.y = _forge_angle()
			_meteor(shape, radius, tint, base, light)
		"lantern": _lantern(shape, radius, tint, base, edge)
		"volley": _volley(shape, radius, tint, base, light)
		"vortex": _vortex(shape, radius, tint, base, edge)
		"prism": _prism(shape, radius, tint, base, light)
		"blood": _blood(shape, radius, tint, base, edge)
		"bell": _bell(shape, radius, tint, base, light)
		"inferno": _inferno(shape, radius, tint, base, light)
		"frost": _frost(shape, radius, tint, base, edge)
		"dream": _dream(shape, radius, tint, base, light)
		"chains": _chains(shape, radius, tint, base, edge)
		"lightning": _lightning(shape, radius, tint, base, light)
		"swarm": _swarm(shape, radius, tint, base, edge)
		_: _vortex(shape, radius, tint, base, edge)
	return shape


func _bulwark(parent: Node3D, radius: float, tint: Color, base: Material, edge: Material) -> void:
	var waves: Array = []
	for current in 5:
		var at := radius * (0.44 + current * 0.092)
		var start := -2.50 + current * 0.36
		var points := PackedVector3Array()
		for sample in 27:
			var t := sample / 26.0
			var angle := start + 3.75 * t
			var y := 0.08 + pow(sin(PI * t), 1.65) * (1.05 + 0.18 * current)
			points.append(Vector3(cos(angle) * at, y, sin(angle) * at))
		waves.append(points)
	_stroke(parent, waves, 0.26, base)
	var crest := _pivot(parent, Vector3.RIGHT * radius * 0.48 + Vector3.UP * 1.19)
	var jaw := [PackedVector3Array([Vector3(-1.1, 0.12, -0.3), Vector3(-0.16, 0.89, 0), Vector3(0.55, 0.84, 0), Vector3(1.01, 0.27, 0), Vector3(0.38, 0.05, 0), Vector3(0.07, 0.32, 0)])]
	var fins: Array = []
	for index in 5:
		var x := -0.98 + 0.34 * index
		fins.append(PackedVector3Array([Vector3(x, 0.14, -0.38), Vector3(x - 0.38, 0.85, 0), Vector3(x, 0.14, 0.38)]))
	_stroke(crest, jaw, 0.27, edge)
	_stroke(crest, fins, 0.14, base)
	_static_bits(crest, _sphere, [Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 0.15), Vector3(0.47, 0.55, 0.06))], tint.lightened(0.72))
	_grow(crest, Vector3.ONE * 0.36, Vector3.ONE * 1.12, 0.46)


func _threads(parent: Node3D, radius: float, tint: Color, base: Material, light: Material) -> void:
	var lattice := _pivot(parent, Vector3.ZERO)
	var paths: Array = []
	for index in 12:
		var angle := index * TAU / 12.0
		var finish := angle + PI * 0.76
		var from := Vector3(cos(angle), 0.13 / radius, sin(angle)) * radius * 0.89
		var to := Vector3(cos(finish), 0.13 / radius, sin(finish)) * radius * 0.89
		var mid := from.lerp(to, 0.5) + Vector3.UP * (1.1 + 0.18 * (index % 3))
		paths.append(_curve(from, mid, to))
	_stroke(lattice, paths, 0.141, base)
	_stroke(lattice, [_arc(Vector3.UP * 0.17, radius * 0.83, 0, TAU, 46), _arc(Vector3.UP * 0.68, radius * 0.30, 0, TAU, 28)], 0.13, light)
	_static_bits(lattice, SHARD, _circle_bits(9, radius * 0.77, 0.54, Vector3(0.24, 0.39, 0.24)), tint.lightened(0.38))
	lattice.rotation.y = -0.34
	lattice.create_tween().tween_property(lattice, "rotation:y", 0.47, 0.85)


func _echo(parent: Node3D, radius: float, length: float, tint: Color, base: Material, edge: Material) -> void:
	var cuts := _pivot(parent, Vector3.ZERO)
	var waves: Array = []
	var mirrored: Array = []
	var splinters: Array[Transform3D] = []
	for layer in 6:
		var t := layer / 5.0
		var z := (0.50 - t) * length
		var x := (1 - (layer % 2) * 2) * radius
		var start := Vector3(x * 0.87, 0.30, z + 0.75)
		var apex := Vector3(x * 0.36, 2.51 + 0.16 * (layer % 3), z - 0.15)
		var finish := Vector3(-x * 0.94, 0.36, z - 0.94)
		waves.append(_curve(start, apex, finish))
		mirrored.append(_curve(start + Vector3.UP * 0.32, apex + Vector3.UP * 0.64, finish + Vector3.UP * 0.36))
		splinters.append(Transform3D(Basis(Vector3.UP, layer).scaled(Vector3(0.21, 0.57, 0.22)), Vector3(x * 0.86, 0.94, z)))
	_stroke(cuts, waves, 0.23, base)
	_stroke(cuts, mirrored, 0.14, edge)
	_static_bits(cuts, SHARD, splinters, tint.lightened(0.25))
	_grow(cuts, Vector3(0.26, 0.22, 0.88), Vector3.ONE, 0.26)


func _meteor(parent: Node3D, radius: float, tint: Color, base: Material, light: Material) -> void:
	var rock := _pivot(parent, Vector3.UP * 0.88)
	_forge_head(rock, tint, base)
	var sparks: Array = []
	for index in 12:
		var angle := index * TAU / 12.0
		var heading := Vector3(cos(angle), 0.0, sin(angle))
		var lift := 0.68 + float(index % 4) * 0.26
		sparks.append(_curve(heading * 0.35 + Vector3.UP * 0.13,
			heading * radius * 0.70 + Vector3.UP * (1.9 * lift), heading * radius * 0.96 + Vector3.UP * lift, 8))
	var ejecta := _pivot(parent, Vector3.ZERO)
	_stroke(ejecta, sparks, 0.146, light)
	_grow(ejecta, Vector3.ONE * 0.12, Vector3.ONE, 0.34)
	var strike := rock.create_tween().set_parallel(true)
	strike.tween_property(rock, "position:y", 0.80, 0.11).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	strike.tween_property(rock, "rotation:z", -0.14, 0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	strike.chain().tween_property(rock, "scale", Vector3(0.88, 0.03, 0.62), 0.42).set_delay(0.23).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	strike.chain().tween_callback(rock.queue_free)


func _forge_head(parent: Node3D, tint: Color, outline_ink: Material) -> void:
	var wall := _molten_anvil(_forge_mesh, tint)
	parent.add_child(wall)
	wall.rotation.y = 0.31
	var engravings: Array = []
	for side in [-1.0, 1.0]:
		var plane: float = side * 0.542
		var edge := PackedVector3Array()
		for corner: Vector2 in FORGE_PROFILE:
			edge.append(Vector3(corner.x, corner.y, plane))
		edge.append(edge[0])
		engravings.append(edge)
		engravings.append(PackedVector3Array([Vector3(-1.50, 0.39, plane), Vector3(-0.64, 0.49, plane),
			Vector3(-0.16, 0.15, plane), Vector3(0.47, 0.48, plane), Vector3(1.35, 0.44, plane)]))
		engravings.append(PackedVector3Array([Vector3(-0.71, -0.66, plane), Vector3(-0.13, -0.20, plane),
			Vector3(0.35, -0.66, plane), Vector3(-0.71, -0.66, plane)]))
	_stroke(wall, engravings, 0.140, outline_ink)


func _forge_angle() -> float:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return 0.0
	var facing := camera.global_basis.z
	return atan2(facing.x, facing.z)


func _lantern(parent: Node3D, radius: float, tint: Color, base: Material, edge: Material) -> void:
	var lantern := _pivot(parent, Vector3.UP * 1.93)
	var ribs: Array = []
	for index in 8:
		var angle := index * TAU / 8.0
		var direction := Vector3(cos(angle), 0.0, sin(angle))
		ribs.append(PackedVector3Array([direction * 0.14 + Vector3.UP * 0.8, direction * 0.64 + Vector3.UP * 0.24,
			direction * 0.58 + Vector3.DOWN * 0.4, direction * 0.10 + Vector3.DOWN * 0.66]))
	ribs.append(_arc(Vector3.UP * 0.23, 0.63, 0.0, TAU, 8))
	ribs.append(_arc(Vector3.DOWN * 0.41, 0.57, 0.0, TAU, 8))
	_stroke(lantern, ribs, 0.118, edge)
	_static_bits(lantern, SHARD, [Transform3D(Basis.IDENTITY.scaled(Vector3(0.57, 0.93, 0.57)), Vector3.ZERO)], tint.lightened(0.51))
	var rays: Array = []
	for index in 8:
		var angle := index * TAU / 8.0
		var from := Vector3(cos(angle), 0.0, sin(angle)) * radius * 0.89 + Vector3.UP * 0.16
		rays.append(_curve(from, from * 0.68 + Vector3.UP * 0.32, Vector3.UP * 1.82))
	_stroke(parent, rays, 0.128, base)
	lantern.create_tween().tween_property(lantern, "rotation:y", 2.16, 1.18)
	_grow(lantern, Vector3.ONE * 0.38, Vector3.ONE, 0.36)


func _volley(parent: Node3D, radius: float, tint: Color, base: Material, light: Material) -> void:
	var arrows := _pivot(parent, Vector3.ZERO)
	var spread: Array = []
	var tips: Array[Transform3D] = []
	for index in 16:
		var angle := index * 2.39996
		var r := sqrt((index + 0.42) / 16.0) * radius * 0.88
		var landing := Vector3(cos(angle) * r, 0.72 + 0.22 * (index % 5), sin(angle) * r)
		var start := landing + Vector3(-0.48, 1.92 + 0.12 * (index % 6), -1.29)
		spread.append(PackedVector3Array([start, start.lerp(landing, 0.48) + Vector3.LEFT * 0.14, landing]))
		var tilt := Basis(Vector3.RIGHT, 0.58) * Basis(Vector3.FORWARD, 0.22)
		tips.append(Transform3D(tilt.scaled(Vector3(0.24, 0.79, 0.24)), landing))
	_stroke(arrows, spread, 0.18, base)
	_static_bits(arrows, _spike, tips, tint.lightened(0.38))
	_stroke(parent, [_arc(Vector3.UP * 0.13, radius * 0.79, 0.0, TAU, 18)], 0.18, light)
	arrows.position = Vector3(-0.58, 2.16, -1.02)
	arrows.create_tween().tween_property(arrows, "position", Vector3(0.06, -0.50, 0.26), 0.31).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)


func _vortex(parent: Node3D, radius: float, tint: Color, base: Material, edge: Material) -> void:
	var current := _pivot(parent, Vector3.ZERO)
	var flows: Array = []
	for strand in 5:
		var points := PackedVector3Array()
		for index in 39:
			var t := index / 38.0
			var angle := t * TAU * 0.74 + strand * TAU / 5.0
			var reach := radius * lerpf(0.93, 0.17, t)
			points.append(Vector3(cos(angle) * reach, 0.06 + 2.3 * t * t, sin(angle) * reach))
		flows.append(points)
	_stroke(current, flows, 0.31, base)
	_stroke(current, [_arc(Vector3.UP * 0.26, radius * 0.87, 0.14, TAU, 44),
		_arc(Vector3.UP * 1.24, radius * 0.42, 0.08, TAU, 34)], 0.14, edge)
	_static_bits(current, _sphere, _circle_bits(15, radius * 0.75, 0.30, Vector3(0.11, 0.23, 0.11)), tint.lightened(0.41))
	current.create_tween().tween_property(current, "rotation:y", 3.74, 1.30).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _prism(parent: Node3D, radius: float, tint: Color, base: Material, light: Material) -> void:
	var structure := _pivot(parent, Vector3.UP * 0.14)
	var ribs: Array = []
	var rose_window: Array = []
	var pillars: Array[Vector3] = []
	var crystal_count := 8
	var crystals := _instance_batch(structure, _crystal_mesh, crystal_count * 2)
	var glass := ShaderMaterial.new()
	glass.shader = PRISM_SHADER
	glass.set_shader_parameter("tint", tint)
	crystals.material_override = glass
	var spire := Vector3.UP * 3.87
	for index in crystal_count:
		var angle := index * TAU / crystal_count + PI * 0.125
		var direction := Vector3(cos(angle), 0.0, sin(angle))
		var foot := direction * radius * 0.73
		var spring := direction * radius * 0.65 + Vector3.UP * 1.72
		var lintel := direction * radius * 0.46 + Vector3.UP * 3.25
		var peak := spire + direction * 0.14
		ribs.append(PackedVector3Array([foot, spring, lintel, peak]))
		var next := direction.rotated(Vector3.UP, TAU / crystal_count)
		var cross := (direction + next).normalized() * radius * 0.68
		ribs.append(PackedVector3Array([spring, cross + Vector3.UP * 2.66, next * radius * 0.65 + Vector3.UP * 1.72]))
		rose_window.append(PackedVector3Array([direction * 0.25 + Vector3.UP * 3.63,
			direction * 0.59 + Vector3.UP * 2.92, (direction + next) * 0.27 + Vector3.UP * 3.21,
			next * 0.25 + Vector3.UP * 3.63]))
		pillars.append(foot)
	_stroke(structure, ribs, 0.139, base)
	_stroke(structure, rose_window, 0.19, light)
	var fracture := func(spread: float):
		for index in crystal_count:
			var foot := pillars[index]
			var outward := foot.normalized()
			var angle := atan2(foot.z, foot.x)
			var shard_turn := Basis(Vector3.UP, angle + spread * 2.18) * Basis(Vector3.RIGHT, -0.14 + spread * (1.7 + 0.13 * (index % 3)))
			var shrink := 1.0 - spread * spread * 0.91
			var block := foot + outward * spread * 1.16 + Vector3.UP * (0.81 + 0.19 * (index % 2) + sin(spread * PI) * 0.83 - spread * 0.84)
			var peak := foot * 0.61 + outward * spread * 2.07 + Vector3.UP * (2.14 + sin(spread * PI) * 0.67 - spread * 1.68)
			crystals.multimesh.set_instance_transform(index, Transform3D(shard_turn.scaled(Vector3(0.61, 1.45, 0.64) * shrink), block))
			crystals.multimesh.set_instance_transform(index + crystal_count, Transform3D(shard_turn.scaled(Vector3(0.33, 0.80, 0.33) * shrink), peak))
	fracture.call(0.0)
	_grow(structure, Vector3(0.91, 0.06, 0.91), Vector3.ONE, 0.27)
	crystals.create_tween().tween_method(fracture, 0.0, 1.0, 0.60).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(0.37).finished.connect(crystals.queue_free)


func _blood(parent: Node3D, radius: float, tint: Color, base: Material, edge: Material) -> void:
	var crown := _pivot(parent, Vector3.ZERO)
	var spokes: Array = []
	for index in 9:
		var angle := index * TAU / 9.0
		var start := Vector3(cos(angle), 0.0, sin(angle)) * radius * 0.90
		var out := start * 0.77 + Vector3.UP * (1.55 + 0.34 * (index % 2))
		var in_ := out.rotated(Vector3.UP, 0.55) * Vector3(0.57, 1.40, 0.57)
		spokes.append(_curve(start + Vector3.UP * 0.14, out + Vector3.UP * 0.66, in_))
	_stroke(crown, spokes, 0.22, base)
	_stroke(crown, [_arc(Vector3.UP * 0.49, radius * 0.76, -0.24, TAU - 0.24, 9)], 0.18, edge)
	_static_bits(crown, SHARD, _circle_bits(9, radius * 0.51, 1.52, Vector3(0.23, 0.72, 0.30)), tint.lightened(0.30))
	_grow(crown, Vector3(1.0, 0.07, 1.0), Vector3.ONE, 0.33)
	crown.create_tween().tween_property(crown, "rotation:y", 1.0, 1.12)


func _bell(parent: Node3D, radius: float, tint: Color, base: Material, light: Material) -> void:
	var bell := _pivot(parent, Vector3.UP * 1.92)
	var cage: Array = []
	for index in 14:
		var angle := TAU * index / 14.0
		var d := Vector3(cos(angle), 0.0, sin(angle))
		cage.append(_curve(d * 0.25 + Vector3.UP * 0.88, d * 0.35 + Vector3.UP * 0.36, d * 0.88 + Vector3.DOWN * 0.64, 8))
	cage.append(_arc(Vector3.DOWN * 0.64, 0.91, 0.0, TAU, 28))
	cage.append(_arc(Vector3.UP * 0.89, 0.25, 0.0, TAU, 16))
	_stroke(bell, cage, 0.11, base)
	_static_bits(bell, _sphere, [Transform3D(Basis.IDENTITY.scaled(Vector3(0.36, 0.48, 0.36)), Vector3.DOWN * 0.53)], tint.lightened(0.37))
	var wave := _pivot(parent, Vector3.ZERO)
	_stroke(wave, [_arc(Vector3.UP * 0.27, radius * 0.93, 0.0, TAU, 48),
		_arc(Vector3.UP * 0.54, radius * 0.73, 0.0, TAU, 42),
		_arc(Vector3.UP * 0.80, radius * 0.47, 0.0, TAU, 34)], 0.17, light)
	_grow(wave, Vector3.ONE * 0.27, Vector3.ONE, 0.49)
	var swing := bell.create_tween()
	bell.rotation.z = -0.52
	swing.tween_property(bell, "rotation:z", 0.36, 0.21).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	swing.tween_property(bell, "rotation:z", -0.13, 0.23)
	swing.tween_property(bell, "rotation:z", 0.04, 0.21)


func _inferno(parent: Node3D, radius: float, tint: Color, base: Material, light: Material) -> void:
	var pyre := _pivot(parent, Vector3.ZERO)
	var flares: Array = []
	var crowns: Array = []
	for index in 9:
		var angle := index * TAU / 9.0
		var heading := Vector3(cos(angle), 0.0, sin(angle))
		var lift := 1.47 + 0.34 * (index % 3)
		var flare := _curve(heading * radius * 0.55 + Vector3.UP * 0.14,
			heading.rotated(Vector3.UP, -0.23) * radius * 0.88 + Vector3.UP * lift,
			heading.rotated(Vector3.UP, -0.56) * radius * 0.91 + Vector3.UP * (lift * 0.26), 10)
		flares.append(flare)
		crowns.append(_curve(heading * radius * 0.57 + Vector3.UP * 0.19,
			heading.rotated(Vector3.UP, -0.22) * radius * 0.84 + Vector3.UP * (lift * 0.94), flare[8], 8))
	_stroke(pyre, flares, 0.42, base)
	_stroke(pyre, crowns, 0.105, light)
	_static_bits(pyre, _spike, _circle_bits(14, radius * 0.90, 0.62, Vector3(0.12, 0.47, 0.12)), tint.lerp(Color("f6813c"), 0.55))
	_grow(pyre, Vector3(0.72, 0.13, 0.72), Vector3.ONE, 0.28)
	pyre.create_tween().tween_property(pyre, "rotation:y", 1.13, 0.98).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _frost(parent: Node3D, radius: float, tint: Color, base: Material, edge: Material) -> void:
	var ice := _pivot(parent, Vector3.ZERO)
	var points: Array[Transform3D] = []
	var branches: Array = []
	for index in 6:
		var angle := index * TAU / 6.0
		var d := Vector3(cos(angle), 0, sin(angle))
		for vein in 3:
			var at := d * radius * (0.27 + 0.27 * vein)
			var height := 1.0 + float(vein) * 0.53
			points.append(Transform3D((Basis(Vector3.UP, -angle) * Basis(Vector3.RIGHT, -0.21)).scaled(Vector3(0.33, height, 0.37)), at + Vector3.UP * height * 0.42))
			for side in [-1.0, 1.0]:
				var offshoot := (d.rotated(Vector3.UP, side * 0.86) * radius) * 0.2
				branches.append(PackedVector3Array([at + Vector3.UP * 0.14, at * 0.85 + offshoot + Vector3.UP * 0.22]))
		branches.append(PackedVector3Array([Vector3.UP * 0.18, d * radius * 0.91 + Vector3.UP * 0.18]))
	_static_bits(ice, _spike, points, tint.lightened(0.34))
	_stroke(ice, branches, 0.145, base)
	_stroke(ice, [_arc(Vector3.UP * 0.15, radius * 0.84, 0.0, TAU, 6)], 0.17, edge)
	_grow(ice, Vector3(1.0, 0.017, 1.0), Vector3.ONE, 0.35)


func _dream(parent: Node3D, radius: float, tint: Color, base: Material, light: Material) -> void:
	var canopy := _pivot(parent, Vector3.ZERO)
	var paths: Array = []
	for rib in 8:
		var direction := Vector3(cos(rib * TAU / 8.0), 0.0, sin(rib * TAU / 8.0))
		var points := PackedVector3Array()
		for index in 12:
			var t := index / 11.0 * PI * 0.5
			points.append(direction * radius * 0.86 * cos(t) + Vector3.UP * (0.12 + 2.62 * sin(t)))
		paths.append(points)
	_stroke(canopy, paths, 0.128, base)
	var moon := _pivot(canopy, Vector3.UP * 2.14)
	moon.rotate_x(-PI * 0.42)
	_stroke(moon, [_arc(Vector3.ZERO, 0.65, -0.80, PI * 1.23, 20),
		_arc(Vector3(0.15, 0, -0.05), 0.45, -0.48, PI * 1.01, 18)], 0.175, light)
	_static_bits(canopy, SHARD, _circle_bits(12, radius * 0.60, 0.92, Vector3(0.19, 0.37, 0.14)), tint.lightened(0.39))
	_grow(canopy, Vector3(0.42, 0.05, 0.42), Vector3.ONE, 0.48)
	canopy.create_tween().tween_property(canopy, "rotation:y", 0.66, 1.2)


func _chains(parent: Node3D, radius: float, tint: Color, base: Material, edge: Material) -> void:
	var cage := _pivot(parent, Vector3.ZERO)
	var links: Array[Transform3D] = []
	var tether: Array = []
	for index in 7:
		var angle := index * TAU / 7.0
		var direction := Vector3(cos(angle), 0.0, sin(angle))
		var points := PackedVector3Array()
		for segment in 7:
			var progress := segment / 6.0
			var at := direction * radius * lerpf(0.90, 0.16, progress) + Vector3.UP * (0.19 + sin(progress * PI) * 1.16 + progress)
			points.append(at)
			var rotation := Basis(Vector3.UP, angle) * Basis(Vector3.FORWARD, -0.55 - (segment % 2) * 0.61)
			links.append(Transform3D(rotation.scaled(Vector3(0.46, 0.28, 0.59)), at))
		tether.append(points)
	_static_bits(cage, _link, links, tint.lightened(0.20))
	_stroke(cage, tether, 0.16, base)
	_stroke(cage, [_arc(Vector3.UP * 0.14, radius * 0.79, 0, TAU, 7)], 0.17, edge)
	_grow(cage, Vector3(0.29, 0.16, 0.29), Vector3.ONE, 0.36)


func _lightning(parent: Node3D, radius: float, tint: Color, base: Material, light: Material) -> void:
	var bolts: Array = []
	var branches: Array = []
	for index in 9:
		var angle := index * TAU / 9.0
		var side := Vector3(cos(angle), 0.0, sin(angle))
		var r := radius * (0.48 + 0.43 * ((index % 3) / 2.0))
		var land := side * r + Vector3.UP * 0.17
		var tip := land * Vector3(0.44, 1, 0.44) + Vector3.UP * (3.7 + (index % 3) * 0.62)
		var right := side.cross(Vector3.UP)
		var line := PackedVector3Array([tip, tip.lerp(land, 0.23) + right * 0.57, tip.lerp(land, 0.41) - right * 0.52,
			tip.lerp(land, 0.60) + right * 0.34, tip.lerp(land, 0.74) - right * 0.26, land])
		bolts.append(line)
		for branch in [-1.0, 1.0]:
			branches.append(PackedVector3Array([line[2], line[2].lerp(land, 0.48) + right * branch * 0.60, land + right * branch * 0.94]))
	_stroke(parent, bolts, 0.22, base)
	_stroke(parent, branches, 0.096, light)
	_stroke(parent, [_arc(Vector3.UP * 0.18, radius * 0.71, 0.0, TAU, 9), _arc(Vector3.UP * 3.6, radius * 0.32, 0.0, TAU, 18)], 0.15, light)
	_static_bits(parent, SHARD, _circle_bits(9, radius * 0.68, 0.5, Vector3(0.18, 0.54, 0.18)), tint.lightened(0.24))


func _swarm(parent: Node3D, radius: float, tint: Color, base: Material, edge: Material) -> void:
	var hurricane := _pivot(parent, Vector3.UP * 0.13)
	var wings: Array = []
	for index in 21:
		var turn := index * 2.39996
		var r := radius * (0.38 + float(index % 6) * 0.11)
		var location := Vector3(cos(turn) * r, 0.35 + 0.19 * (index % 11), sin(turn) * r)
		var rotation := Basis(Vector3.UP, -turn) * Basis(Vector3.RIGHT, -0.71 + float(index % 5) * 0.29)
		var wing := 0.25 + 0.028 * (index % 6)
		for side in [-1.0, 1.0]:
			wings.append(PackedVector3Array([
				location, location + rotation * Vector3(wing * side, 0.35, -0.11),
				location + rotation * Vector3(wing * 1.25 * side, -0.01, 0.21),
				location + rotation * Vector3(0.04 * side, -0.17, 0.12), location
			]))
	_stroke(hurricane, wings, 0.10, base)
	_stroke(hurricane, [_arc(Vector3.UP * 0.29, radius * 0.90, -0.08, 4.92, 34),
		_arc(Vector3.UP * 1.36, radius * 0.52, 0.21, 4.93, 30)], 0.19, edge)
	_grow(hurricane, Vector3(0.24, 0.65, 0.24), Vector3.ONE, 0.52)
	hurricane.create_tween().tween_property(hurricane, "rotation:y", 2.6, 1.19)


func _floor_marks(event: Dictionary, center: Vector2, radius: float, draw_spokes: bool) -> Array:
	var shapes: Array = []
	var affected: Dictionary = event.get("affected_positions", {})
	for id in affected:
		var point: Vector2 = affected[id] - center
		var at := _point(point, 0.25)
		shapes.append(_arc(at, 0.42, 0.0, TAU, 4))
		for angle in [0.0, PI * 0.5, PI, PI * 1.5]:
			var ray := Vector3(cos(angle), 0.0, sin(angle))
			shapes.append(PackedVector3Array([at + ray * 0.4, at + ray * 0.58]))
	if event.get("shape", "") == "line":
		var direction := _heading(event)
		var cross := Vector3(-direction.y, 0, direction.x) * radius * 0.83
		var half := _point(direction, 0) * float(event.get("length", 5.0)) * 0.5
		for side in [-1, 1]:
			shapes.append(PackedVector3Array([half + cross * side + Vector3.UP * 0.13, -half + cross * side + Vector3.UP * 0.13]))
		return shapes
	if not draw_spokes:
		return shapes
	for index in 8:
		var angle := index * TAU / 8.0
		var direction := Vector3(cos(angle), 0, sin(angle))
		var corner := direction * radius * 0.68
		var middle := direction.rotated(Vector3.UP, 0.22) * radius * 0.42
		shapes.append(PackedVector3Array([Vector3.UP * 0.13, middle + Vector3.UP * 0.13, corner + Vector3.UP * 0.13]))
	return shapes


func _impact_floor(parent: Node3D, radius: float, tint: Color, motif: int) -> void:
	var material := ShaderMaterial.new()
	material.shader = IMPACT_FLOOR_SHADER
	material.render_priority = 1
	material.set_shader_parameter("tint", tint)
	material.set_shader_parameter("motif", motif)
	var plate := MeshInstance3D.new()
	plate.mesh = _quad
	plate.material_override = material
	plate.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(plate)
	plate.position.y = 0.118
	plate.rotation.x = -PI * 0.5
	plate.scale = Vector3(radius, radius, 1.0)
	plate.create_tween().tween_method(func(age: float): material.set_shader_parameter("age", age), 0.0, 1.0, 1.22)


func _scatter(parent: Node3D, event: Dictionary, radius: float, tint: Color) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([event.get("source_id", 0), event.get("seq", 0), event.get("name", "")])
	var count := 27
	var particles := _instance_batch(parent, SHARD, count)
	var speeds: Array[Vector3] = []
	var sizes: Array[Vector3] = []
	var style: int = maxi(0, PATTERNS.find(event.get("pattern", "")))
	var upward := [1.11, 1.28, 0.81, 1.12, 1.58, 0.76, 1.03, 1.68, 1.14, 0.94, 0.86, 0.79, 1.42, 0.70, 1.34, 1.81][style] as float
	var angle_drift := [0.0, -0.8, 0.0, 0.0, 0.5, 0.0, 1.17, 0.22, -0.43, 0.0, 0.76, 0.0, -0.59, 0.0, 0.0, -1.02][style] as float
	for index in count:
		var angle := rng.randf_range(0.0, TAU)
		var radial := rng.randf_range(0.29, 0.98) * radius
		speeds.append(Vector3(cos(angle) * radial, rng.randf_range(0.35, 2.11) * upward, sin(angle) * radial))
		sizes.append(Vector3(0.10, 0.23, 0.068) * rng.randf_range(0.46, 1.67))
		var flash_color := GOLD if style in [3, 4, 9, 10] else tint.lightened(0.45)
		particles.multimesh.set_instance_color(index, tint.lerp(flash_color, rng.randf_range(0.07, 0.83)))
	var spray := func(t: float):
		var outgoing := 1.0 - pow(1.0 - t, 2.2)
		for index in count:
			var speed := speeds[index]
			var bend := speed.rotated(Vector3.UP, angle_drift * outgoing)
			var at := Vector3(bend.x * outgoing, maxf(0.13, speed.y * sin(t * PI)), bend.z * outgoing)
			var spin := Basis(Vector3.UP, t * 4.1 + index) * Basis(Vector3.RIGHT, t * 5.2 + index)
			particles.multimesh.set_instance_transform(index, Transform3D(spin.scaled(sizes[index] * maxf(0.022, 1.0 - t * t)), at))
	spray.call(0.0)
	particles.create_tween().tween_method(spray, 0.0, 1.0, 1.08).finished.connect(particles.queue_free)


func _circle_bits(count: int, radius: float, height: float, size: Vector3) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	for n in count:
		var angle := n * TAU / count
		var at := Vector3(cos(angle) * radius, height * (0.82 + 0.20 * (n % 4)), sin(angle) * radius)
		var basis := (Basis(Vector3.UP, angle) * Basis(Vector3.RIGHT, (n % 3 - 1) * 0.19)).scaled(size)
		result.append(Transform3D(basis, at))
	return result


func _static_bits(parent: Node3D, mesh: Mesh, transforms: Array[Transform3D], tint: Color) -> void:
	var batch := _instance_batch(parent, mesh, transforms.size())
	for index in transforms.size():
		batch.multimesh.set_instance_transform(index, transforms[index])
		batch.multimesh.set_instance_color(index, tint.lightened(0.08 * (index % 3)))


func _instance_batch(parent: Node3D, mesh: Mesh, count: int) -> MultiMeshInstance3D:
	var batch := MultiMeshInstance3D.new()
	batch.multimesh = MultiMesh.new()
	batch.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	batch.multimesh.use_colors = true
	batch.multimesh.mesh = mesh
	batch.multimesh.instance_count = count
	batch.material_override = _bits_material
	batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	batch.custom_aabb = AABB(Vector3(-10, -1, -10), Vector3(20, 10, 20))
	parent.add_child(batch)
	return batch


func _disc(parent: Node3D, event: Dictionary, warning: float) -> MeshInstance3D:
	var material := ShaderMaterial.new()
	material.shader = FLOOR_SHADER
	material.set_shader_parameter("tint", _tint(event))
	material.set_shader_parameter("edge_ink", _side(event))
	material.set_shader_parameter("warning", warning)
	material.set_shader_parameter("seed", float(PATTERNS.find(event.get("pattern", "")) + 1))
	var mesh := MeshInstance3D.new()
	mesh.mesh = _quad
	mesh.material_override = material
	mesh.rotation.x = -PI * 0.5
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mesh)
	return mesh


func _place_disc(disk: MeshInstance3D, event: Dictionary, center: Vector2, radius: float, height: float) -> void:
	var half_length := float(event.get("length", 0.0)) * 0.5 if event.get("shape", "") == "line" else 0.0
	disk.position = _point(center, height)
	disk.scale = Vector3(radius, radius + half_length, 1.0)
	if half_length > 0.0:
		var heading := _heading(event)
		disk.rotation.y = atan2(-heading.x, -heading.y)
	var material := disk.material_override as ShaderMaterial
	material.set_shader_parameter("line_half_length", half_length)
	material.set_shader_parameter("line_half_width", maxf(radius, 0.001))


func _stroke(parent: Node3D, paths: Array, width: float, ink: Material) -> void:
	var vertices := PackedVector3Array()
	var uv := PackedVector2Array()
	var indices := PackedInt32Array()
	for path: PackedVector3Array in paths:
		if path.size() < 2:
			continue
		var start_vertex := vertices.size()
		for index in path.size():
			var before := path[maxi(0, index - 1)]
			var after := path[mini(path.size() - 1, index + 1)]
			var norm := before.direction_to(after)
			var right := norm.cross(Vector3.UP)
			if right.length_squared() < 0.10:
				right = norm.cross(Vector3.FORWARD)
			var t := index / float(path.size() - 1)
			var half := right.normalized() * width * lerpf(0.34, 0.50, sin(PI * t))
			var at := path[index]
			vertices.append(at - half)
			vertices.append(at + half)
			uv.append(Vector2(t, 0.0))
			uv.append(Vector2(t, 1.0))
			if index < path.size() - 1:
				var start := start_vertex + index * 2
				indices.append_array([start, start + 2, start + 1, start + 2, start + 3, start + 1])
	if vertices.is_empty():
		return
	var surfaces: Array = []
	surfaces.resize(Mesh.ARRAY_MAX)
	surfaces[Mesh.ARRAY_VERTEX] = vertices
	surfaces[Mesh.ARRAY_TEX_UV] = uv
	surfaces[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surfaces)
	var strip := MeshInstance3D.new()
	strip.mesh = mesh
	strip.material_override = ink
	strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(strip)


func _extrude(outline: PackedVector2Array, half_depth: float) -> ArrayMesh:
	var planar := Geometry2D.triangulate_polygon(outline)
	var draw := SurfaceTool.new()
	draw.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in range(0, planar.size(), 3):
		for offset in [0, 1, 2]:
			var p: Vector2 = outline[planar[index + offset]]
			draw.add_vertex(Vector3(p.x, p.y, -half_depth))
		for offset in [2, 1, 0]:
			var p: Vector2 = outline[planar[index + offset]]
			draw.add_vertex(Vector3(p.x, p.y, half_depth))
	for edge in outline.size():
		var a := outline[edge]
		var b := outline[(edge + 1) % outline.size()]
		for at in [Vector3(a.x, a.y, -half_depth), Vector3(b.x, b.y, -half_depth), Vector3(a.x, a.y, half_depth),
				Vector3(a.x, a.y, half_depth), Vector3(b.x, b.y, -half_depth), Vector3(b.x, b.y, half_depth)]:
			draw.add_vertex(at)
	draw.generate_normals()
	return draw.commit()


func _faceted_crystal() -> ArrayMesh:
	var profile := PackedVector2Array([Vector2(0.08, -0.68), Vector2(0.31, -0.22), Vector2(0.25, 0.46), Vector2(0.016, 0.90)])
	var draw := SurfaceTool.new()
	draw.begin(Mesh.PRIMITIVE_TRIANGLES)
	draw.set_smooth_group(-1)
	var sides := 5
	for side in sides:
		var angle := float(side) * TAU / sides
		var next := float(side + 1) * TAU / sides
		var edge := Vector3(cos(angle), 0.0, sin(angle))
		var adjacent := Vector3(cos(next), 0.0, sin(next))
		for row in range(profile.size() - 1):
			var lower := profile[row]
			var upper := profile[row + 1]
			var a := edge * lower.x + Vector3.UP * lower.y
			var b := adjacent * lower.x + Vector3.UP * lower.y
			var c := edge * upper.x + Vector3.UP * upper.y
			var d := adjacent * upper.x + Vector3.UP * upper.y
			for point: Vector3 in [a, b, c, c, b, d]:
				draw.add_vertex(point)
	draw.generate_normals()
	return draw.commit()


func _molten_anvil(mesh: Mesh, tint: Color) -> MeshInstance3D:
	var material := ShaderMaterial.new()
	material.shader = FORGE_SHADER
	material.set_shader_parameter("blaze", tint.darkened(0.13))
	var body := MeshInstance3D.new()
	body.mesh = mesh
	body.material_override = material
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return body


func _arc(center: Vector3, radius: float, from: float, to: float, steps: int) -> PackedVector3Array:
	var result := PackedVector3Array()
	for index in range(steps + 1):
		var angle := lerpf(from, to, index / float(steps))
		result.append(center + Vector3(cos(angle), 0.0, sin(angle)) * radius)
	return result


func _curve(a: Vector3, mid: Vector3, b: Vector3, steps := 15) -> PackedVector3Array:
	var result := PackedVector3Array()
	for step in range(steps + 1):
		var t := step / float(steps)
		result.append(a.lerp(mid, t).lerp(mid.lerp(b, t), t))
	return result


func _pivot(parent: Node3D, height: Vector3) -> Node3D:
	var node := Node3D.new()
	parent.add_child(node)
	node.position = height
	return node


func _grow(node: Node3D, initial: Vector3, final: Vector3, time: float) -> void:
	node.scale = initial
	node.create_tween().tween_property(node, "scale", final, time).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)


func _light(color: Color, strength: float) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = LIGHT_SHADER
	material.set_shader_parameter("tint", color)
	material.set_shader_parameter("strength", strength)
	return material


func _center(event: Dictionary) -> Vector2:
	return event.get("destination", event.get("center", event.get("position", Vector2.ZERO)))


func _presentation_center(event: Dictionary) -> Vector2:
	var center := _center(event)
	if event.get("shape", "") == "line":
		var origin: Vector2 = event.get("origin", center)
		return origin.lerp(center, 0.5)
	return center


func _heading(event: Dictionary) -> Vector2:
	if event.get("shape", "") == "line":
		var origin: Vector2 = event.get("origin", Vector2.ZERO)
		return origin.direction_to(_center(event))
	return event.get("facing", Vector2.UP)


func _side(event: Dictionary) -> Color:
	if event.get("team", 0) == 1:
		return RED
	return BLUE if event.get("target_kind", "") == "ally" else GOLD


func _tint(event: Dictionary) -> Color:
	return Color(event.get("tint", GOLD))


func _point(position: Vector2, height: float) -> Vector3:
	return Vector3(position.x, height, position.y)


func _remove(node: Node3D) -> void:
	if is_instance_valid(node) and node.get_parent() == self:
		remove_child(node)
		node.queue_free()
