extends RefCounted

# Four champions from the drowned roads, funeral loom, second grave and hunger forge.
# All positions are in the standing model's space. The builder reattaches each
# part to its named joint, so buckles, blades and armor move with the wearer.
static func build(model, class_id: String) -> void:
	match class_id:
		"breakwater": _breakwater(model)
		"threadkeeper": _threadkeeper(model)
		"echo_duelist": _echo_duelist(model)
		"forgecaller": _forgecaller(model)


static func _breakwater(m) -> void:
	var iron := "m:323740"
	var lead := "m:627279"
	var salt := "a1b0a6"
	var brown := "m:633f38"
	var black := "1a252a"
	var jade := "e:40afa4"

	# Wide, downward-layered officer's cuirass and a skirt of seaworn mail.
	_ellipsoid(m, "spine", Vector3(0, 1.25, 0.01), Vector3(0.41, 0.40, 0.26), black)
	_armor(m, "spine", 0, 1.29, -0.25, 0.70, 0.57, 0.12, iron)
	_armor(m, "spine", 0, 1.36, -0.328, 0.59, 0.40, 0.09, lead)
	_armor(m, "spine", 0, 1.31, -0.385, 0.12, 0.26, 0.03, jade)
	for i in range(3):
		_armor(m, "pelvis", 0, 0.92 - i * 0.083, -0.22, 0.57 - i * 0.08, 0.24, 0.075, iron if i % 2 else lead)
	for side in [-1.0, 1.0]:
		var suffix := "l" if side < 0 else "r"
		var upper := "upper_" + suffix
		var fore := "fore_" + suffix
		var thigh := "thigh_" + suffix
		var shin := "shin_" + suffix
		var foot := "foot_" + suffix
		var pauldron := Vector3(side * 0.42, 1.44 + side * -0.055, 0.036)
		_ellipsoid(m, upper, pauldron, Vector3(0.25 if side < 0 else 0.20, 0.16, 0.24), iron)
		for j in range(3):
			var scale_center := pauldron + Vector3(side * (0.07 + j * 0.068), -0.055 * j, -0.12)
			_armor(m, upper, scale_center.x, scale_center.y, scale_center.z, 0.22 - j * 0.027, 0.27, 0.09, lead)
			_ellipsoid(m, upper, scale_center + Vector3(side * 0.02, 0.055, -0.065), Vector3(0.043, 0.045, 0.034), salt)
		_ellipsoid(m, fore, Vector3(side * 0.47, 1.01, -0.017), Vector3(0.147, 0.22, 0.147), iron)
		for j in range(3):
			m.box(fore, Vector3(side * 0.47, 0.93 + j * 0.075, -0.126), Vector3(0.22, 0.024, 0.04), lead)
		_armor(m, thigh, side * 0.18, 0.64, -0.14, 0.29, 0.30, 0.11, iron)
		_armor(m, shin, side * 0.18, 0.34, -0.13, 0.25, 0.39, 0.10, lead)
		_ellipsoid(m, foot, Vector3(side * 0.18, 0.13, -0.10), Vector3(0.125, 0.095, 0.23), iron)
		for j in range(3):
			m.box(foot, Vector3(side * 0.18, 0.168 - j * 0.009, -0.13 - j * 0.055), Vector3(0.22, 0.045, 0.044), lead)

	# Rot and torn cloth push the left outline outward from the iron shell.
	for i in range(3):
		var x := -0.29 + i * 0.19
		_panel(m, "mantle", [Vector2(-0.13, 0.42), Vector2(0.15, 0.43), Vector2(0.18, -0.15), Vector2(0.02, -0.38 + i * 0.08), Vector2(-0.115, -0.09)], Vector3(x, 0.986, 0.23 + i * 0.025), 0.039, black if i % 2 else "314c46")
		_edge(m, "mantle", Vector3(x - 0.13, 1.27, 0.252 + i * 0.025), Vector3(x - 0.125, 0.907, 0.252 + i * 0.025), 0.013, "61564e", 0.006)

	# A drowned helmet capped by three broken tide crown prongs.
	_ellipsoid(m, "head", Vector3(0, 1.76, 0.032), Vector3(0.228, 0.26, 0.218), iron)
	_armor(m, "head", 0, 1.70, -0.175, 0.39, 0.31, 0.09, lead)
	m.box("head", Vector3(0, 1.778, -0.25), Vector3(0.294, 0.033, 0.023), black)
	for side in [-1.0, 1.0]:
		m.box("head", Vector3(side * 0.073, 1.778, -0.266), Vector3(0.071, 0.012, 0.016), jade)
		_edge(m, "head", Vector3(side * 0.18, 1.86, -0.095), Vector3(side * 0.25, 2.10, -0.07), 0.055, lead, 0.008)
	_edge(m, "head", Vector3(0.024, 1.88, -0.08), Vector3(0.01, 2.17, -0.09), 0.087, salt, 0.006)

	# The shield is an arched burial door. Hinges, lock plate, salt blooms and
	# blue-green slits belong to the door's left-hand pivot.
	var shield_x := -0.66
	_panel(m, "hand_l", [Vector2(-0.34, -0.54), Vector2(-0.34, 0.28), Vector2(-0.21, 0.49), Vector2(0.0, 0.57), Vector2(0.21, 0.49), Vector2(0.34, 0.28), Vector2(0.34, -0.54), Vector2(0.0, -0.68)], Vector3(shield_x, 1.00, -0.47), 0.13, iron)
	_panel(m, "hand_l", [Vector2(-0.28, -0.48), Vector2(-0.28, 0.27), Vector2(-0.17, 0.43), Vector2(0.0, 0.51), Vector2(0.17, 0.43), Vector2(0.28, 0.27), Vector2(0.28, -0.48), Vector2(0.0, -0.60)], Vector3(shield_x, 1.00, -0.555), 0.08, brown)
	for i in range(-2, 3):
		m.box("hand_l", Vector3(shield_x + i * 0.096, 0.982, -0.612), Vector3(0.073, 0.93 - absf(float(i)) * 0.065, 0.045), lead if i % 2 else iron)
		m.box("hand_l", Vector3(shield_x + i * 0.096, 1.14, -0.643), Vector3(0.024, 0.29, 0.013), jade)
	for y in [0.67, 1.33]:
		m.box("hand_l", Vector3(shield_x - 0.035, y, -0.657), Vector3(0.51, 0.054, 0.04), iron)
		for offset in [-0.25, 0.21]:
			_ellipsoid(m, "hand_l", Vector3(shield_x + offset, y, -0.695), Vector3(0.037, 0.033, 0.025), salt)
	# Crossbars on the rear fasten the shield to the gauntlet and wrist.
	for y in [0.84, 1.035]:
		_edge(m, "hand_l", Vector3(-0.635, y, -0.413), Vector3(-0.635, y, -0.085), 0.037, brown, 0.037)
		_edge(m, "hand_l", Vector3(-0.635, y, -0.091), Vector3(-0.55, y, -0.083), 0.039, brown, 0.031)
	_traced_ring(m, "hand_l", Vector3(shield_x, 1.25, -0.648), Vector2(0.214, 0.19), -1.37, 2.74, 8, 0.016, salt)
	_ellipsoid(m, "hand_l", Vector3(shield_x + 0.105, 1.011, -0.684), Vector3(0.08, 0.10, 0.04), brown)
	m.box("hand_l", Vector3(shield_x + 0.105, 1.01, -0.718), Vector3(0.026, 0.082, 0.013), black)
	_edge(m, "hand_r", Vector3(0.48, 0.68, -0.123), Vector3(0.72, 1.52, -0.17), 0.091, lead, 0.016)
	_edge(m, "hand_r", Vector3(0.54, 0.90, -0.154), Vector3(0.69, 1.43, -0.174), 0.037, salt, 0.008)
	m.box("hand_r", Vector3(0.52, 0.857, -0.143), Vector3(0.29, 0.071, 0.11), brown, Vector3(0, 0, -0.35))


