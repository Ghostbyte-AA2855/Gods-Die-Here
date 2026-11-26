extends RefCounted

# Ability order matches the eight action slots in scripts/kits.
## Family, seconds, contact fraction, lead side, effort, added pitch, added yaw.
const CLIPS := {
	# Set the vault shield first. The sword follows the captain's hips.
	"breakwater": [
		["cleave", 0.37, 0.24, 1, 1.04, 6, 16],
		["shield", 0.42, 0.21, -1, 1.04, 7, -8],
		["bind", 0.44, 0.25, -1, 0.88, -4, 12],
		["shield", 0.31, 0.16, -1, 1.19, 17, 19],
		["charge", 0.39, 0.15, -1, 1.27, 21, -6],
		["wheel", 0.46, 0.26, -1, 1.18, 9, -24],
		["hew", 0.48, 0.29, 1, 1.19, 19, 7],
		["plant", 0.64, 0.33, -1, 1.32, 24, -11],
	],
	# The empty hand draws the thread while the needle guides the line.
	"threadkeeper": [
		["needle", 0.27, 0.22, 1, 0.88, 5, -7],
		["sew", 0.41, 0.26, -1, 0.90, -7, 16],
		["cradle", 0.48, 0.26, 1, 0.88, -11, -9],
		["threadwork", 0.83, 0.29, 1, 1.00, 7, -7],
		["sever", 0.34, 0.20, 1, 0.89, 10, -19],
		["toss", 0.38, 0.21, -1, 1.03, -7, 14],
		["loom", 0.51, 0.29, 1, 1.11, -9, 15],
		["bloom", 0.63, 0.30, -1, 1.25, -18, -13],
	],
	# Alternate hands so the second stroke can travel the first stroke's return path.
	"echo_duelist": [
		["cleave", 0.29, 0.20, 1, 0.94, 12, 27],
		["lunge", 0.35, 0.18, 1, 1.00, 21, -13],
		["wheel", 0.41, 0.24, -1, 0.97, 8, -34],
		["evade", 0.33, 0.16, 1, 1.00, -11, 16],
		["rewind", 0.39, 0.19, -1, 1.04, -16, 29],
		["toss", 0.29, 0.19, 1, 1.03, 5, -19],
		["lunge", 0.31, 0.20, -1, 1.17, 15, 31],
		["windmill", 0.61, 0.31, 1, 1.24, 4, -44],
	],
	# Stay planted. Heat leaves through the bracer, body vents, or the hammer head.
	"forgecaller": [
		["recoil", 0.31, 0.19, 1, 1.05, 6, 10],
		["brand", 0.37, 0.25, -1, 1.06, 8, -11],
		["haul", 0.51, 0.24, -1, 1.13, -14, 20],
		["shield", 0.44, 0.29, 1, 0.96, 11, -16],
		["inscribe", 0.52, 0.27, 1, 1.13, 26, 5],
		["wave", 0.42, 0.25, -1, 1.00, 16, 18],
		["plant", 0.51, 0.26, -1, 1.12, 18, -7],
		["hew", 0.71, 0.33, 1, 1.37, 25, 19],
	],
	# Keep one hand around the lantern. Plant and pass use that same weight.
	"lamplighter": [
		["needle", 0.29, 0.18, -1, 0.94, 2, 13],
		["cradle", 0.39, 0.27, 1, 0.91, -8, -13],
		["kneel", 0.57, 0.30, 1, 0.96, 21, 11],
		["hold_high", 0.45, 0.29, 1, 1.04, -6, -10],
		["wave", 0.42, 0.23, 1, 1.07, 14, 19],
		["pass", 0.45, 0.27, 1, 1.03, 4, -16],
		["toss", 0.33, 0.20, -1, 0.93, 6, 13],
		["bloom", 0.65, 0.34, 1, 1.28, -21, 16],
	],
	# The left arm carries the bow while the right elbow draws behind the line of aim.
	"longwatch": [
		["draw", 0.34, 0.27, -1, 1.00, 9, -21],
		["sight", 0.30, 0.22, 1, 0.92, -1, 9],
		["draw_low", 0.36, 0.25, -1, 1.04, 19, -16],
		["evade", 0.35, 0.16, -1, 0.99, -16, 18],
		["recoil", 0.33, 0.23, -1, 1.06, 5, 20],
		["draw_fan", 0.48, 0.27, -1, 1.11, 8, -29],
		["kneel", 0.47, 0.33, 1, 0.92, 27, -16],
		["draw_high", 0.63, 0.34, -1, 1.27, 0, -28],
	],
	# Each water cast starts at the trident and continues through a shoulder or full-body turn.
	"sluicecaller": [
		["thrust", 0.36, 0.22, 1, 0.97, 8, -13],
		["inscribe", 0.46, 0.28, -1, 0.90, 14, 16],
		["wave", 0.42, 0.25, 1, 1.06, 14, 21],
		["pass", 0.39, 0.21, -1, 0.96, 6, -15],
		["surf", 0.39, 0.16, 1, 1.08, 15, -23],
		["haul", 0.46, 0.28, 1, 1.11, -15, -23],
		["downpour", 0.52, 0.31, 1, 1.18, 21, 13],
		["windmill", 0.68, 0.34, -1, 1.29, 11, -40],
	],
	# Angular wrists and asymmetrical rebounds keep the crystal work precise.
	"glassmage": [
		["needle", 0.30, 0.23, 1, 0.96, 5, 11],
		["cradle", 0.44, 0.26, -1, 0.97, -12, -22],
		["rewind", 0.35, 0.17, 1, 0.99, -10, 29],
		["mirror", 0.45, 0.24, 1, 1.06, 0, -19],
		["pinch", 0.44, 0.21, 1, 1.05, 11, 20],
		["evade", 0.36, 0.19, -1, 0.91, -12, -21],
		["loom", 0.46, 0.25, -1, 1.13, 4, 18],
		["fracture", 0.68, 0.30, 1, 1.22, 15, -27],
	],
	# Draw power in toward the chest, then offer it away with the chalice.
	"blood_cantor": [
		["haul", 0.38, 0.24, -1, 0.84, -6, 15],
		["offering", 0.48, 0.27, 1, 1.04, 13, -12],
		["cradle", 0.41, 0.24, -1, 1.02, -9, 11],
		["bind", 0.45, 0.28, 1, 0.97, 8, -14],
		["sever", 0.34, 0.18, -1, 1.08, 8, -15],
		["conduct", 0.57, 0.32, 1, 1.18, -10, -17],
		["wheel", 0.43, 0.23, 1, 1.06, 13, 29],
		["offering", 0.69, 0.33, -1, 1.30, 24, 18],
	],
	# Let the bell lag the hand through each ring before bringing it back under control.
	"bellwarden": [
		["hew", 0.43, 0.25, 1, 1.02, 15, 13],
		["hold_high", 0.48, 0.27, 1, 0.94, -12, -6],
		["toll", 0.43, 0.26, 1, 1.06, 3, 19],
		["wave", 0.49, 0.28, 1, 1.16, 19, -21],
		["charge", 0.42, 0.15, -1, 1.19, 24, -9],
		["pinch", 0.39, 0.24, -1, 0.88, 3, 16],
		["kneel", 0.49, 0.25, 1, 1.09, 28, -5],
		["toll", 0.72, 0.34, 1, 1.32, -5, -25],
	],
	# Lead the turn with a heel, then let the hooks follow the hip.
	"ash_dancer": [
		["kick", 0.34, 0.24, 1, 1.06, -12, 25],
		["charge", 0.36, 0.18, 1, 1.11, 21, 16],
		["cleave", 0.34, 0.21, -1, 1.05, 11, -29],
		["wheel", 0.39, 0.25, 1, 1.10, 6, 35],
		["thaw", 0.33, 0.19, -1, 1.02, 12, -21],
		["downpour", 0.44, 0.28, -1, 0.96, 24, 13],
		["kick", 0.37, 0.19, -1, 1.21, -19, -24],
		["windmill", 0.57, 0.30, -1, 1.28, 14, 41],
	],
	# The quill writes short arcs. The free arm keeps the iron book clear of the stroke.
	"winter_scribe": [
		["needle", 0.30, 0.22, 1, 0.87, 1, -12],
		["write", 0.49, 0.31, 1, 1.00, 19, 16],
		["fracture", 0.48, 0.27, -1, 1.06, 12, -21],
		["rewind", 0.37, 0.19, 1, 0.97, -12, 29],
		["open_book", 0.45, 0.29, -1, 0.95, -7, -11],
		["write", 0.41, 0.24, -1, 1.09, 10, -25],
		["sever", 0.38, 0.22, 1, 0.93, 6, 22],
		["downpour", 0.68, 0.35, -1, 1.29, 25, 14],
	],
	# Cushion each gesture and keep the crescent cage level between casts.
	"dream_shepherd": [
		["toss", 0.31, 0.22, -1, 0.86, 0, 10],
		["pass", 0.43, 0.28, 1, 0.92, -5, -13],
		["cradle", 0.47, 0.28, -1, 0.99, -11, 16],
		["surf", 0.42, 0.18, -1, 0.98, 15, -10],
		["fracture", 0.46, 0.25, 1, 1.12, -3, 22],
		["sight", 0.42, 0.25, -1, 1.08, 8, -17],
		["inscribe", 0.54, 0.32, 1, 1.09, 17, -13],
		["conduct", 0.69, 0.34, -1, 1.22, -12, 17],
	],
	# Release the hook, let the shoulder trail the throw, then reel the load into the hip.
	"chainrunner": [
		["cleave", 0.33, 0.21, -1, 0.99, 11, 24],
		["throw_hook", 0.49, 0.23, 1, 1.17, -10, -19],
		["lunge", 0.38, 0.18, 1, 1.12, 18, 19],
		["kneel", 0.41, 0.24, 1, 1.03, 26, -14],
		["wheel", 0.47, 0.27, 1, 1.17, 12, 33],
		["rewind", 0.36, 0.18, -1, 1.04, -16, -21],
		["haul", 0.45, 0.26, -1, 0.99, -14, 19],
		["hew", 0.64, 0.31, 1, 1.29, 20, -20],
	],
	# The electrical current moves from a grounded elbow into one or both fingertips.
	"coilwright": [
		["recoil", 0.28, 0.19, 1, 0.92, 5, 12],
		["brand", 0.35, 0.24, -1, 0.94, 6, -12],
		["arc_split", 0.42, 0.24, 1, 1.10, 9, 16],
		["downpour", 0.47, 0.27, 1, 1.05, 23, -11],
		["rewind", 0.36, 0.21, -1, 1.01, -11, 20],
		["mirror", 0.46, 0.26, 1, 0.98, -2, 18],
		["arc_split", 0.39, 0.20, -1, 1.13, 12, -20],
		["fracture", 0.65, 0.32, 1, 1.26, 12, 24],
	],
	# Antennae and torn wings follow a quick, insect-like lead through the hand or hip.
	"duskmoth": [
		["cleave", 0.31, 0.20, -1, 0.96, 13, 27],
		["pinch", 0.43, 0.26, 1, 0.95, 7, -18],
		["surf", 0.35, 0.17, -1, 1.13, 21, 12],
		["molt", 0.44, 0.24, 1, 1.07, -13, -17],
		["thrust", 0.34, 0.20, 1, 1.04, 15, 23],
		["windmill", 0.49, 0.25, -1, 1.12, 8, -32],
		["open_book", 0.47, 0.28, 1, 1.10, -13, 17],
		["fracture", 0.62, 0.30, -1, 1.22, 17, -26],
	],
}

