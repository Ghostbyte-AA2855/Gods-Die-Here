extends RefCounted

const AbilityMotion = preload("res://scripts/champions/ability_motion.gd")
const UltimateMotion = preload("res://scripts/champions/ultimate_motion.gd")
const STRIDES := {
	"breakwater":[0.78, 0.72, 0.14], "threadkeeper":[0.58, 0.48, -0.12],
	"echo_duelist":[0.47, 1.18, 0.31], "forgecaller":[0.78, 0.66, 0.20],
	"lamplighter":[0.64, 0.55, -0.24], "longwatch":[0.56, 0.86, 0.18],
	"sluicecaller":[0.68, 0.66, 0.24], "glassmage":[0.65, 0.57, -0.07],
	"blood_cantor":[0.66, 0.57, 0.27], "bellwarden":[0.82, 0.70, -0.11],
	"ash_dancer":[0.44, 1.10, 0.37], "winter_scribe":[0.65, 0.59, 0.17],
	"dream_shepherd":[0.75, 0.38, -0.15], "chainrunner":[0.56, 0.96, 0.35],
	"coilwright":[0.61, 0.76, 0.26], "duskmoth":[0.50, 1.00, 0.32],
}
# Fall direction, drop, and torso twist are authored for each champion’s equipment.
const FALLS := {
	"breakwater":[-1.47, -.23, .24], "threadkeeper":[-1.26, -.64, -.40],
	"echo_duelist":[-1.13, .81, .48], "forgecaller":[-1.55, .14, -.30],
	"lamplighter":[-.88, -.87, .20], "longwatch":[-1.37, .45, -.51],
	"sluicecaller":[-1.39, -.42, .70], "glassmage":[-1.22, .59, -.87],
	"blood_cantor":[1.10, .38, -.29], "bellwarden":[-1.60, -.11, .33],
	"ash_dancer":[-1.19, -.74, .59], "winter_scribe":[-1.33, -.25, -.48],
	"dream_shepherd":[-1.02, .72, .28], "chainrunner":[-1.46, .31, -.62],
	"coilwright":[-1.41, -.54, .45], "duskmoth":[-.97, .94, .81],
}
const ACTION_LENGTHS := {"hit":0.28, "stagger":0.43, "dodge":0.32, "rally":0.36, "death":0.73, "channel":0.64}
const LOCOMOTION := ["idle","run","strafe_left","strafe_right","backpedal"]
const SIDES := ["_l", "_r"]
static var _libraries: Dictionary = {}


static func library(class_id: String, archetype: String, model: Node3D) -> AnimationLibrary:
	if not _libraries.has(class_id):
		_libraries[class_id] = _build_library(class_id, archetype, model)
	return _libraries[class_id]


static func _build_library(class_id: String, archetype: String, model: Node3D) -> AnimationLibrary:
	var result := AnimationLibrary.new()
	var stride: Array = STRIDES[class_id]
	var carries_vault_shield := class_id == "breakwater"
	var reset := _clip(model, 0.01, PackedFloat32Array([0.0]), [{}], false)
	result.add_animation("RESET", reset)
	for name_of_clip in LOCOMOTION:
		var seconds: float = 2.8 if name_of_clip == "idle" else stride[0]
		var times := _times(24)
		var poses: Array[Dictionary] = []
		for at in times:
			var pose := _walk(name_of_clip, at, stride, archetype, model)
			if carries_vault_shield:
				_align_vault_shield(pose, 0.24, 0.84)
			poses.append(pose)
		result.add_animation(name_of_clip, _clip(model, seconds, times, poses, true))
	var ready := _ready_pose(0.0, stride, archetype)
	for name_of_clip in ACTION_LENGTHS:
		var times := _times(18)
		var poses: Array[Dictionary] = []
		for at in times:
			var pose := _react(name_of_clip, at, archetype, stride[2], FALLS[class_id])
			if name_of_clip != "channel":
				var entry_time := 0.07 if name_of_clip in ["hit", "stagger"] else 0.15
				var entering := 1.0 - smoothstep(0.0, entry_time, at)
				var leaving := smoothstep(0.64, 1.0, at) if name_of_clip != "death" else 0.0
				_mix_ready(pose, ready, entering + leaving)
				if name_of_clip != "death":
					_plant_cast(pose, model)
			poses.append(pose)
		result.add_animation(name_of_clip, _clip(model, ACTION_LENGTHS[name_of_clip], times, poses, name_of_clip == "channel"))
	var actions: Array = AbilityMotion.actions(class_id)
	for slot in actions.size():
		var record: Array = actions[slot]
		var beats := AbilityMotion.beats(record)
		var times := _times(20)
		times.append_array(PackedFloat32Array([beats.x, beats.y, beats.z]))
		times.sort()
		var poses: Array[Dictionary] = []
		for at in times:
			var pose := AbilityMotion.sample(class_id, slot, at)
			_mix_ready(pose, ready, 1.0 - smoothstep(0.0, beats.x, at) + smoothstep(beats.z, 1.0, at))
			if carries_vault_shield:
				var push := smoothstep(beats.x, beats.y, at) * (1.0 - smoothstep(beats.y, beats.z, at))
				_align_vault_shield(pose, lerpf(0.24, 0.09, push), 0.84)
			_plant_cast(pose, model)
			poses.append(pose)
		result.add_animation("cast_%d" % (slot + 1), _clip(model, record[1], times, poses, false))
	result.add_animation("ultimate", _ultimate_clip(model, class_id, ready))
	return result


