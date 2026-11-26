extends CanvasLayer

signal class_chosen(class_id: String)
signal advance_pressed
signal lobby_pressed

const Pantheon = preload("res://scripts/pantheon.gd")
const ArenaMatch = preload("res://scripts/arena_match.gd")
const ArenaMaps = preload("res://scripts/arena_maps.gd")
const TEXT = Color("#f1ebdc")
const MUTED = Color("#b6c6bb")
const GOLD = Color("#e9bd72")
const ALLY = Color("#9ae0ca")
const FOE = Color("#f6ac83")
const PANEL = Color("#1d1623f5")

var root: Control
var lobby: PanelContainer
var scoreboard: PanelContainer
var combat_bar: PanelContainer
var result: PanelContainer
var round_label: Label
var score_label: Label
var time_label: Label
var health_label: Label
var target_label: Label
var notice_label: Label
var feed_label: Label
var ability_buttons: Array[Button] = []
var roster_buttons: Dictionary = {}
var preview_class: String = "breakwater"
var class_name_label: Label
var role_label: Label
var selected_mastery: int = -1
var selected_map: String = "lockwater"
var map_picker: OptionButton
var map_description: Label
var map_notice: Label
var mastery_picker: OptionButton
var mastery_summary: Label
var kit_scroll: ScrollContainer
var kit_list: VBoxContainer
var start_button: Button
var resource_label: Label
var result_title: Label
var result_details: Label
var result_action: Button


func _ready() -> void:
	root = Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_lobby()
	_build_scoreboard()
	_build_combat_bar()
	_build_result()


func _build_lobby() -> void:
	lobby = _panel(Vector4(0.03, 0.035, 0.93, 0.965), Vector4.ZERO)
	var page := _column(lobby, 9)
	var header := HBoxContainer.new()
	page.add_child(header)
	var title := _label("Gods Die Here", 31, TEXT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_theme_constant_override("separation", 16)
	header.add_child(_label("Arena", 16, MUTED))
	map_picker = _selector()
	for map_id: String in ArenaMaps.MAPS:
		map_picker.add_item(ArenaMaps.MAPS[map_id].name)
		map_picker.set_item_metadata(map_picker.item_count - 1, map_id)
		if map_id == selected_map:
			map_picker.select(map_picker.item_count - 1)
	map_picker.item_selected.connect(_map_changed)
	header.add_child(map_picker)
	header.add_child(_label("3v3 practice  /  First to three", 16, GOLD))
	map_description = _wrapped_label(ArenaMaps.MAPS[selected_map].description, 15, MUTED)
	page.add_child(map_description)
	page.add_child(HSeparator.new())

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 22)
	page.add_child(body)
	var roster := _column(body, 8)
	roster.custom_minimum_size.x = 324
	roster.add_child(_label("Choose your class", 20, GOLD))
	var roster_scroll := _scroll(roster)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	roster_scroll.add_child(grid)
	var class_ids: Array = ArenaMatch.CLASS_INFO.keys()
	class_ids.sort()
	var group := ButtonGroup.new()
	for class_id: String in class_ids:
		var kit: Dictionary = ArenaMatch.CLASS_INFO[class_id]
		var button := _button(kit.name)
		button.focus_mode = Control.FOCUS_ALL
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.toggle_mode = true
		button.button_group = group
		button.pressed.connect(_preview.bind(class_id))
		grid.add_child(button)
		roster_buttons[class_id] = button

	var details := _column(body, 5)
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	class_name_label = _label("", 28, TEXT)
	role_label = _label("", 16, GOLD)
	details.add_child(class_name_label)
	details.add_child(role_label)
	var mastery_row := HBoxContainer.new()
	mastery_row.add_theme_constant_override("separation", 12)
	details.add_child(mastery_row)
	mastery_row.add_child(_label("Mastery", 16, MUTED))
	mastery_picker = _selector()
	mastery_picker.item_selected.connect(_mastery_changed)
	mastery_row.add_child(mastery_picker)
	mastery_summary = _wrapped_label("", 15, TEXT)
	details.add_child(mastery_summary)
	kit_scroll = _scroll(details)
	kit_list = _column(kit_scroll, 7)
	kit_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_child(HSeparator.new())
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 16)
	page.add_child(footer)
	var controls := _wrapped_label("WASD move  ·  mouse aim  ·  click select  ·  Tab cycle enemies  ·  G blood · M sound on/off\n1–8 abilities  ·  Space dodge  ·  R break stun, root or silence  ·  Esc pause", 15, MUTED)
	controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(controls)
	start_button = _button("Enter arena")
	start_button.focus_mode = Control.FOCUS_ALL
	start_button.custom_minimum_size.x = 200
	start_button.pressed.connect(func(): class_chosen.emit(preview_class))
	footer.add_child(start_button)
	_preview(preview_class)


