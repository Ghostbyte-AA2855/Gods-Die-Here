extends RefCounted

# The armor rigs face -Z. Each pose authors the pelvis offset in centimeters,
# then torso and head angles, both arm chains, and the weight over each knee.
const REST := Vector3.ZERO
# Torso recoil, carried gear inertia, and recovery cadence after contact.
const SETTLE := {
	"breakwater":Vector3(0.22, 0.66, 0.87), "threadkeeper":Vector3(0.09, 1.10, 1.08),
	"echo_duelist":Vector3(0.13, 1.20, 1.37), "forgecaller":Vector3(0.29, 0.91, 0.87),
	"lamplighter":Vector3(0.08, 1.02, 0.95), "longwatch":Vector3(0.12, 0.72, 1.13),
	"sluicecaller":Vector3(0.24, 1.27, 1.13), "glassmage":Vector3(0.10, 1.16, 1.20),
	"blood_cantor":Vector3(0.19, 1.13, 1.07), "bellwarden":Vector3(0.29, 0.99, 0.89),
	"ash_dancer":Vector3(0.13, 1.32, 1.41), "winter_scribe":Vector3(0.08, 0.89, 1.05),
	"dream_shepherd":Vector3(0.08, 1.18, 0.94), "chainrunner":Vector3(0.24, 1.27, 1.22),
	"coilwright":Vector3(0.22, 0.93, 1.25), "duskmoth":Vector3(0.13, 1.35, 1.30),
}
const CLIPS := {
	# The Drowned Gate. Crouch behind the vault door, drive it forward,
	# then widen the stance and keep it between the team and the surge.
	"breakwater": [1.82, Vector3(0.40, 0.58, 0.80), "hand_l", [
		[Vector3(-10,-15,9), Vector3(-12,-26,9), Vector3(14,18,-5),
			Vector3(40,14,-18), Vector3(73,-23,-10), Vector3(0,0,0),
			Vector3(12,-24,32), Vector3(62,0,0), Vector3(0,19,14), Vector3(31,23,15)],
		[Vector3(-15,-12,-16), Vector3(-19,27,1), Vector3(12,-18,-9),
			Vector3(61,6,-31), Vector3(25,-15,-3), Vector3(0,0,0),
			Vector3(20,-36,39), Vector3(36,8,0), Vector3(9,-16,7), Vector3(35,15,19)],
		[Vector3(-11,-18,-9), Vector3(-9,19,6), Vector3(9,-14,-4),
			Vector3(41,3,-25), Vector3(42,-11,-6), Vector3(0,0,0),
			Vector3(11,-15,28), Vector3(50,0,4), Vector3(3,0,5), Vector3(29,20,18)],
	]],
	# The Last Thread. Draw sutures from the crook's eye and pull the
	# stitch taut with the bare hand before lowering the crooked staff.
	"threadkeeper": [2.01, Vector3(0.37, 0.52, 0.81), "hand_l", [
		[Vector3(2,-5,9), Vector3(4,24,-7), Vector3(-8,-19,13),
			Vector3(61,21,14), Vector3(76,-20,28), Vector3(-25,33,-18),
			Vector3(54,-15,31), Vector3(57,-11,-15), Vector3(-69,1,12), Vector3(17,12,8)],
		[Vector3(-9,0,-4), Vector3(-10,-17,8), Vector3(2,16,-4),
			Vector3(89,-16,-46), Vector3(22,-7,-8), Vector3(7,79,8),
			Vector3(114,22,25), Vector3(24,-18,16), Vector3(-29,5,15), Vector3(13,18,11)],
		[Vector3(-3,-4,0), Vector3(-4,-10,2), Vector3(8,7,-4),
			Vector3(65,-32,-27), Vector3(38,-20,2), Vector3(-20,34,6),
			Vector3(79,18,33), Vector3(37,-17,2), Vector3(-43,4,3), Vector3(15,15,8)],
	]],
	# A Thousand Final Cuts. Right blade sweeps across the body, a
	# left backstep catches the momentum, and both hands clear the torso.
	"echo_duelist": [1.85, Vector3(0.45, 0.58, 0.76), "hand_r", [
		[Vector3(13,-19,11), Vector3(-10,-62,-9), Vector3(6,44,9),
			Vector3(63,26,14), Vector3(75,-3,-7), Vector3(-9,44,24),
			Vector3(81,-27,42), Vector3(54,14,15), Vector3(19,-23,-21), Vector3(18,43,13)],
		[Vector3(-21,-17,-16), Vector3(-31,53,-12), Vector3(23,-33,0),
			Vector3(29,-39,-65), Vector3(21,11,24), Vector3(-33,16,12),
			Vector3(94,-14,-23), Vector3(23,19,-34), Vector3(32,23,17), Vector3(51,16,18)],
		[Vector3(-17,-10,-8), Vector3(-14,82,11), Vector3(14,-49,-9),
			Vector3(37,-25,-39), Vector3(53,0,14), Vector3(14,-8,-25),
			Vector3(43,4,-48), Vector3(52,10,-26), Vector3(-29,-17,25), Vector3(38,15,15)],
	]],
	# Godfall Hammer. Lift the mallet over the off shoulder, catch the haft
	# with the left hand, and finish the impact through a low planted lunge.
	"forgecaller": [2.16, Vector3(0.43, 0.55, 0.83), "hand_r", [
		[Vector3(12,-9,9), Vector3(14,-35,-16), Vector3(-22,18,9),
			Vector3(93,25,25), Vector3(88,-27,8), Vector3(-22,-12,-57),
			Vector3(157,-22,34), Vector3(72,17,0), Vector3(-65,16,34), Vector3(25,37,12)],
		[Vector3(-4,-22,-20), Vector3(-31,13,5), Vector3(25,0,-3),
			Vector3(74,33,12), Vector3(30,-38,8), Vector3(-30,5,34),
			Vector3(62,-21,-15), Vector3(33,21,-5), Vector3(-9,-10,8), Vector3(50,21,19)],
		[Vector3(-5,-22,-12), Vector3(-28,24,3), Vector3(25,-9,-3),
			Vector3(48,12,10), Vector3(40,-24,9), Vector3(-22,-9,-15),
			Vector3(34,-18,-5), Vector3(48,17,-12), Vector3(5,4,18), Vector3(44,24,18)],
	]],
	# The Last Sunrise. Bow over the lantern, lift it clear above the
	# shoulder and hold the flame high with the other hand open to allies.
	"lamplighter": [2.08, Vector3(0.40, 0.57, 0.80), "hand_r", [
		[Vector3(10,-18,5), Vector3(-25,19,-5), Vector3(15,-10,2),
			Vector3(62,36,20), Vector3(97,-21,-28), Vector3(-17,48,-34),
			Vector3(39,-27,14), Vector3(66,23,22), Vector3(-61,8,35), Vector3(31,37,10)],
		[Vector3(-7,-1,-4), Vector3(12,-18,7), Vector3(-21,9,7),
			Vector3(65,6,-58), Vector3(12,14,0), Vector3(30,39,-18),
			Vector3(133,8,13), Vector3(17,2,16), Vector3(-137,0,-8), Vector3(12,17,11)],
		[Vector3(-4,-5,2), Vector3(4,-7,8), Vector3(-12,9,6),
			Vector3(43,-8,-47), Vector3(30,12,4), Vector3(12,12,-13),
			Vector3(121,-5,20), Vector3(38,5,7), Vector3(-118,1,-5), Vector3(18,21,9)],
	]],
	# The Sky Is a Killing Field. Expose the bow, draw at a high angle
	# and let the string hand slip back while the bow stays on its plane.
	"longwatch": [1.95, Vector3(0.47, 0.61, 0.80), "hand_l", [
		[Vector3(-5,-9,3), Vector3(5,50,8), Vector3(-12,-58,0),
			Vector3(100,-7,-29), Vector3(24,-8,0), Vector3(-86,24,5),
			Vector3(65,-32,14), Vector3(89,33,-13), Vector3(-29,-21,12), Vector3(14,29,11)],
		[Vector3(-9,-1,-4), Vector3(3,41,13), Vector3(-19,-49,2),
			Vector3(123,-7,-28), Vector3(6,-8,4), Vector3(-109,21,-8),
			Vector3(54,-38,73), Vector3(89,25,12), Vector3(-39,-2,46), Vector3(12,22,9)],
		[Vector3(-4,-5,2), Vector3(5,43,9), Vector3(-11,-46,1),
			Vector3(112,-13,-36), Vector3(12,-12,1), Vector3(-95,16,-4),
			Vector3(43,-28,63), Vector3(64,4,28), Vector3(-31,-2,39), Vector3(20,20,9)],
	]],
	# Drown the Court. Wind the trident like a paddle, carve a deep
	# arc ahead, and wrench backward as the water draws rivals inward.
	"sluicecaller": [2.00, Vector3(0.41, 0.55, 0.83), "hand_r", [
		[Vector3(13,-14,13), Vector3(8,-49,-9), Vector3(-11,32,10),
			Vector3(48,28,6), Vector3(64,-49,-10), Vector3(-21,20,-9),
			Vector3(135,-14,62), Vector3(37,10,15), Vector3(-73,-3,38), Vector3(26,37,15)],
		[Vector3(-16,-16,-15), Vector3(-29,32,9), Vector3(18,-17,-4),
			Vector3(62,10,-56), Vector3(21,13,-6), Vector3(-18,16,-13),
			Vector3(71,-12,-45), Vector3(34,28,4), Vector3(-36,-11,-41), Vector3(43,17,18)],
		[Vector3(3,-19,14), Vector3(18,40,-10), Vector3(-13,-14,5),
			Vector3(41,29,-36), Vector3(61,-18,9), Vector3(-25,10,10),
			Vector3(58,1,-32), Vector3(72,28,7), Vector3(-43,14,-44), Vector3(30,31,11)],
	]],
	# Cathedral of Shards. Gather both palms at the mask, pry the crown
	# apart, and lower the fragments with both wrists turned outward.
	"glassmage": [2.14, Vector3(0.38, 0.55, 0.82), "hand_r", [
		[Vector3(-1,-7,7), Vector3(-6,14,4), Vector3(15,-10,-4),
			Vector3(72,34,27), Vector3(78,-19,13), Vector3(-26,48,5),
			Vector3(82,-29,-34), Vector3(70,20,-9), Vector3(-21,-55,-7), Vector3(19,14,9)],
		[Vector3(0,4,-5), Vector3(8,-14,-7), Vector3(-16,11,8),
			Vector3(89,-18,-74), Vector3(17,-9,-5), Vector3(19,36,39),
			Vector3(97,26,75), Vector3(24,7,3), Vector3(11,-35,-32), Vector3(14,21,15)],
		[Vector3(-2,-3,2), Vector3(-3,-5,2), Vector3(6,4,0),
			Vector3(51,-21,-83), Vector3(42,-10,17), Vector3(-14,23,27),
			Vector3(63,16,84), Vector3(37,12,-16), Vector3(-11,-26,-23), Vector3(17,17,12)],
	]],
	# Red Communion. Raise the chalice to the mask with the left palm
	# supporting it, then tip it outward and draw the harvest back.
	"blood_cantor": [2.08, Vector3(0.40, 0.59, 0.81), "hand_r", [
		[Vector3(4,-8,8), Vector3(-12,-17,7), Vector3(17,12,-4),
			Vector3(67,29,22), Vector3(89,-14,9), Vector3(-49,36,0),
			Vector3(66,-45,-29), Vector3(92,29,-4), Vector3(-104,-25,-23), Vector3(17,19,8)],
		[Vector3(9,-15,-15), Vector3(-26,12,-12), Vector3(13,-9,8),
			Vector3(48,-9,-35), Vector3(35,10,13), Vector3(-19,37,-19),
			Vector3(100,-8,21), Vector3(22,16,14), Vector3(-45,-7,48), Vector3(18,36,16)],
		[Vector3(-5,-8,5), Vector3(6,-28,1), Vector3(-2,25,6),
			Vector3(79,-19,-42), Vector3(45,12,8), Vector3(-20,50,9),
			Vector3(45,-24,42), Vector3(55,22,4), Vector3(-117,-15,20), Vector3(19,21,11)],
	]],
	# The Ninth Toll. Cock the hammer across the back, steady the
	# breastplate with the left arm, and strike across the hanging bells.
	"bellwarden": [2.09, Vector3(0.45, 0.57, 0.84), "hand_r", [
		[Vector3(13,-13,12), Vector3(9,-56,-17), Vector3(-5,38,8),
			Vector3(70,14,31), Vector3(59,-25,16), Vector3(-45,11,-6),
			Vector3(126,-37,55), Vector3(69,29,13), Vector3(-58,22,43), Vector3(23,42,13)],
		[Vector3(-14,-17,-11), Vector3(-22,62,9), Vector3(12,-47,-2),
			Vector3(55,-13,-36), Vector3(52,-14,-8), Vector3(-29,7,21),
			Vector3(73,5,-23), Vector3(23,26,-11), Vector3(-21,22,34), Vector3(40,24,17)],
		[Vector3(-12,-22,-8), Vector3(-28,72,4), Vector3(21,-49,-2),
			Vector3(28,-8,-47), Vector3(59,9,7), Vector3(-8,3,-6),
			Vector3(43,12,-49), Vector3(52,11,-9), Vector3(-37,19,19), Vector3(30,34,15)],
	]],
	# Dance of the Black Sun. Cross both hooks low, whip them out
	# as the front boot pivots, and end in a wide, flame-driving spiral.
	"ash_dancer": [1.91, Vector3(0.43, 0.55, 0.77), "hand_r", [
		[Vector3(11,-23,12), Vector3(-13,67,-20), Vector3(13,-46,14),
			Vector3(50,41,36), Vector3(63,-8,-8), Vector3(1,17,-30),
			Vector3(51,-35,-35), Vector3(52,18,11), Vector3(9,-31,19), Vector3(17,48,15)],
		[Vector3(-15,-8,-12), Vector3(-8,-50,14), Vector3(5,32,-11),
			Vector3(85,-6,-74), Vector3(22,12,-8), Vector3(29,-22,14),
			Vector3(108,22,59), Vector3(15,-15,0), Vector3(35,29,-6), Vector3(35,14,18)],
		[Vector3(-16,-17,-7), Vector3(-15,-96,20), Vector3(14,68,-18),
			Vector3(67,-19,-71), Vector3(40,17,1), Vector3(-14,-29,19),
			Vector3(42,7,62), Vector3(63,-10,-2), Vector3(-7,26,31), Vector3(45,18,12)],
	]],
	# The Last Winter. Hold the book high, trace a cold rune with
	# the quill, then punctuate the frost seal against the court.
	"winter_scribe": [2.15, Vector3(0.36, 0.57, 0.78), "hand_r", [
		[Vector3(-4,-6,3), Vector3(4,-21,6), Vector3(13,13,2),
			Vector3(79,12,-14), Vector3(64,-29,19), Vector3(-22,42,-13),
			Vector3(100,-19,-16), Vector3(62,27,23), Vector3(-9,44,21), Vector3(15,18,10)],
		[Vector3(7,-16,-11), Vector3(-24,8,-12), Vector3(18,0,11),
			Vector3(59,20,-16), Vector3(61,-14,2), Vector3(-41,29,-15),
			Vector3(67,-9,33), Vector3(20,11,-12), Vector3(44,17,35), Vector3(21,38,12)],
		[Vector3(7,-20,-9), Vector3(-22,17,-9), Vector3(19,-9,8),
			Vector3(43,13,-25), Vector3(75,-8,1), Vector3(-38,26,-11),
			Vector3(40,-10,49), Vector3(24,-13,-10), Vector3(28,6,39), Vector3(20,45,11)],
	]],
	# Throne Beyond Sleep. Lower the crescent staff into a kneeling
	# surrender, lift it to one side, and open a protective palm.
	"dream_shepherd": [2.14, Vector3(0.43, 0.58, 0.83), "hand_r", [
		[Vector3(11,-23,0), Vector3(-27,25,-12), Vector3(22,-24,5),
			Vector3(61,12,19), Vector3(103,-11,18), Vector3(-37,39,-13),
			Vector3(19,-22,42), Vector3(67,28,-14), Vector3(-57,-3,22), Vector3(21,55,15)],
		[Vector3(-8,-4,-6), Vector3(7,-13,9), Vector3(-14,16,-7),
			Vector3(103,-6,-46), Vector3(16,9,-9), Vector3(-37,43,29),
			Vector3(120,17,51), Vector3(25,12,7), Vector3(-103,6,-41), Vector3(13,28,12)],
		[Vector3(-7,-6,0), Vector3(6,-3,11), Vector3(-4,8,-8),
			Vector3(73,-13,-56), Vector3(29,13,-8), Vector3(-14,24,24),
			Vector3(88,9,57), Vector3(39,2,5), Vector3(-90,6,-31), Vector3(16,23,11)],
	]],
	# The Gallows Choir. Show the hooked hand out front; recoil back
	# into the braced heel as the other hand takes the chain's weight.
	"chainrunner": [1.91, Vector3(0.37, 0.55, 0.79), "hand_r", [
		[Vector3(16,-12,12), Vector3(8,-40,-18), Vector3(-9,26,18),
			Vector3(47,37,17), Vector3(59,-29,-22), Vector3(-14,16,-11),
			Vector3(116,-31,63), Vector3(66,26,16), Vector3(-30,18,26), Vector3(20,36,15)],
		[Vector3(-9,-24,-18), Vector3(-31,15,11), Vector3(19,-12,-10),
			Vector3(67,18,-16), Vector3(30,-9,-6), Vector3(15,29,-19),
			Vector3(96,-4,22), Vector3(9,6,-9), Vector3(35,0,27), Vector3(49,18,17)],
		[Vector3(13,-18,17), Vector3(19,-34,-12), Vector3(-20,27,15),
			Vector3(57,27,13), Vector3(99,-19,6), Vector3(-18,21,-13),
			Vector3(42,-22,51), Vector3(105,19,-17), Vector3(-4,-28,12), Vector3(24,44,19)],
	]],
	# Thunder the Dead. Skewer the sky with the lightning fork, ground
	# the stance, and conduct through the open left gauntlet.
	"coilwright": [2.02, Vector3(0.39, 0.55, 0.78), "hand_l", [
		[Vector3(11,-10,11), Vector3(15,-32,-16), Vector3(-22,14,13),
			Vector3(54,24,15), Vector3(75,-32,-1), Vector3(-26,29,-15),
			Vector3(141,-13,34), Vector3(38,18,10), Vector3(-82,-12,25), Vector3(23,32,12)],
		[Vector3(-12,-15,-11), Vector3(-20,23,9), Vector3(14,-16,-5),
			Vector3(92,-13,-43), Vector3(10,-9,8), Vector3(17,29,33),
			Vector3(65,-38,39), Vector3(22,10,-5), Vector3(-63,32,-16), Vector3(39,19,16)],
		[Vector3(-7,-13,-4), Vector3(-15,19,7), Vector3(12,-10,-7),
			Vector3(71,-11,-65), Vector3(31,12,-5), Vector3(-12,26,26),
			Vector3(58,-27,38), Vector3(48,18,11), Vector3(-50,34,-24), Vector3(32,22,14)],
	]],
	# A Sky of Hungry Wings. Fold the claw arms across the husk, then
	# unfurl with the wing harness lifting behind the shoulders.
	"duskmoth": [2.00, Vector3(0.43, 0.57, 0.82), "hand_r", [
		[Vector3(-8,-24,8), Vector3(-33,28,14), Vector3(26,-20,-10),
			Vector3(58,32,29), Vector3(91,-18,-11), Vector3(-21,47,31),
			Vector3(76,-35,-32), Vector3(71,24,19), Vector3(-25,-42,-36), Vector3(39,33,12)],
		[Vector3(4,3,-4), Vector3(11,-35,-19), Vector3(-22,24,14),
			Vector3(122,-9,-77), Vector3(15,7,-12), Vector3(33,21,8),
			Vector3(136,19,65), Vector3(14,-9,14), Vector3(23,-33,-11), Vector3(14,22,18)],
		[Vector3(9,-7,-8), Vector3(-4,-55,-15), Vector3(11,41,13),
			Vector3(55,-18,-88), Vector3(33,19,-9), Vector3(-13,28,17),
			Vector3(62,4,91), Vector3(35,-19,19), Vector3(-12,-25,-11), Vector3(20,34,16)],
	]],
}


