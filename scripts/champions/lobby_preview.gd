extends SubViewportContainer

const ChampionModel = preload("res://scripts/champions/model.gd")
const BASE_ANGLE := 0.22

var champion: Node3D
var viewport: SubViewport
var _stand: Node3D
var _camera: Camera3D
var _framing: Dictionary = {}
var _current_bounds := Vector3(1.0, 0.0, 2.4)
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
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	add_child(viewport)
	_build_stage()
	resized.connect(_frame_camera)


func _build_stage() -> void:
	var lighting := WorldEnvironment.new()
	var room := Environment.new()
	room.background_mode = Environment.BG_COLOR
	room.background_color = Color("15111b")
	room.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	room.ambient_light_color = Color("d9caef")
	room.ambient_light_energy = 0.44
	lighting.environment = room
	viewport.add_child(lighting)

	_stand = Node3D.new()
	_stand.name = "Turntable"
	viewport.add_child(_stand)
	var stone := CylinderMesh.new()
	stone.top_radius = 0.96
	stone.bottom_radius = 1.03
	stone.height = 0.15
	stone.radial_segments = 32
	_mesh(stone, Vector3(0, -0.073, 0), Color("302637"), 0.12)
	var lip := TorusMesh.new()
	lip.inner_radius = 0.835
	lip.outer_radius = 0.872
	lip.rings = 36
	lip.ring_segments = 6
	_mesh(lip, Vector3(0, 0.006, 0), Color("8f6e52"), 0.5)
	var floor := CylinderMesh.new()
	floor.top_radius = 2.5
	floor.bottom_radius = 2.5
	floor.height = 0.04
	_mesh(floor, Vector3(0, -0.15, 0), Color("1d1524"), 0.0)

	_camera = Camera3D.new()
	_camera.name = "PortraitCamera"
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	viewport.add_child(_camera)
	_frame_camera()
	_camera.current = true
	_light(Vector3(2.5, 4.2, -3.1), Color("ffe3c1"), 2.7, 8.0)
	_light(Vector3(-2.5, 2.2, -1.6), Color("91a5ed"), 1.6, 7.0)
	_light(Vector3(0.8, 3.0, 2.5), Color("e19af2"), 3.5, 7.0)


func _mesh(mesh: Mesh, at: Vector3, color: Color, metallic: float) -> void:
	var instance := MeshInstance3D.new()
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = 0.57
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	viewport.add_child(instance)


func _light(at: Vector3, tint: Color, energy: float, reach: float) -> void:
	var light := OmniLight3D.new()
	light.position = at
	light.light_color = tint
	light.light_energy = energy
	light.omni_range = reach
	viewport.add_child(light)


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
	_stand.rotation.y = BASE_ANGLE
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


func _frame_camera() -> void:
	if _camera == null or size.y < 1.0:
		return
	var aspect := maxf(0.3, size.x / size.y)
	var radius := _current_bounds.x
	var center := (_current_bounds.y + _current_bounds.z) * 0.5
	var height := _current_bounds.z - _current_bounds.y + radius * 0.2
	_camera.size = maxf(2.85, maxf(height + 0.30, (radius * 2.0 + 0.22) / aspect))
	_camera.position = Vector3(0.44, center + 0.53, -5.8)
	_camera.look_at(Vector3(0, center, 0))


func _draw() -> void:
	if has_focus():
		draw_rect(Rect2(Vector2.ONE, size - Vector2(2, 2)), Color("e9bd72"), false, 2.0)


func _on_animation_finished(clip: StringName) -> void:
	if str(clip).begins_with("cast_"):
		champion.player.play("idle", 0.08)


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
	if is_instance_valid(champion):
		champion.player.advance(delta)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		if _dragging:
			grab_focus()
		accept_event()
	elif event is InputEventMouseMotion and _dragging:
		_stand.rotation.y += event.relative.x * 0.014
		accept_event()
	elif event is InputEventScreenDrag:
		_stand.rotation.y += event.relative.x * 0.014
		accept_event()
	elif event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_LEFT:
				_stand.rotation.y -= PI / 12
			KEY_RIGHT:
				_stand.rotation.y += PI / 12
			KEY_HOME:
				_stand.rotation.y = BASE_ANGLE
			_:
				return
		accept_event()
