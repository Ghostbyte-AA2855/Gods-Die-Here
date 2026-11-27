extends Node3D

signal champion_fell(local: bool)
signal cast_released(event: Dictionary)
signal ultimate_started(windup: Dictionary)

const ChampionModel = preload("res://scripts/champions/model.gd")
const EliminationFx = preload("res://scripts/elimination_fx.gd")
const ArenaStage = preload("res://scripts/arena_stage.gd")
const CombatFx = preload("res://scripts/combat_fx.gd")
const UltimateFx = preload("res://scripts/fx/ultimate_fx.gd")
const GroundContact = preload("res://scripts/fx/ground_contact.gd")
const BattleGuides = preload("res://scripts/mobile_battle_guides.gd")
const FIELD_MARKER_SHADER = preload("res://scripts/fx/field_marker.gdshader")
const ARENA_RADIUS := 14.0
const CAMERA_OFFSET := Vector3(0.0, 15.5, 13.5)
const PHONE_CAMERA_NEAR := Vector3(0.0, 10.8, 11.9)
const PHONE_CAMERA_WIDE := Vector3(0.0, 15.3, 14.6)
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
const ARENA_LIGHT := {
	"lockwater": [Color("111e29"), Color("ffd4a4"), Color("72b9e4")],
	"kiln": [Color("251718"), Color("ffce9d"), Color("a399ce")],
	"orchard": [Color("121c1b"), Color("ffe8bd"), Color("86bbab")],
	"quarry": [Color("251d19"), Color("ffd4a4"), Color("a4b9e1")],
	"observatory": [Color("181929"), Color("ffe1c1"), Color("9fa8f4")],
}
const COURT_DUST := {
	"lockwater": Color("8c9798"),
	"kiln": Color("d1a079"),
	"orchard": Color("a5a085"),
	"quarry": Color("b6a179"),
	"observatory": Color("929dba"),
}
const STEP_CLIPS := ["run", "backpedal", "strafe_left", "strafe_right"]

var blood_enabled := true
var phone_camera := false
var reduced_motion := false
var presentation_paused := false:
	set(value):
		if value != presentation_paused:
			presentation_paused = value
			process_mode = Node.PROCESS_MODE_DISABLED if value else Node.PROCESS_MODE_INHERIT
var _eliminations := EliminationFx.new()
var _impact := 0.0
var _impact_axis := Vector3.ZERO
var _stage := ArenaStage.new()
var _fx := CombatFx.new()
var _ultimate_fx := UltimateFx.new()
var _charging_ultimates: Dictionary = {}
var _ground_contact := GroundContact.new()
var _camera: Camera3D
var _camera_focus := Vector3.ZERO
var _wanted_focus := Vector3.ZERO
var _camera_spread := 1.0
var _wanted_spread := 1.0
var _floor_ring: MeshInstance3D
var _floor_ring_material: StandardMaterial3D
var _pawns: Dictionary = {}
var _previous_phase := ""
var _field_rings: Array[MeshInstance3D] = []
var _pending_casts: Array[Dictionary] = []
var _environment: Environment
var _key_light: DirectionalLight3D
var _rim_light: DirectionalLight3D
var _lighting_map := ""
var _vignette: ColorRect


func _ready() -> void:
	_build_lighting()
	add_child(_stage)
	add_child(_fx)
	add_child(_ultimate_fx)
	add_child(_eliminations)
	add_child(_ground_contact)
	if phone_camera:
		_eliminations.settled.connect(_ground_contact.hard_landing)
	_floor_ring_material = _material(Color("537987"), Color("42818b"), true)
	_floor_ring = _ring(self, Vector3(0.0, 0.055, 0.0), 0.991, 1.0, _floor_ring_material)
	_camera = Camera3D.new()
	_camera.fov = 49.0
	_camera.position = CAMERA_OFFSET
	add_child(_camera)
	_camera.look_at(Vector3.ZERO)
	_camera.current = true
	if phone_camera:
		_add_vignette()


