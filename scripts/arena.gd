extends Node3D

const ArenaMatch = preload("res://scripts/arena_match.gd")
const ArenaView = preload("res://scripts/arena_view.gd")
const ArenaHud = preload("res://scripts/arena_hud.gd")
const ABILITY_KEYS = [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8]

var audio_cues := preload("res://scripts/arena_audio.gd").new()
var game = ArenaMatch.new()
var view = ArenaView.new()
var hud = ArenaHud.new()
var selected_target: int = -1
var selected_class: String = "breakwater"
var leave_prompt: bool = false
var feedback: String = ""
var feedback_time: float = 0.0
var last_seen_cast: int = 0


func _ready() -> void:
	add_child(audio_cues)
	add_child(view)
	view.champion_fell.connect(audio_cues.elimination)
	add_child(hud)
	hud.class_chosen.connect(_start)
	hud.advance_pressed.connect(_continue_or_advance)
	hud.lobby_pressed.connect(_lobby)
	_render()


func _physics_process(delta: float) -> void:
	if game.phase != "active" or leave_prompt:
		return
	var movement := _movement()
	var actor: Dictionary = game.fighters[0]
	var mouse_world: Vector2 = view.mouse_world_position(get_viewport().get_mouse_position())
	var aim: Vector2 = mouse_world - actor.position
	game.step(delta, movement, aim.normalized() if aim.length_squared() > 0.03 else Vector2.ZERO)
	if selected_target >= 0 and not game.fighters[selected_target].alive:
		selected_target = -1
	feedback_time = maxf(feedback_time - delta, 0.0)


func _process(_delta: float) -> void:
	_render()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if game.phase == "active" and not leave_prompt:
			selected_target = view.pick_target(event.position, game.fighters)
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
	elif key == KEY_R:
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
		if slot >= 0:
			_cast(slot)


func _movement() -> Vector2:
	var input := Vector2(
		float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
		float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
	)
	return view.movement_vector(input.limit_length())


func _cast(slot: int) -> void:
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
	game.start_match(class_id, -1, hud.selected_mastery, hud.selected_map)


func _advance() -> void:
	if game.phase == "round_over":
		selected_target = -1
		feedback_time = 0.0
		game.next_round()
	elif game.phase == "match_over":
		_start(selected_class)


func _continue_or_advance() -> void:
	if leave_prompt:
		leave_prompt = false
	else:
		_advance()


func _lobby() -> void:
	game = ArenaMatch.new()
	last_seen_cast = 0
	selected_target = -1
	leave_prompt = false
	feedback_time = 0.0


func _render() -> void:
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
