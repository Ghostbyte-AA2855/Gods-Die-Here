extends RefCounted

# Standing model space faces -Z. Every plate, garment and weapon follows its
# named joint. Armor is built from shaped ring sections and inset face profiles.
static func build(model, class_id: String) -> void:
	match class_id:
		"breakwater": _breakwater(model)
		"threadkeeper": _threadkeeper(model)
		"echo_duelist": _echo_duelist(model)
		"forgecaller": _forgecaller(model)


static func _breakwater(m) -> void:
	var iron := "m:263337"
	var face := "m:516364"
	var silver := "m:86908c"
	var brass := "m:685444"
	var hide := "342726"
	var abyss := "121b1e"
	var reed := "29413a"
	var witchlight := "e:54c4ab"

	# The cuirass is widest at the collar and drawn in sharply at the waist.
	_shell(m, "spine", 0.0, [Vector4(0.89, 0.23, -0.015, 0.167), Vector4(1.04, 0.302, -0.018, 0.196), Vector4(1.32, 0.377, -0.022, 0.241), Vector4(1.51, 0.29, 0.005, 0.194)], iron, face)
	_bevel(m, "spine", Vector3(0, 1.302, -0.234), [Vector2(-0.373, 0.096), Vector2(-0.19, 0.232), Vector2(0, 0.161), Vector2(0.19, 0.232), Vector2(0.373, 0.096), Vector2(0.264, -0.115), Vector2(0, -0.286), Vector2(-0.264, -0.115)], 0.106, silver, face)
	for side in [-1.0, 1.0]:
		_line(m, "spine", Vector3(side * 0.327, 1.396, -0.303), Vector3(0, 1.09, -0.337), 0.016, 0.008, brass)
		_line(m, "spine", Vector3(side * 0.182, 1.51, -0.296), Vector3(0, 1.37, -0.331), 0.012, 0.009, silver)
		_face(m, "pelvis", Vector3(side * 0.191, 0.80, -0.175), [Vector2(-0.15, 0.14), Vector2(0.105, 0.147), Vector2(0.16, -0.117), Vector2(0.064, -0.31), Vector2(-0.091, -0.23)], 0.126, iron)
		for i in range(3):
			_bevel(m, "pelvis", Vector3(side * (0.18 + 0.014 * i), 0.85 - 0.068 * i, -0.25), _pointed(0.238 - i * 0.031, 0.146), 0.042, brass, face)
	m.box("pelvis", Vector3(0, 0.916, -0.23), Vector3(0.51, 0.086, 0.075), hide)
	_bevel(m, "pelvis", Vector3(0, 0.912, -0.282), _pointed(0.15, 0.18), 0.042, brass, iron)

	for side in [-1.0, 1.0]:
		var s := _side(side)
		var upper_index := "upper_" + s
		var fore_index := "fore_" + s
		var hand_index := "hand_" + s
		var lift := 0.075 if side < 0 else -0.010
		# Layering the overlapping plates gives the guard the silhouette of an old diving harness.
		_shell(m, upper_index, side * 0.443, [Vector4(1.23, 0.139, 0, 0.145), Vector4(1.38 + lift, 0.24, 0.016, 0.235), Vector4(1.54 + lift, 0.173, 0.027, 0.194), Vector4(1.62 + lift, 0.075, 0.05, 0.125)], iron, face)
		for i in range(3):
			var x: float = side * (0.434 + i * 0.072)
			var z := -0.195 + i * 0.016
			_bevel(m, upper_index, Vector3(x, 1.49 + lift - i * 0.091, z), _pointed(0.327 - 0.049 * i, 0.215), 0.096, silver, face)
			for crag in range(3):
				var at := Vector3(x + side * (0.024 + crag * 0.028), 1.51 + lift - i * 0.086 + crag * 0.013, z - 0.069)
				_line(m, upper_index, at, at + Vector3(side * 0.011, 0.034 + 0.008 * crag, -0.013), 0.024, 0.010, reed if crag % 2 else brass)
		_shell(m, fore_index, side * 0.529, [Vector4(0.875, 0.087, -0.012, 0.095), Vector4(1.013, 0.155, 0.008, 0.151), Vector4(1.133, 0.104, 0.012, 0.116)], iron, face)
		_bevel(m, fore_index, Vector3(side * 0.538, 1.012, -0.151), _pointed(0.237, 0.262), 0.070, silver, face)
		_gauntlet(m, hand_index, side, iron, face, brass)
		_greaves(m, side, iron, face, brass, hide)

	# Angular sallet with a deeply recessed visor and five fractured iron crown teeth.
	_shell(m, "head", 0, [Vector4(1.566, 0.123, -0.018, 0.121), Vector4(1.638, 0.152, -0.019, 0.166), Vector4(1.790, 0.159, 0, 0.167), Vector4(1.884, 0.118, 0.012, 0.127), Vector4(1.92, 0.052, 0.02, 0.069)], abyss, face)
	_bevel(m, "head", Vector3(0, 1.686, -0.166), [Vector2(-0.171, 0.103), Vector2(-0.077, 0.131), Vector2(0.077, 0.131), Vector2(0.171, 0.103), Vector2(0.13, -0.067), Vector2(0.073, -0.124), Vector2(0, -0.155), Vector2(-0.073, -0.124), Vector2(-0.13, -0.067)], 0.066, face, iron)
	_face(m, "head", Vector3(0, 1.758, -0.212), [Vector2(-0.131, 0.033), Vector2(0, 0.010), Vector2(0.131, 0.033), Vector2(0.129, -0.011), Vector2(0, -0.027), Vector2(-0.129, -0.011)], 0.028, abyss)
	for side in [-1.0, 1.0]:
		_line(m, "head", Vector3(side * 0.108, 1.77, -0.233), Vector3(side * 0.032, 1.759, -0.234), 0.009, 0.005, witchlight)
		_line(m, "head", Vector3(side * 0.149, 1.69, -0.158), Vector3(side * 0.12, 1.592, -0.133), 0.018, 0.011, brass)
		_bevel(m, "head", Vector3(side * 0.125, 1.903, -0.045), [Vector2(-0.062, -0.015), Vector2(0.061, -0.009), Vector2(side * 0.146, 0.158 + side * 0.013), Vector2(side * 0.027, 0.076)], 0.052, silver, face)
	_bevel(m, "head", Vector3(0, 1.880, -0.090), [Vector2(-0.055, -0.015), Vector2(-0.024, 0.111), Vector2(0.021, 0.214), Vector2(0.058, 0.02), Vector2(0.042, -0.028)], 0.060, face, iron)

	# Royal vault door. The pointed rim, buttresses and damaged planking are
	# all shaped silhouettes or modeled relief, carried by modeled rear straps.
	var door := Vector3(-0.655, 0.911, -0.49)
	var door_profile := [Vector2(-0.38, -0.44), Vector2(-0.36, 0.29), Vector2(-0.24, 0.506), Vector2(-0.043, 0.655), Vector2(0.027, 0.603), Vector2(0.235, 0.486), Vector2(0.36, 0.29), Vector2(0.38, -0.42), Vector2(0.04, -0.67), Vector2(-0.095, -0.626)]
	_bevel(m, "hand_l", door, door_profile, 0.125, brass, iron)
	_face(m, "hand_l", door + Vector3(0, -0.013, -0.112), [Vector2(-0.281, -0.41), Vector2(-0.268, 0.25), Vector2(-0.171, 0.397), Vector2(-0.045, 0.524), Vector2(0.153, 0.404), Vector2(0.27, 0.25), Vector2(0.281, -0.37), Vector2(0.016, -0.557)], 0.053, hide)
	for i in range(5):
		var x := -0.231 + i * 0.102
		_face(m, "hand_l", door + Vector3(x, -0.10, -0.154), [Vector2(-0.048, -0.27), Vector2(0.043, -0.27), Vector2(0.043, 0.24 + 0.07 * i), Vector2(-0.055, 0.19 + 0.07 * i)], 0.029, iron if i % 2 == 0 else "3b3530")
		for j in range(2):
			m.box("hand_l", door + Vector3(x + 0.019 * j, -0.251 + 0.112 * j, -0.178), Vector3(0.011, 0.136 - 0.029 * j, 0.015), brass, Vector3(0, 0, -0.036 * i))
	for y in [-0.304, 0.218]:
		_bar(m, "hand_l", door + Vector3(-0.347, y, -0.178), door + Vector3(0.295, y + 0.091, -0.178), 0.081, 0.055, face)
		for x in [-0.29, -0.186, 0.201, 0.271]:
			_rivet(m, "hand_l", door + Vector3(x, y + (x + 0.347) * 0.14, -0.211), 0.024, brass)
		_bar(m, "hand_l", door + Vector3(0.109, y, -0.385), Vector3(-0.59, 0.865 + y * 0.18, 0.045), 0.061, 0.05, hide)
	_bevel(m, "hand_l", door + Vector3(0.102, 0.029, -0.181), _pointed(0.227, 0.354), 0.064, brass, face)
	_face(m, "hand_l", door + Vector3(0.102, 0.022, -0.228), [Vector2(-0.027, 0.068), Vector2(0.031, 0.068), Vector2(0.021, 0.006), Vector2(0.027, -0.078), Vector2(-0.024, -0.078), Vector2(-0.016, 0.009)], 0.009, abyss)
	for i in range(4):
		_line(m, "hand_l", door + Vector3(-0.24 + 0.10 * i, -0.451 + i * 0.045, -0.158), door + Vector3(-0.12 + 0.1 * i, -0.30 - i * 0.013, -0.191), 0.018, 0.009, reed)
	# Heavy hooked falchion, extended to read from the arena camera.
	_bar(m, "hand_r", Vector3(0.564, 0.736, -0.043), Vector3(0.682, 0.99, -0.049), 0.103, 0.084, hide)
	_bar(m, "hand_r", Vector3(0.481, 0.974, -0.095), Vector3(0.818, 0.879, -0.084), 0.084, 0.071, brass)
	_bevel(m, "hand_r", Vector3(0.693, 1.08, -0.075), [Vector2(-0.077, -0.14), Vector2(0.086, -0.129), Vector2(0.269, 0.409), Vector2(0.249, 0.523), Vector2(0.145, 0.484), Vector2(0.105, 0.364)], 0.064, silver, iron)
	_line(m, "hand_r", Vector3(0.72, 1.039, -0.125), Vector3(0.895, 1.494, -0.114), 0.012, 0.008, reed)

	for i in range(4):
		var x := -0.329 + i * 0.141
		_drape(m, "mantle", [Vector3(x, 1.459, 0.23), Vector3(x + 0.171, 1.456, 0.227), Vector3(x + 0.207, 0.967, 0.354), Vector3(x + 0.185, 0.557 + 0.028 * i, 0.385), Vector3(x + 0.026, 0.615 + 0.04 * (i % 2), 0.36)], 0.076, reed if i % 2 else abyss, silver)


