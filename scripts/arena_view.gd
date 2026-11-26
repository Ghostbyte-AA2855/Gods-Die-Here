extends Node3D

signal champion_fell(local: bool)

const Regalia = preload("res://scripts/divine_regalia.gd")
const EliminationFx = preload("res://scripts/elimination_fx.gd")
const ArenaStage = preload("res://scripts/arena_stage.gd")
const CombatFx = preload("res://scripts/combat_fx.gd")
const ARENA_RADIUS := 14.0
const CAMERA_OFFSET := Vector3(0.0, 15.5, 13.5)
const TEAM_COLORS := [Color("5ae1e8"), Color("ff9471")]
const ArenaMatch = preload("res://scripts/arena_match.gd")
const CLASS_COLORS := {
	"breakwater": Color("879eaf"), "forgecaller": Color("e49c5b"),
	"threadkeeper": Color("be9ded"), "echo_duelist": Color("74c2ec"),
	"lamplighter": Color("f3c854"), "longwatch": Color("8bb374"),
	"sluicecaller": Color("4bbac1"), "glassmage": Color("98deda"),
	"blood_cantor": Color("d55e78"), "bellwarden": Color("d4b285"),
	"ash_dancer": Color("ff935a"), "winter_scribe": Color("b9d8fc"),
	"dream_shepherd": Color("cba9f3"), "chainrunner": Color("aeacbf"),
	"coilwright": Color("d4ac56"), "duskmoth": Color("bd8ab6"),
}
const EFFECT_COLORS := [Color("cbe8ff"), Color("ffd480"), Color("af9cff"), Color("8af1bd")]

var blood_enabled := true
var _eliminations := EliminationFx.new()
var _impact := 0.0
var _impact_axis := Vector3.ZERO
var _stage := ArenaStage.new()
var _fx := CombatFx.new()
var _camera: Camera3D
var _camera_focus := Vector3.ZERO
var _wanted_focus := Vector3.ZERO
var _floor_ring: MeshInstance3D
var _floor_ring_material: StandardMaterial3D
var _pawns: Dictionary = {}
var _previous_phase := ""
var _field_rings: Array[MeshInstance3D] = []


func _ready() -> void:
	_build_lighting()
	add_child(_stage)
	add_child(_fx)
	add_child(_eliminations)
	_floor_ring_material = _material(Color("537987"), Color("42818b"), true)
	_floor_ring = _ring(self, Vector3(0.0, 0.055, 0.0), 0.991, 1.0, _floor_ring_material)
	_camera = Camera3D.new()
	_camera.fov = 49.0
	_camera.position = CAMERA_OFFSET
	add_child(_camera)
	_camera.look_at(Vector3.ZERO)
	_camera.current = true


func _process(delta: float) -> void:
	_camera_focus = _camera_focus.lerp(_wanted_focus, 1.0 - exp(-5.0 * delta))
	_impact = move_toward(_impact, 0.0, delta * 1.5)
	_camera.position = CAMERA_OFFSET + _camera_focus + _impact_axis * _impact
	_camera.look_at(_camera_focus)