func _process(delta: float) -> void:
	if presentation_paused:
		return
	_camera_focus = _camera_focus.lerp(_wanted_focus, 1.0 - exp(-4.6 * delta))
	_impact *= exp(-13.0 * delta)
	var offset := CAMERA_OFFSET
	if phone_camera:
		var zoom_speed := 3.4 if _wanted_spread > _camera_spread else 1.75
		_camera_spread = lerpf(_camera_spread, _wanted_spread, 1.0 - exp(-zoom_speed * delta))
		offset = PHONE_CAMERA_NEAR.lerp(PHONE_CAMERA_WIDE, _camera_spread)
		_camera.fov = lerpf(44.0, 51.0, _camera_spread)
	var nudge := Vector3.ZERO if reduced_motion else _impact_axis * _impact
	_camera.position = offset + _camera_focus + nudge
	_camera.look_at(_camera_focus)
	var index := 0
	while index < _pending_casts.size():
		var cast: Dictionary = _pending_casts[index]
		cast.remaining -= delta
		if cast.remaining > 0.0:
			index += 1
			continue
		_pending_casts.remove_at(index)
		_release_cast(cast)


func set_state(fighters: Array[Dictionary], safe_radius: float, selected_target: int, phase: String, fields: Array = []) -> void:
	var entering := phase != _previous_phase and phase in ["idle", "active"]
	if entering:
		_eliminations.clear()
		_ground_contact.clear()
		_camera_spread = 1.0
		if _vignette != null:
			_vignette.visible = phase == "active"
	var active_fighters: Dictionary = {}
	var visual_delta := get_process_delta_time() if not presentation_paused else 0.0
	var active_delta := visual_delta if phase == "active" else 0.0
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
				_impact = 0.13
				_impact_axis = Vector3(facing.x, 0.0, facing.y * 0.56)
		piece.visible = alive
		if facing.length_squared() > 0.01 and not presentation_paused:
			var face_angle := atan2(-facing.x, -facing.y)
			if phone_camera and _previous_phase == "active":
				rig.rotation.y = rotate_toward(rig.rotation.y, face_angle, get_process_delta_time() * 22.0)
			else:
				rig.rotation.y = face_angle
		if alive:
			if _previous_phase != "active" and phase == "active":
				pawn.model.reset_motion()
			pawn.model.watch(fighter, active_delta)
			if phone_camera:
				_step_contact(pawn, fighter, not entering and active_delta > 0.0 and fighter_id in [0, selected_target])
		fill.scale.x = maxf(0.001, health_ratio)
		fill.position.x = -(1.24 * (1.0 - health_ratio)) / 2.0
		if phone_camera:
			_update_health_trail(pawn, health_ratio, previous_health - health, entering, visual_delta)
		selection.visible = fighter_id == selected_target
		if phone_camera:
			pawn.nameplate.visible = fighter_id == 0 or fighter_id == selected_target
		_update_status(pawn, fighter, active_fighters, phase == "active")
		if _previous_phase == "active" and previous_health > 0.0:
			var change := roundi(health - previous_health)
			var show_change := not phone_camera or (fighter_id in [0, selected_target] and absi(change) >= 4)
			if change != 0 and show_change:
				_float_amount(piece.position, absi(change), Color("ffcfbb") if change < 0 else Color("aaf2c6"))
		pawn["health"] = health

		if fighter_id == 0:
			_wanted_focus = Vector3(route.x * 0.44, 0.0, route.y * 0.38)

	for fighter_id in _pawns.keys():
		if not active_fighters.has(fighter_id):
			_free_pawn(_pawns[fighter_id])
			_pawns.erase(fighter_id)

	if fighters.is_empty():
		_wanted_focus = Vector3.ZERO
	elif phone_camera:
		_frame_phone_action(fighters, selected_target)
		if entering:
			_camera_focus = _wanted_focus
	var radius := clampf(safe_radius, 0.5, ARENA_RADIUS)
	_floor_ring.visible = phase == "active" and radius < ARENA_RADIUS - 0.01
	_floor_ring.scale = Vector3(radius, 1.0, radius)
	_floor_ring_material.emission = Color("fa8a66") if radius < ARENA_RADIUS - 0.1 else Color("42818b")
	_update_fields(fields if phase == "active" else [])
	_previous_phase = phase


func set_stage(map_id: String, terrain: Array, zones: Array) -> void:
	_stage.set_map(map_id, terrain, zones)
	if map_id != _lighting_map:
		_lighting_map = map_id
		var palette: Array = ARENA_LIGHT.get(map_id, ARENA_LIGHT.lockwater)
		_environment.background_color = palette[0]
		_environment.fog_light_color = palette[0].lightened(0.09)
		_key_light.light_color = palette[1]
		_rim_light.light_color = palette[2]
		_ground_contact.set_surface_color(COURT_DUST.get(map_id, COURT_DUST.lockwater))


