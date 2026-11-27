extends SceneTree

const ArenaView = preload("res://scripts/arena_view.gd")
const ArenaMatch = preload("res://scripts/arena_match.gd")
const Pantheon = preload("res://scripts/pantheon.gd")
const MOVEMENT_CLIPS := ["idle", "run", "strafe_left", "strafe_right", "backpedal"]
const REACTION_CLIPS := ["hit", "dodge", "stagger", "death", "rally"]

var checks := 0
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		push_error(message)
		failures += 1


func _run() -> void:
	var arena_view = ArenaView.new()
	root.add_child(arena_view)
	var roster: Dictionary = ArenaMatch.CLASS_INFO
	_check(roster.size() == 16 and Pantheon.GODS.size() == 16, "The roster and pantheon have all 16 champions.")
	var geometry := {}
	var count := 0
	var cast_shapes := {}
	for class_id: String in roster:
		var pawn: Dictionary = arena_view._create_pawn(count, class_id, 0, 100.0)
		count += 1
		_check(pawn.has("model"), "%s creates an authored model through the arena." % class_id)
		if not pawn.has("model"):
			continue
		var model = pawn.model
		var meshes: Array[MeshInstance3D] = []
		_collect_meshes(model, meshes)
		var geometry_signature := _geometry_signature(meshes, model)
		var surfaces := 0
		for piece in meshes:
			surfaces += piece.mesh.get_surface_count()
		_check(meshes.size() >= 12 and surfaces >= 25, "%s has a full set of modeled armor and equipment." % class_id)
		_check(not geometry.has(geometry_signature), "%s has its own modeled form." % class_id)
		geometry[geometry_signature] = true

		_check(model.joints.size() >= 14, "%s exposes its articulated joints." % class_id)
		_check(model.joints.pelvis.position.y > 1.10, "%s uses the long-leg adult rest proportions." % class_id)
		var weathered := false
		for piece in meshes:
			for surface in piece.mesh.get_surface_count():
				var finish := piece.mesh.surface_get_material(surface) as StandardMaterial3D
				if finish != null and finish.albedo_texture != null and finish.roughness_texture != null and finish.normal_texture != null:
					weathered = true
		_check(weathered, "%s has textured albedo, roughness, and surface normals." % class_id)
		var player: AnimationPlayer = model.player
		for clip: String in MOVEMENT_CLIPS:
			_verify_clip(model, player, clip, class_id, true)
		_verify_clip(model, player, "channel", class_id, true)
		for clip: String in REACTION_CLIPS:
			_verify_clip(model, player, clip, class_id, false)

		var kit: Dictionary = roster[class_id]
		_verify_active_footing(model, class_id, kit.speed)
		var class_poses := {}
		for slot in kit.abilities.size():
			var clip := "cast_%d" % (slot + 1)
			var ability: Dictionary = kit.abilities[slot]
			var samples := _verify_clip(model, player, clip, "%s / %s" % [class_id, ability.name], false)
			if samples.is_empty():
				continue
			var signature := hash(samples)
			_check(not class_poses.has(signature), "%s uses a distinct motion within its class." % ability.name)
			class_poses[signature] = true
			cast_shapes[signature] = true
			_check(_cast_support_stays_above_floor(model, player), "%s / %s keeps its supporting boot above the floor." % [class_id, ability.name])

		# Replay every accepted spell presentation through the handler used by the match.
		arena_view._pawns[0] = pawn
		for slot in kit.abilities.size():
			var event := {
				"source_id": 0, "class_id": class_id, "team": 0, "slot": slot,
				"origin": Vector2.ZERO, "destination": Vector2(1, 0.2),
				"source_after": Vector2(0.4, 0), "target_id": -1, "target_kind": kit.abilities[slot].target,
				"affected_ids": [], "affected_positions": {}, "facing": Vector2.RIGHT,
			}
			arena_view.play_cast(event)
			_check(player.current_animation == "cast_%d" % (slot + 1),
				"%s accepted cast %d drives the arena model." % [class_id, slot + 1])
		arena_view._pawns.erase(0)
		arena_view._free_pawn(pawn)
		await process_frame
	_check(cast_shapes.size() == 128, "All 128 spell motion signatures are distinct.")
	await _verify_live_cast()
	print("Champion model and keyframe checks: %d/%d" % [checks - failures, checks])
	quit(1 if failures else 0)