func set_state(fighters: Array[Dictionary], safe_radius: float, selected_target: int, phase: String, fields: Array = []) -> void:
	if phase == "idle" or (phase == "active" and _previous_phase != "active"):
		_eliminations.clear()
	var active_fighters: Dictionary = {}
	for fighter in fighters:
		active_fighters[fighter["id"]] = fighter
	for fighter in fighters:
		var fighter_id: int = fighter["id"]
		var team: int = fighter["team"]
		var route: Vector2 = fighter["position"]
		var facing: Vector2 = fighter["facing"]
		var alive: bool = fighter["alive"]
		var health: float = fighter["health"]
		var health_ratio := clampf(health / maxf(1.0, fighter["max_health"]), 0.0, 1.0)
		var class_id: String = fighter["class_id"]
		if not _pawns.has(fighter_id) or _pawns[fighter_id]["class_id"] != class_id:
			if _pawns.has(fighter_id):
				_free_pawn(_pawns[fighter_id])
			_pawns[fighter_id] = _create_pawn(fighter_id, class_id, team, health)

		var pawn: Dictionary = _pawns[fighter_id]
		var piece: Node3D = pawn["node"]
		var rig: Node3D = pawn["rig"]
		var fill: MeshInstance3D = pawn["fill"]
		var selection: MeshInstance3D = pawn["selection"]
		var previous_health: float = pawn["health"]
		piece.position = Vector3(route.x, 0.0, route.y)
		if not alive and piece.visible and previous_health > 0.0 and _previous_phase == "active":
			_eliminations.play(pawn, piece.position, facing, blood_enabled)
			champion_fell.emit(fighter_id == 0)
			if fighter_id == 0:
				_impact = 0.23
				_impact_axis = Vector3(facing.x, 0.14, facing.y)
		piece.visible = alive
		if facing.length_squared() > 0.01:
			rig.rotation.y = atan2(-facing.x, -facing.y)
		_fx.animate_fighter(pawn, fighter, get_process_delta_time() if phase == "active" else 0.0)
		fill.scale.x = maxf(0.001, health_ratio)
		fill.position.x = -(1.24 * (1.0 - health_ratio)) / 2.0
		selection.visible = fighter_id == selected_target
		_update_status(pawn, fighter, active_fighters, phase == "active")
		if _previous_phase == "active":
			if health < previous_health:
				_float_amount(piece.position, roundi(previous_health - health), Color("ffcfbb"))
			elif health > previous_health and previous_health > 0.0:
				_float_amount(piece.position, roundi(health - previous_health), Color("aaf2c6"))
		pawn["health"] = health

		if fighter_id == 0:
			_wanted_focus = Vector3(route.x * 0.44, 0.0, route.y * 0.38)

	for fighter_id in _pawns.keys():
		if not active_fighters.has(fighter_id):
			_free_pawn(_pawns[fighter_id])
			_pawns.erase(fighter_id)

	if fighters.is_empty():
		_wanted_focus = Vector3.ZERO
	var radius := clampf(safe_radius, 0.5, ARENA_RADIUS)
	_floor_ring.visible = phase == "active" and radius < ARENA_RADIUS - 0.01
	_floor_ring.scale = Vector3(radius, 1.0, radius)
	_floor_ring_material.emission = Color("fa8a66") if radius < ARENA_RADIUS - 0.1 else Color("42818b")
	_update_fields(fields if phase == "active" else [])
	_previous_phase = phase


func set_stage(map_id: String, terrain: Array, zones: Array) -> void:
	_stage.set_map(map_id, terrain, zones)


func play_cast(event: Dictionary) -> void:
	_fx.play_cast(event, _pawns)
	if event.source_id == 0 and not event.get("affected_ids", []).is_empty() and event.slot != 0:
		var direction: Vector2 = event.destination - event.origin
		_impact_axis = Vector3(direction.normalized().x, 0.24, direction.normalized().y)
		_impact = 0.18 if event.slot == 7 else 0.085


func movement_vector(screen_movement: Vector2) -> Vector2:
	return screen_movement


func mouse_world_position(screen_position: Vector2) -> Vector2:
	var origin := _camera.project_ray_origin(screen_position)
	var direction := _camera.project_ray_normal(screen_position)
	var point: Variant = Plane(Vector3.UP, 0.0).intersects_ray(origin, direction)
	if point is Vector3:
		return Vector2(point.x, point.z)
	return Vector2.ZERO


func pick_target(screen_position: Vector2, fighters: Array[Dictionary]) -> int:
	var closest_id := -1
	var closest_distance := 36.0
	for fighter in fighters:
		if not fighter["alive"]:
			continue
		var route: Vector2 = fighter["position"]
		var torso := Vector3(route.x, 1.05, route.y)
		if _camera.is_position_behind(torso):
			continue
		var distance := _camera.unproject_position(torso).distance_to(screen_position)
		if distance < closest_distance:
			closest_id = fighter["id"]
			closest_distance = distance
	return closest_id


