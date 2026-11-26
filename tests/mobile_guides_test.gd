extends SceneTree

const ArenaMaps = preload("res://scripts/arena_maps.gd")
const ArenaStage = preload("res://scripts/arena_stage.gd")

var _checks := 0
var _failures := 0


func _initialize() -> void:
	call_deferred("_verify")


func _verify() -> void:
	var arena = (load("res://mobile.tscn") as PackedScene).instantiate()
	arena.audio_cues.muted = true
	root.add_child(arena)
	arena.set_physics_process(false)
	for map_id: String in ArenaMaps.MAPS:
		arena.hud.selected_map = map_id
		arena._start("forgecaller")
		var game = arena.game
		var guide: Dictionary = ArenaStage.ZONE_GUIDE[ArenaMaps.MAPS[map_id].kind]
		_check(arena.hud._time_label.text == "3:00", "%s starts with a readable three-minute clock" % map_id)
		_check(arena.hud._hint.text == "%s in 6 s  ·  %s" % [guide.name, guide.effect], "%s explains the next hazard before the warning" % map_id)
		ArenaMaps.update(game, 5.0, 0.0)
		arena._render()
		_check(arena.hud._hint.text == "%s in 1 s  ·  %s" % [guide.name, guide.effect], "%s shows the exact warning countdown" % map_id)
		ArenaMaps.update(game, 6.25, 0.0)
		arena._render()
		_check(arena.hud._hint.text.begins_with(guide.name) and "s left" in arena.hud._hint.text and guide.effect in arena.hud._hint.text, "%s displays the active hazard and expiration" % map_id)
		_check(arena.hud._battle_guides.visible and arena.hud._battle_guides._zones.size() == 2, "%s sends both hazard positions into the floor guide" % map_id)

	arena.hud.selected_map = "kiln"
	arena._start("forgecaller")
	var game = arena.game
	ArenaMaps.update(game, 6.25, 0.0)
	game.fighters[0].position = game.environment_zones[0].position
	arena._render()
	_check("Taking vent damage" in arena.hud._notice.text, "Walking inside an active vent explains the damage")
	game.fighters[0].position = Vector2(-7, 0)
	game.safe_radius = 5.0
	arena._render()
	_check("Taking ring damage" in arena.hud._notice.text, "Walking outside the closing ring explains the damage")
	game.safe_radius = 14.0
	_check(game.try_mobile_ability(5), "The added Furnace Bed ability creates a real field")
	arena._render()
	arena.view._process(0.20)
	arena._render()
	_check(game.fields.size() == 1 and game.fields[0].name == "Furnace Bed", "The field is named after its originating cast")
	_check(arena.view._field_rings[0].has_node("FloorMark") and arena.hud._battle_guides._fields.size() == 1, "The field is rendered in the arena and passed to the projected guide")
	_check(arena.hud._cast_cards[0].visible and arena.hud._cast_names[0].text == "Furnace Bed", "The live release names the player's ability")
	_check(arena.hud._battle_guides._casts.has("YOU"), "The released move also gets a projected caster label")

	arena.hud.record_cast({"source_id": 4, "team": 1, "slot": 2, "target_id": 0, "affected_ids": [0], "name": "Splinter Cage"}, -1)
	arena._render()
	_check(arena.hud._cast_cards[1].visible and arena.hud._cast_names[1].text == "Splinter Cage", "A rival attack targeting the player is identified separately")
	arena._toggle_pause()
	arena._render()
	_check(not arena.hud._battle_guides.visible and not arena.hud._cast_cards[0].visible, "Pause hides the combat cues")
	_check(arena.hud._pause_options.visible, "Presentation options are reachable from pause")
	arena.hud._option_buttons.blood.button.button_pressed = false
	arena.hud._option_buttons.reduced_motion.button.button_pressed = true
	_check(not arena.view.blood_enabled and arena.view.reduced_motion, "Touch settings change the arena presentation")
	arena.hud._option_buttons.sound.button.button_pressed = true
	_check(not arena.audio_cues.muted, "The pause sound button can enable audio")
	arena.hud._option_buttons.sound.button.button_pressed = false
	_check(arena.audio_cues.muted, "The pause sound button can mute audio")
	arena._lobby()
	_check(arena.hud._battle_guides._casts.is_empty() and not arena.hud._cast_cards[1].visible, "Leaving clears both teams' cast cues")
	arena.hud.selected_map = "lockwater"
	_verify_cast_feedback(arena)
	_verify_input_buffer(arena)
	arena.queue_free()
	await process_frame
	print("Mobile battle guides: %d/%d checks passed" % [_checks - _failures, _checks])
	quit(1 if _failures else 0)


