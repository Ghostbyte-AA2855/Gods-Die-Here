extends Node3D

const COURT := preload("res://scripts/stage/objective_court.gdshader")
const CRYSTAL := preload("res://scripts/stage/objective_relic.gdshader")
const CONDUIT := preload("res://scripts/stage/objective_conduit.gdshader")
const PALETTES := {
	"lockwater": [0, Color("95ebeb"), Color("48525d"), Color("9b774f")],
	"kiln": [1, Color("ffb76e"), Color("3f2d2e"), Color("b07559")],
	"orchard": [2, Color("bbec88"), Color("4d4631"), Color("a48355")],
	"quarry": [3, Color("f5d18c"), Color("414044"), Color("a29472")],
	"observatory": [4, Color("dcb9ff"), Color("373750"), Color("b49a62")],
}
const TEAM_TINTS := [Color("78f3f1"), Color("ff9980")]
const HALO_HEIGHT := 2.72

var arena_id := ""
var _court_mesh: MeshInstance3D
var _court_material: ShaderMaterial
var _jewel_material: ShaderMaterial
var _conduit: MeshInstance3D
var _conduit_material: ShaderMaterial
var _floating: Node3D
var _floor_mount: Node3D
var _lens: Node3D
var _stone: StandardMaterial3D
var _bronze: StandardMaterial3D
var _rune: StandardMaterial3D
var _map_tint := Color.WHITE
var _resting := true
var _contested := false
var _charging := false
var _extent := 1.0
var _beat := 0.0
var _last_phase := -1
var _last_progress := -1.0
var _last_claim := Color.TRANSPARENT
var _capture_flash := 0.0


func build(id: String) -> void:
	arena_id = id
	var palette: Array = PALETTES.get(id, PALETTES.lockwater)
	_map_tint = palette[1]
	_stone = _finish(palette[2], 0.24, 0.83)
	_bronze = _finish(palette[3], 0.65, 0.39)
	_rune = _finish(_map_tint.darkened(0.30), 0.20, 0.48)
	_rune.emission_enabled = true
	_rune.emission = _map_tint
	_rune.emission_energy_multiplier = 0.75

	_court_material = ShaderMaterial.new()
	_court_material.shader = COURT
	_court_material.set_shader_parameter("crest", palette[0])
	_court_material.set_shader_parameter("relic_color", _map_tint)
	var disk := PlaneMesh.new()
	disk.size = Vector2(2, 2)
	_court_mesh = _part(self, disk, Vector3.UP * 0.070, _court_material)
	_court_mesh.name = "ObjectiveRadius"
	_conduit_material = ShaderMaterial.new()
	_conduit_material.shader = CONDUIT
	_conduit_material.set_shader_parameter("tint", _map_tint)
	var column := CylinderMesh.new()
	column.height = 1.0
	column.top_radius = 0.14
	column.bottom_radius = 0.29
	column.radial_segments = 10
	column.rings = 0
	column.cap_bottom = false
	column.cap_top = false
	_conduit = _part(self, column, Vector3.ZERO, _conduit_material)

	_jewel_material = ShaderMaterial.new()
	_jewel_material.shader = CRYSTAL
	_jewel_material.set_shader_parameter("tint", _map_tint)
	_floor_mount = Node3D.new()
	_floor_mount.name = "InlaidAltar"
	add_child(_floor_mount)
	_altar(palette[0] as int)

	_floating = Node3D.new()
	_floating.name = "Relic"
	add_child(_floating)
	match id:
		"lockwater": _drowned_lantern()
		"kiln": _ember_crown()
		"orchard": _heartseed()
		"quarry": _basalt_keystone()
		"observatory": _eclipse_astrolabe()
	_batch_static(_floating)
	_batch_static(_floor_mount)


func set_capture(state: Dictionary) -> void:
	var at: Vector2 = state.position
	position = Vector3(at.x, 0, at.y)
	var radius: float = state.radius
	if not is_equal_approx(_extent, radius):
		_extent = radius
		_court_mesh.scale = Vector3(radius, 1.0, radius)
		_floor_mount.scale = Vector3(radius, 1.0, radius)
	var progress := clampf(float(state.progress) / maxf(float(state.hold), 0.01), 0.0, 1.0)
	_contested = state.phase == "contested"
	_charging = state.team >= 0 and progress > 0.0
	_resting = state.phase == "arming" or state.phase == "cooldown"
	var phase := 1
	match state.phase:
		"contested": phase = 3
		"arming": phase = 0
		"cooldown": phase = 4
		_:
			if _charging: phase = 2
	var claim_tint: Color = TEAM_TINTS[state.team] if state.team >= 0 else _map_tint
	if phase == 4 and _last_phase != 4:
		_capture_flash = 1.0
	if phase != _last_phase:
		_last_phase = phase
		_court_material.set_shader_parameter("phase", phase)
	if not is_equal_approx(progress, _last_progress):
		_last_progress = progress
		_court_material.set_shader_parameter("fraction", progress)
	if _last_claim != claim_tint:
		_last_claim = claim_tint
		_court_material.set_shader_parameter("claim_color", claim_tint)
		_jewel_material.set_shader_parameter("tint", _map_tint.lerp(claim_tint, 0.61))
		_conduit_material.set_shader_parameter("tint", _map_tint.lerp(claim_tint, 0.54))
	if not visible:
		show()
		set_process(true)


