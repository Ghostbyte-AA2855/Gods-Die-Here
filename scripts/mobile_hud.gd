extends CanvasLayer

signal class_chosen(class_id: String)
signal advance_pressed
signal lobby_pressed
signal pause_pressed
signal presentation_option_changed(option: String, enabled: bool)

const ArenaMatch = preload("res://scripts/arena_match.gd")
const ArenaMaps = preload("res://scripts/arena_maps.gd")
const ArenaStage = preload("res://scripts/arena_stage.gd")
const ArenaObjectives = preload("res://scripts/arena_objectives.gd")
const ArenaUltimates = preload("res://scripts/arena_ultimates.gd")
const LobbyPreview = preload("res://scripts/champions/lobby_preview.gd")
const BattleGuides = preload("res://scripts/mobile_battle_guides.gd")
const MobileKits = preload("res://scripts/mobile_kits.gd")
const Pantheon = preload("res://scripts/pantheon.gd")

const INK := Color("#101214")
const PANEL := Color("#17191c")
const CELL := Color("#232325")
const LINE := Color("#50443a")
const IVORY := Color("#f6ead6")
const MUTED := Color("#c3b5ae")
const GOLD := Color("#e8be7d")
const ALLY := Color("#a1d5cc")
const FOE := Color("#f1a294")
const TINT := Color("#3a2b24")
const SLOT_LABELS := ["Basic", "I", "II", "III", "IV", "V"]
const CAST_CARD_SECONDS := 1.65


class LobbyBackdrop extends Control:
	func _draw() -> void:
		var full := PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0.0), size, Vector2(0.0, size.y)])
		draw_polygon(full, PackedColorArray([Color("191317"), Color("151718"), Color("141113"), Color("0d1015")]))
		var ink := Color("a87d593c")
		var center := Vector2(size.x * 0.5, size.y * 0.60)
		for radius in [230.0, 278.0, 285.0, 338.0, 446.0]:
			draw_arc(center, radius, PI, TAU, 96, ink, 1.0, true)
		for tick in 48:
			var axis := Vector2.RIGHT.rotated(TAU * tick / 48.0)
			draw_line(center + axis * 289.0, center + axis * (310.0 if tick % 6 == 0 else 296.0), ink, 1.0, true)
		draw_line(Vector2(20, 80), Vector2(size.x - 20, 80), Color("9c755462"), 1.0, true)


class CrownSeal extends Control:
	func _draw() -> void:
		var center := size * 0.5
		var gold := Color("d7ad75")
		draw_set_transform(center)
		var shield := PackedVector2Array([
			Vector2(0, -22), Vector2(21, -9), Vector2(17, 15),
			Vector2(0, 24), Vector2(-17, 15), Vector2(-21, -9),
		])
		draw_colored_polygon(shield, Color("352423"))
		shield.append(shield[0])
		draw_polyline(shield, Color("967456"), 1.2, true)
		var broken_edge := PackedVector2Array([Vector2(-11, -5), Vector2(-6, 4), Vector2(-2, -5), Vector2(3, 2)])
		var crown := PackedVector2Array([Vector2(4, -5), Vector2(8, 3), Vector2(12, -5), Vector2(10, 10), Vector2(-8, 10)])
		draw_polyline(broken_edge, gold, 2.3, true)
		draw_polyline(crown, gold, 2.3, true)


class CourtPanel extends PanelContainer:
	var trim := Color("9674539c"):
		set(value):
			if trim != value:
				trim = value
				queue_redraw()

	func _draw() -> void:
		for sign_x in [-1.0, 1.0]:
			for sign_y in [-1.0, 1.0]:
				var edge := Vector2(4.0 if sign_x > 0.0 else size.x - 4.0, 4.0 if sign_y > 0.0 else size.y - 4.0)
				var corner := edge + Vector2(sign_x, sign_y) * 4.0
				draw_polyline(PackedVector2Array([edge + Vector2(sign_x * 20.0, 0.0), corner, edge + Vector2(0.0, sign_y * 18.0)]), trim, 1.15, true)


