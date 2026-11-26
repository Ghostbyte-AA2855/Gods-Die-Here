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
	arena._lobby()
	_check(arena.hud._battle_guides._casts.is_empty() and not arena.hud._cast_cards[1].visible, "Leaving clears both teams' cast cues")
	arena.queue_free()
	await process_frame
	print("Mobile battle guides: %d/%d checks passed" % [_checks - _failures, _checks])
	quit(1 if _failures else 0)


func _check(condition: bool, detail: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(detail)
