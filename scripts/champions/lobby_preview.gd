extends SubViewportContainer

const ChampionModel = preload("res://scripts/champions/model.gd")
const SurfaceFinish = preload("res://scripts/champions/surface_finish.gd")
const BACKDROP = preload("res://scripts/champions/portrait_backdrop.gdshader")
const BASE_ANGLE := -0.24
const MOTE_COUNT := 24
const PATRON_TINTS := {
	"ash_dancer": Color("#f49865"), "bellwarden": Color("#eac481"),
	"blood_cantor": Color("#e4869c"), "breakwater": Color("#81c8c0"),
	"chainrunner": Color("#a4afd1"), "coilwright": Color("#eace81"),
	"dream_shepherd": Color("#b58df2"), "duskmoth": Color("#cf8ab9"),
	"echo_duelist": Color("#8acaf4"), "forgecaller": Color("#f29361"),
	"glassmage": Color("#a591f1"), "lamplighter": Color("#f4ce81"),
	"longwatch": Color("#a8c491"), "sluicecaller": Color("#76ccdb"),
	"threadkeeper": Color("#d39cf2"), "winter_scribe": Color("#a7cef4"),
}

var champion: Node3D
var viewport: SubViewport
var _stand: Node3D
var _camera: Camera3D
var _backdrop: MeshInstance3D
var _backdrop_material: ShaderMaterial
var _ground_material: ShaderMaterial
var _rim_light: DirectionalLight3D
var _dais_light: StandardMaterial3D
var _mote_light: StandardMaterial3D
var _motes: MultiMesh
var _framing: Dictionary = {}
var _current_bounds := Vector3(1.0, 0.0, 2.4)
var _patron_tint := Color("#d3a079")
var _orbit_target := BASE_ANGLE
var _camera_size_target := 2.7
var _camera_center_target := 1.0
var _invocation := 0.0
var _stage_age := 0.0
var _dragging := false
var _active := true


func _ready() -> void:
	stretch = true
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(0, 192)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_MOVE
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	tooltip_text = "Drag to turn the champion. With the preview focused, use Left and Right to rotate or Home to center."
	viewport = SubViewport.new()
	viewport.name = "PortraitStage"
	viewport.size = Vector2i(300, 400)
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_2X
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	add_child(viewport)
	_build_stage()
	resized.connect(_frame_camera)


func _build_stage() -> void:
	var lighting := WorldEnvironment.new()
	var room := Environment.new()
	room.background_mode = Environment.BG_COLOR
	room.background_color = Color("#15141c")
	room.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	room.ambient_light_color = Color("#d9d7e9")
	room.ambient_light_energy = 0.65
	lighting.environment = room
	viewport.add_child(lighting)

	_stand = Node3D.new()
	_stand.name = "Turntable"
	viewport.add_child(_stand)
	_build_dais()
	_build_motes()

	_camera = Camera3D.new()
	_camera.name = "PortraitCamera"
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	viewport.add_child(_camera)
	_backdrop_material = ShaderMaterial.new()
	_backdrop_material.shader = BACKDROP
	_backdrop = MeshInstance3D.new()
	_backdrop.name = "RecessedArch"
	_backdrop.mesh = QuadMesh.new()
	_backdrop.position.z = -10.0
	_backdrop.material_override = _backdrop_material
	_backdrop.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_camera.add_child(_backdrop)
	_ground_material = ShaderMaterial.new()
	_ground_material.shader = BACKDROP
	_ground_material.set_shader_parameter("dais_ground", true)
	var floor := PlaneMesh.new()
	floor.size = Vector2(14.0, 14.0)
	_mesh(floor, Vector3(0.0, -0.316, 0.0), _ground_material)

	_directional(Vector3(-2.3, 3.55, -3.65), Color("#fff0d5"), 1.50)
	_directional(Vector3(2.7, 1.85, -2.9), Color("#cbd9ff"), 0.64)
	_rim_light = _directional(Vector3(2.15, 2.9, 2.3), _patron_tint, 2.60)
	_frame_camera()
	_camera.current = true


