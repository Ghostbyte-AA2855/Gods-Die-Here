extends Control

const ArenaStage = preload("res://scripts/arena_stage.gd")
const IVORY := Color("fff0dc")
const INK := Color("111319")
const YOU := Color("f1d084")
const RIVAL := Color("ff9d8b")
const FIELD_STYLES := {
	"damage": {"icon": 0, "ours": "Damages rivals", "theirs": "Damages your team", "friendly": Color("ffd197"), "enemy": Color("ff927b")},
	"heal": {"icon": 1, "ours": "Heals your team", "theirs": "Heals rivals", "friendly": Color("86e9b9"), "enemy": Color("f4abbb")},
	"ward": {"icon": 2, "ours": "Shields your team", "theirs": "Shields rivals", "friendly": Color("96d5ff"), "enemy": Color("ebaff1")},
	"slow": {"icon": 3, "ours": "Slows rivals", "theirs": "Slows your team", "friendly": Color("b9d3ff"), "enemy": Color("f1a6e1")},
}
const CAST_SECONDS := 1.15

var _camera: Camera3D
var _zones: Array = []
var _fields: Array = []
var _player := Vector2.ZERO
var _focus_fighters: Array[Vector2] = []
var _relic: Dictionary = {}
var _ultimate_banner_visible := false
var _casts: Dictionary = {}
var _running := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hide()


func update_battle(camera: Camera3D, zones: Array, fields: Array, fighters: Array[Dictionary], target: int, running: bool, relic: Dictionary = {}, ultimate_banner: bool = false) -> void:
	_camera = camera
	_zones = zones
	_fields = fields
	_relic = relic
	_ultimate_banner_visible = ultimate_banner
	_focus_fighters.clear()
	if not fighters.is_empty():
		_player = fighters[0].position
		if fighters[0].alive:
			_focus_fighters.append(_player)
	if target > 0 and target < fighters.size() and fighters[target].alive:
		_focus_fighters.append(fighters[target].position)
	_running = running
	visible = running
	if running:
		queue_redraw()


func clear_casts() -> void:
	_casts.clear()


func record_cast(event: Dictionary, target: int) -> void:
	if int(event.slot) == 0:
		return
	var role := ""
	if event.source_id == 0:
		role = "YOU"
	elif event.team == 1 and (event.source_id == target or 0 in event.affected_ids or event.target_id == 0):
		role = "RIVAL"
	if role.is_empty():
		return
	_casts[role] = {"event": event, "remaining": CAST_SECONDS}


func _process(delta: float) -> void:
	if not _running:
		return
	for role in _casts.keys():
		var cast: Dictionary = _casts[role]
		cast.remaining -= delta
		if cast.remaining <= 0.0:
			_casts.erase(role)


func _draw() -> void:
	if not _running or not is_instance_valid(_camera):
		return
	# The guides yield to HUD panels and never block a thumb control.
	var occupied: Array[Rect2] = [
		Rect2(0, 0, size.x, 222 if _ultimate_banner_visible else 190),
		Rect2(0, 114, 345, 72),
		Rect2(size.x - 345, 114, 345, 72),
		Rect2(0, size.y * 0.59, 268, size.y * 0.41),
		Rect2(size.x - 327, size.y - 300, 327, 300),
	]
	if not _relic.is_empty():
		occupied.append(Rect2(size.x * 0.5 - 232, size.y - 122, 464, 122))
	for point in _focus_fighters:
		var head := _project(point, 2.65)
		var foot := _project(point, 0.0)
		occupied.append(Rect2(head - Vector2(38, 13), Vector2(76, maxf(20.0, foot.y - head.y + 23.0))))
	for role: String in _casts:
		var cast: Dictionary = _casts[role]
		var event: Dictionary = cast.event
		var origin: Vector2 = event.get("source_after", event.origin)
		var color := YOU if role == "YOU" else RIVAL
		color.a = clampf(cast.remaining / 0.24, 0.0, 1.0)
		_draw_tag(_project(origin, 2.45), "%s · %s" % [role, event.name], "", color, -56.0, occupied)
	for zone: Dictionary in _zones:
		if zone.phase != "idle":
			_draw_zone(zone, occupied)
	if not _relic.is_empty():
		_draw_relic(occupied)
	var nearest_fields := _fields.duplicate()
	nearest_fields.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _player.distance_squared_to(a.position) < _player.distance_squared_to(b.position)
	)
	var placed_fields := 0
	for field: Dictionary in nearest_fields:
		if placed_fields >= 3:
			break
		if _draw_field(field, occupied):
			placed_fields += 1