static func contact_time(class_id: String) -> float:
	var timing: Vector3 = CLIPS[class_id][1]
	return float(CLIPS[class_id][0]) * timing.y


static func release_hand(class_id: String) -> String:
	return CLIPS[class_id][2]


static func sample(class_id: String, at: float) -> Dictionary:
	var clip: Array = CLIPS[class_id]
	var timing: Vector3 = clip[1]
	var frames: Array = clip[3]
	var before := 0
	var after := 1
	var amount := 0.0
	if at <= timing.x:
		before = -1
		after = 0
		amount = smoothstep(0.0, timing.x, at)
	elif at <= timing.y:
		amount = pow(inverse_lerp(timing.x, timing.y, at), 2.4)
	elif at <= timing.z:
		before = 1
		after = 2
		amount = 1.0 - pow(1.0 - inverse_lerp(timing.y, timing.z, at), 3.2)
	else:
		before = 2
		after = -1
		amount = smoothstep(timing.z, 1.0, at)
	var pose: Array[Vector3] = []
	for joint in 10:
		var start: Vector3 = REST if before < 0 else frames[before][joint]
		var finish: Vector3 = REST if after < 0 else frames[after][joint]
		pose.append(start.lerp(finish, amount))
	var torso := pose[1] * (PI / 180.0)
	var knees := pose[9] * (PI / 180.0)
	var finish: Vector3 = SETTLE[class_id]
	var stage_weight := smoothstep(0.0, timing.x, at) * (1.0 - smoothstep(timing.z, 1.0, at))
	var secondary := smoothstep(timing.y, timing.y + 0.08, at) * (1.0 - smoothstep(timing.z, 1.0, at))
	var recovery := clampf(inverse_lerp(timing.y, 1.0, at), 0.0, 1.0)
	var decay := (1.0 - recovery) * (1.0 - smoothstep(0.81, 1.0, recovery))
	var recoil := sin(recovery * TAU * finish.z) * decay
	var carried := sin(recovery * TAU * finish.z - 0.72) * decay * smoothstep(0.0, 0.15, recovery)
	var swing: Vector3 = (frames[1][1] - frames[0][1]) * (PI / 180.0)
	swing = swing.limit_length(1.30)
	var ground_return: Vector3 = (frames[1][0] - frames[0][0]) * -0.01 * recoil * finish.x
	var result := {
		"offset": pose[0] * 0.01 + ground_return,
		"pelvis": Vector3(torso.x * 0.30, torso.y * 0.32, torso.z * 0.44),
		"spine": Vector3(torso.x * 0.70, torso.y * 0.68, torso.z * 0.56) - swing * recoil * finish.x,
		"head": pose[2] * (PI / 180.0) + swing * carried * finish.x * 0.50,
		"upper_l": pose[3] * (PI / 180.0),
		"fore_l": pose[4] * (PI / 180.0),
		"hand_l": pose[5] * (PI / 180.0),
		"upper_r": pose[6] * (PI / 180.0),
		"fore_r": pose[7] * (PI / 180.0),
		"hand_r": pose[8] * (PI / 180.0),
		"thigh_l": Vector3(knees.x * 0.67, torso.y * -0.22, knees.z * -0.45),
		"thigh_r": Vector3(knees.y * 0.62, torso.y * -0.17, knees.z * 0.45),
		"shin_l": Vector3(-knees.x, 0, 0),
		"shin_r": Vector3(-knees.y, 0, 0),
		"foot_l": Vector3(knees.x * 0.27, -knees.z * 0.45, knees.z * 0.20),
		"foot_r": Vector3(knees.y * 0.27, knees.z * 0.53, knees.z * -0.20),
		"mantle": Vector3(-torso.x * 0.7 - secondary * 0.32 * finish.y, -torso.y * 0.35, -torso.z * 0.55) + swing * carried * 0.41 * finish.y,
		"ornament": Vector3(-torso.x * 0.46 - secondary * 0.11, -torso.y * 0.48, -torso.z * 0.36) + swing * recoil * 0.29 * finish.y,
	}
	if class_id == "glassmage":
		var grow := smoothstep(timing.x, timing.y, at) * (1.0 - smoothstep(timing.z, 1.0, at))
		var backlash := recoil * 0.32
		result.shard_spread = Vector3.ONE + Vector3(0.72, 0.30, 0.41) * (grow + backlash - (stage_weight - grow) * 0.29)
	elif class_id == "duskmoth":
		result.mantle.x -= secondary * 0.45
	return result
