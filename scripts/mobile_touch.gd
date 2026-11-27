extends Control

signal ability_pressed(button: int)
signal dodge_pressed
signal target_tapped(at: Vector2)

const ArenaMatch = preload("res://scripts/arena_match.gd")
const STICK_RADIUS := 55.0
const STICK_DEAD_ZONE := 8.0
const TAP_SLOP := 22.0
const MOUSE_POINTER := -2
const NO_POINTER := -3
const STICK_ROLE := -1
const FIELD_ROLE := -2
const IGNORED_ROLE := -3
const DODGE_BUTTON := 6
const ULTIMATE_BUTTON := 7
const HIT_PADDING := 3.0
const CONTROL_PADDING := 14.0
const PRESS_MS := 110
const RELEASE_MS := 230
const READY_MS := 320
const REFUSAL_MS := 240
const DIAL_STEPS := 90

# Two thumb rows keep the larger basic attack low and Dodge apart from the spells.
const OFFSETS := [
	Vector2(71, 68),
	Vector2(171, 61),
	Vector2(171, 154),
	Vector2(72, 165),
	Vector2(263, 153),
	Vector2(266, 60),
	Vector2(70, 255),
	Vector2(173, 255),
]
const RADII := [49.0, 39.0, 39.0, 39.0, 39.0, 39.0, 38.0, 45.0]
const ACCENTS := {
	"basic": Color("eabe76"),
	"enemy": Color("ec987c"),
	"ally": Color("98dec5"),
	"self": Color("9bcfed"),
	"aim": Color("d3afea"),
	"dodge": Color("bccce1"),
	"break_free": Color("f4c176"),
	"ultimate": Color("ffd78a"),
}
const INK := Color("14101a")
const TEXT := Color("fff0d6")
const REFUSAL := Color("f48378")
const QUEUED := Color("f1d286")

class ActionAppearance:
	var label := ""
	var glyph := ""
	var blocked := ""
	var countdown := 0
	var dial := 0
	var ready_until := 0
	var press_until := 0
	var refusal_until := 0

	func update(new_label: String, new_glyph: String, new_block: String, remaining: float, duration: float, now: int) -> bool:
		# Store only what is actually visible. An unchanged arc or numeral does
		# not require rebuilding the complete overlay.
		var new_countdown := ceili(remaining * 10.0) if remaining < 1.0 else ceili(remaining) * 10
		var new_dial := ceili(clampf(remaining / maxf(0.1, duration), 0.0, 1.0) * DIAL_STEPS)
		if label == new_label and glyph == new_glyph and blocked == new_block and countdown == new_countdown and dial == new_dial:
			return false
		if countdown > 0 and new_countdown == 0 and new_block.is_empty() and label == new_label:
			ready_until = now + READY_MS
		label = new_label
		glyph = new_glyph
		blocked = new_block
		countdown = new_countdown
		dial = new_dial
		return true

var direction := Vector2.ZERO
var attack_held := false
var _active := false
var _pointers: Dictionary = {}
var _stick_id := NO_POINTER
var _stick_origin := Vector2.ZERO
var _stick_offset := Vector2.ZERO
var _fighter: Dictionary = {}
var _slots: Array = []
var _resource := ""
var _cue_until := PackedInt64Array()
var _label_layouts: Dictionary = {}
var _action_appearance: Array[ActionAppearance] = []
var _buffered_button := -1
var _pulse_draw_ms := 0
var _had_pulse := false
var _winding_up := false
var _ultimate_percent := 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = _active
	set_process_unhandled_input(_active)
	set_process(_active)
	_cue_until.resize(OFFSETS.size())
	for button in OFFSETS.size():
		_action_appearance.append(ActionAppearance.new())
	resized.connect(queue_redraw)


func set_active(value: bool) -> void:
	if _active == value:
		return
	_active = value
	visible = value
	set_process_unhandled_input(value)
	set_process(value)
	if not value:
		reset()
	queue_redraw()


func update_fighter(fighter: Dictionary, slots: Array, resource: String, winding_up: bool = false) -> void:
	_fighter = fighter
	_slots = slots
	_resource = resource
	_winding_up = winding_up
	if _active:
		_update_action_appearance()


func reset() -> void:
	_pointers.clear()
	_stick_id = NO_POINTER
	_stick_offset = Vector2.ZERO
	direction = Vector2.ZERO
	attack_held = false
	_cue_until.fill(0)
	_buffered_button = -1
	_had_pulse = false
	for action in _action_appearance:
		action.countdown = 0
		action.ready_until = 0
		action.press_until = 0
		action.refusal_until = 0
	queue_redraw()


