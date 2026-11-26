extends Node3D

signal settled(at: Vector3, heading: Vector2)

const SHARD_MESH := preload("res://scripts/fx/shard.tres")
const BODY_LIFETIME := 3.7
const MAX_REMAINS := 4

var _stain: StandardMaterial3D
var _fragment: StandardMaterial3D


func _ready() -> void:
	_stain = _finish(0.28)
	_fragment = _finish(0.63)


func play(pawn: Dictionary, at: Vector3, facing: Vector2, full_detail: bool) -> void:
	if get_child_count() >= MAX_REMAINS:
		var oldest := get_child(0)
		remove_child(oldest)
		oldest.queue_free()
	var scene := Node3D.new()
	add_child(scene)
	scene.position = at
	var live_rig: Node3D = pawn.rig
	var fallen := live_rig.duplicate() as Node3D
	scene.add_child(fallen)
	fallen.transform = live_rig.transform
	var player := fallen.get_node("ChampionRig/Motion") as AnimationPlayer
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_IDLE
	player.speed_scale = 1.0
	player.play("death", 0.065)
	player.advance(0.0)
	var ground_contact := player.current_animation_length * 0.70

	var heading := Vector3(facing.x, 0, facing.y).normalized()
	if heading.is_zero_approx():
		heading = Vector3.FORWARD
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(at)
	_scatter(scene, heading, rng, full_detail, ground_contact)
	if full_detail:
		_blood_pool(scene, heading, rng, ground_contact)
	scene.create_tween().tween_callback(func():
		var landing := scene.position - heading * 0.54
		settled.emit(landing, Vector2(heading.x, heading.z))
	).set_delay(ground_contact)
	var retire := scene.create_tween()
	retire.tween_interval(BODY_LIFETIME - 0.27)
	retire.tween_property(scene, "position:y", scene.position.y - 0.3, 0.27)
	retire.tween_callback(scene.queue_free)


func clear() -> void:
	for body in get_children():
		remove_child(body)
		body.queue_free()


func _blood_pool(scene: Node3D, heading: Vector3, rng: RandomNumberGenerator, ground_contact: float) -> void:
	var stain_count := 18
	var film := _batch(scene, stain_count, _stain)
	film.position = -heading * 0.40 + Vector3.UP * 0.018
	var deep := Color("3c0916")
	var wet := Color("910e25")
	var forward := Basis(Vector3.UP, atan2(heading.x, heading.z))
	var amounts := PackedFloat32Array()
	var locations := PackedVector3Array()
	for i in stain_count:
		# A dense central pool and varied sizes around the body read as a single stain.
		var outer := i > 6
		var side := rng.randf_range(-0.63, 0.63) * (1.29 if outer else 0.49)
		var along := rng.randf_range(-0.81, 0.48) * (1.33 if outer else 0.52)
		locations.append(forward * Vector3(side, 0.0011 * i, along))
		amounts.append(rng.randf_range(0.04, 0.22) if outer else rng.randf_range(0.26, 0.53))
		film.multimesh.set_instance_color(i, deep.lerp(wet, rng.randf_range(0.0, 0.75)))
	var spread := func(t: float):
		for i in stain_count:
			var radius := amounts[i] * t
			var scale := Vector3(radius, 0.012, radius * (1.34 + 0.21 * (i % 3)))
			film.multimesh.set_instance_transform(i, Transform3D(forward.scaled(scale), locations[i] * t))
	spread.call(0.015)
	film.create_tween().tween_method(spread, 0.015, 1.0, 0.64).set_delay(ground_contact - 0.13).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _scatter(scene: Node3D, heading: Vector3, rng: RandomNumberGenerator, full_detail: bool, ground_contact: float) -> void:
	var count := 26 if full_detail else 9
	var debris := _batch(scene, count, _fragment)
	var sizes := PackedVector3Array()
	var origins := PackedVector3Array()
	var travels := PackedVector3Array()
	var lives := PackedFloat32Array()
	var delays := PackedFloat32Array()
	var arcs := PackedFloat32Array()
	for i in count:
		var blood := full_detail and i >= 6
		var clotted := blood and i % 4 == 0
		var radius := rng.randf_range(0.032, 0.092) if blood else rng.randf_range(0.028, 0.063)
		sizes.append(Vector3(radius * 0.61, radius * 0.50, radius * (1.8 if clotted else 1.48)))
		var lift := rng.randf_range(0.83, 1.39) if blood else rng.randf_range(0.025, 0.081)
		var point := Vector3(rng.randf_range(-0.15, 0.15), lift, rng.randf_range(-0.15, 0.15))
		origins.append(point)
		var range_out := rng.randf_range(0.29, 1.46)
		var side := Vector3(rng.randf_range(-1.0, 1.0), 0, rng.randf_range(-1.0, 1.0))
		travels.append((side - heading * 0.68).normalized() * range_out + Vector3.UP * 0.019)
		lives.append(rng.randf_range(0.38, 0.65) if blood else rng.randf_range(0.22, 0.42))
		delays.append(rng.randf_range(0.0, 0.11) if blood else ground_contact + rng.randf_range(0.0, 0.09))
		arcs.append(rng.randf_range(0.32, 0.94) if blood else rng.randf_range(0.19, 0.46))
		var tint := Color("5c0919").lerp(Color("bc2131"), rng.randf_range(0.08, 0.85)) if blood else Color("777176").lerp(Color("ad8e77"), rng.randf())
		debris.multimesh.set_instance_color(i, tint)
	var spin_axis := Vector3(0.71, 0.18, 0.3).normalized()
	var simulate := func(elapsed: float):
		for i in count:
			if elapsed <= delays[i]:
				debris.multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * 0.001), origins[i]))
				continue
			var time := minf((elapsed - delays[i]) / lives[i], 1.0)
			var pos := origins[i].lerp(travels[i], time) + Vector3.UP * sin(time * PI) * arcs[i]
			var settled := full_detail and i >= 6 and time >= 1.0
			var scale := sizes[i]
			if settled:
				scale = Vector3(scale.x * 1.18, 0.008, scale.z * 0.73)
			elif not full_detail or i < 6:
				scale *= maxf(0.01, 1.0 - time * time)
			var orientation := Basis.IDENTITY if settled else Basis(spin_axis, time * (3.6 + i % 5))
			debris.multimesh.set_instance_transform(i, Transform3D(orientation.scaled(scale), pos))
	simulate.call(0.0)
	var duration := maxf(0.77, ground_contact + 0.52)
	var flight := scene.create_tween().tween_method(simulate, 0.0, duration, duration)
	if not full_detail:
		flight.finished.connect(debris.queue_free)


func _batch(parent: Node3D, count: int, surface: Material) -> MultiMeshInstance3D:
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = MultiMesh.new()
	instance.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	instance.multimesh.use_colors = true
	instance.multimesh.mesh = SHARD_MESH
	instance.multimesh.instance_count = count
	instance.material_override = surface
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)
	return instance


func _finish(roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = roughness
	return material