func flash_ability(fighter_id: int, slot: int, target_id: int) -> void:
	if not _pawns.has(fighter_id):
		return
	var source: Node3D = _pawns[fighter_id]["node"]
	var destination: Vector3 = source.position
	var class_id: String = _pawns[fighter_id]["class_id"]
	var kit: Dictionary = ArenaMatch.CLASS_INFO[class_id]
	var color: Color = EFFECT_COLORS[posmod(slot, EFFECT_COLORS.size())]
	if slot >= 0 and slot < kit.abilities.size():
		var destination_type: String = kit.abilities[slot].get("target", "self")
		if destination_type in ["enemy", "ally"] and _pawns.has(target_id):
			destination = _pawns[target_id]["node"].position
		color = CLASS_COLORS.get(class_id, color)
	var material := _material(color, color, true)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var wave := _ring(self, destination + Vector3.UP * 0.055, 0.26, 0.33, material)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(wave, "scale", Vector3(4.5, 1.0, 4.5), 0.28)
	tween.tween_property(material, "albedo_color:a", 0.0, 0.28)
	tween.tween_property(material, "emission_energy_multiplier", 0.0, 0.28)
	tween.chain().tween_callback(wave.queue_free)


func _update_status(pawn: Dictionary, fighter: Dictionary, active_fighters: Dictionary, active: bool) -> void:
	var can_show: bool = active and fighter["alive"]
	var trail: MeshInstance3D = pawn["trail"]
	var guard_link: MeshInstance3D = pawn["guard_link"]
	var guard_target: int = fighter.get("guard_target", -1)
	trail.visible = can_show and fighter.get("echo_time", 0.0) > 0.0
	if trail.visible:
		_place_line(trail, fighter["echo_start"], fighter["echo_end"], 0.051)
	guard_link.visible = (
		can_show and fighter.get("guard_time", 0.0) > 0.0
		and active_fighters.has(guard_target) and active_fighters[guard_target]["alive"]
	)
	if guard_link.visible:
		var source: Vector2 = fighter["position"]
		var target: Vector2 = active_fighters[guard_target]["position"]
		guard_link.visible = source.distance_squared_to(target) <= 36.0
		_place_line(guard_link, source, target, 0.8)
	pawn["brace"].visible = can_show and fighter.get("brace", 0.0) > 0.0
	pawn["wound"].visible = can_show and fighter.get("wound_time", 0.0) > 0.0
	pawn["mending"].visible = can_show and fighter.get("mend_time", 0.0) > 0.0

	var effects: Array[String] = []
	if fighter.get("stun", 0.0) > 0.0:
		effects.append("STUN")
	var statuses: Dictionary = fighter.get("statuses", {})
	for effect: Dictionary in statuses.values():
		var tag := str(effect.kind).to_upper()
		if not effects.has(tag):
			effects.append(tag)
	if fighter.get("shield_hp", 0.0) > 0.0:
		effects.append("WARD")
	pawn.status_label.text = " · ".join(effects.slice(0, 3))
	pawn.status_label.visible = can_show and not effects.is_empty()


func _update_fields(fields: Array) -> void:
	# Rings follow the live field list, including any moving fields. The
	# caster's team controls the rim color and the label states its effect.
	while _field_rings.size() > fields.size():
		_field_rings.pop_back().queue_free()
	for index in fields.size():
		var field: Dictionary = fields[index]
		if index == _field_rings.size():
			var ring := _ring(self, Vector3.ZERO, 0.96, 1.0, _material(Color.WHITE, Color.WHITE, true))
			var marker := _label(ring, Vector3(0, 0.22, -0.9), "", Color.WHITE, 0.0045)
			marker.name = "Effect"
			marker.top_level = true
			_field_rings.append(ring)
		var ring: MeshInstance3D = _field_rings[index]
		var radius: float = maxf(0.01, field.radius)
		var point: Vector2 = field.position
		var tint: Color = TEAM_COLORS[field.team]
		ring.position = Vector3(point.x, 0.07 + float(index % 6) * 0.005, point.y)
		ring.scale = Vector3(radius, 1.0, radius)
		var material: StandardMaterial3D = ring.material_override
		material.albedo_color = tint
		material.emission = tint
		var marker := ring.get_node("Effect") as Label3D
		marker.text = "%s  %s" % ["ALLY" if field.team == 0 else "RIVAL", str(field.kind).to_upper()]
		marker.global_position = Vector3(point.x, 0.24, point.y - radius * 0.85)
		marker.modulate = tint