func cue(button: int) -> void:
	if button >= 0 and button < _cue_until.size():
		_cue_until[button] = Time.get_ticks_msec() + RELEASE_MS
		_had_pulse = true
		queue_redraw()


func set_buffered(button: int) -> void:
	if _buffered_button != button:
		_buffered_button = button
		queue_redraw()


func refuse(button: int) -> void:
	if button >= 0 and button < _action_appearance.size():
		_action_appearance[button].refusal_until = Time.get_ticks_msec() + REFUSAL_MS
		_had_pulse = true
		queue_redraw()


func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec()
	if now - _pulse_draw_ms < 25:
		return
	var pulsing := false
	for button in _action_appearance.size():
		var action := _action_appearance[button]
		var latest := maxi(action.press_until, maxi(action.refusal_until, _cue_until[button]))
		if button > 0:
			latest = maxi(latest, action.ready_until)
		if latest > now:
			pulsing = true
			break
	if pulsing or _had_pulse:
		_pulse_draw_ms = now
		queue_redraw()
	_had_pulse = pulsing


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		reset()


func _unhandled_input(event: InputEvent) -> void:
	if not _active or event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	var handled := false
	if event is InputEventScreenTouch:
		if event.pressed and not event.canceled:
			handled = _press(event.index, _local(event.position))
		else:
			handled = _release(event.index, event.position, event.canceled)
	elif event is InputEventScreenDrag:
		handled = _drag(event.index, _local(event.position))
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			handled = _press(MOUSE_POINTER, _local(event.position))
		else:
			handled = _release(MOUSE_POINTER, event.position, false)
	elif event is InputEventMouseMotion:
		handled = _drag(MOUSE_POINTER, _local(event.position))
	if handled:
		get_viewport().set_input_as_handled()