# Shoulder pitch and spread (lead, support), elbow flexion (lead, support),
# lead wrist roll, torso twist, body lean, knee compression, and wind-up pull.
# Values are degrees in the neutral, front-facing rig space.
const GESTURES := {
	"cleave":    [83, -29, 28, 24, 26, 55, -42, -24,  6, 19, 45],
	"hew":       [104, -8, 54, -8, 31, 67, -19, -17, 19, 38, 62],
	"shield":    [55, -24, 21, 17, 61, 43, -31, -12,  8, 33, 18],
	"bind":      [64, -14, 37, 24, 53, 77,  18,   8, -3, 16, 29],
	"charge":    [48,  -8,-21, 24, 35, 65, -12,  16, 27, 32, 20],
	"wheel":     [76, -37, 62, 37, 19, 34, -44, -38,  5, 24, 43],
	"plant":     [96, -19, 61, -8, 56, 61,  12,  -9, 20, 43, 50],
	"needle":    [73, -15, 24, 26, 21, 65,  -9,  10,  2, 14, 24],
	"sew":       [64, -29, 46,-20, 45, 66,  19,   6, -4, 13, 20],
	"cradle":    [55, -34, 43,-27, 71, 73, -22,  -4, -5, 23, 14],
	"threadwork": [63,-19, 62,-25, 71, 49,  29,   8,  4, 17, 23],
	"sever":     [79, -39, 28, 29, 17, 41, -33, -22,  9, 17, 32],
	"toss":      [68,  18, 24, 17, 33, 41,  27,  18, -7, 15, 38],
	"loom":      [56,  27, 69,-21, 63, 27, -19, -11, -5, 17, 25],
	"bloom":     [106, 31, 98, 34, 24, 39,  25,  13,-10, 32, 42],
	"lunge":     [88,  -6,-26, 26, 16, 45, -21,  19, 24, 43, 23],
	"evade":     [24, -21, 60, 33, 66, 33, -26,  -9,-22, 43, 17],
	"rewind":    [39,  32, 66,-11, 68, 33,  31, -21,-11, 28, 29],
	"windmill":  [96,  39, 53,-36, 32, 18,  44, -48,  6, 36, 48],
	"recoil":    [79,  -7, 48, 22, 25, 66,   7,   9, -8, 20, 18],
	"brand":     [68,   9, 25, 24, 45, 47,  14,  13,  7, 19, 26],
	"haul":      [39,  -7, 22,-18, 113, 91,-24,  27,-18, 42, 27],
	"inscribe":  [89, -17, 36, 28, 24, 46,  28, -13, 22, 35, 35],
	"wave":      [77,  32, 74, 25, 18, 22,  17,  14, 13, 28, 37],
	"kneel":     [76, -17, 36,-10, 53, 62, -29,  11, 27, 53, 25],
	"hold_high": [106, 11, 44, 21, 39, 53, -14,  -7, -7, 21, 34],
	"pass":      [69, -23, 56,-21, 52, 38,  34,  17,  4, 22, 23],
	"draw":      [94,  11, 43,-18,  9, 118,-34,  22,  1, 24, 27],
	"sight":     [61,  -8, 18, 24, 61, 48,  14,  -8,  6, 13, 15],
	"draw_low":  [65,   8, 44,-13,  5, 116,-32,  17, 19, 42, 23],
	"draw_fan":  [94,  29, 49,-32,  7, 124,-48,  23,  3, 31, 39],
	"draw_high": [108,  6, 46,-27,  7, 127,-39,  26, -6, 36, 43],
	"thrust":    [91,  -9, 49,-30, 11, 62, -18,  21, 11, 23, 26],
	"surf":      [28,  36,-12, 47, 29,  17, 16, -18, 18, 42, 12],
	"downpour":  [119, 11, 67, 18, 17, 51,  36,  -9, 15, 36, 57],
	"mirror":    [58, -39, 54,-30, 63, 69,  41, -12, -4, 25, 27],
	"pinch":     [79,  -8, 24,  9, 21, 39, -14,  10,  8, 16, 22],
	"fracture":  [103, 37, 79, 41, 10, 16,  43, -21, 13, 29, 46],
	"offering":  [76, -23, 68,-29, 48, 39, -26,  11,  7, 34, 32],
	"conduct":   [106, 48, 81, 37, 25, 33,  42, -19, -8, 26, 42],
	"toll":      [98,  27, 58,-20, 42, 58,  38, -23, -5, 35, 51],
	"kick":      [38,  37, 36, 39, 32, 61, -12,  19, -9, 28, 21],
	"thaw":      [83, -19, 35, 25, 16, 43, -31,  23, 12, 19, 30],
	"write":     [76, -24, 33,-21, 48, 79,  41,   9, 14, 26, 24],
	"open_book": [68,  21, 46, 31, 58, 86,  28, -17, -7, 20, 22],
	"throw_hook":[89, -19, 47, 16, 16, 74, -36, -29, 12, 32, 63],
	"arc_split": [82,  36, 73, 39, 21, 31,  29,  16, 10, 26, 38],
	"molt":      [65,  43, 57, 52, 33, 46, -41, -19, -5, 39, 31],
}