static func _ultimate_clip(model: Node3D, class_id: String, ready: Dictionary) -> Animation:
	var record: Array = UltimateMotion.CLIPS[class_id]
	var beats: Vector3 = record[1]
	var times := _times(42)
	times.append_array(PackedFloat32Array([beats.x, beats.y, beats.z]))
	times.sort()
	var poses: Array[Dictionary] = []
	for at in times:
		var pose := UltimateMotion.sample(class_id, at)
		_mix_ready(pose, ready, 1.0 - smoothstep(0.0, beats.x, at) + smoothstep(beats.z, 1.0, at))
		if class_id == "breakwater":
			var outward := smoothstep(beats.x, beats.y, at) * (1.0 - smoothstep(beats.y, beats.z, at))
			_align_vault_shield(pose, lerpf(0.24, -0.10, outward), 0.94)
		_plant_cast(pose, model)
		poses.append(pose)
	return _clip(model, record[0], times, poses, false)


static func visible_start(class_id: String, slot: int) -> float:
	var maximum_lead := 0.080 if slot == 0 else (0.185 if slot == 7 else 0.145)
	return maxf(0.0, contact_time(class_id, slot) - maximum_lead)


static func contact_time(class_id: String, slot: int) -> float:
	var action: Array = AbilityMotion.actions(class_id)[slot]
	return float(action[1]) * float(action[2])


static func release_hand(class_id: String, slot: int) -> String:
	var action: Array = AbilityMotion.actions(class_id)[slot]
	return "hand_l" if action[3] < 0 else "hand_r"


static func _times(samples: int) -> PackedFloat32Array:
	var result := PackedFloat32Array()
	for i in range(samples + 1):
		result.append(float(i) / samples)
	return result


static func _mix_ready(pose: Dictionary, ready: Dictionary, weight: float) -> void:
	for joint in ready:
		pose[joint] = pose.get(joint, Vector3.ZERO) + ready[joint] * weight


static func _align_vault_shield(pose: Dictionary, pitch: float, weight: float) -> void:
	# The vault door is strapped to the wrist. Compensate for the bent
	# elbow and torso so its face stays between the captain and the foe.
	var arm := Basis.IDENTITY
	for joint in ["pelvis", "spine", "upper_l", "fore_l"]:
		arm *= Basis.from_euler(pose.get(joint, Vector3.ZERO))
	var face := Basis.from_euler(Vector3(pitch, -0.21, 0.04))
	var current := Basis.from_euler(pose.get("hand_l", Vector3.ZERO)).get_rotation_quaternion()
	var supported := (arm.inverse() * face).get_rotation_quaternion()
	pose.hand_l = Basis(current.slerp(supported, weight)).get_euler()