func _local(at: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * at


func _press(pointer: int, at: Vector2) -> bool:
	if _pointers.has(pointer):
		return true
	var button := _button_at(at)
	if button >= 0:
		if _button_held(button):
			_pointers[pointer] = {"role": IGNORED_ROLE}
			return true
		_pointers[pointer] = {"role": button}
		_action_appearance[button].press_until = Time.get_ticks_msec() + PRESS_MS
		_had_pulse = true
		if button == DODGE_BUTTON:
			dodge_pressed.emit()
		else:
			if button == 0:
				attack_held = true
			ability_pressed.emit(button)
	elif _button_at(at, CONTROL_PADDING) >= 0:
		# Near misses stay with the controls so they cannot clear a fighter lock.
		_pointers[pointer] = {"role": IGNORED_ROLE}
	elif at.x <= 270.0 and at.y >= size.y * 0.59:
		if _stick_id == NO_POINTER:
			_stick_id = pointer
			_stick_origin = at
			_pointers[pointer] = {"role": STICK_ROLE}
		else:
			_pointers[pointer] = {"role": IGNORED_ROLE}
	elif pointer != MOUSE_POINTER:
		_pointers[pointer] = {"role": FIELD_ROLE, "origin": at, "moved": false}
	else:
		return false
	queue_redraw()
	return true


func _drag(pointer: int, at: Vector2) -> bool:
	if not _pointers.has(pointer):
		return false
	var press: Dictionary = _pointers[pointer]
	if press.role == STICK_ROLE:
		_stick_offset = (at - _stick_origin).limit_length(STICK_RADIUS)
		var strength := clampf((_stick_offset.length() - STICK_DEAD_ZONE) / (STICK_RADIUS - STICK_DEAD_ZONE), 0.0, 1.0)
		direction = _stick_offset.normalized() * strength
		queue_redraw()
	elif press.role == FIELD_ROLE and at.distance_to(press.origin) > TAP_SLOP:
		press.moved = true
	return true


func _release(pointer: int, at: Vector2, canceled: bool) -> bool:
	if not _pointers.has(pointer):
		return false
	var press: Dictionary = _pointers[pointer]
	_pointers.erase(pointer)
	match int(press.role):
		STICK_ROLE:
			_stick_id = NO_POINTER
			_stick_offset = Vector2.ZERO
			direction = Vector2.ZERO
		FIELD_ROLE:
			if not canceled and not press.moved and _local(at).distance_to(press.origin) <= TAP_SLOP:
				target_tapped.emit(at)
		0:
			attack_held = false
	queue_redraw()
	return true


func _center(button: int) -> Vector2:
	return size - OFFSETS[button]


func _button_at(at: Vector2, padding: float = HIT_PADDING) -> int:
	for button in OFFSETS.size():
		var radius: float = RADII[button] + padding
		if at.distance_squared_to(_center(button)) <= radius * radius:
			return button
	return -1


func _button_held(button: int) -> bool:
	for press: Dictionary in _pointers.values():
		if press.role == button:
			return true
	return false


func _draw() -> void:
	if not _active:
		return
	_draw_stick()
	var now := Time.get_ticks_msec()
	for button in OFFSETS.size():
		_draw_button(button, now)


func _draw_stick() -> void:
	var engaged := _stick_id != NO_POINTER
	var origin := _stick_origin if engaged else Vector2(123, size.y - 109.0)
	var inset := Vector2.ONE * (STICK_RADIUS + 8.0)
	var thumb_inset := Vector2.ONE * 26.0
	origin = origin.clamp(inset, (size - inset).max(inset))
	var thumb := (origin + _stick_offset).clamp(thumb_inset, (size - thumb_inset).max(thumb_inset))
	var accent := Color("af946b") if engaged else Color("8a7975")
	draw_circle(origin + Vector2(0, 3), STICK_RADIUS + 6.0, Color(0.02, 0.02, 0.03, 0.58), true, -1.0, true)
	draw_circle(origin, STICK_RADIUS, Color(0.07, 0.055, 0.09, 0.82), true, -1.0, true)
	draw_arc(origin, STICK_RADIUS, 0.0, TAU, 64, accent, 1.8, true)
	draw_arc(origin, STICK_RADIUS - 7.0, 0.0, TAU, 64, Color(accent, 0.38), 1.0, true)
	for angle in 4:
		var radial := Vector2.RIGHT.rotated(float(angle) * PI * 0.5)
		draw_line(origin + radial * 37.0, origin + radial * 44.0, accent, 1.7, true)
	if engaged:
		draw_line(origin, thumb, Color(accent, 0.7), 3.0, true)
	draw_circle(thumb, 24.0, INK.lightened(0.12 if engaged else 0.06), true, -1.0, true)
	draw_arc(thumb, 24.0, 0.0, TAU, 40, accent, 2.0, true)
	_draw_diamond(thumb, 8.0, accent)


func _update_action_appearance() -> void:
	var now := Time.get_ticks_msec()
	var common_block := ""
	if float(_fighter.get("stun", 0.0)) > 0.0:
		common_block = "Stunned"
	elif float(_fighter.get("mend_time", 0.0)) > 0.0:
		common_block = "Casting"
	var silenced := ArenaMatch.has_status(_fighter, "silence")
	for button in _action_appearance.size():
		_update_button_appearance(button, common_block, silenced, now)


func _update_button_appearance(button: int, common_block: String, silenced: bool, now: int) -> void:
	var label := "Attack"
	var glyph := "basic" if button == 0 else "enemy"
	var remaining := 0.0
	var duration := ArenaMatch.DODGE_COOLDOWN
	var blocked := common_block
	if button == ULTIMATE_BUTTON:
		label = "Ultimate"
		glyph = "ultimate"
		var old_percent := _ultimate_percent
		_ultimate_percent = clampi(floori(float(_fighter.get("ultimate_charge", 0.0)) + 0.0001), 0, 100)
		if _winding_up:
			blocked = "Casting"
		elif bool(_fighter.get("ultimate_used", false)):
			blocked = "Spent"
		elif blocked.is_empty():
			if silenced:
				blocked = "Silenced"
			elif _ultimate_percent < 100:
				blocked = "%d%%" % _ultimate_percent
			elif old_percent < 100:
				_action_appearance[button].ready_until = now + READY_MS
				_had_pulse = true
	elif button == DODGE_BUTTON:
		if ArenaMatch.can_break_free(_fighter):
			label = "Break Free"
			glyph = "break_free"
			blocked = ""
		else:
			label = "Dodge"
			glyph = "dodge"
			remaining = float(_fighter.get("dodge_cooldown", 0.0))
			if blocked.is_empty() and ArenaMatch.has_status(_fighter, "root"):
				blocked = "Rooted"
	elif button < _slots.size():
		var slot := int(_slots[button])
		var abilities: Array = _fighter.get("abilities", [])
		var cooldowns: Array = _fighter.get("cooldowns", [])
		if slot >= 0 and slot < abilities.size() and slot < cooldowns.size():
			var ability: Dictionary = abilities[slot]
			label = str(ability.name)
			remaining = float(cooldowns[slot])
			duration = float(ability.cooldown)
			if button > 0:
				glyph = str(ability.get("target", "enemy"))
			if blocked.is_empty():
				if button > 0 and silenced:
					blocked = "Silenced"
				elif float(_fighter.get("meter", 0.0)) < float(ability.cost):
					blocked = "Need %d %s" % [int(ability.cost), _resource]
	elif button > 0:
		label = "Skill %d" % button
	var action := _action_appearance[button]
	if action.update(label, glyph, blocked, remaining, duration, now):
		if button != 0 and action.ready_until > now:
			_had_pulse = true
		queue_redraw()


func _draw_button(button: int, now: int) -> void:
	var action := _action_appearance[button]
	var center := _center(button)
	var radius: float = RADII[button]
	var held := _button_held(button)
	var glyph := action.glyph
	var accent: Color = ACCENTS.get(glyph, ACCENTS.enemy)
	var unavailable := action.countdown > 0 or not action.blocked.is_empty()
	var flare := _pulse_strength(_cue_until[button], RELEASE_MS, now)
	var press := maxf(0.62 if held else 0.0, _pulse_strength(action.press_until, PRESS_MS, now))
	var readiness := _pulse_strength(action.ready_until, READY_MS, now) if button != 0 and not unavailable else 0.0
	var refusal := _pulse_strength(action.refusal_until, REFUSAL_MS, now)
	var border := accent.darkened(0.42) if unavailable else accent
	if flare > 0.0 or press > 0.0:
		border = border.lightened(maxf(flare * 0.5, press * 0.29))
	if refusal > 0.0:
		border = border.lerp(REFUSAL, refusal)
	draw_circle(center + Vector2(0, 3), radius + 4.0, Color(0.02, 0.02, 0.03, 0.7), true, -1.0, true)
	draw_circle(center, radius, INK.lerp(accent, 0.06 + 0.20 * press), true, -1.0, true)
	draw_circle(center - Vector2(0, 1), radius - 4.0, Color(accent, 0.035 + 0.18 * flare + 0.09 * readiness), true, -1.0, true)
	draw_arc(center, radius, 0.0, TAU, 64, border, 2.0 + press * 0.8, true)
	draw_arc(center, radius + 1.5, -2.64, -0.5, 28, Color(border, 0.45), 1.5, true)
	draw_arc(center, radius - 5.5, -2.66, -0.48, 24, Color(border, 0.6), 1.0, true)
	if flare > 0.0:
		draw_arc(center, radius + 2.0 + (1.0 - flare) * 9.0, 0.0, TAU, 40, Color(accent.lightened(0.35), flare * 0.7), 2.0, true)
	if readiness > 0.0:
		draw_arc(center, radius - 7.0, -2.65, -0.50, 24, Color(accent.lightened(0.66), readiness * 0.86), 2.1, true)
	if button == _buffered_button:
		draw_arc(center, radius + 2.0, -2.62, -0.52, 24, QUEUED, 3.0, true)
	_draw_diamond(center - Vector2(0, radius - 2.0), 3.8, border)
	if button == DODGE_BUTTON:
		# A second full ring makes Dodge recognizable by shape as well as color.
		draw_arc(center, radius - 5.0, 0.0, TAU, 48, Color(border, 0.58), 1.0, true)
	elif button == ULTIMATE_BUTTON:
		var charge := float(_ultimate_percent) / 100.0
		draw_arc(center, radius - 5.0, 0.0, TAU, 56, Color(accent, 0.20), 1.75, true)
		if charge > 0.0:
			draw_arc(center, radius - 5.0, -PI * 0.5, -PI * 0.5 + TAU * charge, 56, accent, 3.1, true)
		for spoke in 8:
			var axis := Vector2.UP.rotated(spoke * TAU / 8.0)
			draw_line(center + axis * (radius + 1.5), center + axis * (radius + 4.0), border, 1.7, true)
	if action.countdown > 0:
		var sweep := TAU * float(action.dial) / DIAL_STEPS
		draw_arc(center, radius - 4.0, -PI * 0.5, -PI * 0.5 + sweep, 64, accent, 2.8, true)
		var countdown := "%.1f" % (action.countdown / 10.0) if action.countdown < 10 else str(floori(action.countdown / 10.0))
		_draw_centered(countdown, center + Vector2(0, 3), 24, TEXT)
	elif not action.blocked.is_empty():
		_draw_glyph(glyph, center - Vector2(0, 11), border)
		_draw_centered(action.blocked, center + Vector2(0, 7), 9, TEXT)
	else:
		_draw_glyph(glyph, center - Vector2(0, 7), accent.lightened(0.13) if held else accent)
	_draw_button_label(action.label, center, radius, TEXT if not unavailable else TEXT.darkened(0.22))


func _pulse_strength(until: int, duration: int, now: int) -> float:
	return clampf(float(until - now) / duration, 0.0, 1.0)


func _draw_button_label(label: String, center: Vector2, radius: float, tint: Color) -> void:
	if not _label_layouts.has(label):
		_label_layouts[label] = _label_layout(label, radius)
	var layout: Dictionary = _label_layouts[label]
	var rows: PackedStringArray = layout.rows
	var baseline := 22.0 if rows.size() == 1 else 19.0
	for row in rows:
		_draw_centered(row, center + Vector2(0.0, baseline), layout.font_size, tint)
		baseline += 12.0


func _label_layout(label: String, radius: float) -> Dictionary:
	var font := ThemeDB.fallback_font
	var width := radius * 1.76
	var words := label.split(" ", false)
	for font_size in range(13, 9, -1):
		if font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= width:
			return {"rows": PackedStringArray([label]), "font_size": font_size}
		for split in range(1, words.size()):
			var first := " ".join(words.slice(0, split))
			var second := " ".join(words.slice(split))
			if font.get_string_size(first, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= radius * 1.72 and font.get_string_size(second, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= radius * 1.48:
				return {"rows": PackedStringArray([first, second]), "font_size": font_size}
	var short := label
	while short.length() > 1 and font.get_string_size(short + "…", HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x > width:
		short = short.left(-1)
	return {"rows": PackedStringArray([short + "…"]), "font_size": 10}


func _draw_centered(label: String, baseline: Vector2, font_size: int, tint: Color) -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, baseline - Vector2(width * 0.5, 0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, tint)


func _draw_diamond(center: Vector2, radius: float, tint: Color) -> void:
	var points := PackedVector2Array()
	for angle in 4:
		points.append(center + Vector2.UP.rotated(float(angle) * PI * 0.5) * radius)
	draw_colored_polygon(points, tint)


func _draw_glyph(glyph: String, at: Vector2, tint: Color) -> void:
	var points := PackedVector2Array()
	match glyph:
		"basic":
			points = PackedVector2Array([Vector2(-9, 10), Vector2(6, -12), Vector2(13, -14), Vector2(11, -6), Vector2(-5, 12)])
			draw_line(at + Vector2(-12, 3), at + Vector2(2, 14), tint, 2.3, true)
		"ally":
			draw_circle(at, 12.0, Color(tint, 0.55), false, 1.5, true)
			draw_line(at - Vector2(6, 0), at + Vector2(6, 0), tint, 2.7, true)
			draw_line(at - Vector2(0, 6), at + Vector2(0, 6), tint, 2.7, true)
		"self":
			draw_circle(at, 11.0, tint, false, 2.0, true)
			_draw_diamond(at, 4.3, tint)
		"aim":
			for index in 4:
				var axis := Vector2.RIGHT.rotated(index * TAU / 4.0)
				draw_line(at + axis * 7.0, at + axis * 13.0, tint, 2.0, true)
			_draw_diamond(at, 4.1, tint)
		"ultimate":
			for index in 8:
				var radius := 13.0 if index % 2 == 0 else 5.0
				points.append(Vector2.UP.rotated(index * TAU / 8.0) * radius)
			points.append(points[0])
			_draw_diamond(at, 3.6, tint)
		"dodge":
			points = PackedVector2Array([Vector2(-13, -7), Vector2(-5, 0), Vector2(-13, 7)])
			draw_polyline(PackedVector2Array([at + Vector2(-1, -10), at + Vector2(10, 0), at + Vector2(-1, 10)]), tint, 2.8, true)
		"break_free":
			points = PackedVector2Array([Vector2(-3, 0), Vector2(-9, 0), Vector2(-13, 5), Vector2(-13, 9), Vector2(-9, 13), Vector2(-5, 13), Vector2(0, 8), Vector2(0, 4)])
			var other_link := PackedVector2Array()
			for point in points:
				other_link.append(at - point)
			draw_polyline(other_link, tint, 2.2, true)
			draw_line(at + Vector2(-9, -7), at + Vector2(-6, -3), tint, 2.2, true)
			draw_line(at + Vector2(7, 5), at + Vector2(11, 8), tint, 2.2, true)
		_:
			draw_arc(at, 11.0, 0.0, TAU, 24, tint, 1.8, true)
			_draw_diamond(at, 3.2, tint)
			draw_line(at + Vector2(-15, 0), at + Vector2(-9, 0), tint, 1.8, true)
			draw_line(at + Vector2(9, 0), at + Vector2(15, 0), tint, 1.8, true)
	if points.is_empty():
		return
	for index in points.size():
		points[index] += at
	draw_polyline(points, tint, 2.2, true)