func play_cast(event: Dictionary) -> void:
	var source: Dictionary = _pawns.get(event.source_id, {})
	if event.get("ultimate", false):
		_release_ultimate(event, source)
		return
	var cast := {"event": event, "remaining": 0.0, "hand": Vector3.UP, "source": null}
	if not source.is_empty() and source.node.visible and not _charging_ultimates.has(event.source_id):
		cast.remaining = float(source.model.cast(event.slot))
		cast.source = source.node
		cast.hand = source.model.release_point(event.slot) - source.node.global_position
	if cast.remaining <= 0.0:
		_release_cast(cast)
		return
	# Bound pending effects if a long frame delivers many combat events together.
	if _pending_casts.size() >= 24:
		_release_cast(_pending_casts.pop_front())
	var windup := event.duplicate()
	windup.hand_origin = _event_origin(event) + cast.hand
	_fx.play_windup(windup, cast.remaining)
	_pending_casts.append(cast)


func clear_casts() -> void:
	_pending_casts.clear()
	_fx.clear()
	for source_id: int in _charging_ultimates.keys():
		_cancel_ultimate_motion(source_id)
	_charging_ultimates.clear()
	_ultimate_fx.clear()
	_stage.set_objective({})
	_ground_contact.clear()
	_impact = 0.0


func update_specials(objective: Dictionary, windups: Array) -> void:
	_stage.set_objective(objective)
	_ultimate_fx.update_windups(windups)
	var active_sources: Dictionary = {}
	for windup: Dictionary in windups:
		var source_id: int = windup.source_id
		active_sources[source_id] = true
		if _charging_ultimates.has(source_id):
			continue
		_charging_ultimates[source_id] = true
		var pawn: Dictionary = _pawns.get(source_id, {})
		if not pawn.is_empty() and pawn.node.visible:
			pawn.model.play_ultimate_windup(windup.remaining)
		ultimate_started.emit(windup)
	for source_id: int in _charging_ultimates.keys():
		if not active_sources.has(source_id):
			_cancel_ultimate_motion(source_id)
			_charging_ultimates.erase(source_id)


func _cancel_ultimate_motion(source_id: int) -> void:
	var pawn: Dictionary = _pawns.get(source_id, {})
	if not pawn.is_empty():
		pawn.model.cancel_ultimate()


func _release_ultimate(event: Dictionary, source: Dictionary) -> void:
	_charging_ultimates.erase(event.source_id)
	var presentation := event.duplicate()
	if not source.is_empty() and source.node.visible:
		source.model.release_ultimate()
		presentation.hand_origin = source.model.release_point(8)
	_ultimate_fx.play_impact(presentation)
	cast_released.emit(event)
	if event.source_id == 0 or 0 in event.affected_ids:
		var aim: Vector2 = (event.destination as Vector2) - (event.origin as Vector2)
		if aim.is_zero_approx():
			aim = event.facing
		var heading := aim.normalized()
		_impact_axis = Vector3(heading.x, 0.0, heading.y * 0.54)
		_impact = 0.28


func _release_cast(cast: Dictionary) -> void:
	var event: Dictionary = cast.event
	var presentation := event.duplicate()
	var hand: Vector3 = cast.hand
	var source: Dictionary = _pawns.get(event.source_id, {})
	if is_instance_valid(cast.source) and source.get("node") == cast.source and cast.source.visible:
		if source.model.player.current_animation == "cast_%d" % (event.slot + 1):
			hand = source.model.release_point(event.slot) - cast.source.global_position
	# Preserve the cast origin even if the rig has dashed to its destination.
	presentation.hand_origin = _event_origin(event) + hand
	_fx.play_cast(presentation)
	cast_released.emit(event)
	if event.source_id == 0 and not event.get("affected_ids", []).is_empty() and event.slot != 0:
		var direction: Vector2 = event.destination - event.origin
		_impact_axis = Vector3(direction.normalized().x, 0.0, direction.normalized().y * 0.56)
		_impact = 0.115 if event.slot == 7 else 0.058


func _event_origin(event: Dictionary) -> Vector3:
	return Vector3(event.origin.x, 0.0, event.origin.y)


