extends SceneTree

const ChampionModel = preload("res://scripts/champions/model.gd")
const LobbyPreview = preload("res://scripts/champions/lobby_preview.gd")
const UltimateMotion = preload("res://scripts/champions/ultimate_motion.gd")
const KIT_MODULES := [
	preload("res://scripts/kits/vanguard.gd"), preload("res://scripts/kits/frontier.gd"),
	preload("res://scripts/kits/covenant.gd"), preload("res://scripts/kits/outliers.gd"),
]
const SAMPLE_COUNT := 80

var checks := 0
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var signatures: Dictionary = {}
	var gallery := LobbyPreview.new()
	root.add_child(gallery)
	for module in KIT_MODULES:
		for class_id: String in module.KITS:
			var archetype: String = module.KITS[class_id].archetype
			var model := ChampionModel.new()
			root.add_child(model)
			model.build(class_id, archetype)
			var signature := _check_motion(model, class_id)
			_check(not signatures.has(signature), "%s has a distinct ultimate motion" % class_id)
			signatures[signature] = class_id
			_check_gallery(gallery, class_id, archetype)
			model.queue_free()
			await process_frame
	_check(signatures.size() == 16, "The full roster has authored ultimate animations")
	gallery.queue_free()
	await process_frame
	print("Ultimate animation checks: %d/%d" % [checks - failures, checks])
	quit(int(failures > 0))


func _check_motion(model: Node3D, class_id: String) -> int:
	var player: AnimationPlayer = model.player
	_check(player.has_animation("ultimate"), "%s ultimate clip loads" % class_id)
	var clip := player.get_animation("ultimate")
	_check(clip.loop_mode == Animation.LOOP_NONE and clip.length > 1.0 and clip.get_track_count() >= 16,
		"%s uses a full body, non-looping clip" % class_id)
	var beats: Vector3 = UltimateMotion.CLIPS[class_id][1]
	var preview_signatures: Array = []
	player.play("ultimate")
	for moment in [beats.x, beats.y, beats.z]:
		player.seek(clip.length * moment, true)
		preview_signatures.append(_signature(model))
	_check(preview_signatures[0] != preview_signatures[1] and preview_signatures[1] != preview_signatures[2],
		"%s changes pose at the windup, release, and follow-through" % class_id)
	_check(_grounded(model, player, clip.length), "%s has finite poses and grounded feet" % class_id)

	var contact := UltimateMotion.contact_time(class_id)
	model.reset_motion()
	model.play_ultimate_windup(0.81)
	model.advance_motion(0.32)
	_check(player.current_animation == "ultimate" and player.current_animation_position > 0.20
		and player.current_animation_position < contact, "%s advances the windup at the scheduled rate" % class_id)
	_check(model.cast(0) == 0.0 and player.current_animation == "ultimate", "%s protects the windup animation from an older cast event" % class_id)
	var charged: float = model.advance_motion(0.72)
	_check(player.current_animation_position < contact and contact - player.current_animation_position < 0.006
		and charged > 1.4, "%s waits at contact with charged equipment" % class_id)
	model.release_ultimate()
	_check(is_equal_approx(player.current_animation_position, contact), "%s starts follow-through exactly at impact" % class_id)
	_check(model.release_point(8).is_equal_approx(model.joints[UltimateMotion.release_hand(class_id)].global_position),
		"%s originates effects from the correct animated hand" % class_id)
	model.cancel_ultimate()
	_check(player.current_animation == "ultimate", "%s does not cancel an impact that already resolved" % class_id)
	model.advance_motion(0.14)
	_check(player.current_animation_position > contact, "%s advances the release pose" % class_id)
	model.reset_motion()
	model.play_ultimate_windup(1.1)
	model.advance_motion(0.10)
	model.cancel_ultimate()
	_check(player.current_animation == "idle" and model.cast(0) > 0.0, "%s can cancel into locomotion and ordinary casts" % class_id)
	return hash(preview_signatures)


func _signature(model: Node3D) -> Array:
	var key := []
	for joint in model.joints:
		var part: Node3D = model.joints[joint]
		key.append(part.rotation.snapped(Vector3.ONE * 0.001))
		key.append(part.position.snapped(Vector3.ONE * 0.001))
	return key


func _grounded(model: Node3D, player: AnimationPlayer, duration: float) -> bool:
	var boots: Array[MeshInstance3D] = [model.joints.foot_l.get_node("Sculpt"), model.joints.foot_r.get_node("Sculpt")]
	for sample in SAMPLE_COUNT:
		player.seek(duration * float(sample) / float(SAMPLE_COUNT), true)
		var sole := INF
		for boot in boots:
			var bounds := boot.get_aabb()
			for corner in 8:
				var at := model.to_local(boot.to_global(bounds.get_endpoint(corner)))
				if not at.is_finite():
					return false
				sole = minf(sole, at.y)
		if sole < -0.020:
			return false
	return true


func _check_gallery(gallery: Control, class_id: String, archetype: String) -> void:
	gallery.show_champion(class_id, archetype)
	gallery.play_ultimate()
	var player: AnimationPlayer = gallery.champion.player
	_check(player.current_animation == "ultimate" and gallery._framing.has(class_id + "/ultimate"),
		"%s preview runs the authored ultimate and fits its keyframes" % class_id)
	var length := player.current_animation_length
	gallery.champion.advance_motion(length + 0.1)
	_check(player.current_animation == "idle", "%s preview returns to idle when the ultimate finishes" % class_id)


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)