func _place_line(line: MeshInstance3D, start: Vector2, finish: Vector2, height: float) -> void:
	var difference := finish - start
	var middle := (start + finish) * 0.5
	line.position = Vector3(middle.x, height, middle.y)
	line.rotation.y = atan2(difference.x, difference.y)
	line.scale.z = maxf(0.001, difference.length())


func _free_pawn(pawn: Dictionary) -> void:
	pawn["node"].queue_free()
	pawn["trail"].queue_free()
	pawn["guard_link"].queue_free()


func _build_lighting() -> void:
	var world_environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("17111d")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("a493b2")
	settings.ambient_light_energy = 0.75
	settings.fog_enabled = true
	settings.fog_light_color = Color("2e1d33")
	settings.fog_density = 0.012
	world_environment.environment = settings
	add_child(world_environment)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-52.0, -32.0, 0.0)
	key.light_color = Color("ffe0b7")
	key.light_energy = 1.0
	key.shadow_enabled = true
	add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-30.0, 148.0, 0.0)
	fill.light_color = Color("75a8eb")
	fill.light_energy = 0.45
	add_child(fill)


func _create_pawn(fighter_id: int, class_id: String, team: int, health: float) -> Dictionary:
	var piece := Node3D.new()
	add_child(piece)
	var rig := Node3D.new()
	piece.add_child(rig)
	var team_color: Color = TEAM_COLORS[team]
	var class_color: Color = CLASS_COLORS.get(class_id, team_color)
	var cloth := _material(class_color.darkened(0.63))
	var accent := _material(class_color, class_color.darkened(0.36))
	var edge := _material(team_color, team_color.darkened(0.83))
	var dark := _material(Color("18151c"))
	var iron := _material(Color("8797a1"))
	var bronze := _material(Color("c9ad7c"))
	var cream := _material(Color("f3d0a0"))
	var eye := _material(Color("eafcff"), team_color, true)

	match class_id:
		"breakwater":
			_legs(rig, 0.24, dark)
			_box(rig, Vector3(0.0, 0.98, 0.0), Vector3(0.78, 0.79, 0.49), cloth)
			_box(rig, Vector3(0.0, 1.04, -0.262), Vector3(0.24, 0.57, 0.09), edge)
			for side in [-1.0, 1.0]:
				_box(rig, Vector3(side * 0.46, 1.13, 0.0), Vector3(0.34, 0.35, 0.46), iron)
			_cylinder(rig, Vector3(0.0, 1.58, 0.0), 0.31, 0.4, dark, 8)
			_box(rig, Vector3(0.0, 1.64, -0.277), Vector3(0.34, 0.068, 0.09), eye)
			_box(rig, Vector3(-0.49, 0.84, -0.36), Vector3(0.51, 0.85, 0.17), bronze)
			_box(rig, Vector3(-0.49, 0.86, -0.47), Vector3(0.38, 0.69, 0.1), cloth)
			_box(rig, Vector3(-0.49, 0.86, -0.53), Vector3(0.077, 0.42, 0.04), edge)
			_box(rig, Vector3(0.57, 0.77, -0.26), Vector3(0.1, 0.8, 0.115), iron).rotate_z(-0.27)
		"threadkeeper":
			_cone(rig, Vector3(0.0, 0.54, 0.0), 0.26, 0.48, 0.92, cloth, 8)
			_cone(rig, Vector3(0.0, 1.11, 0.0), 0.28, 0.27, 0.55, cloth, 8)
			_box(rig, Vector3(0.0, 0.86, 0.0), Vector3(0.61, 0.09, 0.53), bronze)
			_cylinder(rig, Vector3(0.0, 1.61, 0.0), 0.258, 0.46, dark, 8)
			_sphere(rig, Vector3(0.0, 1.57, -0.143), 0.155, cream)
			_box(rig, Vector3(0.55, 0.97, -0.12), Vector3(0.087, 1.57, 0.085), bronze)
			_sphere(rig, Vector3(0.55, 1.82, -0.12), 0.16, eye)
		"echo_duelist":
			_legs(rig, 0.18, dark)
			_cone(rig, Vector3(0.0, 1.0, 0.0), 0.32, 0.22, 0.71, cloth, 8)
			_box(rig, Vector3(0.0, 0.84, 0.01), Vector3(0.53, 0.1, 0.49), bronze)
			_sphere(rig, Vector3(0.0, 1.53, 0.0), 0.25, dark)
			_box(rig, Vector3(0.0, 1.58, -0.218), Vector3(0.29, 0.056, 0.09), eye)
			_box(rig, Vector3(-0.24, 1.15, 0.18), Vector3(0.12, 0.49, 0.12), edge).rotate_x(0.53)
			for side in [-1.0, 1.0]:
				_box(rig, Vector3(side * 0.35, 0.98, 0.0), Vector3(0.22, 0.36, 0.24), cloth)
				_box(rig, Vector3(side * 0.53, 0.82, -0.21), Vector3(0.09, 0.61, 0.094), iron).rotate_z(side * -0.47)

		_:
			_build_class_figure(rig, class_id, cloth, accent, dark, iron, bronze, edge)

	Regalia.dress(self, rig, class_id)
	_ring(piece, Vector3.UP * 0.045, 0.52, 0.57, edge)
	if fighter_id == 0:
		var local_indicator := _material(Color("f4e6cd"), Color("c6ccb5"), true)
		_ring(piece, Vector3.UP * 0.05, 0.68, 0.73, local_indicator)
	var gold := _material(Color("ffe5a6"), Color("ffd178"), true)
	var selection := _ring(piece, Vector3.UP * 0.066, 0.80, 0.87, gold)
	selection.visible = false
	var trail_color := team_color.lerp(Color("a981fb"), 0.51)
	var trail := _box(self, Vector3.ZERO, Vector3(0.26, 0.03, 1.0), _material(trail_color, trail_color, true))
	var trail_tint := _material(Color(trail_color, 0.2), Color.BLACK, true)
	trail_tint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_box(trail, Vector3.DOWN * 0.008, Vector3(2.7, 0.012, 1.0), trail_tint)
	var guard_link := _box(self, Vector3.ZERO, Vector3(0.024, 0.022, 1.0), gold)
	var brace := _box(rig, Vector3(0.0, 0.82, -0.61), Vector3(0.93, 0.13, 0.08), gold)
	var wound := _ring(piece, Vector3.UP * 0.115, 0.58, 0.66, _material(Color("db9dff"), Color("ae59de"), true))
	var mend := _ring(piece, Vector3.UP * 0.125, 0.93, 0.98, _material(Color("b8f7cb"), Color("74e39d"), true))

	var top := _label(piece, Vector3(0.0, 2.26, 0.0), str(ArenaMatch.CLASS_INFO[class_id].name).to_upper(), team_color, 0.0056)
	if fighter_id == 0:
		top.text += "  /  YOU"
	var status_label := _label(piece, Vector3(0, 2.57, 0), "", Color("f2dca9"), 0.0051)
	var bar_back := _material(Color("141a24"), Color.BLACK, true)
	bar_back.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	var bar_fill := _material(team_color, Color.BLACK, true)
	bar_fill.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_quad(piece, Vector3(0.0, 2.05, 0.0), Vector2(1.32, 0.12), bar_back)
	var fill := _quad(piece, Vector3(0.0, 2.05, 0.007), Vector2(1.24, 0.063), bar_fill)
	return {
		"node": piece, "rig": rig, "fill": fill, "selection": selection, "health": health,
		"class_id": class_id, "trail": trail, "guard_link": guard_link, "brace": brace,
		"wound": wound, "mending": mend, "status_label": status_label,
	}