static func _threadkeeper(m) -> void:
	var cloth := "251924"
	var bruised := "433043"
	var silk := "523549"
	var pallor := "c1aea2"
	var copper := "m:ac6b56"
	var iron := "m:58505b"
	var shadow := "181219"
	var stitch := "e:c48af3"

	# Maer is shaped like a vertical funeral monument, drawn to a pointed
	# hood above a deep cloth collar and a train of modeled, overlapping folds.
	_shell(m, "spine", 0, [Vector4(0.91, 0.155, 0.01, 0.126), Vector4(1.07, 0.190, -0.018, 0.153), Vector4(1.27, 0.273, -0.013, 0.196), Vector4(1.433, 0.218, 0.019, 0.17)], cloth, bruised)
	_bevel(m, "spine", Vector3(0, 1.29, -0.188), [Vector2(-0.277, 0.09), Vector2(-0.117, 0.191), Vector2(0.134, 0.194), Vector2(0.272, 0.092), Vector2(0.095, -0.289), Vector2(0.012, -0.373), Vector2(-0.108, -0.287)], 0.053, bruised, cloth)
	for i in range(7):
		var x := -0.25 + float(i) * 0.084
		var edge := absf(x)
		_drape(m, "pelvis", [Vector3(x * 0.66 - 0.05, 0.965, -0.167 + edge * 0.14), Vector3(x * 0.66 + 0.05, 0.977, -0.167 + edge * 0.14), Vector3(x * 1.30 + 0.068, 0.427, -0.168 + edge * 0.38), Vector3(x * 1.64 + 0.038, 0.15 + edge * 0.38 + (i % 2) * 0.10, -0.128 + edge * 0.34), Vector3(x * 1.64 - 0.063, 0.16 + edge * 0.29, -0.161 + edge * 0.46), Vector3(x * 1.17 - 0.068, 0.466, -0.174 + edge * 0.35)], 0.059 + 0.016 * float(i % 2), cloth if i % 2 else bruised, silk)
	for i in range(5):
		var x := -0.227 + i * 0.105
		_drape(m, "mantle", [Vector3(x - 0.081, 1.43, 0.168), Vector3(x + 0.089, 1.429, 0.164), Vector3(x * 1.36 + 0.105, 0.61, 0.331), Vector3(x * 1.75 + 0.064, 0.151 + i * 0.046, 0.378), Vector3(x * 1.72 - 0.103, 0.265 + i * 0.030, 0.366)], 0.062, bruised if i % 2 else cloth, silk)
	_line(m, "spine", Vector3(-0.202, 1.456, -0.229), Vector3(0.13, 0.971, -0.248), 0.019, 0.016, copper)
	_line(m, "spine", Vector3(0.202, 1.456, -0.228), Vector3(-0.111, 0.973, -0.250), 0.018, 0.016, copper)
	for i in range(7):
		_bar(m, "spine", Vector3(-0.061 - i * 0.006, 1.121 + i * 0.041, -0.255), Vector3(0.077 + i * 0.003, 1.152 + i * 0.04, -0.259), 0.012, 0.013, pallor)
	for side in [-1.0, 1.0]:
		var s := _side(side)
		_face(m, "upper_" + s, Vector3(side * 0.365, 1.426, -0.108), [Vector2(-0.118, 0.094), Vector2(0.061, 0.122), Vector2(0.144, -0.042), Vector2(0.053, -0.24), Vector2(-0.09, -0.258)], 0.115, bruised)
		_shell(m, "fore_" + s, side * 0.537, [Vector4(0.868, 0.094, -0.007, 0.108), Vector4(0.958, 0.132, -0.021, 0.126), Vector4(1.131, 0.073, 0.004, 0.086)], cloth, silk)
		_bevel(m, "fore_" + s, Vector3(side * 0.55, 0.952, -0.124), _pointed(0.166, 0.211), 0.033, copper, iron)
		_face(m, "hand_" + s, Vector3(side * 0.607, 0.835, -0.10), _pointed(0.127, 0.14), 0.042, iron)
		for i in range(4):
			var start := Vector3(side * (0.561 + i * 0.026), 0.825, -0.122)
			_line(m, "hand_" + s, start, start + Vector3(side * 0.006, -0.105 + i * 0.014, -0.04), 0.013, 0.005, pallor)
		_pointed_boot(m, side, cloth, iron, copper, -0.232, 0.10)

	_shell(m, "head", 0, [Vector4(1.535, 0.151, 0.009, 0.136), Vector4(1.647, 0.166, -0.006, 0.17), Vector4(1.785, 0.168, 0.011, 0.178), Vector4(1.902, 0.127, 0.046, 0.13), Vector4(2.008, 0.039, 0.105, 0.067), Vector4(2.06, 0.009, 0.133, 0.017)], shadow, bruised)
	for side in [-1.0, 1.0]:
		_face(m, "head", Vector3(side * 0.14, 1.759, -0.161), [Vector2(-0.04, 0.174), Vector2(0.038, 0.154), Vector2(0.051, -0.069), Vector2(-0.032, -0.21)], 0.055, shadow)
		_line(m, "head", Vector3(side * 0.146, 1.85, -0.183), Vector3(side * 0.136, 1.595, -0.192), 0.012, 0.007, copper)
	# The thin ivory veil encases the lower face beneath a sharply shadowed brow.
	_bevel(m, "head", Vector3(0, 1.688, -0.166), [Vector2(-0.111, 0.116), Vector2(-0.064, 0.095), Vector2(0, 0.122), Vector2(0.064, 0.095), Vector2(0.111, 0.116), Vector2(0.122, -0.015), Vector2(0.065, -0.133), Vector2(0.011, -0.171), Vector2(-0.072, -0.11), Vector2(-0.118, -0.007)], 0.05, "89736a", pallor)
	for i in range(-4, 5):
		var x := float(i) * 0.022
		_line(m, "head", Vector3(x, 1.706 + absf(x) * 0.12, -0.207), Vector3(x * 0.58, 1.654 + absf(x) * 0.18, -0.213), 0.0065, 0.006, copper)
	_face(m, "head", Vector3(0, 1.769, -0.193), [Vector2(-0.131, 0.055), Vector2(0, 0.084), Vector2(0.124, 0.042), Vector2(0.111, -0.017), Vector2(0, 0.002), Vector2(-0.119, -0.021)], 0.045, shadow)
	for side in [-1.0, 1.0]:
		_line(m, "head", Vector3(side * 0.088, 1.764, -0.224), Vector3(side * 0.034, 1.755, -0.225), 0.008, 0.003, stitch)

	# Arc spines climb over the head and pull the luminous threads into a knot.
	var halo := Vector3(0, 1.822, 0.283)
	_ring(m, "ornament", halo, Vector2(0.391, 0.448), -1.24, 3.67, 18, 0.016, copper)
	_ring(m, "ornament", halo + Vector3(0, -0.011, 0.028), Vector2(0.345, 0.397), -1.19, 3.45, 18, 0.012, iron)
	for i in range(8):
		var a := -1.10 + i * 0.457
		var at := halo + Vector3(sin(a) * 0.402, cos(a) * 0.448, 0)
		_line(m, "ornament", at, at + Vector3(sin(a) * 0.065, cos(a) * 0.067, -0.039), 0.028, 0.001, pallor)
		_line(m, "ornament", at, halo + Vector3(-sin(a) * 0.045, -0.125, 0.026), 0.0045, 0.005, stitch)
	# Suture crook with a stripped shaft and a sharpened, curved needle head.
	_bar(m, "hand_r", Vector3(0.471, 0.196, -0.032), Vector3(0.701, 1.841, -0.018), 0.041, 0.049, iron)
	for i in range(11):
		var t := float(i) / 10.0
		var y := 0.398 + i * 0.12
		_bar(m, "hand_r", Vector3(0.474 + 0.209 * t, y, -0.061), Vector3(0.52 + 0.22 * t, y + 0.031, -0.06), 0.028, 0.027, copper)
	_ring(m, "hand_r", Vector3(0.728, 1.875, -0.03), Vector2(0.165, 0.249), -0.37, 5.02, 16, 0.027, copper)
	_ring(m, "hand_r", Vector3(0.728, 1.875, -0.039), Vector2(0.125, 0.204), -0.24, 4.64, 16, 0.010, stitch)
	_line(m, "hand_r", Vector3(0.57, 1.91, -0.032), Vector3(0.653, 1.688, -0.036), 0.032, 0.003, pallor)
	_line(m, "hand_r", Vector3(0.731, 1.627, -0.04), Vector3(0.794, 2.084, -0.041), 0.007, 0.007, stitch)
	_line(m, "hand_l", Vector3(-0.608, 0.836, -0.139), Vector3(-0.751, 0.585, -0.18), 0.012, 0.002, copper)


