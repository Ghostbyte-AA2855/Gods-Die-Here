extends Node3D

const ArenaMatch = preload("res://scripts/arena_match.gd")
const ArenaView = preload("res://scripts/arena_view.gd")
const ArenaHud = preload("res://scripts/arena_hud.gd")
const MobileHud = preload("res://scripts/mobile_hud.gd")
const MobileKits = preload("res://scripts/mobile_kits.gd")
const MobileTouch = preload("res://scripts/mobile_touch.gd")
const ABILITY_KEYS = [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8]
const BASIC_RETRY_SECONDS := 0.12

@export var mobile_mode: bool = false

var audio_cues := preload("res://scripts/arena_audio.gd").new()
var game = ArenaMatch.new()
var view = ArenaView.new()
var hud: CanvasLayer
var touch: Control
var selected_target: int = -1
var selected_class: String = "breakwater"
var leave_prompt: bool = false
var feedback: String = ""
var feedback_time: float = 0.0
var last_seen_cast: int = 0
var mobile_slots: Array[int] = []
var attack_retry: float = 0.0


func _ready() -> void:
	game.mobile_mode = mobile_mode
	hud = MobileHud.new() if mobile_mode else ArenaHud.new()
	add_child(audio_cues)
	add_child(view)
	view.champion_fell.connect(audio_cues.elimination)
	add_child(hud)
	hud.class_chosen.connect(_start)
	hud.advance_pressed.connect(_continue_or_advance)
	hud.lobby_pressed.connect(_lobby)
	if mobile_mode:
		hud.pause_pressed.connect(_toggle_pause)
		touch = MobileTouch.new()
		hud.add_child(touch)
		touch.ability_pressed.connect(_cast_mobile)
		touch.dodge_pressed.connect(_dodge_mobile)
		touch.target_tapped.connect(_touch_target)
	_render()


func _physics_process(delta: float) -> void:
	if game.phase != "active" or leave_prompt:
		return
	var movement := _movement()
	var actor: Dictionary = game.fighters[0]
	var aim: Vector2
	if mobile_mode:
		aim = _mobile_aim(actor)
		attack_retry = maxf(attack_retry - delta, 0.0)
	else:
		var mouse_world: Vector2 = view.mouse_world_position(get_viewport().get_mouse_position())
		aim = mouse_world - actor.position
	game.step(delta, movement, aim.normalized() if aim.length_squared() > 0.03 else Vector2.ZERO)
	if selected_target >= 0 and not game.fighters[selected_target].alive:
		selected_target = -1
	if mobile_mode and game.phase == "active" and actor.alive and touch.attack_held and attack_retry == 0.0 and actor.cooldowns[0] <= 0.0:
		attack_retry = BASIC_RETRY_SECONDS
		_cast(0, true)
	feedback_time = maxf(feedback_time - delta, 0.0)


func _process(_delta: float) -> void:
	_render()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if game.phase == "active" and not leave_prompt:
			if not mobile_mode or event.device != InputEvent.DEVICE_ID_EMULATION:
				selected_target = view.pick_target(event.position, game.fighters, 56.0 if mobile_mode else 36.0)
		return
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var key: int = event.physical_keycode if event.physical_keycode else event.keycode
	if key == KEY_G:
		view.blood_enabled = not view.blood_enabled
		_set_feedback("Blood effects on" if view.blood_enabled else "Blood effects off")
		return
	if key == KEY_M:
		audio_cues.toggle()
		_set_feedback("Sound off" if audio_cues.muted else "Sound on")
		return
	if key == KEY_ESCAPE:
		if mobile_mode and game.phase == "active":
			_toggle_pause()
			return
		if leave_prompt or game.phase in ["round_over", "match_over"]:
			_lobby()
		elif game.phase == "active":
			leave_prompt = true
		return
	if key == KEY_ENTER or key == KEY_KP_ENTER:
		_continue_or_advance()
		return
	if game.phase != "active" or leave_prompt:
		return
	if key == KEY_TAB:
		_cycle_target()
	elif mobile_mode and key == KEY_SPACE:
		_dodge_mobile()
	elif key == KEY_R and not mobile_mode:
		if game.try_break_free():
			view.flash_ability(0, -2, -1)
			_set_feedback("Break Free used")
		elif not game.fighters[0].break_free_available:
			_set_feedback("Break Free already used this round")
		else:
			_set_feedback("Break Free is available during stun, root, or silence")
	elif key == KEY_SPACE:
		var movement := _movement()
		if game.try_dodge(movement):
			view.flash_ability(0, -1, -1)
		else:
			_set_feedback("Dodge unavailable")
	else:
		var slot: int = ABILITY_KEYS.find(key)
		if mobile_mode:
			_cast_mobile(slot)
		elif slot >= 0:
			_cast(slot)


func _movement() -> Vector2:
	if touch != null and touch.direction != Vector2.ZERO:
		return view.movement_vector(touch.direction)
	var input := Vector2(
		float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
		float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
	)
	return view.movement_vector(input.limit_length())


func _mobile_aim(fighter: Dictionary) -> Vector2:
	if selected_target >= 0:
		var focused: Dictionary = game.fighters[selected_target]
		if focused.alive and focused.team != fighter.team:
			return focused.position - fighter.position
	# Use the same line-of-sight test as a targeted cast.
	var enemy: Dictionary = game._target(fighter, -1, false, 48.0)
	if not enemy.is_empty():
		return enemy.position - fighter.position
	return _movement()