static func _plant_cast(pose: Dictionary, model: Node3D) -> void:
	var pelvis := Transform3D(Basis.from_euler(pose.get("pelvis", Vector3.ZERO)), model.joints.pelvis.position + pose.get("offset", Vector3.ZERO))
	var floor_height := INF
	for side in SIDES:
		var foot := pelvis
		for segment in ["thigh", "shin", "foot"]:
			var joint: String = segment + side
			foot *= Transform3D(Basis.from_euler(pose.get(joint, Vector3.ZERO)), model.joints[joint].position)
		var bounds: AABB = model.joints["foot" + side].get_node("Sculpt").get_aabb()
		# Project the boot's bounding box onto the vertical axis. This keeps
		# the support sole above the floor even through angled knee bends.
		var sole := foot.origin.y + _sole_height(foot.basis, bounds)
		floor_height = minf(floor_height, sole)
	var offset: Vector3 = pose.get("offset", Vector3.ZERO)
	offset.y += maxf(0.0, -0.004 - floor_height)
	pose.offset = offset


static func _sole_height(basis: Basis, bounds: AABB) -> float:
	var vertical := Vector3(absf(basis.x.y), absf(basis.y.y), absf(basis.z.y))
	return (basis * bounds.get_center()).y - vertical.dot(bounds.size * 0.5)


static func _clip(model: Node3D, seconds: float, times: PackedFloat32Array, poses: Array, loop: bool) -> Animation:
	var animation := Animation.new()
	animation.length = seconds
	animation.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	var pelvis: Node3D = model.joints.pelvis
	var lift := animation.add_track(Animation.TYPE_POSITION_3D)
	animation.track_set_path(lift, model.get_path_to(pelvis))
	for joint in model.joints:
		var track := animation.add_track(Animation.TYPE_ROTATION_3D)
		animation.track_set_path(track, model.get_path_to(model.joints[joint]))
		for index in times.size():
			var pose: Dictionary = poses[index]
			var euler: Vector3 = pose.get(joint, Vector3.ZERO)
			var time := minf(seconds, times[index] * seconds)
			animation.rotation_track_insert_key(track, time, Quaternion.from_euler(euler))
	for index in times.size():
		var offset: Vector3 = poses[index].get("offset", Vector3.ZERO)
		animation.position_track_insert_key(lift, minf(seconds, times[index] * seconds), pelvis.position + offset)
	if model.champion == "glassmage":
		var shards := animation.add_track(Animation.TYPE_SCALE_3D)
		animation.track_set_path(shards, model.get_path_to(model.joints.ornament))
		for index in times.size():
			var spread: Vector3 = poses[index].get("shard_spread", Vector3.ONE)
			animation.scale_track_insert_key(shards, minf(seconds, times[index] * seconds), spread)
	return animation


static func _ready_pose(at: float, stride: Array, archetype: String) -> Dictionary:
	var circle := at * TAU
	var sway := sin(circle)
	var breathing := sin(circle * 2.0) * 0.012
	var stance: float = stride[2]
	var carry := 0.38 if archetype == "guard" else 0.19
	return {
		"offset":Vector3(0.019 * sway + 0.055 * stance, -0.016 + breathing, 0),
		"pelvis":Vector3(0.041, -0.31 * stance, -0.030 * sway - 0.19 * stance),
		"spine":Vector3(0.022 + breathing, 0.041 * sway + 0.64 * stance, 0.024 * sway + 0.14 * stance),
		"head":Vector3(-breathing, -0.052 * sway - 0.35 * stance, -0.017 * sway),
		"upper_l":Vector3(carry + 0.75 * stance + 0.028 * sway, 0.12, -0.22),
		"upper_r":Vector3(0.13 - 0.49 * stance - 0.024 * sway, -0.06, 0.19),
		"fore_l":Vector3(0.30 + carry, -0.10, 0), "fore_r":Vector3(0.36 + absf(stance), 0.09, 0),
		"hand_l":Vector3(0, -0.16, -0.12), "hand_r":Vector3(0, 0.10, 0.08),
		"thigh_l":Vector3(0.11 + 0.14 * stance, 0, 0.032), "thigh_r":Vector3(0.080 - 0.14 * stance, 0, -0.033),
		"shin_l":Vector3(-0.17, 0, 0), "shin_r":Vector3(-0.14, 0, 0),
		"foot_l":Vector3(0.058, -0.084, 0), "foot_r":Vector3(0.054, 0.079, 0),
		"mantle":Vector3(0.032 + breathing, sin(circle - 0.36) * 0.053, -0.025 * sway),
		"ornament":Vector3(-breathing, sway * 0.039, sin(circle - 0.48) * 0.060)
	}