func _build_class_figure(rig: Node3D, class_id: String, cloth: Material, accent: Material,
		dark: Material, iron: Material, bronze: Material, trim: Material) -> void:
	var archetype: String = ArenaMatch.CLASS_INFO[class_id].archetype
	match archetype:
		"guard":
			_legs(rig, 0.26, dark)
			_box(rig, Vector3(0, 0.99, 0), Vector3(0.85, 0.83, 0.5), cloth)
			for side in [-1, 1]:
				_box(rig, Vector3(side * 0.46, 1.25, 0), Vector3(0.33, 0.29, 0.46), iron)
		"healer", "ranged":
			_cone(rig, Vector3(0, 0.54, 0), 0.25, 0.47, 0.96, cloth, 8)
			_cone(rig, Vector3(0, 1.11, 0), 0.31, 0.24, 0.58, cloth, 8)
		_:
			_legs(rig, 0.2, dark)
			_cone(rig, Vector3(0, 0.99, 0), 0.34, 0.23, 0.76, cloth, 8)
	_sphere(rig, Vector3(0, 1.55, 0), 0.25, dark)
	_box(rig, Vector3(0, 1.57, -0.217), Vector3(0.3, 0.055, 0.09), trim)
	_box(rig, Vector3(0, 0.82, 0), Vector3(0.59, 0.1, 0.53), bronze)
	match class_id:
		"forgecaller":
			_box(rig, Vector3(0.55, 0.93, 0), Vector3(0.12, 1.02, 0.13), bronze).rotate_z(-0.25)
			_box(rig, Vector3(0.67, 1.39, 0), Vector3(0.57, 0.36, 0.33), iron)
			_box(rig, Vector3(0.67, 1.39, -0.18), Vector3(0.42, 0.12, 0.05), accent)
		"lamplighter":
			_box(rig, Vector3(0.53, 1.0, 0), Vector3(0.08, 1.7, 0.09), bronze)
			_box(rig, Vector3(0.69, 1.8, 0), Vector3(0.4, 0.07, 0.08), bronze)
			_cone(rig, Vector3(0.86, 1.56, 0), 0.14, 0.2, 0.27, accent, 4)
			_cone(rig, Vector3(0.86, 1.75, 0), 0.07, 0.19, 0.13, bronze, 4)
		"longwatch":
			_box(rig, Vector3(0.53, 1.25, -0.26), Vector3(0.09, 0.66, 0.08), bronze).rotate_x(0.53)
			_box(rig, Vector3(0.53, 0.70, -0.26), Vector3(0.09, 0.66, 0.08), bronze).rotate_x(-0.53)
			_box(rig, Vector3(0.53, 0.98, -0.12), Vector3(0.025, 1.08, 0.025), trim)
			_cone(rig, Vector3(0, 1.83, 0.03), 0.02, 0.31, 0.2, cloth, 6)
		"sluicecaller":
			_box(rig, Vector3(0.54, 1.0, 0), Vector3(0.08, 1.65, 0.08), iron)
			_box(rig, Vector3(0.54, 1.64, 0), Vector3(0.54, 0.1, 0.09), bronze)
			for prong in [-1, 0, 1]:
				_cone(rig, Vector3(0.54 + prong * 0.22, 1.83, 0), 0.0, 0.09, 0.38, accent, 4)
		"glassmage":
			for shard in [Vector3(-0.46, 1.35, 0), Vector3(0.5, 1.6, 0), Vector3(0.22, 2.02, 0.03)]:
				_cone(rig, shard, 0, 0.17, 0.38, accent, 4)
				_cone(rig, shard + Vector3.DOWN * 0.28, 0.17, 0, 0.18, accent, 4)
		"blood_cantor":
			for side in [-1, 1]:
				_cone(rig, Vector3(side * 0.22, 1.82, 0), 0, 0.1, 0.45, bronze, 6).rotate_z(-side * 0.43)
			_cone(rig, Vector3(0.5, 1.11, -0.13), 0.21, 0.08, 0.28, accent, 6)
			_cylinder(rig, Vector3(0.5, 0.88, -0.13), 0.06, 0.3, bronze, 6)
		"bellwarden":
			_cylinder(rig, Vector3(0.67, 1.27, -0.17), 0.065, 0.25, iron, 8)
			_cone(rig, Vector3(0.67, 0.93, -0.17), 0.16, 0.38, 0.5, bronze, 10)
			_sphere(rig, Vector3(0.67, 0.63, -0.17), 0.12, iron)
		"ash_dancer":
			for side in [-1, 1]:
				_cone(rig, Vector3(side * 0.54, 0.96, -0.1), 0.02, 0.14, 0.83, accent, 4).rotate_z(-side * 0.72)
				_cone(rig, Vector3(side * 0.18, 1.86, 0.09), 0.0, 0.10, 0.35, accent, 4)
		"winter_scribe":
			for side in [-1, 1]:
				_box(rig, Vector3(side * 0.15, 1.05, -0.48), Vector3(0.32, 0.43, 0.075), accent).rotate_y(side * 0.47)
			_cone(rig, Vector3(0.43, 1.31, -0.23), 0.015, 0.055, 0.56, iron, 5).rotate_z(-0.46)
		"dream_shepherd":
			_box(rig, Vector3(0.55, 0.99, -0.04), Vector3(0.08, 1.76, 0.09), bronze)
			_ring(rig, Vector3(0.73, 1.86, -0.04), 0.12, 0.24, accent).rotate_x(PI * 0.5)
			for side in [-1, 1]:
				_sphere(rig, Vector3(side * 0.25, 1.29, 0.03), 0.19, accent)
		"chainrunner":
			for link in range(5):
				var angle := PI * float(link) / 5.0
				_ring(rig, Vector3(0.4 + link * 0.12, 1.02 - sin(angle) * 0.19, -0.13),
					0.055, 0.09, iron).rotate_x(1.0 if link % 2 == 0 else 0.3)
			_sphere(rig, Vector3(1.01, 0.95, -0.13), 0.2, accent)
		"coilwright":
			for side in [-1, 1]:
				_cylinder(rig, Vector3(side * 0.37, 1.44, 0.18), 0.055, 0.72, iron, 6)
				for coil in range(3):
					_ring(rig, Vector3(side * 0.37, 1.34 + coil * 0.16, 0.18), 0.075, 0.15, bronze)
				_sphere(rig, Vector3(side * 0.37, 1.88, 0.18), 0.11, accent)
		"duskmoth":
			for side in [-1, 1]:
				_box(rig, Vector3(side * 0.48, 1.24, 0.16), Vector3(0.36, 0.84, 0.07), accent).rotate_z(-side * 0.67)
				_box(rig, Vector3(side * 0.37, 0.83, 0.18), Vector3(0.28, 0.44, 0.07), cloth).rotate_z(side * 0.7)