func _frame_phone_action(fighters: Array[Dictionary], selected_target: int) -> void:
	var human: Dictionary = fighters[0]
	var anchor: Vector2 = human.position
	var encounter := Vector2.ZERO
	var living_center_sum := Vector2.ZERO
	var count := 0
	var living := 0
	var farthest := 0.0
	for fighter in fighters:
		if not fighter.alive:
			continue
		var point: Vector2 = fighter.position
		var distance := anchor.distance_to(point)
		farthest = maxf(farthest, distance)
		living_center_sum += point
		living += 1
		if distance < 10.5:
			encounter += point
			count += 1
	if count > 0:
		anchor = anchor.lerp(encounter / float(count), 0.34 if human.alive else 0.75)
	_wanted_spread = smoothstep(6.1, 18.5, farthest)
	if living > 0:
		anchor = anchor.lerp(living_center_sum / float(living), _wanted_spread * 0.86)
	if selected_target >= 0 and selected_target < fighters.size() and fighters[selected_target].alive:
		var direction: Vector2 = fighters[selected_target].position - anchor
		anchor += direction.limit_length(6.0) * 0.26
	_wanted_focus = Vector3(clampf(anchor.x, -8.7, 8.7), 0.56, clampf(anchor.y, -7.5, 7.5))


func movement_vector(screen_movement: Vector2) -> Vector2:
	return screen_movement


func mouse_world_position(screen_position: Vector2) -> Vector2:
	var origin := _camera.project_ray_origin(screen_position)
	var direction := _camera.project_ray_normal(screen_position)
	var point: Variant = Plane(Vector3.UP, 0.0).intersects_ray(origin, direction)
	if point is Vector3:
		return Vector2(point.x, point.z)
	return Vector2.ZERO


func pick_target(screen_position: Vector2, fighters: Array[Dictionary], radius: float = 36.0) -> int:
	var closest_id := -1
	var closest_distance := radius
	for fighter in fighters:
		if not fighter["alive"]:
			continue
		var route: Vector2 = fighter["position"]
		var torso := Vector3(route.x, 1.26, route.y)
		if _camera.is_position_behind(torso):
			continue
		var distance := _camera.unproject_position(torso).distance_to(screen_position)
		if distance < closest_distance:
			closest_id = fighter["id"]
			closest_distance = distance
	return closest_id


func flash_ability(fighter_id: int, slot: int, target_id: int, dodge_landing: Variant = null) -> void:
	if not _pawns.has(fighter_id):
		return
	var source: Node3D = _pawns[fighter_id]["node"]
	if slot == -1:
		_pawns[fighter_id].model.react("dodge")
		if phone_camera and dodge_landing is Vector2:
			_ground_contact.dodge(source.position, Vector3(dodge_landing.x, 0.0, dodge_landing.y))
	elif slot == -2:
		_pawns[fighter_id].model.react("rally")
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


func _step_contact(pawn: Dictionary, fighter: Dictionary, emit_mark: bool) -> void:
	var player: AnimationPlayer = pawn.model.player
	var motion := str(player.current_animation)
	if motion not in STEP_CLIPS:
		pawn.step_phase = -1
		return
	# Authored locomotion plants the left sole at the loop seam and the
	# right sole at the halfway point. Direction changes retain gait phase.
	var step := int(player.current_animation_position / player.current_animation_length * 2.0) % 2
	var previous: int = pawn.step_phase
	pawn.step_phase = step
	if emit_mark and previous >= 0 and step != previous:
		var boot: Node3D = pawn.model.joints.foot_l if step == 0 else pawn.model.joints.foot_r
		_ground_contact.footstep(boot.global_position, fighter.facing)