static func actions(class_id: String) -> Array:
	return CLIPS.get(class_id, [])


static func sample(class_id: String, slot: int, normalized_time: float) -> Dictionary:
	var clips: Array = actions(class_id)
	if slot < 0 or slot >= clips.size():
		return {}
	var clip: Array = clips[slot]
	var family: String = clip[0]
	var gesture: Array = GESTURES[family]
	var contact: float = clip[2]
	var lead: int = clip[3]
	var force: float = clip[4]
	var t := clampf(normalized_time, 0.0, 1.0)
	var timing := beats(clip)
	var loaded := _pose(gesture, family, lead, clip[5], clip[6], -1)
	var contact_pose := _pose(gesture, family, lead, clip[5], clip[6], 0)
	var follow := _pose(gesture, family, lead, clip[5], clip[6], 1)
	if class_id == "forgecaller" and slot == 7:
		_shape_hammerfall(loaded, contact_pose, follow)
	elif class_id == "glassmage" and slot == 7:
		_shape_shattercast(loaded, contact_pose, follow)
	elif class_id == "breakwater" and slot in [3, 7]:
		_shape_shield_check(loaded, contact_pose, follow, slot == 7)
	elif class_id == "ash_dancer" and slot == 7:
		_shape_furnace_turn(loaded, contact_pose, follow)
	var pose := _body_pose(t, timing, loaded, contact_pose, follow)
	# Free ends lag the body and are still catching up during the recovery.
	var drift := _body_pose(maxf(t - 0.063 * sin(t * PI), 0.0), timing, loaded, contact_pose, follow)
	var echo := sin(smoothstep(contact, 0.95, t) * 2.0 * PI) * smoothstep(contact, timing.z, t)
	pose["mantle"] = drift.mantle + Vector3(-11.0, 7.0 * lead, -8.0 * lead) * echo
	pose["ornament"] = drift.ornament + Vector3(8.0, -13.0 * lead, 11.0 * lead) * echo
	var offset: Vector3 = pose.offset
	for name in pose:
		pose[name] = (pose[name] as Vector3) * (PI / 180.0) * force
	pose["offset"] = offset * force
	if class_id == "glassmage":
		var gather := smoothstep(0.0, timing.x, t) * (1.0 - smoothstep(timing.x, contact, t))
		var scatter := smoothstep(timing.x, contact, t) * (1.0 - smoothstep(contact, minf(1.0, timing.z + 0.18), t))
		var emphasis := 1.0 if slot == 7 else (0.33 if slot == 0 else 0.65)
		pose["shard_spread"] = Vector3.ONE + Vector3(0.23, 0.15, 0.20) * (scatter - gather * 0.53) * emphasis
	return pose


