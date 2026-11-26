extends RefCounted

const AbilityMotion = preload("res://scripts/champions/ability_motion.gd")
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
static var _libraries: Dictionary = {}


static func library(class_id: String, archetype: String, model: Node3D) -> AnimationLibrary:
	if not _libraries.has(class_id):
		_libraries[class_id] = _build_library(class_id, archetype, model)
	return _libraries[class_id]


static func _build_library(class_id: String, archetype: String, model: Node3D) -> AnimationLibrary:
	var result := AnimationLibrary.new()
	var stride: Array = STRIDES[class_id]
	var reset := _clip(model, 0.01, PackedFloat32Array([0.0]), [{}], false)
	result.add_animation("RESET", reset)
	for name_of_clip in LOCOMOTION:
		var seconds: float = 2.8 if name_of_clip == "idle" else stride[0]
		var times := _times(12)
		var poses: Array[Dictionary] = []
		for at in times:
			poses.append(_walk(name_of_clip, at, stride, archetype))
		result.add_animation(name_of_clip, _clip(model, seconds, times, poses, true))
	for name_of_clip in ACTION_LENGTHS:
		var times := _times(12)
		var poses: Array[Dictionary] = []
		for at in times:
			poses.append(_react(name_of_clip, at, archetype, stride[2], FALLS[class_id]))
		result.add_animation(name_of_clip, _clip(model, ACTION_LENGTHS[name_of_clip], times, poses, name_of_clip == "channel"))
	var actions: Array = AbilityMotion.actions(class_id)
	for slot in actions.size():
		var record: Array = actions[slot]
		var times := _times(16)
		times.append(record[2])
		times.sort()
		var poses: Array[Dictionary] = []
		for at in times:
			poses.append(AbilityMotion.sample(class_id, slot, at))
		result.add_animation("cast_%d" % (slot + 1), _clip(model, record[1], times, poses, false))
	return result


static func visible_start(class_id: String, slot: int) -> float:
	var action: Array = AbilityMotion.actions(class_id)[slot]
	return maxf(0.0, float(action[1]) * float(action[2]) - 0.05)


static func release_hand(class_id: String, slot: int) -> String:
	var action: Array = AbilityMotion.actions(class_id)[slot]
	return "hand_l" if action[3] < 0 else "hand_r"


static func _times(samples: int) -> PackedFloat32Array:
	var result := PackedFloat32Array()
	for i in range(samples + 1):
		result.append(float(i) / samples)
	return result


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
	return animation


static func _walk(motion: String, at: float, stride: Array, archetype: String) -> Dictionary:
	var circle := at * TAU
	var sway := sin(circle)
	var breathing := sin(circle * 2) * 0.016
	if motion == "idle":
		return {
			"offset":Vector3(0.014 * sway, breathing, 0),
			"spine":Vector3(0.044 + breathing, 0.041 * sway, 0.028 * sway),
			"head":Vector3(-breathing, -0.052 * sway, -0.017 * sway),
			"upper_l":Vector3(0.09 + stride[2], 0, -0.18), "upper_r":Vector3(0.10, 0, 0.15),
			"fore_l":Vector3(0.22, 0, 0), "fore_r":Vector3(0.21 + absf(stride[2]), 0, 0),
			"mantle":Vector3(0.032 + breathing, sway * 0.041, -0.020 * sway),
			"ornament":Vector3(-breathing, sway * 0.024, sway * 0.052)
		}
	var lateral := -1.0 if motion == "strafe_left" else (1.0 if motion == "strafe_right" else 0.0)
	var backwards := -0.67 if motion == "backpedal" else 1.0
	var forward := backwards * (0.40 if lateral != 0.0 else 1.0)
	var pace: float = stride[1]
	var arm := 0.41 if archetype == "guard" else 0.65
	return {
		"offset":Vector3(sway * .045, -0.026 + absf(cos(circle)) * 0.067 * pace, 0),
		"pelvis":Vector3(-.075 * forward, sway*.085, lateral*.075 - sway*.051),
		"spine":Vector3(-.12 * forward, -sway * .14, lateral * -.11),
		"head":Vector3(.075 * forward, sway * .051 + lateral * .095, lateral * .035),
		"thigh_l":Vector3(sway * .63 * forward * pace, 0, lateral*.19 + .055),
		"thigh_r":Vector3(-sway * .63 * forward * pace, 0, lateral*.19 - .055),
		"shin_l":Vector3(-maxf(0.0,-sway)*.83*pace,0,0),
		"shin_r":Vector3(-maxf(0.0,sway)*.83*pace,0,0),
		"foot_l":Vector3(-cos(circle)*.28,0,lateral*.13),
		"foot_r":Vector3(cos(circle)*.28,0,lateral*.13),
		"upper_l":Vector3(-sway*arm*forward + stride[2]*.36,0,-.21 - lateral*.11),
		"upper_r":Vector3(sway*arm*forward + .08,0,.21 - lateral*.11),
		"fore_l":Vector3(.48 + maxf(0,-sway)*.33,0,0),
		"fore_r":Vector3(.48 + maxf(0,sway)*.33,0,0),
		"mantle":Vector3(-.26*forward + breathing, sway*.11,lateral*.16),
		"ornament":Vector3(-.06*forward, sway*.14,lateral*.10)
	}