static func _threadkeeper(m) -> void:
	var ink := "191421"
	var silk := "3b2a46"
	var ash := "63536b"
	var copper := "m:bb8170"
	var ivory := "ded1b1"
	var spirit := "e:bc8df0"

	# The sleeves and silk robe use thin pointed panels, a tapered waist and
	# vertical folds. Hands are bare porcelain and free for thread gestures.
	_ellipsoid(m, "spine", Vector3(0, 1.28, 0.008), Vector3(0.267, 0.34, 0.203), ink)
	_panel(m, "spine", [Vector2(-0.27, 0.24), Vector2(0.27, 0.24), Vector2(0.155, -0.38), Vector2(0.0, -0.42), Vector2(-0.155, -0.38)], Vector3(0, 1.28, -0.167), 0.11, silk)
	for j in range(-2, 3):
		var x := float(j) * 0.116
		var tip_y := 0.20 + absf(float(j)) * 0.081
		_panel(m, "pelvis", [Vector2(-0.105, 0.35), Vector2(0.105, 0.35), Vector2(0.15, tip_y - 0.58), Vector2(0.0, tip_y - 0.69), Vector2(-0.145, tip_y - 0.58)], Vector3(x, 0.59, -0.14 + absf(x) * 0.16), 0.071, silk if j % 2 else ink)
		_edge(m, "pelvis", Vector3(x, 0.85, -0.218), Vector3(1.2 * x, tip_y + 0.04, -0.244), 0.018, ash, 0.01)
	for side in [-1.0, 1.0]:
		var suffix := "l" if side < 0 else "r"
		var upper := "upper_" + suffix
		var fore := "fore_" + suffix
		var hand := "hand_" + suffix
		_ellipsoid(m, upper, Vector3(side * 0.354, 1.355, 0.015), Vector3(0.137, 0.22, 0.148), silk)
		_panel(m, upper, [Vector2(-0.12, 0.12), Vector2(0.105, 0.13), Vector2(0.092, -0.28), Vector2(-0.105, -0.281)], Vector3(side * 0.397, 1.293, -0.103), 0.06, ink)
		_panel(m, fore, [Vector2(-0.074, 0.12), Vector2(0.077, 0.12), Vector2(0.133, -0.24), Vector2(-0.132, -0.24)], Vector3(side * 0.46, 1.045, -0.072), 0.088, silk)
		_ellipsoid(m, hand, Vector3(side * 0.463, 0.824, -0.06), Vector3(0.073, 0.105, 0.067), ivory)
		_ellipsoid(m, "foot_" + suffix, Vector3(side * 0.143, 0.106, -0.072), Vector3(0.092, 0.080, 0.15), ink)
		_edge(m, "spine", Vector3(side * 0.205, 1.473, -0.236), Vector3(-side * 0.115, 0.953, -0.241), 0.027, copper, 0.019)
		for i in range(5):
			_edge(m, "spine", Vector3(side * 0.032, 1.149 + i * 0.047, -0.25), Vector3(side * (0.093 + i * 0.011), 1.184 + i * 0.045, -0.256), 0.009, ivory, 0.009)

	for i in range(3):
		var x := -0.19 + i * 0.188
		var hem := 0.18 - (1 - absi(i - 1)) * 0.15
		_panel(m, "mantle", [Vector2(-0.088, 0.64), Vector2(0.092, 0.62), Vector2(0.147, -0.33), Vector2(0.013, -0.52 + hem), Vector2(-0.143, -0.35)], Vector3(x, 0.81, 0.173 + i * 0.021), 0.056, silk if i % 2 else ink)
		_edge(m, "mantle", Vector3(x, 1.193, 0.204 + i * 0.021), Vector3(x * 1.29, 0.380 + hem, 0.204 + i * 0.021), 0.013, copper, 0.007)

	# Porcelain jaw veil under a raised hood, crossed by seven copper sutures.
	_ellipsoid(m, "head", Vector3(0, 1.765, 0.039), Vector3(0.233, 0.285, 0.219), ink)
	_panel(m, "head", [Vector2(-0.156, 0.076), Vector2(0.156, 0.076), Vector2(0.13, -0.096), Vector2(0.0, -0.221), Vector2(-0.13, -0.096)], Vector3(0, 1.746, -0.18), 0.064, ivory)
	for i in range(-3, 4):
		var x := i * 0.033
		_edge(m, "head", Vector3(x, 1.715, -0.23), Vector3(x * 0.66, 1.638 + absf(float(i)) * 0.014, -0.233), 0.012, copper, 0.009)
	m.box("head", Vector3(0, 1.802, -0.225), Vector3(0.239, 0.027, 0.025), ink)
	for side in [-1.0, 1.0]:
		_ellipsoid(m, "head", Vector3(side * 0.067, 1.801, -0.24), Vector3(0.035, 0.01, 0.011), spirit)
	_traced_ring(m, "ornament", Vector3(0, 1.872, 0.217), Vector2(0.397, 0.464), -0.94, 4.08, 15, 0.019, copper)
	for i in range(-3, 4):
		var x := float(i) * 0.104
		_edge(m, "ornament", Vector3(x, 2.139 + cos(i * 0.6) * 0.16, 0.219), Vector3(-x * 0.37, 1.84 - absf(x) * 0.27, 0.228), 0.008, spirit, 0.008)
	# The rite spindle is long and thin, with a deep-purple cabochon framed by copper.
	_edge(m, "hand_r", Vector3(0.53, 0.20, 0.052), Vector3(0.7, 1.63, 0.046), 0.041, copper, 0.034)
	_traced_ring(m, "hand_r", Vector3(0.722, 1.735, 0.037), Vector2(0.139, 0.183), 0.0, TAU, 11, 0.025, copper)
	_ellipsoid(m, "hand_r", Vector3(0.725, 1.735, 0.034), Vector3(0.083, 0.122, 0.047), spirit)
	for i in range(5):
		var y := 0.77 + i * 0.058
		m.box("hand_l", Vector3(-0.479, y, -0.132), Vector3(0.151 - 0.009 * i, 0.024, 0.075), copper)