static func _echo_duelist(m) -> void:
	var shadow := "181720"
	var ash := "2a263a"
	var leather := "4a303b"
	var gunmetal := "m:51566b"
	var bright := "m:8f91aa"
	var bone := "c5b6ab"
	var buried_glow := "e:a88bd8"

	# One diagonal set of overlapping blades forms the duelist's body armor.
	_shell(m, "spine", -0.003, [Vector4(0.877, 0.179, -0.003, 0.159), Vector4(1.062, 0.225, 0.009, 0.172), Vector4(1.302, 0.295, -0.015, 0.203), Vector4(1.472, 0.231, 0.021, 0.157)], ash, gunmetal)
	_bevel(m, "spine", Vector3(0, 1.246, -0.209), [Vector2(-0.314, 0.158), Vector2(-0.217, 0.245), Vector2(0.204, 0.198), Vector2(0.284, 0.116), Vector2(0.177, -0.105), Vector2(-0.097, -0.287), Vector2(-0.229, -0.123)], 0.060, gunmetal, ash)
	for i in range(5):
		var y := 1.38 - i * 0.073
		_face(m, "spine", Vector3(-0.032 - i * 0.018, y, -0.259), [Vector2(-0.223, -0.044), Vector2(-0.129, 0.058), Vector2(0.213 - 0.021 * i, 0.104), Vector2(0.186 - 0.025 * i, 0.017), Vector2(-0.136, -0.091)], 0.039, leather if i == 2 else gunmetal)
		_line(m, "spine", Vector3(-0.233 - i * 0.018, y - 0.048, -0.283), Vector3(0.122 - 0.036 * i, y + 0.024, -0.280), 0.009, 0.008, bright)
	_bar(m, "spine", Vector3(-0.261, 1.474, -0.269), Vector3(0.121, 0.942, -0.253), 0.051, 0.031, leather)
	for i in range(5):
		_rivet(m, "spine", Vector3(-0.195 + i * 0.056, 1.385 - i * 0.075, -0.291), 0.014, bright)
	_drape(m, "mantle", [Vector3(-0.278, 1.453, 0.188), Vector3(0.083, 1.44, 0.174), Vector3(0.20, 1.109, 0.291), Vector3(0.12, 0.527, 0.395), Vector3(0.018, 0.433, 0.420), Vector3(-0.073, 0.676, 0.34), Vector3(-0.181, 0.468, 0.348), Vector3(-0.303, 0.595, 0.29)], 0.058, leather, ash)
	_drape(m, "mantle", [Vector3(-0.37, 1.408, 0.172), Vector3(-0.185, 1.423, 0.224), Vector3(-0.135, 0.927, 0.340), Vector3(-0.291, 0.704, 0.354), Vector3(-0.324, 0.878, 0.279)], 0.048, shadow, leather)

	for side in [-1.0, 1.0]:
		var s := _side(side)
		var wide := 0.14 if side < 0 else 0.083
		_shell(m, "upper_" + s, side * 0.428, [Vector4(1.192, 0.094, 0, 0.109), Vector4(1.375, wide + 0.019, -0.008, 0.163), Vector4(1.471, wide, 0.015, 0.14), Vector4(1.528, 0.081, 0.030, 0.106)], shadow, gunmetal)
		_bevel(m, "upper_" + s, Vector3(side * 0.435, 1.397, -0.166), [Vector2(-0.161, 0.079), Vector2(-0.071, 0.147), Vector2(0.083, 0.132), Vector2(0.181, 0.036), Vector2(0.144, -0.043), Vector2(0.055, -0.155), Vector2(-0.133, -0.087)], 0.069, bright if side < 0 else gunmetal, ash)
		_shell(m, "fore_" + s, side * 0.547, [Vector4(0.855, 0.08, -0.021, 0.087), Vector4(0.952, 0.099, -0.018, 0.105), Vector4(1.137, 0.083, 0.008, 0.109)], leather, gunmetal)
		for i in range(3):
			_bevel(m, "fore_" + s, Vector3(side * (0.552 + i * 0.013), 1.032 - i * 0.058, -0.121), _pointed(0.171 - 0.018 * i, 0.101), 0.032, bright, gunmetal)
		_gauntlet(m, "hand_" + s, side, leather, gunmetal, bright)
		_shell(m, "thigh_" + s, side * 0.18, [Vector4(0.502, 0.067, -0.009, 0.075), Vector4(0.697, 0.119, 0.007, 0.126), Vector4(0.86, 0.109, 0, 0.117)], shadow, leather)
		_bevel(m, "thigh_" + s, Vector3(side * 0.185, 0.669, -0.123), _pointed(0.171, 0.264), 0.034, bright, gunmetal)
		_shell(m, "shin_" + s, side * 0.181, [Vector4(0.191, 0.071, 0.003, 0.077), Vector4(0.344, 0.099, 0.0, 0.104), Vector4(0.528, 0.102, -0.006, 0.119)], leather, ash)
		_bevel(m, "shin_" + s, Vector3(side * 0.18, 0.374, -0.114), _pointed(0.148, 0.298), 0.034, bright, gunmetal)
		_pointed_boot(m, side, shadow, gunmetal, bright, -0.281, 0.099)

	# Separate pieces of the burial mask overlap a narrow, faceted cowl.
	_shell(m, "head", 0.0, [Vector4(1.562, 0.103, 0.016, 0.125), Vector4(1.645, 0.140, -0.009, 0.148), Vector4(1.791, 0.148, 0.011, 0.161), Vector4(1.884, 0.117, 0.027, 0.143), Vector4(1.927, 0.048, 0.041, 0.069)], shadow, ash)
	_bevel(m, "head", Vector3(0, 1.729, -0.169), [Vector2(-0.14, 0.092), Vector2(-0.086, 0.15), Vector2(0.023, 0.137), Vector2(-0.018, 0.092), Vector2(0.008, 0.032), Vector2(-0.020, -0.017), Vector2(0.009, -0.080), Vector2(-0.036, -0.144), Vector2(-0.109, -0.086)], 0.053, "847164", bone)
	_bevel(m, "head", Vector3(0, 1.722, -0.162), [Vector2(0.033, 0.132), Vector2(0.125, 0.103), Vector2(0.15, 0.063), Vector2(0.113, -0.091), Vector2(0.053, -0.148), Vector2(0.014, -0.085), Vector2(0.042, -0.022), Vector2(0.027, 0.037), Vector2(0.056, 0.064)], 0.056, shadow, gunmetal)
	for side in [-1.0, 1.0]:
		_line(m, "head", Vector3(side * 0.115, 1.789, -0.209), Vector3(side * 0.05, 1.773, -0.212), 0.018, 0.015, shadow)
		_line(m, "head", Vector3(side * 0.095, 1.786, -0.221), Vector3(side * 0.058, 1.777, -0.219), 0.005, 0.002, buried_glow)
	_ring(m, "ornament", Vector3(-0.024, 1.789, 0.252), Vector2(0.384, 0.42), -0.85, 1.88, 16, 0.013, bright)
	_ring(m, "ornament", Vector3(-0.033, 1.810, 0.261), Vector2(0.371, 0.404), 1.48, 1.37, 12, 0.019, gunmetal)
	_ring(m, "ornament", Vector3(-0.021, 1.764, 0.247), Vector2(0.354, 0.389), 3.38, 1.33, 12, 0.012, leather)
	for a in [-0.54, -0.11, 0.63, 1.69, 2.34, 3.69, 4.2]:
		var point := Vector3(-0.025 + sin(a) * 0.38, 1.789 + cos(a) * 0.42, 0.251)
		_line(m, "ornament", point, point + Vector3(sin(a) * 0.063, cos(a) * 0.073, 0.017), 0.018, 0.002, gunmetal)
	# One nail carries the broken crossbar, and the other preserves the point.
	_bar(m, "hand_l", Vector3(-0.616, 0.927, -0.109), Vector3(-0.647, 0.701, -0.114), 0.075, 0.072, leather)
	_bar(m, "hand_l", Vector3(-0.755, 0.783, -0.124), Vector3(-0.542, 0.750, -0.123), 0.06, 0.045, gunmetal)
	_bevel(m, "hand_l", Vector3(-0.658, 0.711, -0.141), [Vector2(-0.081, 0.06), Vector2(0.061, 0.063), Vector2(0.019, -0.052), Vector2(-0.011, -0.392), Vector2(-0.102, -0.533), Vector2(-0.11, -0.401)], 0.051, bright, gunmetal)
	_line(m, "hand_l", Vector3(-0.657, 0.713, -0.184), Vector3(-0.739, 0.224, -0.173), 0.009, 0.004, buried_glow)
	_bar(m, "hand_r", Vector3(0.6, 0.735, -0.101), Vector3(0.652, 0.987, -0.111), 0.071, 0.066, leather)
	_bar(m, "hand_r", Vector3(0.545, 0.938, -0.107), Vector3(0.809, 0.912, -0.126), 0.078, 0.050, gunmetal)
	_bevel(m, "hand_r", Vector3(0.674, 0.967, -0.132), [Vector2(-0.042, -0.019), Vector2(0.055, -0.02), Vector2(0.078, 0.265), Vector2(0.159, 0.61), Vector2(0.122, 0.724), Vector2(0.011, 0.649), Vector2(-0.023, 0.266), Vector2(-0.060, 0.099)], 0.051, bright, gunmetal)
	_line(m, "hand_r", Vector3(0.676, 1.013, -0.177), Vector3(0.787, 1.661, -0.164), 0.011, 0.002, buried_glow)


