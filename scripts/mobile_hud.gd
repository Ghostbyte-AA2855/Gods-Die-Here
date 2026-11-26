extends CanvasLayer

signal class_chosen(class_id: String)
signal advance_pressed
signal lobby_pressed
signal pause_pressed

const ArenaMatch = preload("res://scripts/arena_match.gd")
const ArenaMaps = preload("res://scripts/arena_maps.gd")
const LobbyPreview = preload("res://scripts/champions/lobby_preview.gd")
const MobileKits = preload("res://scripts/mobile_kits.gd")
const Pantheon = preload("res://scripts/pantheon.gd")

const INK := Color("#0f1016")
const PANEL := Color("#1a1921")
const CELL := Color("#242129")
const LINE := Color("#4c3f3c")
const IVORY := Color("#f6ead6")
const MUTED := Color("#c3b5ae")
const GOLD := Color("#e8be7d")
const ALLY := Color("#a1d5cc")
const FOE := Color("#f1a294")
const TINT := Color("#341e25")
const SLOT_LABELS := ["Basic attack", "Ability I", "Ability II", "Ability III"]
const ARENA_FEATURES := {
	"lockwater": "Rising tide",
	"kiln": "Fire vents",
	"orchard": "Crosswinds",
	"quarry": "Moving cover",
	"observatory": "Eclipse veils",
}


class LobbyBackdrop extends Control:
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("#100f14f5"))
		for index in 14:
			var ratio := float(index) / 13.0
			var height := size.y * (1.0 - ratio) * 0.62
			draw_rect(Rect2(0, size.y - height, size.x, height), Color(0.20, 0.085, 0.10, 0.033))
		var center := Vector2(size.x * 0.5, size.y * 0.46)
		for index in 6:
			var width := size.x * (0.28 + 0.04 * index)
			var height := size.y * (0.33 + 0.07 * index)
			draw_polyline(PackedVector2Array([
				center + Vector2(-width, 0), center + Vector2(0, -height),
				center + Vector2(width, 0), center + Vector2(0, height),
				center + Vector2(-width, 0),
			]), Color(0.79, 0.54, 0.38, 0.08), 1.3, true)


var root: Control
var lobby: Control
var battlefield: Control
var result: Control
var selected_map := "lockwater"
var selected_mastery := -1
var preview_class := "breakwater"
var roster_buttons: Dictionary = {}
var map_buttons: Dictionary = {}
var champion_preview: SubViewportContainer
var start_button: Button
var _display_font: SystemFont
var _roster_panel: PanelContainer
var _loadout_panel: PanelContainer
var _kit_panel: VBoxContainer
var _arena_panel: VBoxContainer
var _ability_rows: Array[Button] = []
var _tab_rows: Array[Button] = []
var _class_label: Label
var _patron_label: Label
var _champion_label: Label
var _lore: Label
var _ability_info: Label
var _map_info: Label
var _map_label: Label
var _round_label: Label
var _score_label: Label
var _time_label: Label
var _fighter_label: Label
var _health_bar: ProgressBar
var _resource_bar: ProgressBar
var _resource_label: Label
var _target_label: Label
var _target_bar: ProgressBar
var _notice: Label
var _feed: Label
var _hint: Label
var _pause: Button
var _result_title: Label
var _result_details: Label
var _result_action: Button
var _result_leave: Button


func _ready() -> void:
	_display_font = SystemFont.new()
	_display_font.font_names = PackedStringArray(["Georgia", "Noto Serif", "DejaVu Serif"])
	root = _surface(self)
	root.resized.connect(_fit_lobby)
	_build_lobby()
	_build_battlefield()
	_build_result()
	_fit_lobby()
	battlefield.hide()
	result.hide()