static func _react(motion: String, at: float, archetype: String, offset: float, end_pose: Array) -> Dictionary:
	var pound := sin(pow(at,0.6) * PI)
	var weight := 0.74 if archetype == "guard" else 1.0
	match motion:
		"death":
			var fall := smoothstep(0.03, 0.84, at)
			return {
				"offset":Vector3(end_pose[1] * .36 * fall, -0.68 * fall, signf(-end_pose[0]) * .47 * fall),
				"pelvis":Vector3(end_pose[0] * fall, end_pose[2] * .49 * fall, end_pose[1] * fall),
				"spine":Vector3(-0.27 * pound, -0.36 * fall, end_pose[2] * .54 * fall),
				"head":Vector3(-0.45 * pound, 0.32 * fall, 0.44 * fall),
				"upper_l":Vector3(0.55*pound, 0.1*fall, -0.82*fall),
				"upper_r":Vector3(0.28*fall, -0.22*fall, 0.65*fall),
				"fore_l":Vector3(0.38*fall, 0, 0), "fore_r":Vector3(-0.14*fall, 0, 0),
				"thigh_l":Vector3(0.28*fall, 0,-0.25*fall), "thigh_r":Vector3(0.39*fall, 0,0.34*fall),
				"shin_r":Vector3(-0.6*fall,0,0), "mantle":Vector3(0.2*pound, 0, -0.22*fall)
			}
		"dodge":
			return {
				"offset":Vector3(0,-0.24*pound, 0.07*pound), "spine":Vector3(-0.43*pound, 0,-.28*pound),
				"thigh_l":Vector3(.59*pound,0,.22*pound), "thigh_r":Vector3(.34*pound,0,-.24*pound),
				"shin_l":Vector3(-.71*pound,0,0), "shin_r":Vector3(-.60*pound,0,0),
				"upper_l":Vector3(.38*pound,0,-.56*pound), "upper_r":Vector3(.63*pound,0,.48*pound),
				"fore_l":Vector3(.89*pound,0,0), "fore_r":Vector3(.70*pound,0,0), "mantle":Vector3(-.54*pound,.23*pound,0)
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
			return {"offset":Vector3(0,-.09*force,.036*force),"pelvis":Vector3(.13*force,0,.045*force),
				"spine":Vector3(.36*force, .32*offset*force,.21*force),"head":Vector3(-.19*force,0,-.27*force),
				"upper_l":Vector3(.34*force,0,-.34*force),"upper_r":Vector3(-.24*force,0,.28*force),
				"thigh_l":Vector3(.27*force,0,.11*force),"shin_r":Vector3(-.38*force,0,0),
				"mantle":Vector3(.26*force,.25*force,-.12*force),"ornament":Vector3(.23*force,-.14*force,-.26*force)}