func _build_dais() -> void:
	var basalt := _finish(Color("#39343c"), 0.07)
	var bronze := _finish(Color("#80664a"), 0.58)
	var slate := _finish(Color("#24262f"), 0.10)
	_course(1.26, 1.44, 0.12, -0.255, basalt)
	_course(1.24, 1.26, 0.036, -0.177, bronze)
	_course(1.03, 1.24, 0.11, -0.104, basalt)
	_course(1.04, 1.07, 0.030, -0.037, bronze)
	_course(0.99, 1.04, 0.022, -0.011, slate)

	_dais_light = StandardMaterial3D.new()
	_dais_light.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_dais_light.cull_mode = BaseMaterial3D.CULL_DISABLED
	var etched := SurfaceTool.new()
	etched.begin(Mesh.PRIMITIVE_TRIANGLES)
	for mark in 24:
		var angle := (float(mark) + 0.5) * TAU / 24.0
		var ray := Vector2.RIGHT.rotated(angle)
		var span := ray.orthogonal()
		var center := ray * 0.914
		var outer := center + ray * (0.045 if mark % 3 == 0 else 0.026)
		var inner := center - ray * 0.024
		_engrave(etched, inner, outer, 0.006)
		if mark % 3 == 0:
			_engrave(etched, outer - ray * 0.009, center + span * 0.028, 0.005)
			_engrave(etched, outer - ray * 0.009, center - span * 0.028, 0.005)
	_mesh(etched.commit(), Vector3(0.0, 0.005, 0.0), _dais_light)
	var band := TorusMesh.new()
	band.inner_radius = 0.846
	band.outer_radius = 0.857
	band.rings = 64
	band.ring_segments = 4
	_mesh(band, Vector3(0.0, 0.004, 0.0), bronze)


func _engrave(etch: SurfaceTool, from: Vector2, to: Vector2, width: float) -> void:
	var normal := from.direction_to(to).orthogonal() * width * 0.5
	for corner: Vector2 in [from - normal, to - normal, to + normal, from - normal, to + normal, from + normal]:
		etch.add_vertex(Vector3(corner.x, 0.0, corner.y))