static func _walk(motion: String, at: float, stride: Array, archetype: String, model: Node3D) -> Dictionary:
	if motion == "idle":
		return _ready_pose(at, stride, archetype)
	var lateral := -1.0 if motion == "strafe_left" else (1.0 if motion == "strafe_right" else 0.0)
	var forward := (-0.77 if motion == "backpedal" else 1.0) if lateral == 0.0 else 0.23
	var direction := Vector3(lateral, 0.0, -forward)
	var pace: float = stride[1]
	var circle := at * TAU
	var sway := cos(circle)
	var heavy := archetype == "guard"
	var step := fposmod(at * 2.0, 1.0)
	var loading := _pulse(step, 0.18 if heavy else 0.12, 0.70)
	var extension := _pulse(step, 0.79, 1.0)
	var swing := cos(circle - (0.45 if heavy else 0.24))
	var arm := 0.22 if heavy else (0.53 if archetype == "melee" else 0.32)
	var bias: float = stride[2]
	var pose := {
		"offset":Vector3(-sway * 0.053 * pace + lateral * 0.029, -0.127 - loading * (0.049 if heavy else 0.035) + extension * 0.037, -0.040 * forward - 0.014 * loading),
		"pelvis":Vector3(-0.080 * forward - loading * 0.051, sway * 0.106, -lateral * 0.104 - sway * 0.052),
		"spine":Vector3(-0.14 * forward - loading * 0.062 + extension * 0.033, -swing * 0.14, -lateral * 0.117 + sway * 0.059),
		"head":Vector3(0.10 * forward + loading * 0.045, sway * 0.056 + lateral * 0.108, lateral * 0.112 - sway * 0.017),
		"upper_l":Vector3(0.32 - swing * arm * forward + bias * 0.43, 0.10, -0.26 - lateral * 0.18),
		"upper_r":Vector3(0.22 + swing * arm * forward - bias * 0.19, -0.067, 0.24 - lateral * 0.14),
		"fore_l":Vector3(0.56 + maxf(0.0, -swing) * arm * 0.37, -0.09, 0),
		"fore_r":Vector3(0.57 + maxf(0.0, swing) * arm * 0.57, 0.08, 0),
		"hand_l":Vector3(loading * 0.072, -0.16, -0.13), "hand_r":Vector3(loading * -0.088, 0.13, 0.11),
		"mantle":Vector3(-0.29 * forward + sin(circle * 2.0 - 0.97) * 0.15, cos(circle - 0.72) * 0.19, lateral * 0.16),
		"ornament":Vector3(-0.085 * forward + sin(circle * 2.0 - 1.48) * 0.101, cos(circle - 1.04) * 0.17, lateral * 0.11),
	}
	_step_foot(pose, model, "_l", at, direction, motion, pace, heavy, -1.0)
	_step_foot(pose, model, "_r", fposmod(at + 0.5, 1.0), direction, motion, pace, heavy, 1.0)
	return pose


static func stance_fraction(motion: String, heavy: bool) -> float:
	return (0.52 if motion == "run" else 0.59) + (0.035 if heavy else 0.0)


static func _stride_extent(pace: float) -> float:
	return 0.28 + pace * 0.188


static func gait_cadence(class_id: String, motion: String, heavy: bool, speed: float) -> float:
	var stride: Array = STRIDES[class_id]
	var direction_scale := 0.77 if motion == "backpedal" else (0.74 if motion.begins_with("strafe") else 1.0)
	var authored_speed := 2.0 * _stride_extent(stride[1]) * direction_scale / (float(stride[0]) * stance_fraction(motion, heavy))
	return clampf(speed / authored_speed, 0.54, 2.05)