func reset() -> void:
	hide()
	set_process(false)
	_last_phase = -1
	_capture_flash = 0.0


func _process(delta: float) -> void:
	_beat += delta * (1.27 if _charging and not _resting else 0.80)
	_capture_flash = move_toward(_capture_flash, 0.0, delta * 1.8)
	_floating.position = Vector3(0, HALO_HEIGHT + sin(_beat * 1.6) * 0.095 + _capture_flash * 0.22, -_extent * 0.19)
	_floating.rotation.y = _beat * 0.59
	_floating.scale = Vector3.ONE * (1.23 + _capture_flash * 0.17)
	if _lens != null:
		_lens.rotation.y = -_beat * 0.27
		_lens.rotation.z = 0.28 + sin(_beat) * 0.25
	var intensity := 0.66 if _resting else 1.11
	if _contested:
		intensity += 0.22 * sin(_beat * 6.0)
	_jewel_material.set_shader_parameter("intensity", intensity + _capture_flash * 0.9)
	var column := _floating.position - Vector3.UP * 0.28
	_conduit.position = column * 0.5 + Vector3.UP * 0.035
	_conduit.basis = Basis(Quaternion(Vector3.UP, column.normalized())) * Basis.from_scale(Vector3(1.0, column.length(), 1.0))
	var beam_strength := 0.64 if _charging and not _resting else 0.23
	_conduit_material.set_shader_parameter("strength", clampf(beam_strength + _capture_flash * 0.55, 0.0, 1.0))


func _altar(crest: int) -> void:
	for index in 4:
		var heading := float(index) * PI * 0.5 + PI * 0.25
		var at := Vector3(sin(heading), 0, cos(heading))
		var iron := _box(_floor_mount, at * 0.77 + Vector3.UP * 0.015, Vector3(0.31, 0.05, 0.34), _stone)
		iron.rotation.y = heading
		var trim := _box(_floor_mount, at * 0.85 + Vector3.UP * 0.047, Vector3(0.18, 0.018, 0.15), _bronze)
		trim.rotation.y = heading
	if crest == 4:
		_hoop(_floor_mount, Vector3.UP * 0.024, 0.59, 0.018, Vector3.ZERO, _bronze)


func _drowned_lantern() -> void:
	_crystal(_floating, Vector3.ZERO, 0.235, 0.62, 6)
	_collar(_floating, Vector3.UP * 0.22, 0.38, 0.30, 0.115, 6, _bronze)
	_collar(_floating, Vector3.DOWN * 0.24, 0.29, 0.37, 0.125, 6, _bronze)
	_collar(_floating, Vector3.UP * 0.35, 0.24, 0.38, 0.16, 6, _stone)
	for index in 6:
		var a := index * TAU / 6.0
		var out := Vector3(cos(a), 0, sin(a))
		_beam(_floating, out * 0.36 + Vector3.UP * 0.22, out * 0.31 + Vector3.DOWN * 0.25, 0.035, _bronze)
		_collar(_floating, out * 0.40 + Vector3.DOWN * 0.27, 0.062, 0.0, 0.17, 4, _rune)
	_hoop(_floating, Vector3.UP * 0.47, 0.13, 0.024, Vector3(PI * 0.5, 0, 0), _bronze)


func _ember_crown() -> void:
	_crystal(_floating, Vector3.UP * 0.12, 0.26, 0.55, 4)
	_collar(_floating, Vector3.DOWN * 0.30, 0.39, 0.25, 0.19, 8, _stone)
	_hoop(_floating, Vector3.DOWN * 0.21, 0.405, 0.035, Vector3.ZERO, _bronze)
	for index in 4:
		var a := (index + 0.5) * TAU / 4.0
		var out := Vector3(sin(a), 0, cos(a))
		var foot := out * 0.31 + Vector3.DOWN * 0.21
		var shoulder := out * 0.47 + Vector3.UP * 0.08
		var tip := out * 0.40 + Vector3.UP * 0.34
		_beam(_floating, foot, shoulder, 0.08, _bronze)
		_beam(_floating, shoulder, tip, 0.066, _bronze)
		_collar(_floating, tip + Vector3.UP * 0.04, 0.0, 0.083, 0.16, 4, _rune)