static func _shape_hammerfall(loaded: Dictionary, contact: Dictionary, follow: Dictionary) -> void:
	# Draw the head behind the shoulder, then drive the off arm across the
	# chest as the hammer comes down. The support arm catches the follow-through.
	loaded.spine += Vector3(2.0, -13.0, 4.0)
	loaded.upper_r += Vector3(5.0, -12.0, 6.0)
	loaded.fore_l += Vector3(14.0, -22.0, -4.0)
	contact.spine += Vector3(-9.0, 9.0, -5.0)
	contact.upper_r += Vector3(-8.0, 10.0, -11.0)
	contact.fore_l += Vector3(27.0, -18.0, 13.0)
	follow.fore_r += Vector3(12.0, 10.0, -14.0)
	follow.fore_l += Vector3(18.0, -17.0, 7.0)


static func _shape_shattercast(loaded: Dictionary, contact: Dictionary, follow: Dictionary) -> void:
	# Hands close around an imaginary prism before a two-handed split.
	loaded.upper_r += Vector3(8.0, -14.0, -25.0)
	loaded.upper_l += Vector3(19.0, 13.0, 18.0)
	loaded.fore_r += Vector3(22.0, 10.0, -10.0)
	loaded.fore_l += Vector3(28.0, -8.0, 8.0)
	contact.upper_r += Vector3(-5.0, -11.0, 7.0)
	contact.upper_l += Vector3(-10.0, 7.0, -8.0)
	follow.hand_r += Vector3(11.0, -16.0, 16.0)
	follow.hand_l += Vector3(9.0, 19.0, -20.0)