class RoundMarks extends Control:
	var wins := 0
	var maximum := 3
	var side_tint := Color("a1d5cc")

	func update_score(value: int, limit: int) -> void:
		if value == wins and limit == maximum:
			return
		wins = value
		maximum = limit
		queue_redraw()

	func _draw() -> void:
		for index in maximum:
			var center := size * 0.5 + Vector2((index - (maximum - 1.0) * 0.5) * 15.0, 0.0)
			var shape := PackedVector2Array([center + Vector2.UP * 5.0, center + Vector2.RIGHT * 5.0, center + Vector2.DOWN * 5.0, center + Vector2.LEFT * 5.0])
			draw_colored_polygon(shape, side_tint if index < wins else Color("3b3232"))
			shape.append(shape[0])
			draw_polyline(shape, Color(side_tint, 0.72 if index < wins else 0.36), 1.0, true)


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
var _ultimate_preview: Button
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
var _round_marks: Array[RoundMarks] = []
var _survivors: Label
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
var _result_fade: Tween
var _pause_options: HBoxContainer
var _option_buttons: Dictionary = {}
var _last_feed := ""
var _feed_until := 0
var _battle_guides: Control
var _cast_cards: Array[PanelContainer] = []
var _cast_roles: Array[Label] = []
var _cast_names: Array[Label] = []
var _cast_until := PackedInt64Array([0, 0])
var _ultimate_banner: Label
var _relic_panel: CourtPanel
var _relic_name: Label
var _relic_status: Label
var _relic_bonus: Label
var _relic_progress: ProgressBar
var _ultimate_impact_name := ""
var _ultimate_impact_team := 0
var _ultimate_impact_round_time := -1.0


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
	var page := _column(outer, 14)
	var header := _row(page, 12)
	var crest := CrownSeal.new()
	crest.custom_minimum_size = Vector2(54.0, 54.0)
	crest.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(crest)
	var logo := _label("Gods Die Here", 43, IVORY, HORIZONTAL_ALIGNMENT_LEFT, true)
	logo.add_theme_color_override("font_shadow_color", Color("#080808"))
	logo.add_theme_constant_override("shadow_offset_y", 3)
	logo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(logo)
	var mode := _label("3v3 practice against bots", 20, GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
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
	var stage := _panel(parent, Color("#1d1d1e"), 7)
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
	_champion_label = _label("", 22, IVORY, HORIZONTAL_ALIGNMENT_CENTER, true)
	_lore = _wrapped_label("", 17, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	_lore.custom_minimum_size.y = 40
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
	var grid := GridContainer.new()
	grid.columns = 2
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid.add_theme_constant_override("h_separation", 7)
	grid.add_theme_constant_override("v_separation", 7)
	_kit_panel.add_child(grid)
	var selection := ButtonGroup.new()
	for slot in SLOT_LABELS.size():
		var button := _button("", 59, 17)
		button.toggle_mode = true
		button.button_group = selection
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_select_ability.bind(slot))
		grid.add_child(button)
		_ability_rows.append(button)
	_ultimate_preview = _button("", 53, 17, true)
	_ultimate_preview.toggle_mode = true
	_ultimate_preview.button_group = selection
	_ultimate_preview.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_ultimate_preview.pressed.connect(_preview_ultimate)
	_kit_panel.add_child(_ultimate_preview)
	_ability_info = _wrapped_label("", 17, IVORY)
	_ability_info.custom_minimum_size.y = 96
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
	var guide: Dictionary = ArenaStage.ZONE_GUIDE[arena.kind]
	var relic: Dictionary = ArenaObjectives.RELICS[map_id]
	_map_info.text = "%s\n%s\n\n%s · %s\n%s" % [relic.name, relic.effect, guide.name, guide.effect, guide.tip]
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
	var ultimate: Dictionary = ArenaUltimates.KITS[class_id]
	_ultimate_preview.text = "ULTIMATE\n" + ultimate.name
	_ultimate_preview.tooltip_text = ultimate.name
	_ultimate_preview.set_pressed_no_signal(false)
	var indexes: Array = MobileKits.slots(class_id)
	for slot in indexes.size():
		var ability: Dictionary = kit.abilities[indexes[slot]]
		_ability_rows[slot].text = "%s\n%s" % [SLOT_LABELS[slot], ability.name]
		_ability_rows[slot].tooltip_text = ability.name
		_ability_rows[slot].set_pressed_no_signal(false)
	_refresh_ability(0)
	_ability_rows[0].set_pressed_no_signal(true)


func _select_ability(slot: int) -> void:
	_refresh_ability(slot)
	champion_preview.play_ability(MobileKits.slots(preview_class)[slot])


func _preview_ultimate() -> void:
	var ultimate: Dictionary = ArenaUltimates.KITS[preview_class]
	_ability_info.text = "One use per round · Build charge in combat\n%s" % ultimate.description
	champion_preview.play_ultimate()


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
	top.offset_left = 22
	top.offset_top = 16
	top.offset_right = -22
	var vital_panel := _panel(top, Color("#181717ec"), 11)
	vital_panel.custom_minimum_size.x = 316
	vital_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var vital := _column(vital_panel, 3)
	_fighter_label = _label("", 21, IVORY)
	vital.add_child(_fighter_label)
	_health_bar = _meter(vital, Color("#75bcb0"), 10)
	_resource_bar = _meter(vital, Color("#e5b577"), 5)
	_resource_label = _label("", 15, MUTED)
	vital.add_child(_resource_label)

	_hud_space(top)
	var scoring := _panel(top, Color("#171616eb"), 9)
	scoring.custom_minimum_size.x = 246
	scoring.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var round_info := _column(scoring, 1)
	_round_label = _label("", 14, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	_score_label = _label("", 23, GOLD, HORIZONTAL_ALIGNMENT_CENTER, true)
	_score_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_score_label.custom_minimum_size.x = 59.0
	_time_label = _label("", 17, IVORY, HORIZONTAL_ALIGNMENT_CENTER)
	_survivors = _label("", 13, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	round_info.add_child(_round_label)
	var score_line := _row(round_info, 5)
	for tint in [ALLY, FOE]:
		var marks := RoundMarks.new()
		marks.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marks.side_tint = tint
		marks.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		marks.resized.connect(marks.queue_redraw)
		score_line.add_child(marks)
		_round_marks.append(marks)
		if _round_marks.size() == 1:
			score_line.add_child(_score_label)
	round_info.add_child(_time_label)
	round_info.add_child(_survivors)

	_hud_space(top)
	var enemy_panel := _panel(top, Color("#181717ec"), 11)
	enemy_panel.custom_minimum_size.x = 244
	enemy_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var enemy := _column(enemy_panel, 4)
	enemy.add_child(_label("TARGET", 14, MUTED))
	_target_label = _label("", 18, IVORY)
	enemy.add_child(_target_label)
	_target_bar = _meter(enemy, Color("#d98a7a"), 8)
	_pause = _button("II", 62, 26)
	_pause.custom_minimum_size.x = 62
	_pause.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_pause.tooltip_text = "Pause match"
	_pause.pressed.connect(func(): pause_pressed.emit())
	top.add_child(_pause)

	_build_cast_card(0)
	_build_cast_card(1)
	var messages := _column(battlefield, 3)
	messages.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	messages.offset_left = -360
	messages.offset_right = 360
	messages.offset_top = 130
	_ultimate_banner = _battle_label(messages, 25, GOLD)
	_ultimate_banner.hide()
	_hint = _battle_label(messages, 19, GOLD)
	_notice = _battle_label(messages, 20, IVORY)
	_feed = _battle_label(messages, 16, MUTED)
	_build_objective_panel()
	_battle_guides = BattleGuides.new()
	battlefield.add_child(_battle_guides)


func _build_objective_panel() -> void:
	_relic_panel = _panel(battlefield, Color("13131aef"), 11)
	_relic_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_relic_panel.offset_left = -228
	_relic_panel.offset_right = 228
	_relic_panel.offset_top = -119
	_relic_panel.offset_bottom = -15
	var stack := _column(_relic_panel, 3)
	_relic_name = _label("", 19, GOLD, HORIZONTAL_ALIGNMENT_CENTER, true)
	_relic_status = _label("", 16, IVORY, HORIZONTAL_ALIGNMENT_CENTER)
	_relic_bonus = _label("", 15, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	stack.add_child(_relic_name)
	stack.add_child(_relic_status)
	_relic_progress = _meter(stack, GOLD, 5)
	stack.add_child(_relic_bonus)
	_relic_panel.hide()


func _build_cast_card(side: int) -> void:
	var card := _panel(battlefield, Color("#121319eb"), 10)
	card.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT if side == 0 else Control.PRESET_TOP_RIGHT)
	card.offset_left = 22 if side == 0 else -340
	card.offset_right = 338 if side == 0 else -22
	card.offset_top = 119
	card.offset_bottom = 183
	var contents := _column(card, 2)
	var color := GOLD if side == 0 else FOE
	var role := _label("", 13, color)
	var name := _label("", 20, IVORY, HORIZONTAL_ALIGNMENT_LEFT, true)
	contents.add_child(role)
	contents.add_child(name)
	card.hide()
	_cast_cards.append(card)
	_cast_roles.append(role)
	_cast_names.append(name)


func _hud_space(parent: Control) -> void:
	var spacer := Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(spacer)


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
	_pause_options = _row(column, 8)
	_add_pause_option("sound", "Sound")
	_add_pause_option("blood", "Blood")
	_add_pause_option("reduced_motion", "Reduce shake")


func _add_pause_option(option: String, label: String) -> void:
	var button := _button("", 62, 16)
	button.toggle_mode = true
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.toggled.connect(func(enabled: bool):
		_option_label(button, label, enabled)
		presentation_option_changed.emit(option, enabled)
	)
	_pause_options.add_child(button)
	_option_buttons[option] = {"button": button, "label": label}


func _option_label(button: Button, label: String, enabled: bool) -> void:
	button.text = "%s\n%s" % [label, "ON" if enabled else "OFF"]


func sync_presentation_options(sound: bool, blood: bool, reduce_shake: bool) -> void:
	var settings := {"sound": sound, "blood": blood, "reduced_motion": reduce_shake}
	for option in settings:
		var item: Dictionary = _option_buttons[option]
		item.button.set_pressed_no_signal(settings[option])
		_option_label(item.button, item.label, settings[option])


func update_match(game: ArenaMatch, target: int, quit_prompt: bool, feedback: String) -> void:
	if not is_instance_valid(root):
		return
	var in_match: bool = game.phase != "idle"
	lobby.visible = not in_match
	champion_preview.set_active(not in_match)
	battlefield.visible = in_match
	var show_result: bool = in_match and (quit_prompt or game.phase in ["round_over", "match_over"])
	if result.visible != show_result:
		_reveal_result(show_result, quit_prompt)
	if not in_match:
		_last_feed = ""
		clear_battle_cues()
		return
	var running: bool = game.phase == "active" and not quit_prompt
	_update_ultimate_banner(game, running)
	_update_relic_panel(game.objective, running)
	_battle_guides.update_battle(get_viewport().get_camera_3d(), game.environment_zones, game.fields, game.fighters, target, running, game.objective, _ultimate_banner.visible)
	_update_cast_cards(running)
	_pause.disabled = game.phase != "active" or quit_prompt
	_round_label.text = "ROUND %d  /  FIRST TO %d" % [game.round_number, game.round_limit()]
	_score_label.text = "%d   /   %d" % [game.wins[0], game.wins[1]]
	for team in _round_marks.size():
		_round_marks[team].update_score(game.wins[team], game.round_limit())
	var ring_suffix := "  ·  Stay inside ring" if game.safe_radius < ArenaMatch.ARENA_RADIUS else ""
	var seconds := ceili(game.round_time)
	_time_label.text = "%d:%02d%s" % [floori(seconds / 60.0), seconds % 60, ring_suffix]
	var remaining := PackedInt32Array([0, 0])
	for fighter in game.fighters:
		if fighter.alive:
			remaining[fighter.team] += 1
	_survivors.text = "%d allies alive  ·  %d rivals alive" % [remaining[0], remaining[1]]
	var latest: String = game.feed[0] if not game.feed.is_empty() else ""
	if latest != _last_feed:
		_last_feed = latest
		_feed_until = Time.get_ticks_msec() + 2600
	_feed.text = latest if Time.get_ticks_msec() < _feed_until and not result.visible else ""
	_hint.text = _arena_hint(game) if running else ""
	if not game.fighters.is_empty():
		_update_vitals(game, target)
		var player_alive: bool = game.fighters[0].alive
		_notice.text = _player_notice(game, feedback) if player_alive else "Eliminated  ·  Spectating this round"
	if result.visible:
		_notice.text = ""
		_update_result(game, quit_prompt)


func _arena_hint(game: ArenaMatch) -> String:
	if game.environment_zones.is_empty():
		return ""
	var zone: Dictionary = game.environment_zones[0]
	var guide: Dictionary = ArenaStage.ZONE_GUIDE[zone.kind]
	var seconds := ceili(zone.phase_left)
	var status := "%d s left" % seconds if zone.phase == "active" else "in %d s" % (
		seconds + int(ArenaMaps.ACTIVE_START - ArenaMaps.WARNING_START) if zone.phase == "idle" else seconds
	)
	return "%s %s  ·  %s" % [guide.name, status, guide.effect]


func _update_relic_panel(relic: Dictionary, running: bool) -> void:
	_relic_panel.visible = running and not relic.is_empty()
	if not _relic_panel.visible:
		return
	_relic_name.text = relic.name
	var side := "Your team" if relic.team == 0 else "Rivals"
	var accent := GOLD if relic.team < 0 or relic.phase == "contested" else ALLY if relic.team == 0 else FOE
	if _relic_panel.trim != Color(accent, 0.66):
		_relic_panel.trim = Color(accent, 0.66)
		_relic_name.add_theme_color_override("font_color", accent)
		var fill := _relic_progress.get_theme_stylebox("fill") as StyleBoxFlat
		fill.bg_color = accent
	match relic.phase:
		"arming":
			_relic_status.text = "Opens in %d s" % ceili(relic.time_left)
		"contested":
			_relic_status.text = "Contested · Clear rivals from the circle"
		"cooldown":
			_relic_status.text = "%s claimed it · Reopens in %d s" % [side, ceili(relic.time_left)]
		_:
			_relic_status.text = "%s claiming · %.1f / %.0f s" % [side, relic.progress, relic.hold] if relic.team >= 0 else "Hold the circle for %.0f s" % relic.hold
	_relic_progress.max_value = relic.hold
	_relic_progress.value = relic.progress
	_relic_bonus.text = relic.effect if relic.buff_left <= 0 else "%s · %d s left" % [relic.effect.split(" for ")[0], ceili(relic.buff_left)]


func _update_ultimate_banner(game: ArenaMatch, running: bool) -> void:
	var chosen: Dictionary = {}
	if running:
		for entry: Dictionary in game.ultimate_windups:
			if chosen.is_empty() or (entry.team == 1 and chosen.team == 0) or (entry.team == chosen.team and entry.remaining < chosen.remaining):
				chosen = entry
	if running and not _ultimate_impact_name.is_empty() and _ultimate_impact_round_time < 0.0:
		_ultimate_impact_round_time = game.round_time
	var released := running and _ultimate_impact_round_time >= 0.0 and _ultimate_impact_round_time - game.round_time < 1.6
	_ultimate_banner.visible = not chosen.is_empty() or released
	if not chosen.is_empty():
		var who := "RIVAL WINDUP" if chosen.team == 1 else "YOUR WINDUP" if chosen.source_id == 0 else "ALLY WINDUP"
		_ultimate_banner.text = "%s · %s · %.1f s" % [who, chosen.name, chosen.remaining]
		_ultimate_banner.modulate = FOE if chosen.team == 1 else GOLD
	elif released:
		_ultimate_banner.text = _ultimate_impact_name
		_ultimate_banner.modulate = FOE if _ultimate_impact_team == 1 else GOLD


func _player_notice(game: ArenaMatch, feedback: String) -> String:
	var point: Vector2 = game.fighters[0].position
	if game.safe_radius < ArenaMatch.ARENA_RADIUS and point.length_squared() > game.safe_radius * game.safe_radius:
		return "Taking ring damage · Move inside the boundary"
	for zone in game.environment_zones:
		if zone.phase == "active" and zone.kind == "vent" and point.distance_squared_to(zone.position) < zone.radius * zone.radius:
			return "Taking vent damage · Step out of the circle"
	return feedback


func record_cast(event: Dictionary, locked: int) -> void:
	_battle_guides.record_cast(event, locked)
	if event.get("ultimate", false):
		_ultimate_impact_name = event.name
		_ultimate_impact_team = event.team
		_ultimate_impact_round_time = -1.0
	var player_effect: bool = event.target_id == 0 or 0 in event.affected_ids
	if event.source_id == 0:
		var role := "YOUR ULTIMATE" if event.get("ultimate", false) else "YOUR ATTACK" if event.slot == 0 else "YOUR ABILITY"
		_show_cast(0, role, event)
	elif event.slot > 0 and (player_effect or (event.team == 1 and event.source_id == locked)):
		var role := "ALLY SUPPORT" if event.team == 0 else ("RIVAL · ON YOU" if player_effect else "RIVAL ABILITY")
		_show_cast(1, role, event)


func clear_battle_cues() -> void:
	_cast_until.fill(0)
	_ultimate_impact_name = ""
	_ultimate_impact_round_time = -1.0
	_battle_guides.clear_casts()
	_battle_guides.hide()
	for card in _cast_cards:
		card.hide()


func _show_cast(side: int, role: String, event: Dictionary) -> void:
	var now := Time.get_ticks_msec()
	if event.slot == 0 and now < _cast_until[side]:
		return
	_cast_roles[side].text = role
	_cast_roles[side].modulate = ALLY if role == "ALLY SUPPORT" else Color.WHITE
	_cast_names[side].text = event.name
	_cast_until[side] = now + int(CAST_CARD_SECONDS * 1000.0)


func _update_cast_cards(running: bool) -> void:
	var now := Time.get_ticks_msec()
	for side in _cast_cards.size():
		var left := _cast_until[side] - now
		_cast_cards[side].visible = running and left > 0
		_cast_cards[side].modulate.a = clampf(left / 275.0, 0.0, 1.0)


func _reveal_result(show_result: bool, paused: bool) -> void:
	if _result_fade != null:
		_result_fade.kill()
	result.visible = show_result
	if not show_result:
		return
	result.modulate.a = 0.0
	_result_fade = result.create_tween()
	if not paused:
		_result_fade.tween_interval(0.26)
	_result_fade.tween_property(result, "modulate:a", 1.0, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _update_vitals(game: ArenaMatch, target: int) -> void:
	var fighter: Dictionary = game.fighters[0]
	var kit: Dictionary = ArenaMatch.CLASS_INFO[fighter.class_id]
	_fighter_label.text = "%s   %d / %d HP" % [kit.name, ceili(fighter.health), ceili(fighter.max_health)]
	_health_bar.max_value = fighter.max_health
	_health_bar.value = fighter.health
	_resource_bar.value = fighter.get("meter", 0)
	_resource_label.text = "%s  %d / 100" % [kit.resource, int(_resource_bar.value)]
	_target_bar.visible = target >= 0 and target < game.fighters.size()
	_target_label.text = "Auto · Tap to lock"
	_target_label.add_theme_color_override("font_color", MUTED)
	if not _target_bar.visible:
		return
	var enemy: Dictionary = game.fighters[target]
	_target_label.text = "%s   %d HP" % [ArenaMatch.CLASS_INFO[enemy.class_id].name, ceili(enemy.health)]
	_target_label.add_theme_color_override("font_color", ALLY if enemy.team == 0 else FOE)
	_target_bar.max_value = enemy.max_health
	_target_bar.value = enemy.health


func _update_result(game: ArenaMatch, quit_prompt: bool) -> void:
	_pause_options.visible = quit_prompt
	_result_leave.text = "Leave match" if quit_prompt else "Return to champions"
	if quit_prompt:
		_result_title.text = "Match paused"
		_result_details.text = "%s  ·  Round %d" % [ArenaMaps.MAPS[game.map_id].name, game.round_number]
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


func _panel(parent: Control, background: Color, padding: int) -> CourtPanel:
	var panel := CourtPanel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var surface := _style(background, LINE, 7, padding)
	surface.shadow_color = Color("07060b90")
	surface.shadow_size = 3
	surface.shadow_offset = Vector2(0, 2)
	panel.add_theme_stylebox_override("panel", surface)
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
	var face := _style(Color("#65312b") if primary else CELL, Color("#b17b5c") if primary else LINE, 6, 10)
	face.border_width_bottom = 2 if primary else 1
	button.add_theme_stylebox_override("normal", face)
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
	label.clip_text = false
	label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
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