func _heartseed() -> void:
	var husk := _crystal(_floating, Vector3.UP * 0.02, 0.24, 0.55, 5)
	husk.rotation.z = 0.30
	for index in 5:
		var angle := index * TAU / 5.0
		var branch := Vector3(sin(angle), 0, cos(angle))
		var root := branch * 0.18 + Vector3.DOWN * 0.27
		var shoulder := branch * 0.43 + Vector3.DOWN * 0.09
		var leaf := branch * 0.32 + Vector3.UP * 0.21
		_beam(_floating, root, shoulder, 0.048, _stone)
		_beam(_floating, shoulder, leaf, 0.032, _bronze)
		var seed := _crystal(_floating, leaf + Vector3.UP * 0.085, 0.056, 0.15, 4)
		seed.rotation.z = 0.51
	_hoop(_floating, Vector3.DOWN * 0.19, 0.30, 0.022, Vector3(0.31, 0.0, 0.15), _rune)


func _basalt_keystone() -> void:
	var spire := _crystal(_floating, Vector3.ZERO, 0.26, 0.79, 5)
	spire.rotation.z = -0.14
	for layer in 3:
		var at := Vector3(0, -0.18 + layer * 0.17, 0)
		var clamp := _collar(_floating, at, 0.29, 0.29, 0.065, 5, _stone if layer == 1 else _bronze)
		clamp.rotation.z = 0.19
	for index in 3:
		var a := index * TAU / 3.0
		var chip := _crystal(_floating, Vector3(cos(a) * 0.43, sin(a) * 0.23, sin(a) * 0.43), 0.075, 0.24, 4)
		chip.rotation.z = 0.52 + float(index) * 0.74


func _eclipse_astrolabe() -> void:
	_crystal(_floating, Vector3.ZERO, 0.24, 0.63, 6)
	_hoop(_floating, Vector3.ZERO, 0.49, 0.032, Vector3(PI * 0.25, 0.0, 0.42), _bronze)
	_hoop(_floating, Vector3.ZERO, 0.40, 0.025, Vector3(PI * 0.50, 0.0, -0.46), _rune)
	_lens = Node3D.new()
	_floating.add_child(_lens)
	_hoop(_lens, Vector3.ZERO, 0.54, 0.021, Vector3(0.1, 0.0, 0.33), _bronze)
	for index in 4:
		var angle := index * TAU / 4.0
		_crystal(_lens, Vector3(cos(angle) * 0.56, 0, sin(angle) * 0.56), 0.071, 0.14, 4)
	_batch_static(_lens)


func _finish(color: Color, metal: float, rough: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metal
	material.roughness = rough
	return material


func _part(parent: Node3D, mesh: Mesh, at: Vector3, material: Material) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = material
	part.position = at
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(part)
	return part


func _crystal(parent: Node3D, at: Vector3, radius: float, height: float, edges: int) -> MeshInstance3D:
	var jewel := SurfaceTool.new()
	jewel.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in edges:
		var a := index * TAU / float(edges)
		var b := (index + 1) * TAU / float(edges)
		var first := Vector3(cos(a) * radius, 0, sin(a) * radius)
		var second := Vector3(cos(b) * radius, 0, sin(b) * radius)
		var top := Vector3.UP * height * 0.52
		var low := Vector3.DOWN * height * 0.48
		for point in [top, second, first, low, first, second]:
			jewel.add_vertex(point)
	jewel.generate_normals()
	return _part(parent, jewel.commit(), at, _jewel_material)


func _collar(parent: Node3D, at: Vector3, top: float, bottom: float, height: float, sides: int, material: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = sides
	mesh.rings = 0
	return _part(parent, mesh, at, material)


func _box(parent: Node3D, at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _part(parent, mesh, at, material)


func _beam(parent: Node3D, from: Vector3, to: Vector3, radius: float, material: Material) -> void:
	var path := to - from
	var beam := _collar(parent, from.lerp(to, 0.5), radius * 0.70, radius, path.length(), 5, material)
	beam.basis = Basis(Quaternion(Vector3.UP, path.normalized()))


func _hoop(parent: Node3D, at: Vector3, radius: float, width: float, angle: Vector3, material: Material) -> void:
	var hoop := TorusMesh.new()
	hoop.inner_radius = radius - width
	hoop.outer_radius = radius + width
	hoop.rings = 32
	hoop.ring_segments = 6
	_part(parent, hoop, at, material).rotation = angle


# Parts that rotate together share a draw call per material.
func _batch_static(parent: Node3D) -> void:
	var surfaces: Dictionary = {}
	var originals: Array[MeshInstance3D] = []
	for child in parent.get_children():
		if not child is MeshInstance3D:
			continue
		var part := child as MeshInstance3D
		var material := part.material_override
		if not surfaces.has(material):
			var batch := SurfaceTool.new()
			batch.begin(Mesh.PRIMITIVE_TRIANGLES)
			surfaces[material] = batch
		var batch: SurfaceTool = surfaces[material]
		for index in part.mesh.get_surface_count():
			batch.append_from(part.mesh, index, part.transform)
		originals.append(part)
	for material: Material in surfaces:
		var batch: SurfaceTool = surfaces[material]
		_part(parent, batch.commit(), Vector3.ZERO, material)
	for mesh in originals:
		mesh.free()