static func _echo_duelist(m) -> void:
	var midnight := "242037"
	var charcoal := "141421"
	var mulberry := "523547"
	var nickel := "m:767c98"
	var pallor := "d8c5b0"
	var lightning := "e:c08efd"

	# A lightly armoured diagonal harness. The hip tails bend independently of
	# the collar crown and follow the acceleration of the mantle joint.
	_panel(m, "spine", [Vector2(-0.31, 0.26), Vector2(0.16, 0.28), Vector2(0.28, 0.14), Vector2(0.16, -0.23), Vector2(-0.04, -0.33), Vector2(-0.17, -0.24)], Vector3(0, 1.25, -0.174), 0.105, midnight)
	_panel(m, "spine", [Vector2(-0.29, 0.21), Vector2(0.13, 0.23), Vector2(0.19, 0.19), Vector2(-0.16, -0.22), Vector2(-0.22, -0.18)], Vector3(0, 1.27, -0.242), 0.035, mulberry)
	_edge(m, "spine", Vector3(-0.27, 1.50, -0.276), Vector3(0.144, 0.95, -0.256), 0.047, nickel, 0.045)
	for i in range(5):
		_ellipsoid(m, "spine", Vector3(-0.206 + i * 0.073, 1.412 - i * 0.092, -0.313), Vector3(0.031, 0.021, 0.018), charcoal)
	_panel(m, "mantle", [Vector2(-0.28, 0.34), Vector2(0.12, 0.32), Vector2(0.169, -0.32), Vector2(0.06, -0.41), Vector2(-0.025, -0.21), Vector2(-0.20, -0.40)], Vector3(-0.103, 0.97, 0.21), 0.055, mulberry)
	_edge(m, "mantle", Vector3(-0.327, 1.267, 0.246), Vector3(-0.269, 0.608, 0.254), 0.023, nickel, 0.007)
	m.box("pelvis", Vector3(-0.034, 0.854, -0.203), Vector3(0.471, 0.081, 0.052), charcoal, Vector3(0, 0, 0.16))
	_armor(m, "pelvis", -0.048, 0.858, -0.251, 0.113, 0.127, 0.03, nickel)
	for side in [-1.0, 1.0]:
		var suffix := "l" if side < 0 else "r"
		var upper := "upper_" + suffix
		var fore := "fore_" + suffix
		var hand := "hand_" + suffix
		var shin := "shin_" + suffix
		var thigh := "thigh_" + suffix
		var shoulder := Vector3(side * 0.391, 1.416, -0.119)
		_panel(m, upper, [Vector2(-0.162, 0.082), Vector2(0.08, 0.151), Vector2(0.142, 0.047), Vector2(0.061, -0.139), Vector2(-0.123, -0.102)], shoulder, 0.13, midnight if side > 0 else nickel)
		for i in range(4):
			m.box(fore, Vector3(side * (0.534 + i * 0.018), 1.082 - i * 0.051, -0.103), Vector3(0.16, 0.029, 0.064), mulberry if i % 2 else charcoal)
		_armor(m, thigh, side * 0.18, 0.656, -0.117, 0.157, 0.27, 0.045, mulberry)
		_armor(m, shin, side * 0.18, 0.348, -0.138, 0.177, 0.36, 0.076, midnight)
		_edge(m, shin, Vector3(side * 0.183, 0.434, -0.188), Vector3(side * 0.163, 0.222, -0.189), 0.022, nickel, 0.009)
		m.box(hand, Vector3(side * 0.615, 0.898, -0.083), Vector3(0.187, 0.045, 0.09), nickel, Vector3(0, 0, side * 0.35))

	# Two visibly different wedges that read as halves of one coffin nail.
	_panel(m, "hand_l", [Vector2(-0.038, -0.425), Vector2(0.031, -0.33), Vector2(0.084, 0.25), Vector2(0.023, 0.404), Vector2(-0.05, 0.278)], Vector3(-0.651, 0.605, -0.111), 0.051, nickel)
	_panel(m, "hand_r", [Vector2(-0.048, -0.33), Vector2(0.093, -0.27), Vector2(0.057, 0.57), Vector2(0.011, 0.63), Vector2(-0.03, 0.208)], Vector3(0.652, 1.096, -0.106), 0.055, nickel)
	_edge(m, "hand_l", Vector3(-0.66, 0.868, -0.151), Vector3(-0.707, 0.255, -0.144), 0.013, lightning, 0.004)
	_edge(m, "hand_r", Vector3(0.679, 0.93, -0.147), Vector3(0.674, 1.61, -0.153), 0.014, lightning, 0.004)

	# The masks meet at an uneven seam, with one recessed black eye versus one
	# inset pale cheekbone. The broken orbit hangs behind, rather than over the face.
	_ellipsoid(m, "head", Vector3(0, 1.758, 0.019), Vector3(0.199, 0.246, 0.20), charcoal)
	_panel(m, "head", [Vector2(-0.156, 0.172), Vector2(0.027, 0.181), Vector2(-0.008, 0.07), Vector2(0.026, 0.024), Vector2(-0.028, -0.156), Vector2(-0.077, -0.101), Vector2(-0.147, -0.040)], Vector3(0, 1.74, -0.18), 0.058, pallor)
	_panel(m, "head", [Vector2(0.04, 0.167), Vector2(0.157, 0.122), Vector2(0.148, -0.044), Vector2(0.073, -0.139), Vector2(0.004, -0.172), Vector2(0.063, 0.038), Vector2(0.019, 0.093)], Vector3(0, 1.735, -0.182), 0.061, midnight)
	for side in [-1.0, 1.0]:
		m.box("head", Vector3(side * 0.074, 1.79, -0.229), Vector3(0.082, 0.018, 0.022), charcoal, Vector3(0, 0, side * 0.135))
		m.box("head", Vector3(side * 0.064, 1.791, -0.244), Vector3(0.029, 0.008, 0.013), lightning)
	_traced_ring(m, "ornament", Vector3(-0.018, 1.81, 0.234), Vector2(0.384, 0.44), -0.72, 1.91, 10, 0.015, nickel)
	_traced_ring(m, "ornament", Vector3(-0.018, 1.81, 0.234), Vector2(0.384, 0.44), 1.44, 1.26, 7, 0.02, pallor)
	_traced_ring(m, "ornament", Vector3(-0.018, 1.81, 0.234), Vector2(0.384, 0.44), 3.03, 1.06, 6, 0.014, mulberry)