static func _forgecaller(m) -> void:
	var slag := "m:353035"
	var char := "262228"
	var nickel := "m:6c6262"
	var brass := "m:93634d"
	var crust := "672d20"
	var molten := "e:ff7d36"

	# Korr wears a full black foundry harness, wideset and armoured on
	# every side. A custom faceted firebox breaks the heavy torso open.
	_shell(m, "spine", 0.014, [Vector4(0.865, 0.273, 0.019, 0.211), Vector4(1.033, 0.365, 0.001, 0.258), Vector4(1.291, 0.454, 0.012, 0.293), Vector4(1.452, 0.413, 0.023, 0.276), Vector4(1.543, 0.274, 0.062, 0.201)], slag, nickel)
	_bevel(m, "spine", Vector3(0, 1.227, -0.298), [Vector2(-0.417, 0.150), Vector2(-0.289, 0.274), Vector2(0.282, 0.278), Vector2(0.427, 0.138), Vector2(0.315, -0.166), Vector2(0.188, -0.369), Vector2(-0.208, -0.363), Vector2(-0.318, -0.172)], 0.096, nickel, slag)
	var firebox := [Vector2(-0.235, -0.138), Vector2(-0.238, 0.12), Vector2(-0.112, 0.225), Vector2(0.106, 0.225), Vector2(0.237, 0.118), Vector2(0.229, -0.153), Vector2(0, -0.208)]
	_bevel(m, "spine", Vector3(0, 1.245, -0.365), firebox, 0.116, brass, char)
	_face(m, "spine", Vector3(0, 1.235, -0.443), _pointed(0.321, 0.309), 0.044, crust)
	for i in range(-3, 4):
		var h := absf(float(i)) * 0.013
		_bar(m, "spine", Vector3(i * 0.044, 1.11 + h, -0.481), Vector3(i * 0.046, 1.385 - h, -0.484), 0.012, 0.023, molten)
		_bar(m, "spine", Vector3(i * 0.049 - 0.008, 1.107 + h, -0.496), Vector3(i * 0.05 - 0.008, 1.407 - h, -0.493), 0.023, 0.043, slag)
	for side in [-1.0, 1.0]:
		var s := _side(side)
		_bar(m, "spine", Vector3(side * 0.19, 1.127, -0.425), Vector3(side * 0.337, 0.965, -0.317), 0.093, 0.067, brass)
		for ind in range(5):
			_rivet(m, "spine", Vector3(side * (0.201 + sin(ind * 0.44) * 0.057), 1.073 + ind * 0.081, -0.441), 0.021, nickel)
		var upper_index := "upper_" + s
		var fore_index := "fore_" + s
		var hand_index := "hand_" + s
		_shell(m, upper_index, side * 0.507, [Vector4(1.192, 0.179, 0.012, 0.181), Vector4(1.338, 0.234, 0.021, 0.243), Vector4(1.485, 0.202, 0.034, 0.188), Vector4(1.596, 0.125, 0.029, 0.141)], slag, nickel)
		for i in range(3):
			_bevel(m, upper_index, Vector3(side * (0.459 + 0.073 * i), 1.496 - i * 0.089, -0.206 + i * 0.015), [Vector2(-0.114, 0.074), Vector2(-0.07, 0.109), Vector2(0.147, 0.08), Vector2(0.124, -0.107), Vector2(-0.136, -0.054)], 0.096 - i * 0.014, brass, slag)
		_line(m, upper_index, Vector3(side * 0.609, 1.488, 0.006), Vector3(side * 0.685, 1.692, 0.106), 0.097, 0.023, nickel)
		_shell(m, fore_index, side * 0.563, [Vector4(0.851, 0.123, -0.004, 0.131), Vector4(1.013, 0.16, -0.013, 0.157), Vector4(1.158, 0.135, 0.035, 0.139)], slag, nickel)
		for i in range(3):
			_bar(m, fore_index, Vector3(side * (0.48 + i * 0.061), 0.871, -0.164), Vector3(side * (0.464 + i * 0.061), 1.117, -0.142), 0.043, 0.038, brass)
			_line(m, fore_index, Vector3(side * (0.481 + i * 0.061), 0.939, -0.189), Vector3(side * (0.461 + i * 0.061), 1.068, -0.170), 0.008, 0.006, molten)
		_gauntlet(m, hand_index, side, slag, nickel, brass)
		_greaves(m, side, slag, nickel, brass, char)

	# Small, severe helmet nested visibly into the shoulder silhouette.
	_shell(m, "head", 0, [Vector4(1.555, 0.108, -0.025, 0.126), Vector4(1.635, 0.145, -0.019, 0.150), Vector4(1.773, 0.153, 0.001, 0.148), Vector4(1.846, 0.124, 0.026, 0.126), Vector4(1.905, 0.057, 0.048, 0.070)], slag, nickel)
	_bevel(m, "head", Vector3(0, 1.670, -0.158), [Vector2(-0.145, 0.109), Vector2(0.139, 0.103), Vector2(0.128, -0.042), Vector2(0.063, -0.124), Vector2(-0.069, -0.125), Vector2(-0.137, -0.047)], 0.076, brass, slag)
	_face(m, "head", Vector3(0, 1.754, -0.199), [Vector2(-0.126, 0.027), Vector2(0, 0.009), Vector2(0.119, 0.028), Vector2(0.111, -0.025), Vector2(0, -0.038), Vector2(-0.116, -0.025)], 0.022, char)
	for side in [-1.0, 1.0]:
		_line(m, "head", Vector3(side * 0.103, 1.756, -0.221), Vector3(side * 0.022, 1.748, -0.223), 0.009, 0.006, molten)
		_bar(m, "head", Vector3(side * 0.046, 1.599, -0.200), Vector3(side * 0.13, 1.649, -0.199), 0.019, 0.022, brass)
		_line(m, "head", Vector3(side * 0.136, 1.628, -0.173), Vector3(side * 0.186, 1.616, 0.108), 0.054, 0.073, slag)

	# Four battered stacks each have a rim, a dark mouth, and a deeper glow.
	for i in range(4):
		var x := (i - 1.52) * 0.18
		var height := 1.97 + (0.15 if i in [0, 3] else 0.064) + (0.06 if i % 2 else 0.0)
		var bottom := Vector3(x * 0.71, 1.38 + i * 0.04, 0.235)
		var mouth := Vector3(x * 1.16, height, 0.43 - i * 0.027)
		m.tube("ornament", bottom, mouth, 0.091, 0.067, slag, 6)
		m.tube("ornament", mouth + Vector3.DOWN * 0.068, mouth + Vector3.DOWN * 0.023, 0.078, 0.088, brass, 6)
		m.tube("ornament", mouth + Vector3.DOWN * 0.024, mouth + Vector3.UP * 0.006, 0.064, 0.062, char, 7)
		m.tube("ornament", mouth + Vector3.UP * 0.006, mouth + Vector3.UP * 0.008, 0.043, 0.043, crust if i % 2 else molten, 7)
		for j in range(2):
			_rivet(m, "ornament", mouth + Vector3(0.045 * (j * 2 - 1), -0.09, 0.066), 0.011, nickel)

	# A fractured furnace-mallet with a faceted head and interlocking metal wedges.
	_bar(m, "hand_r", Vector3(0.544, 0.606, -0.025), Vector3(0.826, 1.578, -0.123), 0.067, 0.070, brass)
	for i in range(9):
		var t := i / 8.0
		_bar(m, "hand_r", Vector3(0.535 + 0.187 * t, 0.697 + 0.481 * t, -0.075 - 0.047 * t), Vector3(0.61 + 0.183 * t, 0.714 + 0.483 * t, -0.079 - 0.044 * t), 0.033, 0.035, char)
	var hammer := Vector3(0.873, 1.53, -0.173)
	_bevel(m, "hand_r", hammer, [Vector2(-0.32, -0.16), Vector2(-0.283, 0.121), Vector2(-0.174, 0.192), Vector2(0.168, 0.153), Vector2(0.277, 0.08), Vector2(0.29, -0.153), Vector2(0.167, -0.196), Vector2(-0.229, -0.188)], 0.285, nickel, slag)
	for x in [-0.242, -0.13, 0.106, 0.209]:
		_bar(m, "hand_r", hammer + Vector3(x, -0.118, -0.211), hammer + Vector3(x - 0.017, 0.121, -0.195), 0.038, 0.041, brass)
	_line(m, "hand_r", hammer + Vector3(-0.221, 0.053, -0.236), hammer + Vector3(0.206, -0.078, -0.224), 0.015, 0.026, molten)