static func _step_foot(pose: Dictionary, model: Node3D, side: String, at: float, direction: Vector3, motion: String, pace: float, heavy: bool, side_sign: float) -> void:
	var plant := stance_fraction(motion, heavy)
	var stance := clampf(at / plant, 0.0, 1.0)
	var swing := clampf((at - plant) / (1.0 - plant), 0.0, 1.0)
	var travel := lerpf(1.0, -1.0, stance) + 2.0 * smoothstep(0.0, 1.0, swing)
	var lift := pow(sin(PI * swing), 1.35) * (0.071 + pace * (0.084 if heavy else 0.123))
	var lateral := direction.x
	var sweep := direction * travel * _stride_extent(pace)
	sweep.x *= 0.74 if lateral != 0.0 else 1.0
	sweep.x += side_sign * (0.020 + lift * 0.18)
	var heel := 0.19 * (1.0 - smoothstep(0.0, 0.23, stance) + smoothstep(0.56, 1.0, swing))
	var toe := 0.31 * smoothstep(0.55, 1.0, stance) * (1.0 - smoothstep(0.0, 0.63, swing))
	var sole := Quaternion.from_euler(Vector3(heel - toe, side_sign * -0.10 - lateral * 0.26, -lateral * lift * 0.37))
	var hip: Vector3 = model.joints["thigh" + side].position
	var knee: Vector3 = model.joints["shin" + side].position
	var ankle: Vector3 = model.joints["foot" + side].position
	var bounds: AABB = model.joints["foot" + side].get_node("Sculpt").get_aabb()
	var target := hip + knee + ankle + sweep
	target.y = 0.003 + lift - _sole_height(Basis(sole), bounds)
	var leg := solve_leg(model, side, model.joints.pelvis.position + pose.offset, Quaternion.from_euler(pose.pelvis), target, sole)
	pose["thigh" + side] = leg[0].get_euler()
	pose["shin" + side] = leg[1].get_euler()
	pose["foot" + side] = leg[2].get_euler()


static func solve_leg(model: Node3D, side: String, pelvis_at: Vector3, pelvis: Quaternion, target: Vector3, sole: Quaternion) -> Array[Quaternion]:
	var hip: Vector3 = model.joints["thigh" + side].position
	var knee: Vector3 = model.joints["shin" + side].position
	var ankle: Vector3 = model.joints["foot" + side].position
	# The lower leg follows the ankle target while the knee stays in front.
	var relative: Vector3 = pelvis.inverse() * (target - pelvis_at) - hip
	var aim := relative.normalized()
	var upper_length := knee.length()
	var lower_length := ankle.length()
	var reach := clampf(relative.length(), absf(upper_length - lower_length) + 0.006, upper_length + lower_length - 0.003)
	var projection := (upper_length * upper_length - lower_length * lower_length + reach * reach) / (2.0 * reach)
	var bend_direction := (Vector3.FORWARD - aim * aim.dot(Vector3.FORWARD)).normalized()
	var upper := aim * projection + bend_direction * sqrt(maxf(0.0, upper_length * upper_length - projection * projection))
	var thigh_rotation := Quaternion(knee.normalized(), upper.normalized())
	var lower := thigh_rotation.inverse() * (aim * reach - upper)
	var shin_rotation := Quaternion(ankle.normalized(), lower.normalized())
	return [thigh_rotation, shin_rotation, (pelvis * thigh_rotation * shin_rotation).inverse() * sole]