func _verify_live_cast() -> void:
	var arena = load("res://arena.tscn").instantiate()
	root.add_child(arena)
	arena.audio_cues.muted = true
	arena._start("breakwater")
	arena.game.fighters[0].position = Vector2.ZERO
	arena.game.fighters[3].position = Vector2(0, 1.0)
	arena._render()
	var releases: Array[int] = []
	arena.view.cast_released.connect(func(event: Dictionary): releases.append(event.seq))
	_check(arena.game.try_ability(0, 3), "Strike is accepted by the match rules.")
	arena._render()
	var player: AnimationPlayer = arena.view._pawns[0].model.player
	_check(player.current_animation == "cast_1", "An accepted live Strike animates its champion.")
	_check(arena.view._pending_casts.size() == 1 and releases.is_empty(), "Renders the windup before releasing Strike effects and sound.")
	arena.view.presentation_paused = true
	arena.view._process(0.2)
	_check(releases.is_empty(), "A paused arena holds pending cast presentation.")
	arena.view.presentation_paused = false
	arena.view._process(0.2)
	arena.view._process(0.2)
	_check(releases == [arena.game.cast_events.back().seq], "Strike releases the effect and audio signal exactly once.")
	_check(arena.game.try_ability(1), "Brace can wind up before a scene transition.")
	arena._render()
	_check(arena.view._pending_casts.size() == 1, "The second cast is waiting to release.")
	arena.game._apply_damage(arena.game.fighters[3], 1000)
	arena._render()
	var effects: Node3D = arena.view._eliminations
	_check(effects.get_child_count() == 1, "An elimination displays exactly one champion body.")
	if effects.get_child_count() == 1:
		var fallen: AnimationPlayer = effects.get_child(0).get_child(0).get_node("ChampionRig/Motion")
		_check(fallen.current_animation == "death", "The defeated model plays its articulated death animation.")
	arena._render()
	_check(effects.get_child_count() == 1, "Repeated view updates do not spawn duplicate bodies.")
	arena._lobby()
	arena._render()
	_check(effects.get_child_count() == 0, "Leaving the match clears eliminated champions.")
	arena.view._process(0.2)
	_check(arena.view._pending_casts.is_empty() and releases.size() == 1, "Leaving a match discards queued cast presentation.")
	arena.queue_free()
	await process_frame


func _verify_clip(model, player: AnimationPlayer, clip: String, label: String, looping: bool) -> Array:
	_check(player.has_animation(clip), "%s has the %s clip." % [label, clip])
	if not player.has_animation(clip):
		return []
	var animation := player.get_animation(clip)
	_check(animation.length > 0.08 and animation.get_track_count() >= 3,
		"%s %s animates several parts of the body." % [label, clip])
	_check((animation.loop_mode != Animation.LOOP_NONE) == looping, "%s %s has the expected playback mode." % [label, clip])
	player.play(clip)
	player.seek(0.0, true)
	var start := _pose(model.joints)
	player.seek(animation.length * 0.37, true)
	var middle := _pose(model.joints)
	player.seek(animation.length * 0.64, true)
	var after := _pose(model.joints)
	_check(start != middle or start != after, "%s %s moves actual model joints." % [label, clip])
	return [start, middle, after]


func _cast_support_stays_above_floor(model: Node3D, player: AnimationPlayer) -> bool:
	var boots: Array[MeshInstance3D] = [
		model.joints.foot_l.get_node("Sculpt"),
		model.joints.foot_r.get_node("Sculpt"),
	]
	for sample in range(64):
		player.seek(player.current_animation_length * sample / 64.0, true)
		var sole := INF
		for boot in boots:
			var bounds := boot.get_aabb()
			for corner in range(8):
				var at := model.to_local(boot.to_global(bounds.get_endpoint(corner)))
				sole = minf(sole, at.y)
		if sole < -0.015:
			return false
	return true


func _verify_active_footing(model: Node3D, class_id: String, speed: float) -> void:
	var starting_position := model.position
	var frame := 1.0 / 60.0
	var player: AnimationPlayer = model.player
	var boots: Array[Node3D] = [model.joints.foot_l, model.joints.foot_r]
	for direction: Vector2 in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN]:
		model.position = starting_position
		model.reset_motion()
		var previous: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]
		var drift := 0.0
		var samples := 0
		var lowest := INF
		var state := {"position": Vector2.ZERO, "health": 100.0, "facing": Vector2.UP, "stun": 0.0, "mend_time": 0.0}
		for tick in 108:
			state.position += direction * speed * frame
			model.position = starting_position + Vector3(state.position.x, 0.0, state.position.y)
			model.watch(state, frame)
			var phase := player.current_animation_position / player.current_animation_length
			for limb in boots.size():
				var boot := boots[limb]
				var foot := Vector2(boot.global_position.x, boot.global_position.z)
				var at := fposmod(phase + limb * 0.5, 1.0)
				if tick > 30 and at > 0.09 and at < 0.44:
					var bounds: AABB = boot.get_node("Sculpt").get_aabb()
					for corner in 8:
						lowest = minf(lowest, boot.to_global(bounds.get_endpoint(corner)).y)
					drift += foot.distance_to(previous[limb])
					samples += 1
				previous[limb] = foot
		var gait := str(player.current_animation)
		_check(samples > 0 and drift / maxf(1, samples) / frame < 0.58 and lowest > -0.017,
			"%s %s keeps the supporting boot on its flagstone." % [class_id, gait])
	model.position = starting_position
	model.reset_motion()


func _pose(joints: Dictionary) -> Array:
	var snapshot := []
	var names := joints.keys()
	names.sort()
	for name in names:
		var joint: Node3D = joints[name]
		snapshot.append(joint.rotation.snapped(Vector3.ONE * 0.001))
		snapshot.append(joint.position.snapped(Vector3.ONE * 0.001))
	return snapshot


func _collect_meshes(node: Node, found: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D and node.mesh != null:
		found.append(node)
	for child in node.get_children():
		_collect_meshes(child, found)


func _geometry_signature(meshes: Array[MeshInstance3D], model: Node3D) -> int:
	var inverse := model.global_transform.affine_inverse()
	var forms := []
	for piece in meshes:
		forms.append(hash([piece.mesh.get_aabb(), inverse * piece.global_transform]))
	forms.sort()
	return hash(forms)