func _finish(color: Color, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	SurfaceFinish.weather(material, metallic > 0.4)
	return material


func _course(top: float, base: float, height: float, level: float, material: StandardMaterial3D) -> void:
	var piece := CylinderMesh.new()
	piece.top_radius = top
	piece.bottom_radius = base
	piece.height = height
	piece.radial_segments = 16
	piece.rings = 0
	_mesh(piece, Vector3(0.0, level, 0.0), material)


func _mesh(mesh: Mesh, at: Vector3, material: Material) -> void:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	viewport.add_child(instance)


func _directional(at: Vector3, tint: Color, energy: float) -> DirectionalLight3D:
	var light := DirectionalLight3D.new()
	light.position = at
	light.light_color = tint
	light.light_energy = energy
	viewport.add_child(light)
	light.look_at(Vector3(0.0, 1.2, 0.0))
	return light


func _build_motes() -> void:
	_mote_light = StandardMaterial3D.new()
	_mote_light.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var mote := SphereMesh.new()
	mote.radial_segments = 5
	mote.rings = 3
	mote.radius = 1.0
	mote.height = 2.0
	mote.material = _mote_light
	_motes = MultiMesh.new()
	_motes.transform_format = MultiMesh.TRANSFORM_3D
	_motes.mesh = mote
	_motes.instance_count = MOTE_COUNT
	var scatter := MultiMeshInstance3D.new()
	scatter.name = "RisingSparks"
	scatter.multimesh = _motes
	scatter.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	viewport.add_child(scatter)


func show_champion(class_id: String, archetype: String) -> void:
	if is_instance_valid(champion):
		if champion.champion == class_id:
			return
		_stand.remove_child(champion)
		champion.queue_free()
	champion = ChampionModel.new()
	_stand.add_child(champion)
	champion.build(class_id, archetype)
	champion.player.animation_finished.connect(_on_animation_finished)
	_orbit_target = BASE_ANGLE
	_stand.rotation.y = _orbit_target
	_patron_tint = PATRON_TINTS.get(class_id, Color("#d3a079"))
	_rim_light.light_color = _patron_tint
	_invocation = 0.0
	_backdrop_material.set_shader_parameter("patron_tint", _patron_tint)
	_ground_material.set_shader_parameter("patron_tint", _patron_tint)
	_mote_light.albedo_color = Color("#826d6b").lerp(_patron_tint, 0.42)
	_preview_framing("idle")


func play_ability(slot: int) -> void:
	if not is_instance_valid(champion):
		return
	var clip := "cast_%d" % (slot + 1)
	if not champion.player.has_animation(clip):
		return
	champion.player.stop()
	champion.player.play(clip)
	champion.player.advance(0.0)
	_preview_framing(clip)
	_invocation = 0.22


func idle() -> void:
	if is_instance_valid(champion):
		champion.reset_motion()
		_preview_framing("idle")


func _preview_framing(clip: String) -> void:
	var key: String = champion.champion + "/" + clip
	if not _framing.has(key):
		var player: AnimationPlayer = champion.player
		var duration: float = player.current_animation_length
		var meshes := champion.find_children("*", "MeshInstance3D", true, false)
		var radial := 0.0
		var low := 0.0
		var high := 0.0
		# Fit the entire gesture, including the weapon at extension. Horizontal
		# radius allows inspection from all angles without cropping the model.
		for i in range(13):
			player.seek(duration * minf(float(i) / 12.0, 0.995), true)
			for part: MeshInstance3D in meshes:
				var bounds := part.get_aabb()
				for corner in range(8):
					var at := part.to_global(bounds.get_endpoint(corner))
					radial = maxf(radial, Vector2(at.x, at.z).length())
					low = minf(low, at.y)
					high = maxf(high, at.y)
		player.seek(0.0, true)
		_framing[key] = Vector3(radial, low, high)
	_current_bounds = _framing[key]
	_frame_camera()


func _frame_camera(immediate: bool = true) -> void:
	if _camera == null or size.y < 1.0:
		return
	var aspect := maxf(0.3, size.x / size.y)
	var radius := _current_bounds.x
	var low := minf(_current_bounds.y, -0.29)
	_camera_center_target = (low + _current_bounds.z) * 0.5
	var height := _current_bounds.z - low + 0.10
	_camera_size_target = maxf(2.46, maxf(height + 0.19, (radius * 2.0 + 0.18) / aspect))
	_backdrop_material.set_shader_parameter("stage_aspect", aspect)
	if immediate or _camera_size_target > _camera.size:
		_apply_camera(_camera_size_target, _camera_center_target)


func _apply_camera(framing: float, center: float) -> void:
	var aspect := maxf(0.3, size.x / size.y)
	_camera.size = framing
	_camera.position = Vector3(0.30, center + 0.36, -5.8)
	_camera.look_at(Vector3(0, center, 0))
	_backdrop.scale = Vector3(framing * aspect * 1.04, framing * 1.04, 1.0)


func _draw() -> void:
	if has_focus():
		draw_rect(Rect2(Vector2.ONE, size - Vector2(2, 2)), Color("e9bd72"), false, 2.0)


func _on_animation_finished(clip: StringName) -> void:
	if str(clip).begins_with("cast_"):
		champion.player.play("idle", 0.08)
		_current_bounds = _framing[champion.champion + "/idle"]
		_frame_camera(false)


func set_active(active: bool) -> void:
	if _active == active:
		return
	_active = active
	_dragging = false
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE if active else SubViewport.UPDATE_DISABLED
	set_process(active)
	if active:
		idle()


func _process(delta: float) -> void:
	var cast_light := 0.0
	if is_instance_valid(champion):
		cast_light = champion.advance_motion(delta)
	var focus_y := _camera.position.y - 0.36
	if not is_equal_approx(_camera.size, _camera_size_target) or not is_equal_approx(focus_y, _camera_center_target):
		var weight := 1.0 - exp(-12.0 * delta)
		_apply_camera(lerpf(_camera.size, _camera_size_target, weight), lerpf(focus_y, _camera_center_target, weight))
	_stand.rotation.y = lerp_angle(_stand.rotation.y, _orbit_target, 1.0 - exp(-19.0 * delta))
	_invocation = maxf(cast_light, move_toward(_invocation, 0.0, delta * 1.92))
	_stage_age += delta
	_backdrop_material.set_shader_parameter("invocation", _invocation)
	_ground_material.set_shader_parameter("invocation", _invocation)
	_rim_light.light_energy = 2.60 + _invocation * 0.92
	_dais_light.albedo_color = _patron_tint.darkened(0.48 - 0.32 * _invocation)
	for index in MOTE_COUNT:
		var phase := fposmod(_stage_age * (0.105 + 0.013 * float(index % 5)) + float(index) * 0.38197, 1.0)
		var angle := index * 2.39996 + phase * 0.9
		var distance := 1.1 + float(index % 4) * 0.17
		var center := Vector3(cos(angle) * distance, phase * 2.48 - 0.07, 0.40 + sin(angle) * distance)
		var radius := (0.004 + float(index % 5) * 0.001) * sin(phase * PI) * (1.0 + _invocation * 0.9)
		_motes.set_instance_transform(index, Transform3D(Basis.from_scale(Vector3.ONE * radius), center))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		if _dragging:
			grab_focus()
		accept_event()
	elif event is InputEventMouseMotion and _dragging:
		_orbit_target = wrapf(_orbit_target + event.relative.x * 0.014, -PI, PI)
		accept_event()
	elif event is InputEventScreenDrag:
		_orbit_target = wrapf(_orbit_target + event.relative.x * 0.014, -PI, PI)
		accept_event()
	elif event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_LEFT:
				_orbit_target -= PI / 12
			KEY_RIGHT:
				_orbit_target += PI / 12
			KEY_HOME:
				_orbit_target = BASE_ANGLE
			_:
				return
		accept_event()
