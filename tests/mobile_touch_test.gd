extends SceneTree

const MobileKits = preload("res://scripts/mobile_kits.gd")
const MobileTouch = preload("res://scripts/mobile_touch.gd")
const TICK := 1.0 / 60.0

var checks := 0
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	var mobile_scene := load("res://mobile.tscn") as PackedScene
	if mobile_scene == null:
		push_error("The mobile scene must load")
		quit(1)
		return
	var arena = mobile_scene.instantiate()
	arena.audio_cues.muted = true
	root.add_child(arena)
	arena.set_physics_process(false)
	await process_frame
	await process_frame
	if arena.touch == null:
		push_error("The mobile scene must initialize its controls")
		quit(1)
		return
	_check(arena.game.mobile_mode and arena.game.phase == "idle" and not arena.touch.visible, "The mobile entry opens in the hall with combat controls hidden")
	_check(arena.hud.roster_buttons.size() == 16 and arena.hud.map_buttons.size() == 5, "The hall offers all sixteen classes and five arenas")
	_check(root.get_visible_rect().encloses(arena.hud.start_button.get_global_rect()), "The arena entry fits on a conventional landscape display")
	arena.hud.roster_buttons["breakwater"].pressed.emit()
	arena.hud.start_button.pressed.emit()
	arena._render()
	_check(arena.game.phase == "active" and arena.touch.visible, "A class selection puts the mobile controls in play")
	_check_dimensions(arena.touch)
	_prepare_fighters(arena)
	_check_targeting(arena)
	_check_multitouch(arena)
	_check_added_abilities(arena)
	_check_reset(arena)

	var initial_viewport := root.get_visible_rect().size
	root.size = Vector2i(1600, 740)
	await process_frame
	await process_frame
	_check_dimensions(arena.touch)
	var touch_surface := root.get_visible_rect().size
	_check(touch_surface.x > initial_viewport.x, "A wider landscape window expands the gameplay viewport")
	var stick := Vector2(123, touch_surface.y - 109.0)
	var attack := _button_position(0)
	_press(0, stick)
	_drag(0, stick + Vector2(68, 0))
	_press(1, attack)
	_check(arena.touch.direction.x > 0.9 and arena.touch.attack_held, "Both thumb zones still accept touch after a landscape resize")
	arena.hud.lobby_pressed.emit()
	arena._render()
	_check(arena.game.mobile_mode and arena.game.phase == "idle" and not arena.touch.visible, "Returning to the hall preserves mobile rules and hides the controls")
	_check(arena.touch.direction.is_zero_approx() and not arena.touch.attack_held, "Returning to the hall clears both fingers")
	_check(root.get_visible_rect().encloses(arena.hud.start_button.get_global_rect()), "The arena entry fits after widening the landscape display")
	arena.queue_free()
	await process_frame
	print("Mobile touch: %d/%d checks passed" % [checks - failures, checks])
	quit(1 if failures else 0)


func _check_dimensions(touch: Control) -> void:
	var viewport_rect := root.get_visible_rect()
	_check(viewport_rect.size.x > viewport_rect.size.y, "The gameplay viewport is landscape")
	_check(touch.get_global_rect().is_equal_approx(viewport_rect), "The combat controls cover the full landscape viewport")
	var stick := Vector2(123, viewport_rect.size.y - 109.0)
	var attack := _button_position(0)
	_check(viewport_rect.has_point(stick) and viewport_rect.has_point(attack) and stick.distance_to(attack) > viewport_rect.size.x * 0.6,
		"The movement and action thumb zones remain inside opposite edges")
	_check(MobileTouch.OFFSETS.size() == 7 and MobileTouch.DODGE_BUTTON == 6, "Six combat actions preserve a distinct Dodge slot")
	var fit := true
	var separate := true
	for button in MobileTouch.OFFSETS.size():
		var center := _button_position(button)
		var radius: float = MobileTouch.RADII[button] + MobileTouch.HIT_PADDING
		fit = fit and viewport_rect.encloses(Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2.0))
		for other in range(button + 1, MobileTouch.OFFSETS.size()):
			var minimum: float = radius + MobileTouch.RADII[other] + MobileTouch.HIT_PADDING
			separate = separate and center.distance_to(_button_position(other)) > minimum
	_check(fit, "Every tappable combat circle fits in the landscape viewport")
	_check(separate, "Combat button hit areas do not overlap")


