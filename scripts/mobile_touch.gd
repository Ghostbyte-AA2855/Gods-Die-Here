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
const DODGE_BUTTON := 4
const BREAK_FREE_GLYPH := 5

const OFFSETS := [
	Vector2(81, 88),
	Vector2(185, 67),
	Vector2(177, 168),
	Vector2(72, 193),
	Vector2(289, 82),
]
const RADII := [50.0, 41.0, 41.0, 42.0, 39.0]
const ACCENTS := [Color("c7a16d"), Color("dd8459"), Color("81b9b2"), Color("d989a3"), Color("a7b7c4")]
const INK := Color("14101a")
const TEXT := Color("fff0d6")

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
var _cue_until: PackedInt64Array = [0, 0, 0, 0, 0]


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = _active
	set_process_unhandled_input(_active)
	resized.connect(queue_redraw)


func set_active(value: bool) -> void:
	if _active == value:
		return
	_active = value
	visible = value
	set_process_unhandled_input(value)
	if not value:
		reset()
	queue_redraw()


func update_fighter(fighter: Dictionary, slots: Array, resource: String) -> void:
	_fighter = fighter
	_slots = slots
	_resource = resource
	if _active:
		queue_redraw()


func reset() -> void:
	_pointers.clear()
	_stick_id = NO_POINTER
	_stick_offset = Vector2.ZERO
	direction = Vector2.ZERO
	attack_held = false
	_cue_until.fill(0)
	queue_redraw()


func cue(button: int) -> void:
	if button >= 0 and button < _cue_until.size():
		_cue_until[button] = Time.get_ticks_msec() + 230
		queue_redraw()


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
		if button == DODGE_BUTTON:
			dodge_pressed.emit()
		else:
			if button == 0:
				attack_held = true
			ability_pressed.emit(button)
	elif _stick_id == NO_POINTER and at.x <= 270.0 and at.y >= size.y * 0.59:
		_stick_id = pointer
		_stick_origin = at
		_pointers[pointer] = {"role": STICK_ROLE}
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


func _button_at(at: Vector2) -> int:
	for button in OFFSETS.size():
		if at.distance_to(_center(button)) <= RADII[button] + 3.0:
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
	for button in OFFSETS.size():
		_draw_button(button)


func _draw_stick() -> void:
	var engaged := _stick_id != NO_POINTER
	var origin := _stick_origin if engaged else Vector2(123, size.y - 109.0)
	var thumb := origin + _stick_offset
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


func _draw_button(button: int) -> void:
	var center := _center(button)
	var radius: float = RADII[button]
	var accent: Color = ACCENTS[button]
	var held := _button_held(button)
	var label := "Attack"
	var glyph := button
	var remaining := 0.0
	var duration := ArenaMatch.DODGE_COOLDOWN
	var short_on_resource := false
	if button == DODGE_BUTTON:
		if ArenaMatch.can_break_free(_fighter):
			label = "Break Free"
			glyph = BREAK_FREE_GLYPH
			accent = Color("f4c176")
		else:
			label = "Dodge"
			remaining = float(_fighter.get("dodge_cooldown", 0.0))
	elif button < _slots.size():
		var slot := int(_slots[button])
		var abilities: Array = _fighter.get("abilities", [])
		var cooldowns: Array = _fighter.get("cooldowns", [])
		if slot >= 0 and slot < abilities.size() and slot < cooldowns.size():
			var ability: Dictionary = abilities[slot]
			label = str(ability.name)
			remaining = float(cooldowns[slot])
			duration = float(ability.cooldown)
			short_on_resource = float(_fighter.get("meter", 0.0)) < float(ability.cost)
	elif button > 0:
		label = "Skill %d" % button
	var unavailable := remaining > 0.0 or short_on_resource
	var flare := clampf((_cue_until[button] - Time.get_ticks_msec()) / 230.0, 0.0, 1.0)
	var border := accent.darkened(0.42) if unavailable else accent
	if held or flare > 0.0:
		border = accent.lightened(maxf(flare * 0.5, 0.22 if held else 0.0))
	draw_circle(center + Vector2(0, 3), radius + 4.0, Color(0.02, 0.02, 0.03, 0.7), true, -1.0, true)
	draw_circle(center, radius, INK.lerp(accent, 0.26 if held else 0.06), true, -1.0, true)
	draw_circle(center - Vector2(0, 1), radius - 4.0, Color(accent, 0.035 + 0.18 * flare), true, -1.0, true)
	draw_arc(center, radius, 0.0, TAU, 64, border, 2.5 if held else 2.0, true)
	draw_arc(center, radius + 1.5, -2.64, -0.5, 28, Color(border, 0.45), 1.5, true)
	draw_arc(center, radius - 5.5, -2.66, -0.48, 24, Color(border, 0.6), 1.0, true)
	if flare > 0.0:
		draw_arc(center, radius + 2.0 + (1.0 - flare) * 9.0, 0.0, TAU, 40, Color(accent.lightened(0.35), flare * 0.7), 2.0, true)
	_draw_diamond(center - Vector2(0, radius - 2.0), 3.8, border)
	if remaining > 0.0:
		var sweep := TAU * clampf(remaining / maxf(0.1, duration), 0.0, 1.0)
		draw_arc(center, radius - 4.0, -PI * 0.5, -PI * 0.5 + sweep, 64, accent, 2.8, true)
		var countdown := "%.1f" % remaining if remaining < 1.0 else str(ceili(remaining))
		_draw_centered(countdown, center + Vector2(0, 3), 24, TEXT)
	elif short_on_resource:
		_draw_glyph(glyph, center - Vector2(0, 11), border)
		var low_resource := "LOW %s" % _resource.to_upper()
		_draw_centered(low_resource, center + Vector2(0, 7), 8, TEXT)
	else:
		_draw_glyph(glyph, center - Vector2(0, 7), accent.lightened(0.13) if held else accent)
	_draw_button_label(label, center, radius, TEXT if not unavailable else TEXT.darkened(0.22))