func _draw_zone(zone: Dictionary, occupied: Array[Rect2]) -> void:
	var guide: Dictionary = ArenaStage.ZONE_GUIDE.get(zone.kind, {})
	if guide.is_empty():
		return
	var active: bool = zone.phase == "active"
	var heading := "%s · %s%d s" % [guide.name, "" if active else "in ", ceili(zone.phase_left)]
	var tint: Color = guide.active_tint if active else YOU
	var rim: Vector2 = zone.position + Vector2(0, zone.radius * 0.52)
	_draw_tag(_project(rim), heading, guide.effect, tint, 28.0, occupied)


func _draw_relic(occupied: Array[Rect2]) -> void:
	var caption: String
	var tint := YOU
	match _relic.phase:
		"arming": caption = "Opens in %d s" % ceili(_relic.time_left)
		"contested":
			caption = "Contested"
			tint = Color("e7b6ff")
		"cooldown": caption = "Reopens in %d s" % ceili(_relic.time_left)
		_:
			caption = "Hold to claim"
			if _relic.team >= 0:
				caption = "%d%% claimed" % floori(100.0 * _relic.progress / _relic.hold)
				tint = Color("93f5e2") if _relic.team == 0 else RIVAL
	var point: Vector2 = _relic.position
	var rim := point + Vector2(0, float(_relic.radius) * 0.84)
	_draw_tag(_project(rim, 0.24), _relic.name, caption, tint, 25.0, occupied)


func _draw_field(field: Dictionary, occupied: Array[Rect2]) -> bool:
	var style: Dictionary = FIELD_STYLES.get(field.kind, {})
	if style.is_empty():
		return false
	var friendly: bool = field.team == 0
	var field_name: String = field.get("name", "")
	if field_name.is_empty():
		field_name = str(field.kind).capitalize()
	var heading := "%s %s · %d s" % ["Ally" if friendly else "Rival", field_name, ceili(field.remaining)]
	var rim: Vector2 = field.position + Vector2(0, field.radius * 0.53)
	return _draw_tag(_project(rim), heading, style.ours if friendly else style.theirs, style.friendly if friendly else style.enemy, 29.0, occupied)


func _project(point: Vector2, height: float = 0.09) -> Vector2:
	var world := Vector3(point.x, height, point.y)
	if _camera.is_position_behind(world):
		return Vector2(-2000, -2000)
	return _camera.unproject_position(world)


func _draw_tag(anchor: Vector2, heading: String, effect: String, tint: Color, offset: float, occupied: Array[Rect2]) -> bool:
	if not Rect2(16, 156, size.x - 32, size.y - 170).has_point(anchor):
		return false
	var font := ThemeDB.fallback_font
	var width := maxf(_width(font, heading, 17), _width(font, effect, 15)) + 26.0
	var height := 29.0 if effect.is_empty() else 51.0
	var requested := Rect2(anchor + Vector2(-width * 0.5, offset), Vector2(width, height))
	for nudge: Vector2 in [Vector2.ZERO, Vector2(-112, 2), Vector2(112, 2), Vector2(0, 55), Vector2(-152, 52), Vector2(152, 52), Vector2(0, -height - 33)]:
		var rect := Rect2(requested.position + nudge, requested.size)
		if not Rect2(12, 157, size.x - 24, size.y - 170).encloses(rect):
			continue
		if occupied.any(func(other: Rect2) -> bool: return other.intersects(rect.grow(6.0))):
			continue
		occupied.append(rect)
		var pointer := Vector2(clampf(anchor.x, rect.position.x + 9, rect.end.x - 9), rect.position.y if anchor.y < rect.position.y else rect.end.y)
		draw_line(anchor, pointer, Color(INK, tint.a * 0.96), 4.2, true)
		draw_line(anchor, pointer, Color(tint, tint.a * 0.82), 1.6, true)
		draw_circle(anchor, 2.7, tint, true, -1.0, true)
		draw_rect(rect, Color(INK, tint.a * 0.90))
		draw_rect(rect, Color(tint, tint.a * 0.72), false, 1.0)
		_center_text(font, heading, rect.get_center().x, rect.position.y + 20, 17, tint.lightened(0.20))
		if not effect.is_empty():
			_center_text(font, effect, rect.get_center().x, rect.position.y + 41, 15, Color(IVORY, tint.a))
		return true
	return false


func _width(font: Font, caption: String, pixels: int) -> float:
	return font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, pixels).x


func _center_text(font: Font, caption: String, center: float, baseline: float, pixels: int, tint: Color) -> void:
	draw_string(font, Vector2(center - _width(font, caption, pixels) * 0.5, baseline), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, pixels, tint)