func _verify_cast_feedback(arena) -> void:
	arena._start("breakwater")
	var game = arena.game
	var player: Dictionary = game.fighters[0]
	var rival: Dictionary = game.fighters[3]
	player.position = Vector2(-1, 0)
	rival.position = Vector2(5, 0)
	arena.selected_target = 3
	arena._cast_mobile(0)
	_check("Move closer" in arena.feedback, "An out-of-range target gives actionable feedback")
	rival.position = Vector2(1, 0)
	game.terrain[0].position = Vector2.ZERO
	arena._cast_mobile(0)
	_check("behind cover" in arena.feedback, "A blocked target is distinguished from an out-of-range target")
	game.terrain[0].position = Vector2(-7, 0)
	game.afflict(player, "silence", 1.0)
	arena._cast_mobile(4)
	_check("Silenced" in arena.feedback, "A silenced ability has a specific reason")
	arena._cast_mobile(0)
	_check(game.last_cast_failure.is_empty() and not game.cast_events.is_empty(), "A basic attack is still accepted during silence")


func _verify_input_buffer(arena) -> void:
	arena._start("breakwater")
	var game = arena.game
	var player: Dictionary = game.fighters[0]
	var brace_slot: int = arena.mobile_slots[4]
	for fighter in game.fighters.slice(1):
		fighter.stun = 5.0
		fighter.break_free_available = false
	player.cooldowns[brace_slot] = 0.12
	var initial_meter: float = player.meter
	arena._cast_mobile(4)
	_check(arena._queued_button == 4 and game.cast_events.is_empty() and player.meter == initial_meter, "An early tap queues neither a cast event nor resource spend")
	arena._physics_process(0.06)
	_check(arena._queued_button == 4 and game.cast_events.is_empty(), "The queue waits while a cooldown is still active")
	arena._physics_process(0.075)
	_check(arena._queued_button == -1 and game.cast_events.size() == 1 and game.cast_events.back().name == "Brace", "The buffered ability fires once when its cooldown clears")
	arena._physics_process(0.025)
	_check(game.cast_events.size() == 1, "A consumed buffer cannot recast")

	player.cooldowns[brace_slot] = 0.35
	arena._cast_mobile(4)
	_check(arena._queued_button == -1 and "ready in" in arena.feedback, "Taps well before readiness are rejected with remaining cooldown")
	player.cooldowns[brace_slot] = 0.12
	arena._cast_mobile(4)
	arena.selected_target = 3
	arena._physics_process(0.15)
	_check(arena._queued_button == -1 and game.cast_events.size() == 1, "Changing the target lock cancels a queued cast")
	player.cooldowns[brace_slot] = 0.12
	arena._cast_mobile(4)
	arena._toggle_pause()
	_check(arena._queued_button == -1, "Pausing clears any queued ability")
	arena._continue_or_advance()
	arena._physics_process(0.15)
	_check(game.cast_events.size() == 1, "Resuming does not fire a queued pre-pause tap")

	player.cooldowns[brace_slot] = 0.219
	arena._cast_mobile(4)
	for step in 14:
		arena._physics_process(1.0 / 60.0)
	_check(game.cast_events.size() == 2, "The final physics tick accepts a tap just inside the buffer window")

	player.cooldowns[brace_slot] = 0.12
	arena._cast_mobile(4)
	player.cooldowns[brace_slot] = 1.0
	arena._physics_process(0.25)
	_check(arena._queued_button == -1 and game.cast_events.size() == 2, "A delayed cooldown cannot leave an expired cast queued")


func _check(condition: bool, detail: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(detail)