static func _shape_shield_check(loaded: Dictionary, contact: Dictionary, follow: Dictionary, planted: bool) -> void:
	# Draw the vault door back against the shoulder, then drive with the body.
	loaded.spine += Vector3(3.0, -13.0, -5.0)
	loaded.upper_l = Vector3(31.0, 10.0, 12.0)
	loaded.fore_l = Vector3(44.0, -17.0, -6.0)
	loaded.hand_l = Vector3(-28.0, -8.0, 3.0)
	contact.spine += Vector3(-5.0, 16.0, 3.0)
	contact.upper_l = Vector3(64.0, 7.0, -11.0)
	contact.fore_l = Vector3(18.0, -7.0, 3.0)
	contact.hand_l = Vector3(-49.0, 5.0, -4.0)
	contact.upper_r += Vector3(-16.0, -9.0, 4.0)
	follow.upper_l = Vector3(36.0, 1.0, -5.0)
	follow.fore_l = Vector3(39.0, -9.0, 2.0)
	follow.hand_l = Vector3(-40.0, 0.0, 2.0)
	if planted:
		contact.upper_l.x = 44.0
		contact.fore_l.x = 23.0
		contact.spine.x -= 10.0
		follow.offset += Vector3(-0.025, -0.055, -0.012)
		follow.upper_l = contact.upper_l.lerp(follow.upper_l, 0.42)
		follow.fore_l = contact.fore_l.lerp(follow.fore_l, 0.42)