func _build_lobby() -> void:
	lobby = _surface(root)
	var backdrop := LobbyBackdrop.new()
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lobby.add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.resized.connect(backdrop.queue_redraw)

	var outer := MarginContainer.new()
	outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lobby.add_child(outer)
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		outer.add_theme_constant_override("margin_" + side, 20)
	var page := _column(outer, 12)
	var header := _row(page, 12)
	var logo := _label("Gods Die Here", 43, IVORY, HORIZONTAL_ALIGNMENT_LEFT, true)
	logo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(logo)
	var mode := _label("3v3 practice against bots", 22, GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	mode.custom_minimum_size.x = 270
	header.add_child(mode)

	var body := _row(page, 12)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_roster_panel = _panel(body, PANEL, 14)
	_build_roster(_column(_roster_panel, 10))
	_build_champion(body)
	_loadout_panel = _panel(body, PANEL, 14)
	_build_loadout(_column(_loadout_panel, 10))
	_select_class(preview_class)


func _build_roster(roster: VBoxContainer) -> void:
	roster.add_child(_label("Choose your champion", 24, IVORY, HORIZONTAL_ALIGNMENT_LEFT, true))
	var scroll := _scroll(roster)
	var entries := _column(scroll, 6)
	entries.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ids := ArenaMatch.CLASS_INFO.keys()
	ids.sort()
	var selection := ButtonGroup.new()
	for class_id: String in ids:
		var kit: Dictionary = ArenaMatch.CLASS_INFO[class_id]
		var button := _button(kit.name, 62, 22)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		button.button_group = selection
		button.pressed.connect(_select_class.bind(class_id))
		entries.add_child(button)
		roster_buttons[class_id] = button


func _build_champion(parent: Control) -> void:
	var stage := _panel(parent, Color("#201b23"), 6)
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.custom_minimum_size.x = 260
	var column := _column(stage, 7)
	var identity := _column(column, 0)
	_class_label = _label("", 42, IVORY, HORIZONTAL_ALIGNMENT_CENTER, true)
	_patron_label = _label("", 19, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	identity.add_child(_class_label)
	identity.add_child(_patron_label)

	champion_preview = LobbyPreview.new()
	column.add_child(champion_preview)
	var caption := _column(column, 4)
	caption.add_child(_label("Drag to rotate", 15, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	_champion_label = _label("", 20, IVORY, HORIZONTAL_ALIGNMENT_CENTER, true)
	_lore = _wrapped_label("", 17, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	caption.add_child(_champion_label)
	caption.add_child(_lore)


func _build_loadout(parent: VBoxContainer) -> void:
	var tabs := _row(parent, 6)
	var group := ButtonGroup.new()
	for index in 2:
		var tab := _button("Abilities" if index == 0 else "Arena", 59, 21)
		tab.toggle_mode = true
		tab.button_group = group
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.pressed.connect(_set_tab.bind(index))
		tabs.add_child(tab)
		_tab_rows.append(tab)
	var scroll := _scroll(parent)
	var panels := _column(scroll, 0)
	panels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_kit_panel = _column(panels, 7)
	_arena_panel = _column(panels, 7)
	_build_ability_list()
	_build_arena_list()

	_map_label = _label("", 16, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	parent.add_child(_map_label)
	start_button = _button("Enter the arena", 72, 26, true)
	start_button.pressed.connect(func(): class_chosen.emit(preview_class))
	parent.add_child(start_button)
	_select_map(selected_map)
	_set_tab(0)


func _build_ability_list() -> void:
	_kit_panel.add_child(_label("Tap a move to preview its animation", 17, MUTED))
	var selection := ButtonGroup.new()
	for slot in SLOT_LABELS.size():
		var button := _button("", 64, 20)
		button.toggle_mode = true
		button.button_group = selection
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_select_ability.bind(slot))
		_kit_panel.add_child(button)
		_ability_rows.append(button)
	_ability_info = _wrapped_label("", 19, IVORY)
	_kit_panel.add_child(_ability_info)


func _build_arena_list() -> void:
	_map_info = _wrapped_label("", 19, IVORY)
	_arena_panel.add_child(_map_info)
	var selection := ButtonGroup.new()
	for map_id: String in ArenaMaps.MAPS:
		var button := _button(ArenaMaps.MAPS[map_id].name, 62, 20)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		button.button_group = selection
		button.pressed.connect(_select_map.bind(map_id))
		_arena_panel.add_child(button)
		map_buttons[map_id] = button


func _set_tab(index: int) -> void:
	_tab_rows[index].set_pressed_no_signal(true)
	_kit_panel.visible = index == 0
	_arena_panel.visible = index == 1
	var scroll: ScrollContainer = _kit_panel.get_parent().get_parent()
	scroll.set_deferred("scroll_vertical", 0)


func _select_map(map_id: String) -> void:
	selected_map = map_id
	var arena: Dictionary = ArenaMaps.MAPS[map_id]
	map_buttons[map_id].set_pressed_no_signal(true)
	_map_info.text = "%s\n%s" % [ARENA_FEATURES[map_id], arena.description]
	_map_label.text = arena.name


func _select_class(class_id: String) -> void:
	preview_class = class_id
	var kit: Dictionary = ArenaMatch.CLASS_INFO[class_id]
	var god: Array = Pantheon.GODS[class_id]
	roster_buttons[class_id].set_pressed_no_signal(true)
	_class_label.text = kit.name
	_patron_label.text = "%s  /  %s, %s" % [kit.role, god[0], god[1]]
	_champion_label.text = god[2]
	_lore.text = god[3]
	champion_preview.show_champion(class_id, kit.archetype)
	var indexes: Array = MobileKits.slots(class_id)
	for slot in indexes.size():
		var ability: Dictionary = kit.abilities[indexes[slot]]
		_ability_rows[slot].text = "%s\n%s" % [SLOT_LABELS[slot], ability.name]
		_ability_rows[slot].set_pressed_no_signal(false)
	_refresh_ability(0)
	_ability_rows[0].set_pressed_no_signal(true)


func _select_ability(slot: int) -> void:
	_refresh_ability(slot)
	champion_preview.play_ability(MobileKits.slots(preview_class)[slot])


func _refresh_ability(slot: int) -> void:
	var kit: Dictionary = ArenaMatch.CLASS_INFO[preview_class]
	var ability: Dictionary = kit.abilities[MobileKits.slots(preview_class)[slot]]
	var cost := int(ability.get("cost", 0))
	var gain := int(ability.get("gain", 0))
	var timing := "%ss cooldown" % str(ability.cooldown)
	if cost > 0:
		timing += "   ·   Costs %d %s" % [cost, kit.resource]
	elif gain > 0:
		timing += "   ·   Builds %d %s" % [gain, kit.resource]
	_ability_info.text = "%s\n%s" % [timing, ability.description]


func _fit_lobby() -> void:
	if not is_instance_valid(_roster_panel) or not is_instance_valid(_loadout_panel):
		return
	_roster_panel.custom_minimum_size.x = clampf(root.size.x * 0.235, 235, 336)
	_loadout_panel.custom_minimum_size.x = clampf(root.size.x * 0.299, 312, 420)


func _build_battlefield() -> void:
	battlefield = _surface(root)
	var top := _row(battlefield, 10)
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 20
	top.offset_top = 14
	top.offset_right = -20
	var vital_panel := _panel(top, Color("#16151de8"), 11)
	vital_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var vital := _column(vital_panel, 3)
	_fighter_label = _label("", 21, IVORY)
	vital.add_child(_fighter_label)
	_health_bar = _meter(vital, Color("#75bcb0"), 10)
	_resource_bar = _meter(vital, Color("#e5b577"), 5)
	_resource_label = _label("", 15, MUTED)
	vital.add_child(_resource_label)

	var scoring := _panel(top, Color("#16151def"), 10)
	scoring.custom_minimum_size.x = 260
	var round_info := _column(scoring, 0)
	_round_label = _label("", 16, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	_score_label = _label("", 24, GOLD, HORIZONTAL_ALIGNMENT_CENTER, true)
	_time_label = _label("", 20, IVORY, HORIZONTAL_ALIGNMENT_CENTER)
	round_info.add_child(_round_label)
	round_info.add_child(_score_label)
	round_info.add_child(_time_label)

	var enemy_panel := _panel(top, Color("#16151de8"), 11)
	enemy_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var enemy := _column(enemy_panel, 5)
	enemy.add_child(_label("TARGET", 16, MUTED))
	_target_label = _label("", 21, IVORY)
	enemy.add_child(_target_label)
	_target_bar = _meter(enemy, Color("#d98a7a"), 10)
	_pause = _button("Ⅱ", 74, 29)
	_pause.custom_minimum_size.x = 74
	_pause.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_pause.tooltip_text = "Pause match"
	_pause.pressed.connect(func(): pause_pressed.emit())
	top.add_child(_pause)

	var messages := _column(battlefield, 3)
	messages.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	messages.offset_left = -360
	messages.offset_right = 360
	messages.offset_top = 116
	_hint = _battle_label(messages, 19, GOLD)
	_notice = _battle_label(messages, 20, IVORY)
	_feed = _battle_label(messages, 16, MUTED)


func _build_result() -> void:
	result = _surface(root)
	var backdrop := ColorRect.new()
	backdrop.color = Color("#0d0b13b5")
	result.add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	result.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := _panel(center, PANEL, 24)
	panel.custom_minimum_size.x = 460
	var column := _column(panel, 13)
	_result_title = _label("", 44, IVORY, HORIZONTAL_ALIGNMENT_CENTER, true)
	_result_details = _label("", 23, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	column.add_child(_result_title)
	column.add_child(_result_details)
	_result_action = _button("", 71, 24, true)
	_result_action.pressed.connect(func(): advance_pressed.emit())
	column.add_child(_result_action)
	_result_leave = _button("Return to champions", 64, 21)
	_result_leave.pressed.connect(func(): lobby_pressed.emit())
	column.add_child(_result_leave)


func update_match(game: ArenaMatch, target: int, quit_prompt: bool, feedback: String) -> void:
	if not is_instance_valid(root):
		return
	var in_match: bool = game.phase != "idle"
	lobby.visible = not in_match
	champion_preview.set_active(not in_match)
	battlefield.visible = in_match
	result.visible = in_match and (quit_prompt or game.phase in ["round_over", "match_over"])
	if not in_match:
		return
	_pause.disabled = game.phase != "active" or quit_prompt
	_round_label.text = "ROUND %d  /  FIRST TO %d" % [game.round_number, game.round_limit()]
	_score_label.text = "%d   /   %d" % [game.wins[0], game.wins[1]]
	var ring_suffix := "  ·  Ring closing" if game.safe_radius < ArenaMatch.ARENA_RADIUS else ""
	_time_label.text = "%02d s%s" % [ceili(game.round_time), ring_suffix]
	_feed.text = game.feed[0] if not game.feed.is_empty() and not result.visible else ""
	_hint.text = game.map_hint if not result.visible else ""
	if not game.fighters.is_empty():
		_update_vitals(game, target)
		var player_alive: bool = game.fighters[0].alive
		_notice.text = feedback if player_alive else "Eliminated  ·  Spectating this round"
	if result.visible:
		_notice.text = ""
		_update_result(game, quit_prompt)


func _update_vitals(game: ArenaMatch, target: int) -> void:
	var fighter: Dictionary = game.fighters[0]
	var kit: Dictionary = ArenaMatch.CLASS_INFO[fighter.class_id]
	_fighter_label.text = "%s   %d / %d HP" % [kit.name, ceili(fighter.health), fighter.max_health]
	_health_bar.max_value = fighter.max_health
	_health_bar.value = fighter.health
	_resource_bar.value = fighter.get("meter", 0)
	_resource_label.text = "%s  %d / 100" % [kit.resource, int(_resource_bar.value)]
	_target_bar.visible = target >= 0 and target < game.fighters.size()
	_target_label.text = "Automatic  ·  Tap a fighter"
	_target_label.add_theme_color_override("font_color", MUTED)
	if not _target_bar.visible:
		return
	var enemy: Dictionary = game.fighters[target]
	_target_label.text = "%s   %d HP" % [ArenaMatch.CLASS_INFO[enemy.class_id].name, ceili(enemy.health)]
	_target_label.add_theme_color_override("font_color", ALLY if enemy.team == 0 else FOE)
	_target_bar.max_value = enemy.max_health
	_target_bar.value = enemy.health


func _update_result(game: ArenaMatch, quit_prompt: bool) -> void:
	_result_leave.text = "Leave match" if quit_prompt else "Return to champions"
	if quit_prompt:
		_result_title.text = "Match paused"
		_result_details.text = "The arena will wait."
		_result_action.text = "Resume match"
	elif game.phase == "match_over":
		_result_title.text = "Match won" if game.match_winner == 0 else "Match lost"
		_result_details.text = "Final score  %d  /  %d" % [game.wins[0], game.wins[1]]
		_result_action.text = "Rematch"
	else:
		var titles := {0: "Round won", 1: "Round lost", -1: "Draw"}
		_result_title.text = titles.get(game.round_winner, "Round complete")
		_result_details.text = "Your team  %d  /  %d  Rivals" % [game.wins[0], game.wins[1]]
		_result_action.text = "Next round"


func _surface(parent: Node) -> Control:
	var control := Control.new()
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(control)
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return control


func _column(parent: Control, separation: int) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", separation)
	parent.add_child(box)
	return box


func _row(parent: Control, separation: int) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", separation)
	parent.add_child(box)
	return box


func _scroll(parent: Control) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	scroll.scroll_deadzone = 12
	var bar := scroll.get_v_scroll_bar()
	bar.add_theme_stylebox_override("scroll", _style(Color("#18151e"), Color.TRANSPARENT, 3, 4))
	bar.add_theme_stylebox_override("grabber", _style(Color("#775953"), Color.TRANSPARENT, 3, 4))
	bar.add_theme_stylebox_override("grabber_highlight", _style(GOLD, Color.TRANSPARENT, 3, 4))
	bar.add_theme_stylebox_override("grabber_pressed", _style(GOLD, Color.TRANSPARENT, 3, 4))
	parent.add_child(scroll)
	return scroll


func _panel(parent: Control, background: Color, padding: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _style(background, LINE, 10, padding))
	parent.add_child(panel)
	return panel


func _meter(parent: Control, color: Color, height: float) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.show_percentage = false
	bar.custom_minimum_size.y = height
	bar.add_theme_stylebox_override("background", _style(INK, Color.TRANSPARENT, 4))
	bar.add_theme_stylebox_override("fill", _style(color, Color.TRANSPARENT, 4))
	parent.add_child(bar)
	return bar


func _button(title: String, height: float, font_size: int, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size.y = height
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", IVORY)
	button.add_theme_color_override("font_hover_color", IVORY)
	button.add_theme_color_override("font_pressed_color", GOLD)
	button.add_theme_color_override("font_focus_color", IVORY)
	button.add_theme_color_override("font_disabled_color", MUTED)
	button.add_theme_stylebox_override("normal", _style(Color("#65312b") if primary else CELL, Color("#ad6d58") if primary else LINE, 7, 10))
	button.add_theme_stylebox_override("hover", _style(Color("#794038") if primary else Color("#34282e"), GOLD, 7, 10))
	button.add_theme_stylebox_override("pressed", _style(TINT, GOLD, 7, 10))
	button.add_theme_stylebox_override("hover_pressed", _style(TINT, GOLD, 7, 10))
	button.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, GOLD, 7))
	button.add_theme_stylebox_override("disabled", _style(INK, LINE, 7, 10))
	return button


func _label(title: String, font_size: int, color: Color, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, serif: bool = false) -> Label:
	var label := Label.new()
	label.text = title
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = alignment
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if serif:
		label.add_theme_font_override("font", _display_font)
	return label


func _wrapped_label(title: String, font_size: int, color: Color, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := _label(title, font_size, color, alignment)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _battle_label(parent: Control, font_size: int, color: Color) -> Label:
	var label := _label("", font_size, color, HORIZONTAL_ALIGNMENT_CENTER)
	label.add_theme_color_override("font_outline_color", INK)
	label.add_theme_constant_override("outline_size", 7)
	parent.add_child(label)
	return label


func _style(background: Color, border: Color, radius: int, padding: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	if border.a > 0.0:
		style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_content_margin(side, padding)
	return style