static func _forgecaller(m) -> void:
	var slag := "m:332c2d"
	var black := "242227"
	var wrought := "m:696365"
	var brass := "m:92614b"
	var coals := "a23f2e"
	var lava := "e:ff9249"

	# Korr is pitched around the furnace door. The low narrow visor is framed
	# by exposed intake bellows and sits below four crooked chimney mouths.
	_ellipsoid(m, "spine", Vector3(0, 1.24, 0.03), Vector3(0.464, 0.384, 0.291), slag)
	_panel(m, "spine", [Vector2(-0.433, 0.196), Vector2(-0.31, 0.311), Vector2(0.30, 0.311), Vector2(0.432, 0.19), Vector2(0.321, -0.20), Vector2(0.206, -0.372), Vector2(-0.206, -0.372), Vector2(-0.31, -0.24)], Vector3(0, 1.247, -0.266), 0.16, slag)
	_armor(m, "spine", 0, 1.28, -0.361, 0.464, 0.395, 0.095, brass)
	_armor(m, "spine", 0, 1.27, -0.424, 0.345, 0.295, 0.044, black)
	_armor(m, "spine", 0, 1.265, -0.457, 0.268, 0.235, 0.039, coals)
	for i in range(-2, 3):
		m.box("spine", Vector3(i * 0.052, 1.262, -0.493), Vector3(0.024, 0.177, 0.041), slag)
		m.box("spine", Vector3(i * 0.052 + 0.015, 1.253 - absf(float(i)) * 0.017, -0.515), Vector3(0.007, 0.115, 0.015), lava)
	for side in [-1.0, 1.0]:
		_ellipsoid(m, "spine", Vector3(side * 0.173, 1.41, -0.456), Vector3(0.048, 0.046, 0.027), wrought)
		_ellipsoid(m, "spine", Vector3(side * 0.179, 1.133, -0.444), Vector3(0.045, 0.046, 0.027), wrought)
		_edge(m, "spine", Vector3(side * 0.16, 1.05, -0.377), Vector3(side * 0.302, 0.90, -0.196), 0.058, slag, 0.077)
		_edge(m, "spine", Vector3(side * 0.3, 1.38, 0.195), Vector3(side * 0.263, 1.71, 0.25), 0.101, slag, 0.083)
		var suffix := "l" if side < 0 else "r"
		var upper := "upper_" + suffix
		var fore := "fore_" + suffix
		var hand := "hand_" + suffix
		var shin := "shin_" + suffix
		_armor(m, upper, side * 0.461, 1.415, -0.133, 0.37, 0.344, 0.154, slag)
		_armor(m, upper, side * 0.514, 1.439, -0.213, 0.29, 0.241, 0.103, brass)
		_edge(m, upper, Vector3(side * 0.608, 1.447, -0.111), Vector3(side * 0.655, 1.633, -0.099), 0.106, wrought, 0.027)
		_ellipsoid(m, fore, Vector3(side * 0.58, 1.012, -0.01), Vector3(0.16, 0.223, 0.151), slag)
		for j in range(3):
			_edge(m, fore, Vector3(side * 0.65, 0.875, -0.11 + j * 0.065), Vector3(side * 0.596, 1.143, -0.099 + j * 0.07), 0.035, brass, 0.038)
		m.box(hand, Vector3(side * 0.623, 0.827, -0.076), Vector3(0.232, 0.183, 0.232), slag)
		for j in range(3):
			m.box(hand, Vector3(side * (0.552 + j * 0.061), 0.807, -0.213), Vector3(0.032, 0.111, 0.056), wrought)
		_armor(m, "thigh_" + suffix, side * 0.212, 0.699, -0.122, 0.335, 0.292, 0.096, slag)
		_armor(m, shin, side * 0.193, 0.369, -0.117, 0.269, 0.414, 0.128, wrought)
		for j in range(3):
			m.box(shin, Vector3(side * 0.19, 0.255 + j * 0.083, -0.214), Vector3(0.208 - j * 0.032, 0.026, 0.031), black)
		m.box("foot_" + suffix, Vector3(side * 0.195, 0.135, -0.125), Vector3(0.255, 0.138, 0.368), slag)

	_ellipsoid(m, "head", Vector3(0, 1.735, 0.025), Vector3(0.21, 0.214, 0.177), slag)
	_armor(m, "head", 0, 1.691, -0.176, 0.353, 0.244, 0.081, wrought)
	m.box("head", Vector3(0, 1.748, -0.228), Vector3(0.292, 0.047, 0.035), black)
	m.box("head", Vector3(0, 1.753, -0.251), Vector3(0.213, 0.012, 0.012), lava)
	for side in [-1.0, 1.0]:
		_edge(m, "head", Vector3(side * 0.139, 1.623, -0.213), Vector3(side * 0.211, 1.618, 0.006), 0.055, brass, 0.092)
		_ellipsoid(m, "head", Vector3(side * 0.143, 1.641, -0.218), Vector3(0.047, 0.036, 0.023), coals)
	for i in range(4):
		var x := (float(i) - 1.5) * 0.18
		var y := 1.83 + sqrt(absf(x)) * (0.91 if i % 2 else 0.72)
		var chimney := Vector3(x * 1.09, y, 0.46 - i * 0.021)
		_edge(m, "ornament", Vector3(x, 1.49, 0.296), chimney, 0.098, slag, 0.076)
		_edge(m, "ornament", chimney - Vector3.UP * 0.052, chimney + Vector3.UP * 0.006, 0.087, wrought, 0.087)
		_edge(m, "ornament", chimney + Vector3.DOWN * 0.009, chimney + Vector3.UP * 0.012, 0.05, lava, 0.052)
	# Forgemallet: a stone billet in wrought collars. Offset head and heavy
	# grip rotate with the sword-shoulder joints, independent of the furnace.
	_edge(m, "hand_r", Vector3(0.63, 0.62, -0.088), Vector3(0.881, 1.52, -0.078), 0.052, brass, 0.044)
	m.box("hand_r", Vector3(0.885, 1.546, -0.119), Vector3(0.389, 0.218, 0.348), slag, Vector3(0, 0, -0.22))
	for x in [0.71, 0.873, 1.037]:
		m.box("hand_r", Vector3(x, 1.547 - (x - 0.873) * 0.20, -0.304), Vector3(0.045, 0.182, 0.054), wrought, Vector3(0, 0, -0.22))
	m.box("hand_r", Vector3(0.899, 1.515, -0.344), Vector3(0.29, 0.029, 0.014), lava, Vector3(0, 0, -0.22))