static func _side(side: float) -> String:
	return "l" if side < 0 else "r"


static func _pointed(width: float, height: float) -> Array:
	return [
		Vector2(-width * 0.50, height * 0.23), Vector2(-width * 0.30, height * 0.5),
		Vector2(width * 0.31, height * 0.5), Vector2(width * 0.50, height * 0.23),
		Vector2(width * 0.41, -height * 0.16), Vector2(width * 0.115, -height * 0.45),
		Vector2(0, -height * 0.5), Vector2(-width * 0.41, -height * 0.18),
	]


static func _at_ring(center_x: float, section: Vector4, index: int) -> Vector3:
	const CORNERS := [Vector2(-0.64, -1.0), Vector2(0.64, -1.0), Vector2(1, -0.60), Vector2(1, 0.60), Vector2(0.64, 1), Vector2(-0.64, 1), Vector2(-1, 0.60), Vector2(-1, -0.60)]
	var corner: Vector2 = CORNERS[index]
	return Vector3(center_x + corner.x * section.y, section.x, section.z + corner.y * section.w)


static func _shell(m, joint: String, center_x: float, sections: Array, base: String, facet: String) -> void:
	for i in range(sections.size() - 1):
		for j in range(8):
			var next := (j + 1) % 8
			var a := _at_ring(center_x, sections[i], j)
			var b := _at_ring(center_x, sections[i], next)
			var c := _at_ring(center_x, sections[i + 1], next)
			var d := _at_ring(center_x, sections[i + 1], j)
			var color := facet if j in [1, 7] and i % 2 != 1 else base
			m.plate(joint, PackedVector3Array([a, b, c]), 0.011, color)
			m.plate(joint, PackedVector3Array([a, c, d]), 0.011, color)
	for end in [0, sections.size() - 1]:
		var points := PackedVector3Array()
		for j in range(8):
			points.append(_at_ring(center_x, sections[end], j))
		m.plate(joint, points, 0.009, base)