func _prepare_fighters(arena) -> void:
	var positions := [Vector2(-1.5, 0), Vector2(-2.6, 0.8), Vector2(-4, -2), Vector2(0, 0), Vector2(0.9, 1), Vector2(0, 3.3)]
	for fighter in arena.game.fighters:
		fighter.position = positions[fighter.id]
		fighter.stun = 0.0 if fighter.id == 0 else 20.0
		fighter.break_free_available = false
	arena._render()


func _check_targeting(arena) -> void:
	var target := _target_point(arena, 4)
	_press(1, target)
	_check(arena.selected_target == -1, "Touching a fighter does not select it until the tap completes")
	_drag(1, target + Vector2(40, 0))
	_release(1, target)
	_check(arena.selected_target == -1, "Dragging on the field cannot accidentally select a fighter")
	_press(1, target)
	_release(1, target, true)
	_check(arena.selected_target == -1, "A canceled field tap cannot select a fighter")
	_press(1, target)
	_release(1, target)
	_check(arena.selected_target == 4, "A clean field tap selects the fighter under the finger")
	var between_controls := _button_position(1).lerp(_button_position(5), 0.5)
	_press(1, between_controls)
	_release(1, between_controls)
	_check(arena.selected_target == 4 and arena.game.cast_events.is_empty(), "A near miss in the thumb cluster neither casts nor clears the field target")


func _check_multitouch(arena) -> void:
	var touch_surface := root.get_visible_rect().size
	var stick := Vector2(123, touch_surface.y - 109.0)
	var basic := _button_position(0)
	var skill := _button_position(1)
	var dodge := _button_position(MobileTouch.DODGE_BUTTON)
	var player: Dictionary = arena.game.fighters[0]
	_press(0, stick)
	_drag(0, stick + Vector2(68, 0))
	var before_movement: Vector2 = player.position
	arena._physics_process(TICK)
	_check(arena.touch.direction.x > 0.9 and player.position.x > before_movement.x, "The first finger moves the real player through a simulation tick")

	_press(1, basic)
	_check(arena.touch.attack_held and arena.touch.direction.x > 0.9, "Holding attack with another finger preserves the movement direction")
	_check(arena.game.cast_events.size() == 1 and arena.game.cast_events[-1].slot == 0 and arena.game.cast_events[-1].target_id == 4,
		"The attack touch casts the basic attack against the chosen rival")
	player.cooldowns[0] = 0.0
	before_movement = player.position
	arena._physics_process(0.15)
	_check(arena.game.cast_events.size() == 2 and player.position.x > before_movement.x, "Holding attack repeats when available while the other finger still moves")

	_release(99, basic)
	_check(arena.touch.attack_held and arena.touch.direction.x > 0.9, "Releasing an unowned finger changes neither action nor movement")
	_release(1, _target_point(arena, 3))
	_check(not arena.touch.attack_held and arena.touch.direction.x > 0.9 and arena.selected_target == 4,
		"Releasing the attack finger over another fighter ends only the attack")

	_press(1, skill)
	var slot: int = MobileKits.slots("breakwater")[1]
	_check(arena.game.cast_events.size() == 3 and arena.game.cast_events[-1].slot == slot and arena.game.cast_events[-1].target_id == 1 and arena.selected_target == 4,
		"A second finger can cast an ally ability without changing the selected enemy")
	_release(1, skill)
	before_movement = player.position
	_press(1, dodge)
	_check(player.dodge_cooldown > 0.0 and player.position.x - before_movement.x > 1.0 and arena.touch.direction.x > 0.9,
		"Dodge follows the active joystick direction while both fingers are down")
	_release(1, dodge)
	player.stun = 0.6
	player.break_free_available = true
	var cooldown: float = player.dodge_cooldown
	_press(1, dodge)
	_check(player.stun == 0.0 and not player.break_free_available and player.dodge_cooldown == cooldown,
		"The dodge button uses Break Free while controlled, even during the dodge cooldown")
	_check(arena.touch._cue_until[MobileTouch.DODGE_BUTTON] > Time.get_ticks_msec(), "A successful Break Free pulses the Dodge control")
	_release(1, dodge)
	_release(0, stick + Vector2(68, 0), true)
	_check(arena.touch.direction.is_zero_approx(), "Canceling the movement finger releases the joystick")