static func _armor(m, joint: String, x: float, y: float, z: float, width: float, height: float, thickness: float, color: String) -> void:
	var half_w := width * 0.5
	var half_h := height * 0.5
	_panel(m, joint, [
		Vector2(-half_w, half_h * 0.52), Vector2(-half_w * 0.69, half_h), Vector2(half_w * 0.69, half_h),
		Vector2(half_w, half_h * 0.52), Vector2(half_w, -half_h * 0.32),
		Vector2(half_w * 0.61, -half_h), Vector2(-half_w * 0.61, -half_h), Vector2(-half_w, -half_h * 0.32),
	], Vector3(x, y, z), thickness, color)


static func _panel(m, joint: String, section: Array, center: Vector3, thickness: float, color: String) -> void:
	var points := PackedVector3Array()
	for p: Vector2 in section:
		points.append(center + Vector3(p.x, p.y, 0))
	m.plate(joint, points, thickness, color)


static func _edge(m, joint: String, start: Vector3, end: Vector3, width: float, color: String, end_width: float) -> void:
	m.tube(joint, start, end, width, end_width, color, 6)


static func _ellipsoid(m, joint: String, center: Vector3, radii: Vector3, color: String) -> void:
	m.ellipsoid(joint, center, radii * 2.0, color)


static func _traced_ring(m, joint: String, center: Vector3, radii: Vector2, start: float, span: float, segments: int, width: float, color: String) -> void:
	for i in range(segments):
		var a := start + span * i / float(segments)
		var b := start + span * (i + 1) / float(segments)
		var from := center + Vector3(sin(a) * radii.x, cos(a) * radii.y, 0)
		var to := center + Vector3(sin(b) * radii.x, cos(b) * radii.y, 0)
		m.tube(joint, from, to, width, width, color, 6)