func _map_changed(index: int) -> void:
	selected_map = str(map_picker.get_item_metadata(index))
	map_description.text = ArenaMaps.MAPS[selected_map].description


func _preview(class_id: String) -> void:
	if preview_class != class_id:
		selected_mastery = -1
	preview_class = class_id
	var kit: Dictionary = ArenaMatch.CLASS_INFO[class_id]
	roster_buttons[class_id].set_pressed_no_signal(true)
	class_name_label.text = kit.name
	role_label.text = "%s  /  %s" % [kit.role, kit.resource]
	mastery_picker.clear()
	mastery_picker.add_item("Standard")
	for mastery: Dictionary in kit.masteries:
		mastery_picker.add_item(mastery.name)
	mastery_picker.select(selected_mastery + 1)
	_refresh_kit_details()
	start_button.text = "Play %s" % kit.name


func _mastery_changed(index: int) -> void:
	selected_mastery = index - 1
	_refresh_kit_details()


func _refresh_kit_details() -> void:
	var kit: Dictionary = ArenaMatch.CLASS_INFO[preview_class]
	mastery_summary.text = "Use the base class kit." if selected_mastery < 0 else str(kit.masteries[selected_mastery].description)
	for child in kit_list.get_children():
		kit_list.remove_child(child)
		child.queue_free()
	var patron: Array = Pantheon.GODS[preview_class]
	kit_list.add_child(_wrapped_label("%s   /   %s" % [patron[2], patron[1]], 18, GOLD))
	kit_list.add_child(_wrapped_label("Sworn to %s" % patron[0], 16, TEXT))
	kit_list.add_child(_wrapped_label(patron[3], 15, TEXT))
	kit_list.add_child(_wrapped_label(patron[4], 15, MUTED))
	kit_list.add_child(_wrapped_label("Passive  ·  %s" % kit.get("passive", ""), 16, ALLY))
	kit_list.add_child(_wrapped_label("Counterplay  ·  %s" % kit.get("counterplay", ""), 15, MUTED))
	kit_list.add_child(HSeparator.new())
	var abilities: Array = ArenaMatch.loadout(preview_class, selected_mastery)
	for slot in abilities.size():
		var ability: Dictionary = abilities[slot]
		var cost := int(ability.get("cost", 0))
		var gain := int(ability.get("gain", 0))
		var price := ""
		if cost > 0:
			price = "   ·   Spend %d %s" % [cost, kit.get("resource", "")]
		if gain > 0:
			price += "   ·   Gain %d %s" % [gain, kit.get("resource", "")]
		kit_list.add_child(_wrapped_label("%d   %s   ·   %ss%s" % [slot + 1, ability.name, str(ability.cooldown), price], 16, GOLD))
		kit_list.add_child(_wrapped_label(ability.description, 15, TEXT))
	kit_scroll.scroll_vertical = 0


func _scroll(parent: Control) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	parent.add_child(scroll)
	return scroll