func _check_added_abilities(arena) -> void:
	var player: Dictionary = arena.game.fighters[0]
	var slots := MobileKits.slots("breakwater")
	var cast_count: int = arena.game.cast_events.size()
	player.meter = 100.0
	var stick := Vector2(123, root.get_visible_rect().size.y - 109.0)
	_press(0, stick)
	_drag(0, stick + Vector2(68, 0))
	var fourth := _button_position(4)
	_press(1, fourth)
	_press(2, fourth)
	_release(2, fourth)
	_release(1, fourth)
	_check(arena.game.cast_events.size() == cast_count + 1 and arena.game.cast_events[-1].slot == slots[4] and player.brace > 0.0,
		"The fourth ability casts Brace once even if fingers arrive on the same button")
	var fifth := _button_position(5)
	_press(1, fifth)
	_release(1, fifth)
	_check(arena.game.cast_events.size() == cast_count + 2 and arena.game.cast_events[-1].slot == slots[5] and arena.game.fields[-1].kind == "ward",
		"The fifth ability casts Holdfast and places the ward in the running match")
	_check(arena.touch.direction.x > 0.9 and arena.selected_target == 4 and not arena.touch.attack_held,
		"Both added spells keep movement and targeting independent")
	_release(0, stick + Vector2(68, 0))
	player.cooldowns[slots[4]] = 0.0
	_mouse_tap(fourth)
	_check(arena.game.cast_events.size() == cast_count + 3 and arena.game.cast_events[-1].slot == slots[4],
		"The added button also works through the mouse fallback")


func _check_reset(arena) -> void:
	var touch_surface := root.get_visible_rect().size
	var stick := Vector2(123, touch_surface.y - 109.0)
	var basic := _button_position(0)
	_press(0, stick)
	_drag(0, stick + Vector2(68, 0))
	_press(1, basic)
	arena.hud.pause_pressed.emit()
	arena._render()
	_check(not arena.touch.visible and arena.touch.direction.is_zero_approx() and not arena.touch.attack_held,
		"Opening the pause overlay releases both combat fingers")
	arena.hud.advance_pressed.emit()
	arena._render()
	_drag(0, stick + Vector2(68, 0))
	_release(1, basic)
	_check(arena.touch.visible and arena.touch.direction.is_zero_approx() and not arena.touch.attack_held,
		"Resuming requires a fresh touch rather than reusing paused fingers")
	_press(0, stick)
	_drag(0, stick + Vector2(68, 0))
	_press(1, basic)
	arena.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_check(arena.leave_prompt and arena.touch.direction.is_zero_approx() and not arena.touch.attack_held, "Losing app focus pauses the match and releases both combat fingers")
	arena.hud.advance_pressed.emit()


func _target_point(arena, id: int) -> Vector2:
	var position: Vector2 = arena.game.fighters[id].position
	var camera := root.get_camera_3d()
	return camera.unproject_position(Vector3(position.x, 1.26, position.y))


func _button_position(button: int) -> Vector2:
	return root.get_visible_rect().size - MobileTouch.OFFSETS[button]


func _mouse_tap(at: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = at
		event.global_position = at
		event.pressed = pressed
		root.push_input(event, true)


func _press(index: int, at: Vector2) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = at
	event.pressed = true
	root.push_input(event, true)


func _release(index: int, at: Vector2, canceled := false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = at
	event.pressed = false
	event.canceled = canceled
	root.push_input(event, true)


func _drag(index: int, at: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = at
	root.push_input(event, true)


func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)
