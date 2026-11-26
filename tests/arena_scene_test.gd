extends SceneTree

var failed: int = 0
var checks: int = 0

func _initialize() -> void:
	call_deferred("verify_scene")


func verify(value: bool, label: String) -> void:
	checks += 1
	if not value:
		push_error(label)
		failed += 1


func verify_scene() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var arena = load("res://arena.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	await process_frame
	var hud = arena.hud
	var view = arena.view
	verify(hud.roster_buttons.size() == 16, "All classes get a roster button.")
	for class_id: String in hud.roster_buttons:
		hud.roster_buttons[class_id].pressed.emit()
		await process_frame
		await process_frame
		var kit = arena.game.CLASS_INFO[class_id]
		verify(hud.class_name_label.text == kit.name, class_id + " title")
		verify(hud.mastery_picker.item_count == 3, class_id + " two masteries plus base")
		verify(hud.selected_mastery == -1, class_id + " changing class resets mastery")
		for mastery_index in range(2):
			hud.mastery_picker.select(mastery_index + 1)
			hud.mastery_picker.item_selected.emit(mastery_index + 1)
			verify(hud.selected_mastery == mastery_index and hud.mastery_summary.text == kit.masteries[mastery_index].description, class_id + " mastery preview")
		var descriptions: Array[String] = []
		for row in hud.kit_list.get_children():
			if row is Label:
				descriptions.append(row.text)
		for ability in arena.game.loadout(class_id, 1):
			verify(descriptions.has(ability.description), class_id + " " + ability.name + " description")
		verify(hud.kit_scroll.size.y <= hud.lobby.size.y, class_id + " pane fits")
		hud.kit_scroll.scroll_vertical = 999999
		await process_frame
		var bottom_label = hud.kit_list.get_child(-1)
		var lower := float(bottom_label.global_position.y + bottom_label.size.y)
		var pane_bottom := float(hud.kit_scroll.global_position.y + hud.kit_scroll.size.y)
		verify(lower <= pane_bottom + 2, class_id + " final ability scrolls into view")
		verify(hud.start_button.get_global_rect().end.y <= hud.lobby.get_global_rect().end.y, class_id + " start within panel")
		hud.start_button.pressed.emit()
		await process_frame
		await process_frame
		verify(arena.game.fighters[0].class_id == class_id, class_id + " entered")
		verify(arena.game.fighters[0].abilities == arena.game.loadout(class_id, 1), class_id + " selected build applied")
		verify(hud.ability_buttons.size() == 8 and hud.ability_buttons[7].visible and kit.abilities[7].name in hud.ability_buttons[7].text, class_id + " kit on HUD")
		verify(view._pawns[0].class_id == class_id and view._pawns[0].rig.get_child_count() > 0, class_id + " model")
		verify(hud.combat_bar.get_global_rect().position.x >= 0 and hud.combat_bar.get_global_rect().end.x <= 1280, class_id + " bar screen fit")
		arena._lobby()
		await process_frame
		await process_frame
	verify(hud.map_picker.item_count == 5, "five arenas available")
	for index in hud.map_picker.item_count:
		hud.map_picker.select(index)
		hud.map_picker.item_selected.emit(index)
		var map_id = hud.map_picker.get_item_metadata(index)
		verify(hud.selected_map == map_id and hud.map_description.text == hud.ArenaMaps.MAPS[map_id].description, str(map_id) + " selected map details")
		hud.start_button.pressed.emit()
		await process_frame
		await process_frame
		verify(arena.game.map_id == map_id and hud.ArenaMaps.MAPS[map_id].name in hud.round_label.text, str(map_id) + " starts selected arena")
		arena.game.map_hint = "Test warning"
		arena._render()
		verify(hud.map_notice.visible and hud.map_notice.text == "Test warning", str(map_id) + " warning visible")
		arena._lobby()
		await process_frame
		await process_frame
	hud.roster_buttons["bellwarden"].pressed.emit()
	hud.start_button.pressed.emit()
	arena.game.place_field(arena.game.fighters[0], "ward", Vector2(1, 2), 3.0, 5.0, 8.0)
	arena.game.afflict(arena.game.fighters[0], "root", 1.0)
	arena._render()
	verify(view._field_rings.size() == 1 and view._field_rings[0].scale.x == 3.0, "Area is drawn at the given radius")
	verify("ROOT" in view._pawns[0].status_label.text,"Root readable on pawn")
	arena._lobby()
	arena._render()
	verify(view._field_rings.is_empty(), "Area rings clear in lobby")
	print("Arena lobby and visual-state checks: %d/%d" % [checks-failed, checks])
	quit(1 if failed else 0)