func _wrapped_label(title: String, size: int, color: Color) -> Label:
	var label := _label(title, size, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _build_scoreboard() -> void:
	scoreboard = _panel(Vector4(0.5, 0, 0.5, 0), Vector4(-206, 18, 206, 0))
	var column := _column(scoreboard, 3)
	round_label = _label("", 14, MUTED, true)
	score_label = _label("", 20, TEXT, true)
	time_label = _label("", 17, GOLD, true)
	column.add_child(round_label)
	column.add_child(score_label)
	column.add_child(time_label)
	map_notice = _wrapped_label("", 17, GOLD)
	map_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(map_notice)
	feed_label = _label("", 15, TEXT)
	feed_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feed_label.add_theme_color_override("font_shadow_color", Color("#101c18"))
	feed_label.add_theme_constant_override("shadow_outline_size", 5)
	root.add_child(feed_label)
	_place(feed_label, Vector4(1, 0, 1, 0), Vector4(-282, 28, -23, 105))


func _build_combat_bar() -> void:
	combat_bar = _panel(Vector4(0.5, 1, 0.5, 1), Vector4(-587, -130, 587, -15))
	var column := _column(combat_bar, 7)
	var status := HBoxContainer.new()
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(status)
	health_label = _label("", 17, ALLY)
	health_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	target_label = _label("", 16, FOE)
	target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status.add_child(health_label)
	resource_label = _label("", 16, GOLD, true)
	resource_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.add_child(resource_label)
	target_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.add_child(target_label)
	var abilities := HBoxContainer.new()
	abilities.mouse_filter = Control.MOUSE_FILTER_IGNORE
	abilities.add_theme_constant_override("separation", 8)
	column.add_child(abilities)
	for slot in range(8):
		var button := _button("")
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size.y = 48
		button.add_theme_font_size_override("font_size", 14)
		# The bar shows keyboard bindings. Clicking through selects a fighter in
		# the arena when it is not covered by a modal.
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ability_buttons.append(button)
		abilities.add_child(button)
	notice_label = _label("", 14, MUTED, true)
	column.add_child(notice_label)


func _build_result() -> void:
	result = _panel(Vector4(0.5, 0.5, 0.5, 0.5), Vector4(-216, -114, 216, 0))
	var column := _column(result, 10)
	result_title = _label("", 33, TEXT, true)
	result_details = _label("", 17, MUTED, true)
	column.add_child(result_title)
	column.add_child(result_details)
	result_action = _button("")
	result_action.pressed.connect(func(): advance_pressed.emit())
	column.add_child(result_action)
	var leave := _button("Return to class select  /  Esc")
	leave.pressed.connect(func(): lobby_pressed.emit())
	column.add_child(leave)


func update_match(game: ArenaMatch, target: int, quit_prompt: bool, feedback: String) -> void:
	if not is_instance_valid(root):
		return
	var has_game: bool = game.phase != "idle"
	lobby.visible = not has_game
	scoreboard.visible = has_game
	feed_label.visible = has_game
	combat_bar.visible = game.phase == "active" and not quit_prompt
	result.visible = quit_prompt or game.phase in ["round_over", "match_over"]
	if not has_game:
		return
	round_label.text = "%s  /  Round %d" % [ArenaMaps.MAPS[game.map_id].name, game.round_number]
	map_notice.text = game.map_hint
	map_notice.visible = game.phase == "active" and not game.map_hint.is_empty()
	score_label.text = "Your team  %d   :   %d  Rivals" % [game.wins[0], game.wins[1]]
	time_label.text = "%02ds%s" % [
		ceili(game.round_time),
		"  ·  Ring closing" if game.safe_radius < ArenaMatch.ARENA_RADIUS and game.phase == "active" else ""
	]
	feed_label.text = game.feed[0] if not game.feed.is_empty() else ""
	if game.phase == "active" and not quit_prompt:
		_update_combat_bar(game, target, feedback)
	if result.visible:
		_update_result(game, quit_prompt)


func _update_combat_bar(game: ArenaMatch, target: int, feedback: String) -> void:
	var fighter: Dictionary = game.fighters[0]
	var kit: Dictionary = ArenaMatch.CLASS_INFO[fighter.class_id]
	health_label.text = "%s  ·  %d / %d HP" % [kit.name, ceili(fighter.health), fighter.max_health]
	resource_label.text = "%s  %d / 100" % [kit.get("resource", "Resource"), int(fighter.get("meter", 0))]
	target_label.text = "Auto target  /  Tab or click"
	target_label.add_theme_color_override("font_color", MUTED)
	if target >= 0:
		var selected: Dictionary = game.fighters[target]
		target_label.text = "%s  ·  %d HP" % [ArenaMatch.CLASS_INFO[selected.class_id].name, ceili(selected.health)]
		for key: String in selected.get("marks", {}):
			if key.begins_with("0/"):
				target_label.text += "  ·  %s" % key.get_slice("/", 1).capitalize()
				break
		target_label.add_theme_color_override("font_color", ALLY if selected.team == 0 else FOE)
	for slot in ability_buttons.size():
		var button := ability_buttons[slot]
		button.visible = slot < fighter.abilities.size()
		if not button.visible:
			continue
		var ability: Dictionary = fighter.abilities[slot]
		var time: float = fighter.cooldowns[slot]
		button.text = "%d  %s" % [slot + 1, ability.name]
		if time > 0:
			button.text += "  %.1fs" % time
		button.disabled = not fighter.alive or time > 0 or fighter.get("meter", 0) < ability.get("cost", 0)
	var dodge: String = "Dodge %.1fs" % fighter.dodge_cooldown if fighter.dodge_cooldown > 0 else "Space dodge"
	if not fighter.alive:
		notice_label.text = "Eliminated  /  Spectating for the rest of the round"
	elif not feedback.is_empty():
		notice_label.text = feedback
	else:
		var pending_damage: float = fighter.get("wound_damage", 0.0)
		var break_free := "R Break Free ready" if fighter.get("break_free_available", false) else "Break Free used"
		var status := "%d damage deferred" % ceili(pending_damage) if pending_damage > 0.0 else dodge
		notice_label.text = "%s  /  %s" % [status, break_free]


func _update_result(game: ArenaMatch, quit_prompt: bool) -> void:
	if quit_prompt:
		result_title.text = "Leave this match?"
		result_details.text = "The practice match is paused."
		result_action.text = "Keep playing  /  Enter"
	elif game.phase == "match_over":
		result_title.text = "Match won" if game.match_winner == 0 else "Match lost"
		result_details.text = "Final score  %d : %d" % [game.wins[0], game.wins[1]]
		result_action.text = "Rematch  /  Enter"
	else:
		var titles := {0: "Round won", 1: "Round lost", -1: "Draw"}
		result_title.text = titles.get(game.round_winner, "Round complete")
		result_details.text = "Your team  %d : %d  Rivals" % [game.wins[0], game.wins[1]]
		result_action.text = "Next round  /  Enter"


func _selector() -> OptionButton:
	var selector := OptionButton.new()
	selector.fit_to_longest_item = true
	selector.add_theme_color_override("font_color", TEXT)
	selector.add_theme_stylebox_override("normal", _style(Color("#302437"), Color("#645471"), 7))
	selector.add_theme_stylebox_override("hover", _style(Color("#46304e"), GOLD, 7))
	return selector


func _button(title: String) -> Button:
	var button := Button.new()
	button.text = title
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0, 40)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_hover_color", TEXT)
	button.add_theme_color_override("font_disabled_color", MUTED)
	button.add_theme_stylebox_override("normal", _style(Color("#302437"), Color("#645471"), 7))
	button.add_theme_stylebox_override("hover", _style(Color("#46304e"), GOLD, 7))
	button.add_theme_stylebox_override("pressed", _style(Color("#5d3863"), GOLD, 7))
	button.add_theme_stylebox_override("disabled", _style(Color("#221b2a"), Color("#4b3a54"), 7))
	return button


func _label(title: String, size: int, color: Color, centered: bool = false) -> Label:
	var label := Label.new()
	label.text = title
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	if centered:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _panel(anchors: Vector4, offsets: Vector4) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _style(PANEL, Color("#6b5374"), 14))
	root.add_child(panel)
	_place(panel, anchors, offsets)
	return panel


func _place(control: Control, anchors: Vector4, offsets: Vector4) -> void:
	control.anchor_left = anchors.x
	control.anchor_top = anchors.y
	control.anchor_right = anchors.z
	control.anchor_bottom = anchors.w
	control.offset_left = offsets.x
	control.offset_top = offsets.y
	control.offset_right = offsets.z
	control.offset_bottom = offsets.w


func _column(parent: Control, spacing: int) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", spacing)
	parent.add_child(column)
	return column


func _style(fill: Color, border: Color, padding: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = padding
	style.content_margin_top = padding
	style.content_margin_right = padding
	style.content_margin_bottom = padding
	return style