static func _react(motion: String, at: float, archetype: String, offset: float, end_pose: Array) -> Dictionary:
	var pound := _pulse(at, 0.08, 0.87)
	var rebound := _pulse(maxf(0.0, at - 0.25), 0.19, 0.69)
	var weight := 0.74 if archetype == "guard" else 1.0
	match motion:
		"death":
			var drop := smoothstep(0.14, 0.70, at)
			var falter := _pulse(at, 0.15, 0.55)
			var floor_bounce := _pulse(maxf(0.0, at - 0.68), 0.10, 0.31)
			var fall := drop - floor_bounce * 0.062
			return {
				"offset":Vector3(end_pose[1] * .36 * fall, -0.88 * fall - falter * 0.085, signf(-end_pose[0]) * (.47 * fall + falter * .079)),
				"pelvis":Vector3(end_pose[0] * fall, end_pose[2] * .49 * fall, end_pose[1] * fall),
				"spine":Vector3(-0.29 * pound + floor_bounce * .17, -0.36 * fall, end_pose[2] * .54 * fall),
				"head":Vector3(-0.50 * pound + floor_bounce * .27, 0.32 * fall, 0.44 * fall),
				"upper_l":Vector3(0.55*pound + falter * .34, 0.1*fall, -0.82*fall),
				"upper_r":Vector3(0.28*fall + falter * .61, -0.22*fall, 0.65*fall),
				"fore_l":Vector3(0.38*fall, 0, 0), "fore_r":Vector3(-0.14*fall, 0, 0),
				"thigh_l":Vector3(0.28*fall, 0,-0.25*fall), "thigh_r":Vector3(0.39*fall, 0,0.34*fall),
				"shin_l":Vector3(-falter * .41,0,0), "shin_r":Vector3(-0.6*fall,0,0),
				"mantle":Vector3(0.2*pound, .24 * floor_bounce, -0.22*fall),
				"ornament":Vector3(-.22 * floor_bounce, .14 * rebound, .22 * floor_bounce)
			}
		"dodge":
			var tuck := _pulse(at, 0.24, 0.92)
			var steer := -1.0 if offset < 0.0 else 1.0
			return {
				"offset":Vector3(-.15 * steer * tuck, -0.24*pound, 0.13*pound - .17 * tuck),
				"pelvis":Vector3(-.24 * tuck, -.24 * steer * tuck, .28 * steer * tuck),
				"spine":Vector3(-0.47*tuck, .35 * steer * tuck, -.29 * steer * tuck),
				"head":Vector3(.34 * tuck, -.17 * steer * tuck, .15 * steer * tuck),
				"thigh_l":Vector3(.69*tuck,0,.35*pound), "thigh_r":Vector3(.33*pound-.58*tuck,0,-.39*tuck),
				"shin_l":Vector3(-.94*tuck,0,0), "shin_r":Vector3(-.66*pound,0,0),
				"upper_l":Vector3(.55*tuck,0,-.64*pound), "upper_r":Vector3(.72*pound,0,.54*tuck),
				"fore_l":Vector3(.91*tuck,0,0), "fore_r":Vector3(.70*pound,0,0),
				"mantle":Vector3(-.69*tuck,.32*steer*rebound,0), "ornament":Vector3(.28*rebound,-.32*steer*rebound,0)
			}
		"channel":
			var breath := sin(at * TAU) * .08
			return {"spine":Vector3(-.16+breath, .04, 0), "head":Vector3(.20-breath,0,0),
				"upper_l":Vector3(.91,.19,-.32), "upper_r":Vector3(.88,-.17,.43),
				"fore_l":Vector3(.52+breath,.15,0), "fore_r":Vector3(.63-breath,-.09,0),
				"hand_l":Vector3(0,.27,0),"hand_r":Vector3(0,-.22,0),"mantle":Vector3(breath,.06,0)}
		"rally":
			return {"offset":Vector3(0,.073*pound,0),"spine":Vector3(.23*pound,0,0),
				"upper_l":Vector3(.68*pound,0,-.74*pound),"upper_r":Vector3(.73*pound,0,.78*pound),
				"fore_l":Vector3(.22*pound,0,0),"fore_r":Vector3(.32*pound,0,0),
				"head":Vector3(-.29*pound,0,0),"mantle":Vector3(-.22*pound,0,0)}
		_:
			var force := (1.5 if motion == "stagger" else 1.0) * pound * weight
			var side := -1.0 if offset < 0.0 else 1.0
			return {"offset":Vector3(-.058*side*force,-.10*force,.103*force),
				"pelvis":Vector3(.16*force, .14*side*force,.12*side*force),
				"spine":Vector3(.43*force - .15 * rebound, .36*side*force,.24*side*force),
				"head":Vector3(-.28*force, -.12*side*force, -.37*side*force),
				"upper_l":Vector3(.34*force,0,-.34*force),"upper_r":Vector3(-.24*force,0,.28*force),
				"thigh_l":Vector3(.27*force,0,.11*force),"shin_r":Vector3(-.45*force,0,0),
				"mantle":Vector3(.26*force - .33 * rebound,.25*side*force,-.12*side*force),
				"ornament":Vector3(.23*force - .41 * rebound,-.14*side*force,-.33*side*force)}


static func _pulse(at: float, peak: float, end: float) -> float:
	return smoothstep(0.0, peak, at) * (1.0 - smoothstep(peak, end, at))