static func _face(m, joint: String, center: Vector3, silhouette: Array, depth: float, color: String) -> void:
	var points := PackedVector3Array()
	for p: Vector2 in silhouette:
		points.append(center + Vector3(p.x, p.y, 0))
	m.plate(joint, points, depth, color)


static func _bevel(m, joint: String, center: Vector3, silhouette: Array, depth: float, edge: String, face: String) -> void:
	_face(m, joint, center, silhouette, depth, edge)
	var inset := []
	for p: Vector2 in silhouette:
		inset.append(Vector2(p.x * 0.86, p.y * 0.88))
	_face(m, joint, center + Vector3(0, 0, -depth * 0.423), inset, depth * 0.33, face)


static func _line(m, joint: String, a: Vector3, b: Vector3, radius: float, tip_radius: float, color: String) -> void:
	m.tube(joint, a, b, radius, tip_radius, color, 6)


static func _bar(m, joint: String, a: Vector3, b: Vector3, width: float, depth: float, color: String) -> void:
	# A rotated low-sided tube gives forged bars square faces and softer edges.
	var radius := width * 0.707
	var side_count := 4 if depth < width * 0.80 else 6
	m.tube(joint, a, b, radius, radius, color, side_count)


static func _rivet(m, joint: String, at: Vector3, width: float, color: String) -> void:
	m.tube(joint, at + Vector3.BACK * 0.012, at + Vector3.FORWARD * 0.013, width, width * 0.81, color, 6)