static func _shape_furnace_turn(loaded: Dictionary, contact: Dictionary, follow: Dictionary) -> void:
	# Gather both hooks around the leading shoulder, then open them around the torso.
	loaded.spine += Vector3(2.0, 26.0, 6.0)
	loaded.head.y -= 13.0
	loaded.upper_l += Vector3(15.0, -10.0, 43.0)
	loaded.upper_r += Vector3(17.0, 14.0, -30.0)
	loaded.fore_r += Vector3(28.0, 8.0, 4.0)
	loaded.hand_l += Vector3(-16.0, 16.0, 13.0)
	contact.spine.y -= 15.0
	contact.upper_l += Vector3(-19.0, -13.0, -48.0)
	contact.upper_r += Vector3(-18.0, 12.0, 35.0)
	contact.fore_l -= Vector3(13.0, 6.0, 0.0)
	contact.hand_l += Vector3(16.0, -9.0, -19.0)
	follow.spine.y -= 29.0
	follow.pelvis.y -= 10.0
	follow.upper_l += Vector3(5.0, 12.0, -55.0)
	follow.upper_r += Vector3(-4.0, -10.0, 37.0)
	follow.hand_r += Vector3(10.0, 24.0, 19.0)


static func beats(clip: Array) -> Vector3:
	var contact: float = clip[2]
	var family: String = clip[0]
	var follow := 0.73 if family == "threadwork" else contact + 0.12 + 0.09 * float(clip[4])
	return Vector3(contact * 0.52, contact, follow)


static func _body_pose(t: float, timing: Vector3, loaded: Dictionary, contact: Dictionary, follow: Dictionary) -> Dictionary:
	var from: Dictionary
	var to: Dictionary
	var mix: float
	if t <= timing.x:
		from = {}
		to = loaded
		mix = smoothstep(0.0, timing.x, t)
	elif t <= timing.y:
		from = loaded
		to = contact
		mix = pow(inverse_lerp(timing.x, timing.y, t), 1.70)
	elif t <= timing.z:
		from = contact
		to = follow
		mix = 1.0 - pow(1.0 - inverse_lerp(timing.y, timing.z, t), 2.6)
	else:
		from = follow
		to = {}
		mix = smoothstep(timing.z, 1.0, t)
	var pose := {}
	for name: String in contact:
		var start: Vector3 = from.get(name, Vector3.ZERO)
		var finish: Vector3 = to.get(name, Vector3.ZERO)
		pose[name] = start.lerp(finish, mix)
	return pose