func _float_amount(point: Vector3, amount: int, color: Color) -> void:
	if amount == 0:
		return
	var position := point + Vector3(0.32, 1.8, 0.05)
	var label := _label(self, position, str(amount), color, 0.008)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", position.y + 0.69, 0.56)
	tween.tween_property(label, "modulate:a", 0.0, 0.56)
	tween.tween_property(label, "outline_modulate:a", 0.0, 0.56)
	tween.chain().tween_callback(label.queue_free)


func _legs(rig: Node3D, spread: float, material: Material) -> void:
	for side in [-1.0, 1.0]:
		_box(rig, Vector3(side * spread, 0.29, 0.0), Vector3(0.25, 0.52, 0.24), material)
		_box(rig, Vector3(side * spread, 0.094, -0.09), Vector3(0.29, 0.17, 0.42), material)


func _label(parent: Node3D, point: Vector3, caption: String, color: Color, pixels: float) -> Label3D:
	var label := Label3D.new()
	label.position = point
	label.text = caption
	label.font_size = 32
	label.pixel_size = pixels
	label.outline_size = 9
	label.modulate = color
	label.outline_modulate = Color("151f28")
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(label)
	return label


func _material(color: Color, emission := Color.BLACK, unlit := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	if emission != Color.BLACK:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = 0.58
	if unlit:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material


func _quad(parent: Node3D, point: Vector3, size: Vector2, material: Material) -> MeshInstance3D:
	var mesh := QuadMesh.new()
	mesh.size = size
	return _add_mesh(parent, point, mesh, material)


func _box(parent: Node3D, point: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _add_mesh(parent, point, mesh, material)


func _cylinder(parent: Node3D, point: Vector3, radius: float, height: float, material: Material, segments: int) -> MeshInstance3D:
	return _cone(parent, point, radius, radius, height, material, segments)


func _cone(parent: Node3D, point: Vector3, top: float, bottom: float, height: float, material: Material, segments: int) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = segments
	return _add_mesh(parent, point, mesh, material)


func _sphere(parent: Node3D, point: Vector3, radius: float, material: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 5
	return _add_mesh(parent, point, mesh, material)


func _ring(parent: Node3D, point: Vector3, inner: float, outer: float, material: Material) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner
	mesh.outer_radius = outer
	mesh.rings = 64
	mesh.ring_segments = 6
	return _add_mesh(parent, point, mesh, material)


func _add_mesh(parent: Node3D, point: Vector3, mesh: Mesh, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.position = point
	parent.add_child(node)
	return node