static func _drape(m, joint: String, points: Array, depth: float, color: String, hem: String) -> void:
	var tri := PackedVector3Array(points)
	m.plate(joint, tri, depth, color)
	for i in range(1, points.size() - 1):
		var a: Vector3 = points[i]
		var b: Vector3 = points[i + 1]
		_line(m, joint, a + Vector3.BACK * 0.018, b + Vector3.BACK * 0.018, 0.007, 0.006, hem)


static func _ring(m, joint: String, center: Vector3, radii: Vector2, start: float, span: float, segments: int, width: float, color: String) -> void:
	for i in range(segments):
		var a := start + span * i / float(segments)
		var b := start + span * (i + 1) / float(segments)
		_line(m, joint, center + Vector3(sin(a) * radii.x, cos(a) * radii.y, 0), center + Vector3(sin(b) * radii.x, cos(b) * radii.y, 0), width, width, color)


static func _gauntlet(m, joint: String, side: float, shell: String, face: String, lining: String) -> void:
	_shell(m, joint, side * 0.61, [Vector4(0.744, 0.06, -0.034, 0.048), Vector4(0.792, 0.085, -0.036, 0.067), Vector4(0.857, 0.087, -0.014, 0.076), Vector4(0.921, 0.073, -0.01, 0.061)], shell, face)
	for i in range(4):
		var x := side * (0.546 + i * 0.039)
		_bevel(m, joint, Vector3(x, 0.809 + (3 - i) * 0.004, -0.095), _pointed(0.052, 0.102), 0.022, lining, face)
		_line(m, joint, Vector3(x, 0.809, -0.111), Vector3(x + side * 0.003, 0.75, -0.108), 0.013, 0.009, shell)