static func _pose(gesture: Array, family: String, side: int, pitch: float, yaw: float, phase: int) -> Dictionary:
	var lead_pitch: float = gesture[0]
	var off_pitch: float = gesture[2]
	var lead_roll: float = gesture[1] * side
	var off_roll: float = gesture[3] * -side
	var lead_elbow: float = gesture[4]
	var off_elbow: float = gesture[5]
	var wrist: float = gesture[6] * side
	var torso_turn: float = (gesture[7] + yaw) * side
	var lean: float = gesture[8] + pitch * 0.5
	var compression: float = gesture[9]
	var anticipation: float = gesture[10]
	var kick := family == "kick"
	var bow := family.begins_with("draw")
	var swing := family in ["cleave", "hew", "wheel", "windmill", "throw_hook", "toll"]
	var brace := family in ["shield", "mirror", "cradle", "hold_high", "threadwork"]
	var travel := family in ["charge", "lunge", "surf", "kick", "rewind", "evade"]
	var grounded := family in ["hew", "plant", "kneel", "toll"]
	var width := 0.09 if grounded or travel else 0.058
	var weight_shift := Vector3(width * side, -compression * 0.00185, -0.15 if travel else -0.077)
	var leg_forward := compression * (0.80 if kick else 0.48)
	var leg_back := compression * 0.36
	var tilt := 4.0 * side
	var back_sweep := 0.0
	if phase == -1:
		var draw_back := 14.0 if bow else anticipation
		lead_pitch = lead_pitch * (0.86 if bow else 0.54) - draw_back
		if family == "hew":
			lead_pitch = 120.0
			lead_elbow -= 13.0
		off_pitch *= 0.74
		lead_roll *= -0.58
		off_roll *= 0.51
		lead_elbow += 24.0
		off_elbow *= 0.79
		wrist *= -0.42
		lean = -lean * 0.56
		torso_turn = -torso_turn * 0.68 - (14.0 * side if swing else 0.0)
		compression *= 0.73
		back_sweep = -18.0
		leg_forward *= 0.58
		leg_back *= 1.65
		weight_shift = Vector3(-0.69 * width * side, weight_shift.y * 0.69, 0.083 if travel or grounded else 0.047)
	elif phase == 1:
		var hold := 0.92 if brace else 0.54
		lead_pitch = lead_pitch * hold - (16.0 if swing else 0.0)
		off_pitch *= 0.67
		lead_roll = lead_roll * 0.78 - (24.0 * side if swing else 0.0)
		off_roll *= 0.73
		lead_elbow = lead_elbow * 0.83 + 25.0
		off_elbow *= 0.74
		wrist *= 0.69
		lean *= 1.15 if grounded else 0.55
		torso_turn = torso_turn * (1.11 if swing else 0.54) + (19.0 * side if swing else 0.0)
		compression *= 0.85 if grounded else 0.57
		back_sweep = 27.0 if swing else 9.0
		leg_forward *= 0.73
		weight_shift *= 1.32 if grounded or swing else 0.55
	elif family == "hew":
		lead_pitch = 69.0
		lead_elbow *= 0.54
		lean += 6.0
	if kick and phase == 0:
		leg_forward = 72.0 if pitch < -15.0 else 56.0
		compression *= 0.39
		tilt *= 2.7

	var lead := "_r" if side > 0 else "_l"
	var off := "_l" if side > 0 else "_r"
	var upper_lead_yaw := -torso_turn * 0.42
	if bow:
		upper_lead_yaw -= 10.0 * side
	var upper_off_yaw := torso_turn * (0.43 if bow else 0.17)
	var head_yaw := -torso_turn * (0.76 if bow else 0.49)
	return {
		"offset": weight_shift,
		"pelvis": Vector3(-lean * 0.29, torso_turn * 0.28, tilt * 0.39),
		"spine": Vector3(-lean * 0.71, torso_turn * 0.61, tilt * 0.58),
		"head": Vector3(lean * 0.37, head_yaw, -tilt * 0.56),
		"upper" + lead: Vector3(lead_pitch, upper_lead_yaw, lead_roll),
		"upper" + off: Vector3(off_pitch, upper_off_yaw, off_roll),
		"fore" + lead: Vector3(lead_elbow, -torso_turn * 0.20, lead_roll * 0.24),
		"fore" + off: Vector3(off_elbow, torso_turn * 0.16, off_roll * 0.15),
		"hand" + lead: Vector3(-lead_pitch * 0.17, upper_lead_yaw * 0.52, wrist),
		"hand" + off: Vector3(-off_elbow * 0.17, 0.0, -wrist * 0.31),
		"thigh" + lead: Vector3(leg_forward, torso_turn * 0.15, side * (7.0 if kick else 3.0)),
		"thigh" + off: Vector3(leg_back, torso_turn * -0.12, side * -4.0),
		"shin" + lead: Vector3(-compression, 0.0, 0.0),
		"shin" + off: Vector3(-compression * 0.75, 0.0, 0.0),
		"foot" + lead: Vector3(compression * 0.42, torso_turn * 0.16, 0.0),
		"foot" + off: Vector3(compression * 0.32, -torso_turn * 0.11, 0.0),
		"mantle": Vector3(back_sweep + lean * 0.24, -torso_turn * 0.55, tilt * 0.61),
		"ornament": Vector3(-lean * 0.46, -torso_turn * 0.38, -wrist * 0.17),
	}