func _touch_target(at: Vector2) -> void:
	if game.phase == "active" and not leave_prompt and game.fighters[0].alive:
		selected_target = view.pick_target(at, game.fighters, 56.0)


func _cast_mobile(button: int) -> void:
	if game.phase != "active" or leave_prompt or button < 0 or button >= mobile_slots.size():
		return
	if button == 0:
		attack_retry = BASIC_RETRY_SECONDS
	var fighter: Dictionary = game.fighters[0]
	var aim := _mobile_aim(fighter)
	if aim.length_squared() > 0.03:
		fighter.facing = aim.normalized()
	_cast(mobile_slots[button])


func _dodge_mobile() -> void:
	if game.phase != "active" or leave_prompt:
		return
	if game.try_break_free():
		view.flash_ability(0, -2, -1)
		_set_feedback("Break Free used")
	elif game.try_dodge(_movement()):
		view.flash_ability(0, -1, -1)
	else:
		_set_feedback("Dodge unavailable")


func _toggle_pause() -> void:
	if game.phase != "active":
		return
	leave_prompt = not leave_prompt
	touch.set_active(not leave_prompt and game.fighters[0].alive)


func _notification(what: int) -> void:
	if mobile_mode and touch != null and (what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT):
		if game.phase == "active" and not leave_prompt:
			_toggle_pause()


func _cast(slot: int, quiet: bool = false) -> void:
	var fighter: Dictionary = game.fighters[0]
	var ability: Dictionary = fighter.abilities[slot]
	var target := -1
	if selected_target >= 0:
		var target_side := "ally" if game.fighters[selected_target].team == fighter.team else "enemy"
		if ability.get("target") == target_side:
			target = selected_target
	if game.try_ability(slot, target):
		feedback_time = 0.0
		return
	if quiet:
		return
	if not fighter.alive:
		_set_feedback("Eliminated · spectating")
	elif fighter.cooldowns[slot] > 0:
		_set_feedback("Ability on cooldown")
	elif fighter.meter < ability.cost:
		_set_feedback("Need %d %s" % [ability.cost, ArenaMatch.CLASS_INFO[fighter.class_id].resource])
	elif slot != 0 and game.has_status(fighter, "silence"):
		_set_feedback("Silenced · basic attack available")
	elif fighter.get("stun", 0.0) > 0.0:
		_set_feedback("You are briefly disabled")
	elif fighter.get("mend_time", 0.0) > 0.0:
		_set_feedback("Finishing Mend the Break")
	else:
		_set_feedback("Check target, range, cover, or ability setup")


func _set_feedback(message: String) -> void:
	feedback = message
	feedback_time = 2.0


func _cycle_target() -> void:
	var enemies: Array[int] = []
	for fighter in game.fighters:
		if fighter.team == 1 and fighter.alive:
			enemies.append(fighter.id)
	if not enemies.is_empty():
		selected_target = enemies[(enemies.find(selected_target) + 1) % enemies.size()]


func _start(class_id: String) -> void:
	selected_class = class_id
	selected_target = -1
	feedback_time = 0.0
	leave_prompt = false
	if mobile_mode:
		mobile_slots = MobileKits.slots(class_id)
		attack_retry = 0.0
		touch.reset()
	game.start_match(class_id, -1, hud.selected_mastery, hud.selected_map)
	_render()


func _advance() -> void:
	if game.phase == "round_over":
		selected_target = -1
		feedback_time = 0.0
		game.next_round()
		_render()
	elif game.phase == "match_over":
		_start(selected_class)


func _continue_or_advance() -> void:
	if leave_prompt:
		leave_prompt = false
		_render()
	else:
		_advance()


func _lobby() -> void:
	game = ArenaMatch.new()
	game.mobile_mode = mobile_mode
	last_seen_cast = 0
	selected_target = -1
	leave_prompt = false
	feedback_time = 0.0
	_render()


func _render() -> void:
	if mobile_mode:
		view.visible = game.phase != "idle"
		var playing: bool = game.phase == "active" and not leave_prompt and game.fighters[0].alive
		touch.set_active(playing)
		if playing:
			var player: Dictionary = game.fighters[0]
			touch.update_fighter(player, mobile_slots, ArenaMatch.CLASS_INFO[player.class_id].resource)
	if game.phase == "idle" and (game.terrain.is_empty() or game.map_id != hud.selected_map):
		game.map_id = hud.selected_map
		game.ArenaMaps.prepare(game)
	view.set_stage(game.map_id, game.terrain, game.environment_zones)
	view.set_state(game.fighters, game.safe_radius, selected_target, game.phase, game.fields)
	if not game.cast_events.is_empty() and game.cast_events.back().seq > last_seen_cast:
		for event in game.cast_events:
			if event.seq > last_seen_cast:
				view.play_cast(event)
				audio_cues.cast(event)
				last_seen_cast = event.seq
	audio_cues.environment(game.map_id, game.environment_zones, game.phase == "active")
	hud.update_match(game, selected_target, leave_prompt, feedback if feedback_time > 0.0 else "")