func _update_health_trail(pawn: Dictionary, health_ratio: float, damage: float, entering: bool, delta: float) -> void:
	var trail: MeshInstance3D = pawn.health_trail
	if entering or health_ratio >= pawn.trail_health:
		pawn.trail_health = health_ratio
		pawn.trail_hold = 0.0
	elif damage >= 4.0:
		pawn.trail_hold = 0.12
	else:
		pawn.trail_hold = maxf(0.0, pawn.trail_hold - delta)
		if pawn.trail_hold <= 0.0:
			pawn.trail_health = move_toward(pawn.trail_health, health_ratio, delta * 1.16)
	var delayed: float = pawn.trail_health
	trail.visible = delayed > health_ratio + 0.002
	if trail.visible:
		trail.scale.x = delayed - health_ratio
		trail.position.x = 1.24 * ((health_ratio + delayed) * 0.5 - 0.5)


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
			marker.visible = not phone_camera
			if phone_camera:
				var material := ShaderMaterial.new()
				material.shader = FIELD_MARKER_SHADER
				var floor_mark := _quad(ring, Vector3.DOWN * 0.016, Vector2(2, 2), material)
				floor_mark.name = "FloorMark"
				floor_mark.rotation.x = -PI * 0.5
			_field_rings.append(ring)
		var ring: MeshInstance3D = _field_rings[index]
		var radius: float = maxf(0.01, field.radius)
		var point: Vector2 = field.position
		var tint: Color = TEAM_COLORS[field.team]
		if phone_camera:
			var style: Dictionary = BattleGuides.FIELD_STYLES[field.kind]
			tint = style.friendly if field.team == 0 else style.enemy
			var floor_mark := ring.get_node("FloorMark") as MeshInstance3D
			var floor_material := floor_mark.material_override as ShaderMaterial
			floor_material.set_shader_parameter("tint", tint)
			floor_material.set_shader_parameter("motif", style.icon)
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
	_environment = Environment.new()
	_environment.background_mode = Environment.BG_COLOR
	_environment.background_color = Color("161521")
	_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_environment.ambient_light_color = Color("a2abc2")
	_environment.ambient_light_energy = 0.58
	_environment.fog_enabled = true
	_environment.fog_light_color = Color("282333")
	_environment.fog_density = 0.015
	_environment.fog_sky_affect = 0.0
	world_environment.environment = _environment
	add_child(world_environment)

	_key_light = DirectionalLight3D.new()
	_key_light.rotation_degrees = Vector3(-48.0, -40.0, 0.0)
	_key_light.light_color = Color("ffe0b7")
	_key_light.light_energy = 1.21
	_key_light.shadow_enabled = true
	_key_light.directional_shadow_max_distance = 40.0
	if phone_camera:
		_key_light.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	add_child(_key_light)
	_rim_light = DirectionalLight3D.new()
	_rim_light.rotation_degrees = Vector3(-29.0, 143.0, 0.0)
	_rim_light.light_color = Color("75a8eb")
	_rim_light.light_energy = 0.69
	add_child(_rim_light)


func _add_vignette() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 0
	add_child(layer)
	_vignette = ColorRect.new()
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_vignette)
	_vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_vignette.hide()
	var shader := Shader.new()
	shader.code = """
		shader_type canvas_item;
		render_mode unshaded;
		void fragment() {
			vec2 at = (UV - vec2(0.50, 0.48)) * vec2(1.60, 1.36);
			float falloff = smoothstep(0.44, 1.02, length(at));
			COLOR = vec4(0.034, 0.025, 0.042, falloff * 0.49);
		}
	"""
	var shade := ShaderMaterial.new()
	shade.shader = shader
	_vignette.material = shade


func _create_pawn(fighter_id: int, class_id: String, team: int, health: float) -> Dictionary:
	var piece := Node3D.new()
	add_child(piece)
	var rig := Node3D.new()
	piece.add_child(rig)
	var team_color: Color = TEAM_COLORS[team]
	var edge := _material(team_color, team_color.darkened(0.83))
	var model := ChampionModel.new()
	rig.add_child(model)
	model.build(class_id, ArenaMatch.CLASS_INFO[class_id].archetype)

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

	var top := _label(piece, Vector3(0.0, 2.76, 0.0), str(ArenaMatch.CLASS_INFO[class_id].name).to_upper(), team_color, 0.0056)
	if fighter_id == 0:
		top.text = "YOU" if phone_camera else top.text + "  /  YOU"
	if phone_camera:
		top.pixel_size = 0.0072
	var status_label := _label(piece, Vector3(0, 3.06, 0), "", Color("f2dca9"), 0.0051)
	var bar_back := _material(Color("141a24"), Color.BLACK, true)
	bar_back.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	var bar_fill := _material(team_color, Color.BLACK, true)
	bar_fill.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_quad(piece, Vector3(0.0, 2.55, 0.0), Vector2(1.32, 0.12), bar_back)
	var health_trail: MeshInstance3D
	if phone_camera:
		var lost := _material(Color("fbe2b9"), Color.BLACK, true)
		lost.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		health_trail = _quad(piece, Vector3(0.0, 2.55, 0.004), Vector2(1.24, 0.080), lost)
		health_trail.hide()
	var fill := _quad(piece, Vector3(0.0, 2.55, 0.007), Vector2(1.24, 0.063), bar_fill)
	return {
		"node": piece, "rig": rig, "model": model, "fill": fill, "selection": selection, "health": health,
		"class_id": class_id, "trail": trail, "guard_link": guard_link, "brace": brace,
		"wound": wound, "mending": mend, "status_label": status_label, "nameplate": top,
		"step_phase": -1, "health_trail": health_trail, "trail_health": 1.0, "trail_hold": 0.0,
	}


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