func _draw_button_label(label: String, center: Vector2, radius: float, tint: Color) -> void:
	var font := ThemeDB.fallback_font
	var max_width := radius * 1.64
	if font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x <= max_width:
		_draw_centered(label, center + Vector2(0, 23), 12, tint)
		return
	var first := ""
	var second := ""
	for word in label.split(" ", false):
		var candidate := word if first.is_empty() else "%s %s" % [first, word]
		if second.is_empty() and font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x <= max_width:
			first = candidate
		else:
			second = word if second.is_empty() else "%s %s" % [second, word]
	if first.is_empty():
		first = second
		second = ""
	_draw_centered(_clip_label(first, max_width), center + Vector2(0, 18), 11, tint)
	if not second.is_empty():
		_draw_centered(_clip_label(second, max_width * 0.88), center + Vector2(0, 29), 11, tint)


func _clip_label(label: String, width: float) -> String:
	var font := ThemeDB.fallback_font
	if font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x <= width:
		return label
	while font.get_string_size(label + "…", HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x > width and not label.is_empty():
		label = label.left(-1)
	return label + "…"


func _draw_centered(label: String, baseline: Vector2, font_size: int, tint: Color) -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, baseline - Vector2(width * 0.5, 0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, tint)


func _draw_diamond(center: Vector2, radius: float, tint: Color) -> void:
	var points := PackedVector2Array()
	for angle in 4:
		points.append(center + Vector2.UP.rotated(float(angle) * PI * 0.5) * radius)
	draw_colored_polygon(points, tint)


func _draw_glyph(button: int, at: Vector2, tint: Color) -> void:
	var points := PackedVector2Array()
	match button:
		0:
			points = PackedVector2Array([Vector2(-9, 10), Vector2(6, -12), Vector2(13, -14), Vector2(11, -6), Vector2(-5, 12)])
			draw_line(at + Vector2(-12, 3), at + Vector2(2, 14), tint, 2.3, true)
		1:
			points = PackedVector2Array([Vector2(1, -15), Vector2(10, -4), Vector2(4, -5), Vector2(10, 6), Vector2(4, 12), Vector2(-6, 12), Vector2(-11, 5), Vector2(-7, -5), Vector2(-2, -2), Vector2(1, -15)])
		2:
			points = PackedVector2Array([Vector2(0, -13), Vector2(11, -8), Vector2(9, 4), Vector2(0, 12), Vector2(-9, 4), Vector2(-11, -8), Vector2(0, -13)])
			_draw_diamond(at - Vector2(0, 1), 5.0, tint)
		3:
			points = PackedVector2Array([Vector2(0, -15), Vector2(4, -5), Vector2(13, -4), Vector2(6, 2), Vector2(8, 12), Vector2(0, 7), Vector2(-8, 12), Vector2(-6, 2), Vector2(-13, -4), Vector2(-4, -5), Vector2(0, -15)])
		4:
			points = PackedVector2Array([Vector2(-13, -7), Vector2(-5, 0), Vector2(-13, 7)])
			draw_polyline(PackedVector2Array([at + Vector2(-1, -10), at + Vector2(10, 0), at + Vector2(-1, 10)]), tint, 2.8, true)
		BREAK_FREE_GLYPH:
			points = PackedVector2Array([Vector2(-3, 0), Vector2(-9, 0), Vector2(-13, 5), Vector2(-13, 9), Vector2(-9, 13), Vector2(-5, 13), Vector2(0, 8), Vector2(0, 4)])
			var other_link := PackedVector2Array()
			for point in points:
				other_link.append(at - point)
			draw_polyline(other_link, tint, 2.2, true)
			draw_line(at + Vector2(-9, -7), at + Vector2(-6, -3), tint, 2.2, true)
			draw_line(at + Vector2(7, 5), at + Vector2(11, 8), tint, 2.2, true)
	for index in points.size():
		points[index] += at
	draw_polyline(points, tint, 2.2, true)