static func _greaves(m, side: float, steel: String, face: String, brass: String, hide: String) -> void:
	var s := _side(side)
	_shell(m, "thigh_" + s, side * 0.18, [Vector4(0.491, 0.101, -0.012, 0.109), Vector4(0.679, 0.161, 0.001, 0.157), Vector4(0.901, 0.142, 0.003, 0.141)], hide, steel)
	_bevel(m, "thigh_" + s, Vector3(side * 0.185, 0.683, -0.147), _pointed(0.293, 0.327), 0.069, brass, steel)
	_shell(m, "shin_" + s, side * 0.179, [Vector4(0.155, 0.081, 0.001, 0.089), Vector4(0.336, 0.106, -0.014, 0.118), Vector4(0.51, 0.132, -0.001, 0.139), Vector4(0.577, 0.111, 0.017, 0.124)], steel, face)
	_bevel(m, "shin_" + s, Vector3(side * 0.183, 0.346, -0.122), [Vector2(-0.12, 0.183), Vector2(0.108, 0.178), Vector2(0.096, -0.133), Vector2(0, -0.213), Vector2(-0.096, -0.137)], 0.061, face, steel)
	_bevel(m, "shin_" + s, Vector3(side * 0.18, 0.514, -0.166), _pointed(0.251, 0.194), 0.068, brass, face)
	for i in range(3):
		_rivet(m, "shin_" + s, Vector3(side * (0.246 - 0.012 * i), 0.382 - 0.064 * i, -0.171), 0.012, brass)
	_pointed_boot(m, side, hide, face, brass, -0.291, 0.119)


static func _pointed_boot(m, side: float, leather: String, metal: String, edging: String, toe_z: float, width: float) -> void:
	var joint := "foot_" + _side(side)
	var x := side * 0.181
	var foot := PackedVector3Array([
		Vector3(x - width, 0.045, 0.094), Vector3(x + width, 0.045, 0.094),
		Vector3(x + width, 0.045, -0.108), Vector3(x + width * 0.7, 0.045, toe_z + 0.046),
		Vector3(x + side * 0.036, 0.045, toe_z), Vector3(x - width * 0.62, 0.045, toe_z + 0.057),
		Vector3(x - width, 0.045, -0.097),
	])
	m.plate(joint, foot, 0.055, leather)
	for i in range(4):
		var z := -0.056 + (toe_z + 0.104) * i / 3.0
		var offset := side * 0.018 * i / 3.0
		var w := width * (1.02 - float(i) * 0.105)
		var y := 0.151 - i * 0.019
		m.plate(joint, PackedVector3Array([
			Vector3(x - w + offset, y - 0.048, z + 0.040),
			Vector3(x - w * 0.59 + offset, y, z + 0.044),
			Vector3(x + w * 0.59 + offset, y, z + 0.044),
			Vector3(x + w + offset, y - 0.048, z + 0.021),
			Vector3(x + w * 0.68 + offset, y - 0.025, z - 0.06),
			Vector3(x - w * 0.67 + offset, y - 0.025, z - 0.059),
		]), 0.035, metal if i % 2 else edging)
