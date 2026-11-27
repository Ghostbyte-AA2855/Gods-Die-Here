extends RefCounted

# Rhuun's choir vestments use arterial reds over old silver.
const CASSOCK := "210b16"
const VERMILION := "8c2439"
const WINE := "572136"
const SILVER := "b7a4a0"
const TARNISH := "725559"
const COAGULATE := "bf3851"
const CHOIR_SKIN := "8d6b70"

# Hest's bronze is blackened except where the rain polishes the bell rims.
const BLACK_BRONZE := "222025"
const BRONZE := "715748"
const BRASS := "b39262"
const PATINA := "426964"
const GRAVE_CLOTH := "23242a"
const TOLL_LIGHT := "bb8241"

# Zarya wears split slag-glass plates that show the fire between them.
const OBSIDIAN := "271c24"
const CHAR := "45313a"
const SCALE := "80504a"
const HEAT := "97392a"
const FIRE := "9f3828"
const CORE := "ffae64"
const ASH_SKIN := "94696b"
const FORGED_EDGE := "d49a62"
const PYRE_GOLD := "ffd098"

# Eive's oath lets color survive only in the ice and the inventory seals.
const INDIGO := "191f30"
const RIME_CLOTH := "415668"
const SCRIBE_IRON := "53616a"
const BONE := "c6bdab"
const PAPER := "bba986"
const ICE := "729eb7"
const SEAL_GLOW := "85c0d3"

static func build(model, class_id: String) -> void:
	match class_id:
		"blood_cantor":
			_rhuun(model)
			_choir_reliquary(model)
			_choir_vestment(model)
		"bellwarden":
			_hest(model)
			_toll_plate(model)
			_funeral_yoke(model)
		"ash_dancer":
			_zarya(model)
			_pyre_harness(model)
			_cinder_ribbons(model)
		"winter_scribe":
			_eive(model)
			_winter_regalia(model)
			_pale_record(model)


static func _rhuun(m) -> void:
	# The choir's silhouette starts high and narrow, then descends into two uneven red panels.
	_cuirass(m, "spine", [[0.94, 0.224, 0.151], [1.02, 0.252, 0.180], [1.24, 0.291, 0.202], [1.38, 0.328, 0.173], [1.466, 0.194, 0.145]], CASSOCK)
	_folded_shroud(m, "mantle", 0.97, 0.13, 0.33, 0.46, VERMILION, CASSOCK, true)
	_panel(m, "spine", -0.224, [Vector2(-0.25, 1.37), Vector2(0, 1.28), Vector2(0.25, 1.37), Vector2(0.18, 0.97), Vector2(0, 0.9), Vector2(-0.18, 0.97)], 0.036, CASSOCK)
	_cuirass(m, "pelvis", [[0.77, 0.29, 0.174], [0.87, 0.29, 0.202], [0.955, 0.246, 0.163]], CASSOCK)
	_cord(m, "pelvis", Vector3(0, 0.89, 0.001), 0.31, 0.031, "m:" + TARNISH)
	_panel(m, "pelvis", -0.269, [Vector2(-0.16, 0.85), Vector2(0.15, 0.85), Vector2(0.095, 0.41), Vector2(0.01, 0.30), Vector2(-0.13, 0.48)], 0.024, VERMILION)
	_folded_shroud(m, "mantle", 1.45, 0.074, 0.30, 0.51, CASSOCK, WINE, false)
	for side in [-1.0, 1.0]:
		var suffix := _side(side)
		# Each silver rib curls into the cloth. Uneven heights imply bone rather than a uniform grille.
		for row in 5:
			var y := 1.32 - row * 0.066
			var elbow := Vector3(side * (0.16 + row * 0.008), y - 0.027, -0.233)
			m.tube("spine", Vector3(side * 0.031, y, -0.267), elbow, 0.021, 0.019, "m:" + SILVER, 6)
			m.tube("spine", elbow, Vector3(side * (0.30 - row * 0.012), y + 0.024, -0.149), 0.019, 0.010, "m:" + TARNISH, 6)
		_pauldron(m, "upper_" + suffix, side, 1.0, CASSOCK, VERMILION, SILVER)
		m.tube("upper_" + suffix, Vector3(side * 0.39, 1.28, -0.12), Vector3(side * 0.47, 1.12, -0.16), 0.028, 0.015, "m:" + TARNISH, 6)
		m.tube("fore_" + suffix, Vector3(side * 0.53, 1.08, 0.0), Vector3(side * 0.60, 0.88, -0.025), 0.103, 0.065, CASSOCK, 8)
		for cuff in 3:
			_cord(m, "fore_" + suffix, Vector3(side * (0.58 + cuff * 0.006), 0.97 - cuff * 0.032, -0.024), 0.076 - cuff * 0.003, 0.010, "m:" + SILVER)
		_panel(m, "thigh_" + suffix, -0.142, [Vector2(side * 0.10, 0.80), Vector2(side * 0.33, 0.83), Vector2(side * 0.34, 0.58), Vector2(side * 0.22, 0.37), Vector2(side * 0.115, 0.52)], 0.030, CASSOCK)
		_armored_foot(m, suffix, side, 0.96, CASSOCK, "m:" + TARNISH)
		_gauntlet(m, suffix, side, CASSOCK, "m:" + TARNISH)
	# Gilded mitre, raised cartilage seam, and turned-up resonant mouth plate.
	_cuirass(m, "head", [[1.52, 0.076, 0.098], [1.60, 0.113, 0.147], [1.754, 0.144, 0.158], [1.882, 0.108, 0.124]], CHOIR_SKIN)
	_cuirass(m, "head", [[1.80, 0.17, 0.174], [1.925, 0.163, 0.16], [2.14, 0.101, 0.094], [2.25, 0.018, 0.024]], WINE)
	_panel(m, "head", -0.189, [Vector2(-0.222, 1.81), Vector2(-0.171, 2.02), Vector2(-0.06, 2.19), Vector2(0, 2.245), Vector2(0.12, 2.132), Vector2(0.206, 1.99), Vector2(0.218, 1.81)], 0.26, VERMILION)
	m.tube("head", Vector3(0, 1.83, -0.328), Vector3(0, 2.20, -0.328), 0.02, 0.013, "m:" + SILVER, 7)
	m.box("head", Vector3(0, 1.813, -0.308), Vector3(0.414, 0.031, 0.025), "m:" + TARNISH)
	for side in [-1.0, 1.0]:
		m.tube("head", Vector3(side * 0.052, 1.731, -0.195), Vector3(side * 0.103, 1.749, -0.184), 0.007, 0.004, "e:" + COAGULATE, 5)
		m.tube("head", Vector3(side * 0.099, 1.70, -0.180), Vector3(side * 0.093, 1.54, -0.179), 0.012, 0.006, VERMILION, 5)
		m.tube("head", Vector3(side * 0.144, 1.81, -0.31), Vector3(side * 0.088, 2.012, -0.32), 0.012, 0.010, "m:" + SILVER, 7)
	_panel(m, "head", -0.187, [Vector2(-0.15, 1.657), Vector2(0, 1.63), Vector2(0.15, 1.657), Vector2(0.119, 1.525), Vector2(0, 1.488), Vector2(-0.12, 1.525)], 0.035, "m:" + TARNISH)
	for tooth in range(-3, 4):
		m.box("head", Vector3(tooth * 0.025, 1.575, -0.210), Vector3(0.009, 0.045 - absf(tooth) * 0.006, 0.009), "m:" + SILVER)
	# The throat-chalice mounts through the fist. Deep dark and red lip surfaces read as liquid-filled.
	m.tube("hand_r", Vector3(0.60, 0.745, -0.06), Vector3(0.60, 1.02, -0.10), 0.062, 0.044, "m:" + TARNISH, 8)
	m.tube("hand_r", Vector3(0.60, 1.00, -0.10), Vector3(0.60, 1.25, -0.14), 0.043, 0.165, "m:" + SILVER, 11)
	for ring in 5:
		_cord(m, "hand_r", Vector3(0.60, 1.035 + ring * 0.053, -0.106 - ring * 0.008), 0.059 + ring * 0.025, 0.010, "m:" + TARNISH)
	m.ellipsoid("hand_r", Vector3(0.60, 1.251, -0.14), Vector3(0.30, 0.018, 0.30), CASSOCK)
	m.ellipsoid("hand_r", Vector3(0.60, 1.260, -0.14), Vector3(0.241, 0.015, 0.245), "e:" + COAGULATE)
	_cord(m, "hand_r", Vector3(0.60, 1.27, -0.14), 0.157, 0.018, "m:" + TARNISH)
	for x in [-0.09, 0.02, 0.1]:
		m.tube("hand_r", Vector3(0.6 + x, 1.245, -0.265), Vector3(0.61 + x, 1.12, -0.233), 0.012, 0.006, VERMILION, 6)
	# A small ceremonial lancet and its hooked counterweight ride the off hand.
	m.tube("hand_l", Vector3(-0.595, 0.98, -0.063), Vector3(-0.61, 0.735, -0.095), 0.038, 0.032, WINE, 7)
	_panel(m, "hand_l", -0.10, [Vector2(-0.68, 0.76), Vector2(-0.55, 0.75), Vector2(-0.56, 0.49), Vector2(-0.69, 0.44), Vector2(-0.625, 0.55)], 0.024, "m:" + SILVER)


static func _hest(m) -> void:
	# The heavy flat-chested figure carries counterweights rather than infantry pauldrons.
	_cuirass(m, "spine", [[0.97, 0.283, 0.181], [1.10, 0.348, 0.229], [1.28, 0.395, 0.257], [1.46, 0.371, 0.223], [1.503, 0.221, 0.174]], "m:" + BLACK_BRONZE)
	_panel(m, "spine", -0.285, [Vector2(-0.37, 1.36), Vector2(-0.25, 1.46), Vector2(0.24, 1.46), Vector2(0.38, 1.34), Vector2(0.28, 0.96), Vector2(0, 0.89), Vector2(-0.29, 0.97)], 0.084, "m:" + BLACK_BRONZE)
	_panel(m, "spine", -0.335, [Vector2(-0.27, 1.36), Vector2(0.27, 1.36), Vector2(0.19, 1.05), Vector2(0, 1.00), Vector2(-0.19, 1.06)], 0.022, "m:" + BRONZE)
	m.band("spine", Vector3(0, 1.215, -0.356), 0.157, 0.025, "m:" + BRASS)
	_bevel(m, "spine", -0.38, [Vector2(-0.09, 1.235), Vector2(0, 1.315), Vector2(0.102, 1.235), Vector2(0.066, 1.125), Vector2(0, 1.083), Vector2(-0.068, 1.128)], 0.039, "m:" + PATINA, "m:" + BRONZE)
	m.tube("spine", Vector3(0, 1.32, -0.41), Vector3(0, 1.12, -0.41), 0.014, 0.014, "e:" + TOLL_LIGHT, 7)
	m.tube("pelvis", Vector3(0, 0.74, 0), Vector3(0, 0.91, 0), 0.373, 0.332, GRAVE_CLOTH, 10)
	for i in range(-2, 3):
		var x := i * 0.132
		m.box("pelvis", Vector3(x, 0.84 - 0.014 * absf(i), -0.272 + 0.047 * absf(i)), Vector3(0.16, 0.15, 0.065), "m:" + BRONZE, Vector3(0.08, -0.19 * i, 0.012 * i))
		m.ellipsoid("pelvis", Vector3(x, 0.86 - 0.012 * absf(i), -0.316 + 0.047 * absf(i)), Vector3(0.044, 0.044, 0.023), "m:" + BRASS)
	# A three-piece bell helmet with a black mouth and pierced eye openings.
	m.tube("head", Vector3(0, 1.54, 0.04), Vector3(0, 1.63, 0.027), 0.31, 0.259, "m:" + BRONZE, 11)
	m.tube("head", Vector3(0, 1.63, 0.027), Vector3(0, 1.95, 0.018), 0.259, 0.19, "m:" + BLACK_BRONZE, 11)
	_cuirass(m, "head", [[1.878, 0.218, 0.219], [1.961, 0.180, 0.190], [2.036, 0.119, 0.119], [2.075, 0.019, 0.045]], "m:" + BLACK_BRONZE)
	_cord(m, "head", Vector3(0, 1.557, 0.018), 0.305, 0.029, "m:" + BRASS)
	m.band("head", Vector3(0, 2.062, 0.02), 0.058, 0.021, "m:" + BRONZE)
	m.ellipsoid("head", Vector3(0, 1.537, -0.001), Vector3(0.527, 0.022, 0.51), GRAVE_CLOTH)
	_panel(m, "head", -0.232, [Vector2(-0.175, 1.82), Vector2(0.175, 1.82), Vector2(0.205, 1.688), Vector2(-0.205, 1.688)], 0.025, GRAVE_CLOTH)
	for slit in range(-2, 3):
		var x := slit * 0.062
		m.box("head", Vector3(x, 1.753, -0.25), Vector3(0.023, 0.071 - absf(slit) * 0.007, 0.026), "e:" + TOLL_LIGHT)
		m.box("head", Vector3(x - 0.019, 1.756, -0.267), Vector3(0.019, 0.100, 0.022), "m:" + BRONZE)
	for side in [-1.0, 1.0]:
		var suffix := _side(side)
		_pauldron(m, "upper_" + suffix, side, 1.46, "m:" + BLACK_BRONZE, "m:" + BRONZE, BRASS)
		m.tube("fore_" + suffix, Vector3(side * 0.52, 1.095, 0), Vector3(side * 0.6, 0.885, -0.025), 0.13, 0.106, "m:" + BLACK_BRONZE, 8)
		_panel(m, "fore_" + suffix, -0.112, [Vector2(side * 0.403, 1.102), Vector2(side * 0.61, 1.09), Vector2(side * 0.692, 0.848), Vector2(side * 0.521, 0.864)], 0.043, "m:" + BRONZE)
		_panel(m, "thigh_" + suffix, -0.169, [Vector2(side * 0.04, 0.81), Vector2(side * 0.39, 0.81), Vector2(side * 0.35, 0.61), Vector2(side * 0.19, 0.46), Vector2(side * 0.084, 0.57)], 0.051, "m:" + BLACK_BRONZE)
		_greave(m, suffix, side, 1.22, "m:" + BLACK_BRONZE, "m:" + BRONZE)
		m.tube("shin_" + suffix, Vector3(side * 0.18, 0.43, -0.048), Vector3(side * 0.18, 0.18, -0.032), 0.118, 0.098, "m:" + BLACK_BRONZE, 7)
		_armored_foot(m, suffix, side, 1.29, "m:" + BLACK_BRONZE, "m:" + BRONZE)
		_gauntlet(m, suffix, side, GRAVE_CLOTH, "m:" + BRONZE)
	# A bronze yoke seats nine actual open-throated bells in two tiers.
	m.tube("mantle", Vector3(-0.54, 1.43, 0.28), Vector3(0.54, 1.43, 0.28), 0.039, 0.039, "m:" + BLACK_BRONZE, 9)
	for i in range(-2, 3):
		_bell(m, "mantle", Vector3(i * 0.184, 1.405 - absf(i) * 0.037, 0.34 + absf(i) * 0.012), 0.085, 0.192)
	for i in range(-3, 4, 2):
		_bell(m, "mantle", Vector3(i * 0.105, 1.13, 0.375), 0.084, 0.177)
	# Tonguehammer's head is recognizable as a large swinging grave bell.
	m.tube("hand_r", Vector3(0.62, 0.40, 0.103), Vector3(0.64, 1.34, -0.162), 0.047, 0.057, "m:" + BLACK_BRONZE, 8)
	for i in 4:
		_cord(m, "hand_r", Vector3(0.628, 0.809 + i * 0.032, -0.016 - i * 0.011), 0.060, 0.011, "m:" + BRASS)
	m.tube("hand_r", Vector3(0.64, 1.34, -0.162), Vector3(0.65, 1.585, -0.17), 0.057, 0.045, "m:" + BLACK_BRONZE, 8)
	# Small buckler is a struck sounding plate on the free forearm.
	m.ellipsoid("fore_l", Vector3(-0.59, 1.01, -0.184), Vector3(0.32, 0.40, 0.073), "m:" + BLACK_BRONZE)
	m.band("fore_l", Vector3(-0.59, 1.01, -0.229), 0.145, 0.025, "m:" + BRASS)
	m.ellipsoid("fore_l", Vector3(-0.59, 1.01, -0.246), Vector3(0.108, 0.108, 0.042), "m:" + PATINA)


static func _bell(m, joint: String, crown: Vector3, rim: float, height: float) -> void:
	var lip := crown - Vector3.UP * height
	m.band(joint, crown + Vector3.UP * (height * 0.11), rim * 0.24, rim * 0.12, "m:" + PATINA)
	m.tube(joint, crown, lip + Vector3.UP * (height * 0.23), rim * 0.53, rim * 0.71, "m:" + BRONZE, 9)
	m.tube(joint, lip + Vector3.UP * (height * 0.23), lip, rim * 0.71, rim, "m:" + BRONZE, 9)
	_cord(m, joint, lip, rim * 0.985, rim * 0.075, "m:" + BRASS)
	m.ellipsoid(joint, lip - Vector3.UP * (height * 0.012), Vector3(rim * 1.79, height * 0.04, rim * 1.79), BLACK_BRONZE)
	m.tube(joint, lip + Vector3.UP * (height * 0.09), lip - Vector3.UP * (height * 0.19), rim * 0.071, rim * 0.098, "m:" + GRAVE_CLOTH, 6)
	m.ellipsoid(joint, lip - Vector3.UP * (height * 0.22), Vector3.ONE * (rim * 0.26), "m:" + BRASS)


static func _zarya(m) -> void:
	# Broken slag plates sit over hide. Bright fissures stay in the seams at distance.
	_cuirass(m, "spine", [[0.946, 0.168, 0.107], [1.06, 0.204, 0.150], [1.26, 0.265, 0.190], [1.39, 0.284, 0.170], [1.463, 0.188, 0.125]], CHAR)
	_panel(m, "spine", -0.195, [Vector2(-0.265, 1.35), Vector2(-0.12, 1.42), Vector2(0, 1.32), Vector2(0.19, 1.39), Vector2(0.27, 1.30), Vector2(0.154, 0.975), Vector2(-0.10, 0.975)], 0.052, "m:" + OBSIDIAN)
	m.tube("pelvis", Vector3(0, 0.80, 0.012), Vector3(0, 0.97, 0.012), 0.278, 0.22, CHAR, 8)
	_panel(m, "pelvis", -0.225, [Vector2(-0.17, 0.94), Vector2(0.03, 0.88), Vector2(0.19, 0.91), Vector2(0.143, 0.81), Vector2(-0.05, 0.765), Vector2(-0.19, 0.82)], 0.054, "m:" + SCALE)
	_slagline(m, "spine", [Vector3(-0.148, 1.394, -0.23), Vector3(0.016, 1.288, -0.238), Vector3(-0.025, 1.235, -0.24), Vector3(0.114, 1.152, -0.239), Vector3(0.069, 1.056, -0.231)], 0.012)
	# Staggered glass scales leave the vertical fire seam visible between them.
	for side in [-1.0, 1.0]:
		for scale_row in 2:
			var y := 1.391 - scale_row * 0.087 - (0.018 if side < 0 else 0.0)
			var x: float = side * (0.158 - scale_row * 0.014)
			var z := -0.239 - sin(float(scale_row) * 0.81) * 0.012
			var rakes := [Vector2(x + side * 0.076, y + 0.034), Vector2(x - side * 0.058, y + 0.022), Vector2(x - side * 0.039, y - 0.073), Vector2(x + side * 0.104, y - 0.021)]
			_panel(m, "spine", z, rakes, 0.031, "m:" + SCALE)
			m.tube("spine", Vector3(rakes[0].x, rakes[0].y, z - 0.020), Vector3(rakes[3].x, rakes[3].y, z - 0.020), 0.008, 0.005, "m:" + FORGED_EDGE, 5)
	_cuirass(m, "head", [[1.558, 0.088, 0.093], [1.629, 0.121, 0.135], [1.757, 0.141, 0.151], [1.859, 0.133, 0.147], [1.925, 0.082, 0.10]], ASH_SKIN)
	_panel(m, "head", -0.178, [Vector2(-0.173, 1.865), Vector2(0, 1.92), Vector2(0.174, 1.855), Vector2(0.135, 1.679), Vector2(0.005, 1.589), Vector2(-0.155, 1.670)], 0.053, "m:" + OBSIDIAN)
	_cuirass(m, "head", [[1.689, 0.143, 0.15], [1.804, 0.17, 0.181], [1.909, 0.151, 0.173], [1.966, 0.061, 0.11]], "m:" + OBSIDIAN)
	for side in [-1.0, 1.0]:
		var suffix := _side(side)
		var shoulder_joint := "upper_" + suffix
		var forearm_joint := "fore_" + suffix
		var thigh_joint := "thigh_" + suffix
		var shin_joint := "shin_" + suffix
		# Pointed shoulder plates reach outward. Separate forearm pieces follow the blades.
		_panel(m, shoulder_joint, -0.120, [Vector2(side * 0.245, 1.366), Vector2(side * 0.332, 1.39), Vector2(side * 0.529, 1.515), Vector2(side * 0.499, 1.279), Vector2(side * 0.378, 1.213)], 0.14, "m:" + OBSIDIAN)
		_slagline(m, shoulder_joint, [Vector3(side * 0.288, 1.355, -0.208), Vector3(side * 0.388, 1.371, -0.206), Vector3(side * 0.494, 1.46, -0.20)], 0.009)
		_panel(m, forearm_joint, -0.102, [Vector2(side * 0.454, 1.095), Vector2(side * 0.549, 1.145), Vector2(side * 0.666, 0.973), Vector2(side * 0.651, 0.851), Vector2(side * 0.541, 0.881)], 0.069, "m:" + CHAR)
		for band in 3:
			m.tube(forearm_joint, Vector3(side * (0.483 + 0.031 * band), 1.049 - 0.048 * band, -0.143), Vector3(side * (0.575 + 0.022 * band), 1.070 - 0.047 * band, -0.143), 0.014, 0.009, "m:" + SCALE, 5)
		_panel(m, thigh_joint, -0.107, [Vector2(side * 0.105, 0.825), Vector2(side * 0.287, 0.845), Vector2(side * 0.263, 0.570), Vector2(side * 0.181, 0.495), Vector2(side * 0.112, 0.61)], 0.058, "m:" + OBSIDIAN)
		_panel(m, shin_joint, -0.074, [Vector2(side * 0.088, 0.49), Vector2(side * 0.233, 0.529), Vector2(side * 0.297, 0.448), Vector2(side * 0.217, 0.176), Vector2(side * 0.115, 0.2)], 0.069, "m:" + CHAR)
		_slagline(m, shin_joint, [Vector3(side * 0.235, 0.488, -0.12), Vector3(side * 0.165, 0.361, -0.12), Vector3(side * 0.199, 0.285, -0.117)], 0.009)
		_armored_foot(m, suffix, side, 1.12, "m:" + OBSIDIAN, "m:" + SCALE)
		m.tube("foot_" + suffix, Vector3(side * 0.174, 0.126, 0.013), Vector3(side * 0.174, 0.126, 0.151), 0.037, 0.001, "m:" + SCALE, 5)
		m.tube("head", Vector3(side * 0.046, 1.759, -0.213), Vector3(side * 0.127, 1.787, -0.208), 0.024, 0.013, HEAT, 5)
		m.tube("head", Vector3(side * 0.051, 1.763, -0.231), Vector3(side * 0.117, 1.787, -0.229), 0.009, 0.005, "e:" + CORE, 5)
		# Each half of the ember crown is a staggered row of obsidian splinters.
		for shard in 3:
			var base := Vector3(side * (0.067 + 0.045 * shard), 1.899 - 0.018 * shard, 0.047)
			m.tube("head", base, base + Vector3(side * (0.019 + 0.046 * shard), 0.32 - 0.057 * shard, 0.026 + 0.046 * shard), 0.05 - 0.007 * shard, 0.002, "m:" + OBSIDIAN, 5)
			m.tube("head", base + Vector3(0, 0.014, -0.04), base + Vector3(side * 0.021, 0.224 - 0.037 * shard, -0.019), 0.016 - 0.003 * shard, 0.002, "e:" + FIRE, 5)
		_gauntlet(m, suffix, side, "m:" + CHAR, "m:" + SCALE)
		_hook_blade(m, "hand_" + suffix, side)
	# The short, singed fork of the pyre sash stays above the boots so kicks remain visible.
	_panel(m, "mantle", 0.173, [Vector2(-0.237, 0.933), Vector2(0.203, 0.935), Vector2(0.299, 0.460), Vector2(0.152, 0.563), Vector2(0.060, 0.386), Vector2(-0.09, 0.552), Vector2(-0.236, 0.471)], 0.027, HEAT)
	_slagline(m, "mantle", [Vector3(-0.224, 0.88, 0.198), Vector3(-0.125, 0.76, 0.198), Vector3(0.08, 0.755, 0.195), Vector3(0.202, 0.587, 0.194)], 0.007)


static func _hook_blade(m, joint: String, side: float) -> void:
	# The broad back absorbs light while the curved, honed edge catches it.
	var grip := Vector3(side * 0.60, 0.865, -0.047)
	var base := grip + Vector3(-side * 0.043, 0.133, 0.0)
	var hilt := grip + Vector3(side * 0.042, -0.127, -0.01)
	m.tube(joint, base, hilt, 0.030, 0.026, CHAR, 8)
	m.ellipsoid(joint, base, Vector3(0.087, 0.068, 0.082), "m:" + HEAT)
	for wrap in 4:
		var a := (wrap + 0.06) / 5.0
		m.tube(joint, base.lerp(hilt, a), base.lerp(hilt, a + 0.047), 0.038, 0.036, "m:" + FORGED_EDGE, 6)
	m.tube(joint, hilt + Vector3(-side * 0.106, 0.032, -0.008), hilt + Vector3(side * 0.132, -0.044, -0.039), 0.036, 0.028, "m:" + FORGED_EDGE, 7)
	var outline := [Vector2(side * 0.51, 0.741), Vector2(side * 0.67, 0.751),
		Vector2(side * 0.79, 0.669), Vector2(side * 0.92, 0.52), Vector2(side * 0.995, 0.319),
		Vector2(side * 0.99, 0.187), Vector2(side * 0.936, 0.091), Vector2(side * 0.81, 0.033),
		Vector2(side * 0.855, 0.167), Vector2(side * 0.835, 0.287), Vector2(side * 0.753, 0.394),
		Vector2(side * 0.647, 0.473)]
	_panel(m, joint, -0.088, outline, 0.072, "m:" + OBSIDIAN)
	var edge := [Vector2(side * 0.713, 0.724), Vector2(side * 0.793, 0.666), Vector2(side * 0.923, 0.516),
		Vector2(side * 0.997, 0.32), Vector2(side * 0.992, 0.185), Vector2(side * 0.934, 0.095),
		Vector2(side * 0.809, 0.034), Vector2(side * 0.900, 0.121), Vector2(side * 0.945, 0.217),
		Vector2(side * 0.950, 0.323), Vector2(side * 0.881, 0.50), Vector2(side * 0.769, 0.626)]
	_bevel(m, joint, -0.112, edge, 0.020, "m:" + FORGED_EDGE, "m:" + HEAT)
	# The back has its own bevel and a luminous fuller. The secondary face
	# matters on the reversed grip and during her turning ultimate.
	_bevel(m, joint, -0.049, edge, 0.020, "m:" + FORGED_EDGE, "m:" + HEAT)
	var fuller := PackedVector3Array([
		Vector3(side * 0.681, 0.684, -0.048), Vector3(side * 0.778, 0.615, -0.048),
		Vector3(side * 0.902, 0.444, -0.048), Vector3(side * 0.951, 0.322, -0.048),
		Vector3(side * 0.918, 0.354, -0.048), Vector3(side * 0.831, 0.467, -0.048),
		Vector3(side * 0.778, 0.559, -0.048),
	])
	m.plate(joint, fuller, 0.012, "e:" + FIRE)
	_slagline(m, joint, [Vector3(side * 0.686, 0.697, -0.130), Vector3(side * 0.781, 0.604, -0.130),
		Vector3(side * 0.891, 0.459, -0.130), Vector3(side * 0.939, 0.308, -0.130),
		Vector3(side * 0.927, 0.207, -0.130), Vector3(side * 0.893, 0.153, -0.130)], 0.013)
	m.tube(joint, Vector3(side * 0.89, 0.467, -0.137), Vector3(side * 0.922, 0.365, -0.135), 0.008, 0.004, "e:" + PYRE_GOLD, 5)
	for cut in 2:
		var y := 0.547 - 0.068 * cut
		var x := side * (0.80 + cut * 0.038)
		m.tube(joint, Vector3(x, y, -0.129), Vector3(x - side * 0.045, y + 0.056, -0.129), 0.008, 0.002, "m:" + SCALE, 5)


static func _eive(m) -> void:
	# Iron backed court coat and oversized scholar's collar under a broken glacial crown.
	_cuirass(m, "spine", [[0.945, 0.191, 0.135], [1.12, 0.233, 0.15], [1.272, 0.289, 0.186], [1.395, 0.294, 0.171], [1.45, 0.196, 0.159]], INDIGO)
	_panel(m, "spine", -0.196, [Vector2(-0.25, 1.39), Vector2(-0.04, 1.323), Vector2(0.21, 1.402), Vector2(0.28, 1.30), Vector2(0.14, 0.947), Vector2(-0.164, 0.938)], 0.064, "m:" + SCRIBE_IRON)
	_panel(m, "spine", -0.239, [Vector2(-0.17, 1.316), Vector2(-0.033, 1.274), Vector2(0.106, 1.322), Vector2(0.104, 1.01), Vector2(0, 0.945), Vector2(-0.146, 1.018)], 0.022, RIME_CLOTH)
	m.tube("pelvis", Vector3(0, 0.748, 0.052), Vector3(0, 0.94, 0.025), 0.359, 0.275, INDIGO, 10)
	_cord(m, "pelvis", Vector3(0, 0.90, 0.022), 0.286, 0.018, "m:" + SCRIBE_IRON)
	# The narrow coat panels are split onto the thighs to articulate during a run.
	for side in [-1.0, 1.0]:
		var suffix := _side(side)
		var shoulder := "upper_" + suffix
		var forearm := "fore_" + suffix
		_pauldron(m, shoulder, side, 1.24, INDIGO, SCRIBE_IRON, ICE)
		for chip in 4:
			var star := Vector3(side * (0.269 + chip * 0.058), 1.420 - chip * 0.016, 0.033 + 0.008 * chip)
			m.tube(shoulder, star, star + Vector3(side * (0.08 + 0.008 * chip), 0.191 - chip * 0.021, 0.049), 0.038 - 0.003 * chip, 0.001, ICE, 5)
		m.tube(forearm, Vector3(side * 0.521, 1.074, 0.012), Vector3(side * 0.594, 0.884, -0.017), 0.111, 0.069, RIME_CLOTH, 8)
		m.box(forearm, Vector3(side * 0.56, 0.988, -0.088), Vector3(0.122, 0.16, 0.054), "m:" + SCRIBE_IRON, Vector3(0, 0, side * 0.216))
		for knot in 3:
			m.ellipsoid(forearm, Vector3(side * (0.558 + knot * 0.015), 1.023 - 0.038 * knot, -0.129), Vector3(0.027, 0.028, 0.022), "e:" + SEAL_GLOW)
		_panel(m, "thigh_" + suffix, -0.157, [Vector2(side * 0.031, 0.858), Vector2(side * 0.303, 0.849), Vector2(side * 0.326, 0.505), Vector2(side * 0.176, 0.30), Vector2(side * 0.087, 0.532)], 0.040, INDIGO)
		_panel(m, "thigh_" + suffix, -0.183, [Vector2(side * 0.092, 0.823), Vector2(side * 0.239, 0.807), Vector2(side * 0.254, 0.539), Vector2(side * 0.173, 0.391)], 0.015, RIME_CLOTH)
		_armored_foot(m, suffix, side, 1.04, INDIGO, "m:" + SCRIBE_IRON)
		_gauntlet(m, suffix, side, INDIGO, "m:" + SCRIBE_IRON)
		m.tube("foot_" + suffix, Vector3(side * 0.109, 0.123, -0.198), Vector3(side * 0.249, 0.123, -0.198), 0.014, 0.014, "m:" + SCRIBE_IRON, 6)
	# Hair, collar and scalloped nose bridge leave an unmistakably narrow skull.
	_cuirass(m, "spine", [[1.35, 0.31, 0.189], [1.43, 0.264, 0.183], [1.503, 0.206, 0.14], [1.55, 0.169, 0.123]], RIME_CLOTH)
	_cuirass(m, "head", [[1.535, 0.083, 0.105], [1.65, 0.109, 0.147], [1.769, 0.133, 0.157], [1.848, 0.131, 0.133], [1.900, 0.096, 0.093]], BONE)
	_panel(m, "head", -0.162, [Vector2(-0.128, 1.792), Vector2(0.127, 1.785), Vector2(0.097, 1.644), Vector2(0.052, 1.554), Vector2(-0.061, 1.573), Vector2(-0.094, 1.639)], 0.043, RIME_CLOTH)
	for side in [-1.0, 1.0]:
		m.tube("head", Vector3(side * 0.024, 1.728, -0.206), Vector3(side * 0.102, 1.755, -0.2), 0.013, 0.009, "e:" + SEAL_GLOW, 6)
		m.tube("head", Vector3(side * 0.0, 1.867, -0.10), Vector3(side * 0.207, 1.83, 0.04), 0.024, 0.014, "m:" + SCRIBE_IRON, 6)
	for tooth in range(-3, 4):
		var y := 1.90 + 0.028 * (3 - absf(tooth))
		var base := Vector3(tooth * 0.067, y, -0.015 + 0.012 * absf(tooth))
		var tip := base + Vector3(tooth * 0.035, 0.37 - absf(tooth) * 0.052, 0.04 + 0.022 * tooth)
		m.tube("head", base, tip, 0.061 - 0.005 * absf(tooth), 0.001, ICE, 5)
		m.tube("head", base + Vector3(0, 0.035, -0.048), tip.lerp(base, 0.44), 0.012, 0.003, "e:" + SEAL_GLOW, 5)
	# Wax-sealed obituary slips hang beneath the mantle and glint behind the crown.
	_folded_shroud(m, "mantle", 1.49, 0.16, 0.35, 0.48, INDIGO, RIME_CLOTH, false)
	for slip in 4:
		var x := -0.235 + 0.13 * slip
		var y := 1.375 - 0.055 * slip
		m.box("mantle", Vector3(x, y - 0.14, 0.252), Vector3(0.08, 0.281 + slip * 0.025, 0.013), PAPER, Vector3(0.06, 0, (slip - 1.5) * 0.11))
		m.ellipsoid("mantle", Vector3(x, y - 0.024, 0.269), Vector3(0.042, 0.047, 0.021), WINE)
	_vellum(m)
	_quill(m)


static func _vellum(m) -> void:
	# The book is open, with two iron covers and a seam that exposes the stitched spine.
	m.box("hand_l", Vector3(-0.608, 0.847, -0.201), Vector3(0.04, 0.245, 0.07), "m:" + SCRIBE_IRON)
	for side in [-1.0, 1.0]:
		var center := Vector3(-0.609 + side * 0.133, 0.853, -0.223)
		var pose := Vector3(-0.53, side * 0.37, 0)
		m.box("hand_l", center, Vector3(0.254, 0.262, 0.036), "m:" + SCRIBE_IRON, pose)
		m.box("hand_l", center + Vector3(0, 0.008, -0.031), Vector3(0.228, 0.236, 0.024), PAPER, pose)
		for row in 4:
			var scribe := center + Vector3(-0.063, 0.06 - row * 0.033, -0.055 + row * 0.008)
			m.tube("hand_l", scribe, scribe + Vector3(0.108 - 0.018 * (row % 2), 0, side * -0.036), 0.004, 0.003, INDIGO, 4)
	m.band("hand_l", Vector3(-0.50, 0.870, -0.312), 0.039, 0.009, "e:" + SEAL_GLOW, 0.42, TAU * 0.76)


static func _quill(m) -> void:
	# A long pointed shaft balances the handed silhouette of the open book.
	var tail := Vector3(0.59, 0.661, 0.015)
	var nib := Vector3(0.728, 1.50, -0.261)
	m.tube("hand_r", tail, nib, 0.031, 0.011, BONE, 6)
	m.tube("hand_r", nib.lerp(tail, 0.1), nib + Vector3(0.018, 0.128, -0.057), 0.031, 0.001, ICE, 5)
	for i in 5:
		var base := tail.lerp(nib, 0.39 + i * 0.092)
		m.tube("hand_r", base, base + Vector3(0.155 - 0.026 * i, 0.18 - 0.019 * i, -0.066), 0.017 - 0.0015 * i, 0.001, BONE, 5)
	m.ellipsoid("hand_r", nib + Vector3(0.005, 0.035, -0.02), Vector3(0.073, 0.065, 0.058), "e:" + SEAL_GLOW)


static func _side(x: float) -> String:
	return "l" if x < 0.0 else "r"


static func _panel(m, joint: String, z: float, outline: Array, depth: float, color: String) -> void:
	var vertices := PackedVector3Array()
	for vertex: Vector2 in outline:
		vertices.append(Vector3(vertex.x, vertex.y, z))
	m.plate(joint, vertices, depth, color)


static func _cord(m, joint: String, at: Vector3, radius: float, thickness: float, color: String) -> void:
	m.band(joint, at, radius, thickness, color, 0.0, TAU, Vector3(PI * 0.5, 0, 0))


static func _slagline(m, joint: String, points: Array, width: float) -> void:
	for index in range(points.size() - 1):
		m.tube(joint, points[index], points[index + 1], width, width * 0.64, "e:" + FIRE, 5)


# Octagonal sectional volumes give helmets and breastplates distinct profiles.
static func _cuirass(m, joint: String, rows: Array, material: String) -> void:
	var angles := [Vector2(-0.74, -1), Vector2(0.74, -1), Vector2(1, -0.56), Vector2(1, 0.55),
		Vector2(0.66, 1), Vector2(-0.66, 1), Vector2(-1, 0.55), Vector2(-1, -0.56)]
	var rings: Array[PackedVector3Array] = []
	for row: Array in rows:
		var section := PackedVector3Array()
		for point: Vector2 in angles:
			section.append(Vector3(point.x * row[1], row[0], point.y * row[2]))
		rings.append(section)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for r in range(rings.size() - 1):
		for i in angles.size():
			var next := (i + 1) % angles.size()
			_face(surface, rings[r][i], rings[r + 1][i], rings[r + 1][next], rings[r][next])
	var lower: PackedVector3Array = rings[0]
	var upper: PackedVector3Array = rings[-1]
	for i in range(1, angles.size() - 1):
		_tri(surface, lower[0], lower[i], lower[i + 1])
		_tri(surface, upper[0], upper[i + 1], upper[i])
	surface.generate_normals()
	m._add(joint, Vector3.ZERO, Basis.IDENTITY, surface.commit(), material, true)


# A polygon's shoulder slopes out from a raised inset face. The sides catch light independently.
static func _bevel(m, joint: String, z: float, outline: Array, height: float, face: String, sides: String) -> void:
	var center := Vector2.ZERO
	for point: Vector2 in outline:
		center += point
	center /= outline.size()
	var inset: Array[Vector2] = []
	var bevel := SurfaceTool.new()
	bevel.begin(Mesh.PRIMITIVE_TRIANGLES)
	for point: Vector2 in outline:
		inset.append(center.lerp(point, 0.84))
	for i in outline.size():
		var next := (i + 1) % outline.size()
		_face(bevel, Vector3(outline[i].x, outline[i].y, z),
			Vector3(inset[i].x, inset[i].y, z - height),
			Vector3(inset[next].x, inset[next].y, z - height),
			Vector3(outline[next].x, outline[next].y, z))
	bevel.generate_normals()
	m._add(joint, Vector3.ZERO, Basis.IDENTITY, bevel.commit(), sides, true)
	_panel(m, joint, z - height + 0.002, inset, 0.012, face)


static func _folded_shroud(m, joint: String, high: float, low: float, start_width: float, hem_width: float, cloth: String, lining: String, front: bool) -> void:
	var cols := 12
	var rows := 6
	var sign_z := -1.0 if front else 1.0
	var strips: Array[PackedVector3Array] = []
	for r in range(rows + 1):
		var fraction := float(r) / rows
		var line := PackedVector3Array()
		for c in range(cols + 1):
			var u := float(c) / cols
			var side := u * 2.0 - 1.0
			var y := lerpf(high, low, fraction) + pow(fraction, 5.0) * (0.12 + 0.12 * sin(c * 2.8) + absf(side) * 0.09)
			var x := side * lerpf(start_width, hem_width, fraction) + fraction * fraction * 0.10
			var pleat := 0.056 * sin(c * 2.61 + fraction * 1.2) * (0.3 + fraction * 0.7)
			var z := sign_z * (lerpf(0.172, 0.276, fraction) + (1.0 - side * side) * 0.075 + pleat)
			line.append(Vector3(x, y, z))
		strips.append(line)
	var face := SurfaceTool.new()
	var shade := SurfaceTool.new()
	face.begin(Mesh.PRIMITIVE_TRIANGLES)
	shade.begin(Mesh.PRIMITIVE_TRIANGLES)
	for r in rows:
		for c in cols:
			var mesh_builder := shade if c % 4 == 0 or c % 4 == 3 else face
			_face(mesh_builder, strips[r][c], strips[r + 1][c], strips[r + 1][c + 1], strips[r][c + 1])
	face.generate_normals()
	shade.generate_normals()
	m._add(joint, Vector3.ZERO, Basis.IDENTITY, face.commit(), cloth, true)
	m._add(joint, Vector3.ZERO, Basis.IDENTITY, shade.commit(), lining, true)


static func _face(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_tri(surface, a, b, c)
	_tri(surface, a, c, d)


static func _tri(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var normal := (b - a).cross(c - a).abs()
	for p: Vector3 in [a, b, c]:
		var uv := Vector2(p.x, p.y)
		if normal.y >= normal.x and normal.y >= normal.z:
			uv = Vector2(p.x, p.z)
		elif normal.x >= normal.z:
			uv = Vector2(p.z, p.y)
		surface.set_uv(uv * 3.0)
		surface.add_vertex(p)


static func _pauldron(m, joint: String, side: float, scale: float, inner: String, outer: String, trim: String) -> void:
	for lamella in 4:
		var low := 1.27 - 0.057 * lamella
		var outside := (0.11 + 0.076 * lamella) * scale
		_bevel(m, joint, -0.13 - 0.010 * lamella, [
			Vector2(side * (0.26 + 0.043 * lamella), low + 0.09), Vector2(side * (0.31 + outside * 0.7), low + 0.21),
			Vector2(side * (0.38 + outside), low + 0.16), Vector2(side * (0.43 + outside), low + 0.063),
			Vector2(side * (0.40 + outside * 0.7), low - 0.009)], 0.043 - 0.004 * lamella, outer if lamella % 2 == 0 else inner, inner)
		var cap := Vector3(side * (0.37 + outside * 0.83), low + 0.070, -0.199)
		m.tube(joint, cap + Vector3(0, 0, 0.003), cap - Vector3(0, 0, 0.017), 0.015, 0.011, "m:" + trim, 5)
	var shoulder := Vector3(side * (0.44 + 0.036 * scale), 1.42, -0.02)
	m.tube(joint, shoulder, shoulder + Vector3(side * 0.143 * scale, 0.134 * scale, 0.019), 0.078 * scale, 0.002, inner, 5)


static func _gauntlet(m, suffix: String, side: float, glove: String, plates: String) -> void:
	var joint := "hand_" + suffix
	_bevel(m, joint, -0.076, [Vector2(side * 0.553, 0.874), Vector2(side * 0.649, 0.887),
		Vector2(side * 0.697, 0.805), Vector2(side * 0.661, 0.737), Vector2(side * 0.571, 0.751)], 0.029, glove, plates)
	for knuckle in 4:
		var x := side * (0.562 + knuckle * 0.029)
		var y := 0.788 + (2.0 - absf(knuckle - 2.0)) * 0.009
		m.tube(joint, Vector3(x, y + 0.03, -0.109), Vector3(x + side * 0.006, y - 0.019, -0.111), 0.014, 0.011, plates, 5)


static func _greave(m, suffix: String, side: float, scale: float, iron: String, bright: String) -> void:
	var joint := "shin_" + suffix
	var x := side * 0.18
	_bevel(m, joint, -0.113, [Vector2(x - 0.105 * scale, 0.541), Vector2(x, 0.599),
		Vector2(x + 0.109 * scale, 0.533), Vector2(x + 0.093 * scale, 0.275), Vector2(x + 0.045, 0.214),
		Vector2(x - 0.065, 0.226), Vector2(x - 0.083 * scale, 0.312)], 0.058, iron, bright)
	for ridge in 3:
		var y := 0.325 + ridge * 0.065
		m.tube(joint, Vector3(x - 0.067, y, -0.171), Vector3(x + 0.067, y + 0.017, -0.173), 0.010, 0.010, bright, 6)


static func _armored_foot(m, suffix: String, side: float, scale: float, base: String, trim: String) -> void:
	var joint := "foot_" + suffix
	var x := side * 0.18
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var side_width := 0.091 * scale
	var heel := 0.095
	var toe := -0.289 - 0.06 * (scale - 1)
	var sole := PackedVector3Array([
		Vector3(x - side_width * 0.74, 0.043, heel), Vector3(x + side_width * 0.75, 0.043, heel),
		Vector3(x + side_width, 0.043, -0.153), Vector3(x + side_width * 0.42, 0.043, toe),
		Vector3(x - side_width * 0.54, 0.043, toe + 0.036), Vector3(x - side_width, 0.043, -0.137)])
	var upper := PackedVector3Array()
	for i in sole.size():
		var pt := sole[i]
		upper.append(Vector3(lerpf(x, pt.x, 0.82), 0.186 if i in [0, 1] else (0.101 if i in [3, 4] else 0.138), pt.z + 0.019))
	for i in sole.size():
		var next := (i + 1) % sole.size()
		_face(surface, sole[i], sole[next], upper[next], upper[i])
	for i in range(1, sole.size() - 1):
		_tri(surface, upper[0], upper[i], upper[i + 1])
		_tri(surface, sole[0], sole[i + 1], sole[i])
	surface.generate_normals()
	m._add(joint, Vector3.ZERO, Basis.IDENTITY, surface.commit(), base, true)
	for arch in 3:
		var y := 0.150 - arch * 0.018
		var z := -0.104 - arch * 0.055
		m.tube(joint, Vector3(x - side_width * 0.83, y - 0.009, z), Vector3(x + side_width * 0.80, y, z - 0.012), 0.010, 0.009, trim, 5)


static func _choir_reliquary(m) -> void:
	# A deep hood casts darkness through narrow openings above the ribbed censor's mask.
	_bevel(m, "head", -0.154, [Vector2(-0.168, 1.82), Vector2(-0.102, 1.853), Vector2(0.091, 1.848),
		Vector2(0.165, 1.818), Vector2(0.122, 1.769), Vector2(0.028, 1.766),
		Vector2(0.003, 1.737), Vector2(-0.029, 1.766), Vector2(-0.111, 1.77)], 0.052, CASSOCK, "m:" + TARNISH)
	_bevel(m, "head", -0.192, [Vector2(-0.114, 1.673), Vector2(-0.051, 1.675), Vector2(0.003, 1.699),
		Vector2(0.063, 1.679), Vector2(0.13, 1.677), Vector2(0.086, 1.549),
		Vector2(0.015, 1.494), Vector2(-0.075, 1.539)], 0.038, "m:" + TARNISH, "m:" + SILVER)
	for side in [-1.0, 1.0]:
		_bevel(m, "head", -0.078, [Vector2(side * 0.111, 1.865), Vector2(side * 0.179, 1.828),
			Vector2(side * 0.164, 1.577), Vector2(side * 0.098, 1.509), Vector2(side * 0.115, 1.69)], 0.113, WINE, CASSOCK)
		_greave(m, _side(side), side, 0.93, CASSOCK, "m:" + TARNISH)
		for n in 7:
			var y := 1.719 - n * 0.109
			var x: float = side * (0.187 + 0.087 * (1.0 - pow((y - 1.3) * 2.5, 2.0)))
			m.tube("mantle", Vector3(x, y, 0.271), Vector3(x + side * 0.046, y - 0.026, 0.266), 0.010, 0.008, "m:" + TARNISH, 5)
		# Raised choir stole crosses over the mantle shoulder and ends in sharpened bone clasps.
		_bevel(m, "spine", -0.209, [Vector2(side * 0.118, 1.486), Vector2(side * 0.226, 1.414),
			Vector2(side * 0.234, 1.235), Vector2(side * 0.194, 1.136), Vector2(side * 0.161, 1.25)], 0.029, VERMILION, "m:" + TARNISH)
		# The chalice grows into a weapon-shaped reliquary. Cartilage spurs cradle the bowl.
		var x: float = 0.60 + side * 0.156
		m.tube("hand_r", Vector3(0.60 + side * 0.032, 1.01, -0.112), Vector3(x, 1.255, -0.141), 0.034, 0.016, "m:" + TARNISH, 5)
		m.tube("hand_r", Vector3(x, 1.253, -0.141), Vector3(x + side * 0.04, 1.387, -0.166), 0.016, 0.002, "m:" + SILVER, 5)
	# Low blood-pendulum and sharp tips give the chalice length in the running silhouette.
	m.tube("hand_r", Vector3(0.603, 0.758, -0.069), Vector3(0.616, 0.433, -0.117), 0.042, 0.022, "m:" + TARNISH, 7)
	m.tube("hand_r", Vector3(0.616, 0.433, -0.117), Vector3(0.616, 0.336, -0.159), 0.042, 0.002, "m:" + SILVER, 5)
	_panel(m, "pelvis", -0.292, [Vector2(-0.063, 0.91), Vector2(0, 0.948), Vector2(0.068, 0.907),
		Vector2(0.04, 0.852), Vector2(0, 0.821), Vector2(-0.042, 0.851)], 0.026, "m:" + SILVER)
	# Threaded counters mark the tributes without extra floating lights.
	for bead in 5:
		var point := Vector3(-0.165 + 0.009 * bead, 0.832 - 0.043 * bead, -0.299)
		m.tube("pelvis", point, point + Vector3(0.013, -0.037, -0.008), 0.018, 0.014, VERMILION, 6)


static func _toll_plate(m) -> void:
	# The bell helm is battered and razor-beaked. The face cavity is exposed in a narrow slit.
	_bevel(m, "head", -0.219, [Vector2(-0.206, 1.831), Vector2(-0.155, 1.942), Vector2(0, 1.999),
		Vector2(0.155, 1.934), Vector2(0.205, 1.819), Vector2(0.157, 1.786), Vector2(0, 1.800),
		Vector2(-0.16, 1.788)], 0.087, "m:" + BLACK_BRONZE, "m:" + BRONZE)
	_bevel(m, "head", -0.235, [Vector2(-0.204, 1.708), Vector2(-0.166, 1.791), Vector2(-0.047, 1.743),
		Vector2(0, 1.767), Vector2(0.048, 1.743), Vector2(0.164, 1.789), Vector2(0.205, 1.706),
		Vector2(0.158, 1.547), Vector2(0, 1.474), Vector2(-0.157, 1.551)], 0.077, "m:" + BLACK_BRONZE, "m:" + BRONZE)
	m.tube("head", Vector3(0, 1.926, -0.283), Vector3(0, 1.568, -0.324), 0.014, 0.011, "m:" + BRONZE, 5)
	for side in [-1.0, 1.0]:
		var side_slot := Vector3(side * 0.087, 1.750, -0.311)
		m.tube("head", side_slot - Vector3(side * 0.032, -0.012, 0), side_slot + Vector3(side * 0.040, 0.001, 0.005), 0.006, 0.004, "e:" + TOLL_LIGHT, 5)
		m.tube("head", Vector3(side * 0.257, 1.655, -0.061), Vector3(side * 0.328, 1.604, 0.074), 0.026, 0.013, "m:" + BRONZE, 5)
		var suffix := _side(side)
		for abdominal in 3:
			_bevel(m, "spine", -0.302 + abdominal * 0.02, [Vector2(side * 0.093, 1.091 - abdominal * 0.065),
				Vector2(side * 0.233, 1.155 - abdominal * 0.065), Vector2(side * 0.268, 1.101 - abdominal * 0.069),
				Vector2(side * 0.148, 1.034 - abdominal * 0.067)], 0.035, "m:" + BLACK_BRONZE, "m:" + BRONZE)
		# Triangular hip tassets wrap each plane of the moving thigh.
		_bevel(m, "thigh_" + suffix, -0.183, [Vector2(side * 0.081, 0.833), Vector2(side * 0.262, 0.929),
			Vector2(side * 0.396, 0.812), Vector2(side * 0.320, 0.564), Vector2(side * 0.182, 0.457),
			Vector2(side * 0.10, 0.601)], 0.061, "m:" + BLACK_BRONZE, "m:" + BRONZE)
		for link in 4:
			var y := 0.863 - 0.058 * link
			m.band("thigh_" + suffix, Vector3(side * (0.337 - 0.019 * link), y, -0.213), 0.037, 0.007, "m:" + BRASS,
				0.0, TAU, Vector3(0, PI * 0.31 if link % 2 else 0, side * 0.22))
	# The striking rim carries inward blades. Their negative spaces keep the hammer recognizable by silhouette.
	_bell(m, "hand_r", Vector3(0.71, 1.545, -0.169), 0.294, 0.359)
	for point in 5:
		var angle := point * TAU / 5.0
		var from := Vector3(0.71 + cos(angle) * 0.229, 1.233, -0.169 + sin(angle) * 0.229)
		var to := Vector3(0.71 + cos(angle) * 0.318, 1.054, -0.169 + sin(angle) * 0.318)
		m.tube("hand_r", from, to, 0.039, 0.003, "m:" + BLACK_BRONZE, 5)
	_bevel(m, "fore_l", -0.233, [Vector2(-0.752, 1.126), Vector2(-0.60, 1.25), Vector2(-0.467, 1.12),
		Vector2(-0.45, 0.934), Vector2(-0.606, 0.797), Vector2(-0.735, 0.919)], 0.075, "m:" + BLACK_BRONZE, "m:" + BRONZE)
	for rail in 3:
		var y := 1.007 + (rail - 1) * 0.065
		m.tube("fore_l", Vector3(-0.694, y, -0.309), Vector3(-0.526, y + 0.028, -0.313), 0.012, 0.008, "m:" + BRASS, 5)


static func _pyre_harness(m) -> void:
	# Broken slots expose small fissures between overlapping layers of helmet and gorget.
	_bevel(m, "head", -0.174, [Vector2(-0.152, 1.877), Vector2(-0.087, 1.914), Vector2(-0.005, 1.884),
		Vector2(0.078, 1.909), Vector2(0.161, 1.864), Vector2(0.106, 1.788), Vector2(0.018, 1.768),
		Vector2(-0.094, 1.789)], 0.066, "m:" + OBSIDIAN, "m:" + SCALE)
	_bevel(m, "head", -0.178, [Vector2(-0.149, 1.766), Vector2(-0.092, 1.711), Vector2(-0.036, 1.727),
		Vector2(0.073, 1.726), Vector2(0.14, 1.776), Vector2(0.113, 1.627), Vector2(0.019, 1.552),
		Vector2(-0.097, 1.629)], 0.078, "m:" + OBSIDIAN, "m:" + CHAR)
	_slagline(m, "head", [Vector3(-0.077, 1.669, -0.261), Vector3(0.016, 1.638, -0.265),
		Vector3(0.006, 1.608, -0.256)], 0.005)
	for rail in 3:
		var y := 1.18 - rail * 0.084
		for side in [-1.0, 1.0]:
			var width := 0.175 - rail * 0.022
			_bevel(m, "spine", -0.240, [Vector2(side * 0.018, y + 0.053), Vector2(side * width, y + 0.101),
				Vector2(side * (width + 0.010), y + 0.051), Vector2(side * 0.024, y)], 0.023, "m:" + CHAR, "m:" + HEAT)
			m.tube("spine", Vector3(side * 0.033, y + 0.051, -0.269), Vector3(side * width, y + 0.096, -0.248), 0.009, 0.006, "m:" + FORGED_EDGE, 5)
	for side in [-1.0, 1.0]:
		var suffix := _side(side)
		var shoulder := 0.60 if side > 0 else 0.50
		_bevel(m, "upper_" + suffix, -0.141, [Vector2(side * 0.284, 1.437),
			Vector2(side * 0.449, 1.514), Vector2(side * shoulder, 1.630), Vector2(side * (shoulder + 0.053), 1.445),
			Vector2(side * 0.513, 1.31), Vector2(side * 0.363, 1.369)], 0.058, "m:" + CHAR, "m:" + OBSIDIAN)
		m.tube("upper_" + suffix, Vector3(side * 0.381, 1.397, -0.207),
			Vector3(side * (shoulder - 0.014), 1.537, -0.182), 0.016, 0.006, "m:" + FORGED_EDGE, 6)
		for slat in 3:
			_bevel(m, "fore_" + suffix, -0.123, [Vector2(side * (0.449 + slat * 0.028), 1.112 - slat * 0.065),
				Vector2(side * (0.541 + slat * 0.029), 1.089 - slat * 0.065),
				Vector2(side * (0.636 + slat * 0.012), 1.165 - slat * 0.043),
				Vector2(side * (0.632 + slat * 0.027), 1.038 - slat * 0.063),
				Vector2(side * (0.542 + slat * 0.023), 1.043 - slat * 0.066)], 0.028, "m:" + OBSIDIAN, "m:" + SCALE)
		_greave(m, suffix, side, 0.93, "m:" + OBSIDIAN, "m:" + CHAR)


static func _winter_regalia(m) -> void:
	# The hood opens like a battered reliquary. It hides the face except for the ice around the eyes.
	_bevel(m, "head", -0.164, [Vector2(-0.186, 1.804), Vector2(-0.127, 1.953),
		Vector2(-0.035, 2.005), Vector2(0.100, 1.968), Vector2(0.172, 1.842), Vector2(0.125, 1.753),
		Vector2(0.084, 1.807), Vector2(-0.004, 1.820), Vector2(-0.102, 1.787)], 0.063, INDIGO, RIME_CLOTH)
	_bevel(m, "head", -0.163, [Vector2(-0.121, 1.756), Vector2(-0.078, 1.707), Vector2(0.005, 1.735),
		Vector2(0.086, 1.712), Vector2(0.137, 1.761), Vector2(0.132, 1.586),
		Vector2(0.018, 1.484), Vector2(-0.11, 1.574)], 0.061, INDIGO, "m:" + SCRIBE_IRON)
	for side in [-1.0, 1.0]:
		var suffix := _side(side)
		_bevel(m, "head", -0.075, [Vector2(side * 0.140, 1.93), Vector2(side * 0.194, 1.871),
			Vector2(side * 0.195, 1.635), Vector2(side * 0.103, 1.48), Vector2(side * 0.115, 1.735)], 0.114, INDIGO, RIME_CLOTH)
		m.tube("head", Vector3(side * 0.042, 1.77, -0.228), Vector3(side * 0.108, 1.786, -0.221), 0.006, 0.003, "e:" + SEAL_GLOW, 5)
		_greave(m, suffix, side, 0.94, INDIGO, "m:" + SCRIBE_IRON)
		# Engraved obituaries are soldered to armor and hung from the front of the waist.
		for slip in 3:
			var x: float = side * (0.105 + 0.068 * slip)
			var y := 0.885 - 0.085 * slip
			_bevel(m, "thigh_" + suffix, -0.203, [Vector2(x - 0.034, y - 0.193), Vector2(x - 0.035, y),
				Vector2(x + 0.028, y - 0.010), Vector2(x + 0.038, y - 0.206)], 0.008, PAPER, "m:" + SCRIBE_IRON)
			for line in 3:
				var row_y := y - 0.043 - line * 0.028
				m.tube("thigh_" + suffix, Vector3(x - 0.017, row_y, -0.22), Vector3(x + 0.02, row_y, -0.222), 0.0035, 0.0035, INDIGO, 4)
	# The tool can be read as an ice pick in the thrust silhouette. Its feather has a serrated outline.
	_bevel(m, "hand_r", -0.186, [Vector2(0.650, 0.950), Vector2(0.725, 1.171),
		Vector2(0.835, 1.244), Vector2(0.851, 1.467), Vector2(0.732, 1.683), Vector2(0.733, 1.494),
		Vector2(0.663, 1.437), Vector2(0.698, 1.370), Vector2(0.635, 1.307), Vector2(0.675, 1.228)], 0.022, BONE, "m:" + SCRIBE_IRON)
	m.tube("hand_r", Vector3(0.622, 0.958, -0.237), Vector3(0.740, 1.696, -0.225), 0.018, 0.001, ICE, 5)
	m.tube("hand_r", Vector3(0.586, 0.753, -0.031), Vector3(0.591, 0.524, 0.049), 0.030, 0.006, "m:" + SCRIBE_IRON, 6)
	var book := Vector3(-0.608, 0.851, -0.289)
	for i in 4:
		m.tube("hand_l", book + Vector3(-0.200, -0.062 + 0.033 * i, 0.063), book + Vector3(-0.143, -0.055 + 0.033 * i, -0.043), 0.009, 0.008, "m:" + SCRIBE_IRON, 5)


static func _choir_vestment(m) -> void:
	# Ivory splints frame the cardinal's mantle. The red sleeves stay soft under the armor.
	for side: float in [-1.0, 1.0]:
		var shoulder := "upper_" + _side(side)
		_bevel(m, shoulder, -0.188, [
			Vector2(side * 0.24, 1.43), Vector2(side * 0.35, 1.62),
			Vector2(side * 0.54, 1.67), Vector2(side * 0.64, 1.53),
			Vector2(side * 0.54, 1.37), Vector2(side * 0.32, 1.35),
		], 0.054, "m:" + SILVER, "m:" + TARNISH)
		_tapered_cloth(m, "spine", [
			[Vector3(side * 0.225, 1.52, -0.203), 0.053],
			[Vector3(side * 0.264, 1.32, -0.247), 0.058],
			[Vector3(side * 0.207, 1.09, -0.238), 0.066],
			[Vector3(side * 0.15, 0.96, -0.212), 0.040],
		], WINE, "m:" + SILVER)
		_tapered_cloth(m, "thigh_" + _side(side), [
			[Vector3(side * 0.183, 0.875, -0.219), 0.091],
			[Vector3(side * 0.25, 0.65, -0.236), 0.106],
			[Vector3(side * 0.268, 0.37 if side < 0.0 else 0.49, -0.221), 0.074],
			[Vector3(side * 0.244, 0.26 if side < 0.0 else 0.39, -0.19), 0.005],
		], VERMILION, "m:" + TARNISH)
		var palm := Vector3(0.603 + side * 0.139, 1.20, -0.164)
		var arch := Vector3(0.603 + side * 0.114, 1.414, -0.152)
		m.tube("hand_r", palm, arch, 0.019, 0.012, "m:" + TARNISH, 5)
		m.tube("hand_r", arch, Vector3(0.603, 1.498, -0.153), 0.012, 0.009, "m:" + SILVER, 5)
		m.tube("head", Vector3(side * 0.115, 1.89, -0.326), Vector3(side * 0.066, 2.082, -0.335), 0.012, 0.009, "m:" + SILVER, 5)
		m.tube("head", Vector3(side * 0.066, 2.082, -0.335), Vector3(0, 2.163, -0.334), 0.009, 0.005, "m:" + SILVER, 5)
	m.tube("hand_r", Vector3(0.603, 1.289, -0.142), Vector3(0.603, 1.431, -0.150), 0.028, 0.008, "e:" + COAGULATE, 5)
	_bevel(m, "head", -0.31, [Vector2(-0.046, 1.99), Vector2(0, 2.06), Vector2(0.046, 1.99), Vector2(0, 1.915)],
		0.029, WINE, "m:" + SILVER)


static func _funeral_yoke(m) -> void:
	# Brass suspension cheeks and a verdigris apron identify the Bellwarden from behind.
	for side: float in [-1.0, 1.0]:
		var yoke_tip := Vector3(side * 0.55, 1.61, 0.31)
		m.tube("mantle", Vector3(side * 0.30, 1.456, 0.287), yoke_tip, 0.051, 0.045, "m:" + BRONZE, 6)
		m.tube("mantle", yoke_tip, Vector3(side * 0.575, 1.53, 0.446), 0.045, 0.028, "m:" + BRASS, 6)
		m.tube("mantle", Vector3(side * 0.575, 1.53, 0.446), Vector3(side * 0.575, 1.391, 0.460), 0.022, 0.014, "m:" + PATINA, 6)
		m.tube("mantle", Vector3(side * 0.08, 1.20, 0.23), yoke_tip, 0.036, 0.036, "m:" + BLACK_BRONZE, 6)
		var joint := "upper_" + _side(side)
		# An inset shoulder cheek breaks up the broad bronze planes of the bell armor.
		_bevel(m, joint, -0.209, [Vector2(side * 0.382, 1.477), Vector2(side * 0.545, 1.552),
			Vector2(side * 0.633, 1.46), Vector2(side * 0.575, 1.344), Vector2(side * 0.427, 1.373)],
			0.043, "m:" + PATINA, "m:" + BRASS)
		m.tube("head", Vector3(side * 0.248, 1.586, -0.184), Vector3(side * 0.257, 1.789, -0.119), 0.023, 0.017, "m:" + BRASS, 5)
		m.tube("head", Vector3(side * 0.257, 1.789, -0.119), Vector3(side * 0.18, 1.983, -0.053), 0.017, 0.008, "m:" + BRONZE, 5)
	_tapered_cloth(m, "pelvis", [[Vector3(0, 0.859, -0.325), 0.149], [Vector3(-0.017, 0.665, -0.328), 0.144],
		[Vector3(-0.038, 0.476, -0.307), 0.147], [Vector3(-0.015, 0.340, -0.274), 0.013]], PATINA, "m:" + BRASS)
	_panel(m, "pelvis", -0.365, [Vector2(-0.087, 0.726), Vector2(0, 0.752), Vector2(0.087, 0.726),
		Vector2(0.071, 0.653), Vector2(0, 0.604), Vector2(-0.071, 0.653)], 0.030, "m:" + BRONZE)
	# A lifting eye at the crown makes the helm look like an actual suspended casting.
	m.band("head", Vector3(0, 2.100, 0.020), 0.084, 0.023, "m:" + BRASS, 0.21, PI * 0.86)


static func _cinder_ribbons(m) -> void:
	# Angled silk panels give turns a trailing silhouette beyond the blades.
	_tapered_cloth(m, "mantle", [[Vector3(-0.177, 0.959, 0.165), 0.102], [Vector3(-0.253, 0.740, 0.275), 0.145],
		[Vector3(-0.344, 0.470, 0.383), 0.111], [Vector3(-0.280, 0.232, 0.474), 0.015]], HEAT, "m:" + FORGED_EDGE)
	_tapered_cloth(m, "mantle", [[Vector3(0.129, 0.953, 0.195), 0.098], [Vector3(0.200, 0.735, 0.331), 0.130],
		[Vector3(0.300, 0.563, 0.397), 0.098], [Vector3(0.431, 0.395, 0.481), 0.011]], HEAT, "m:" + FORGED_EDGE)
	for side: float in [-1.0, 1.0]:
		var suffix := _side(side)
		var y := 0.684 if side < 0 else 0.735
		_tapered_cloth(m, "thigh_" + suffix, [[Vector3(side * 0.158, 0.882, -0.184), 0.110],
			[Vector3(side * 0.210, y, -0.206), 0.106], [Vector3(side * 0.230, y - 0.15, -0.183), 0.005]],
			HEAT, "m:" + FORGED_EDGE)
		# A brass eye around each ember makes the tapered face guard read in profile.
		m.tube("head", Vector3(side * 0.133, 1.799, -0.240), Vector3(side * 0.166, 1.702, -0.198), 0.013, 0.008, "m:" + FORGED_EDGE, 5)
		m.tube("head", Vector3(side * 0.166, 1.702, -0.198), Vector3(side * 0.091, 1.61, -0.238), 0.008, 0.006, "m:" + FORGED_EDGE, 5)
	_bevel(m, "spine", -0.266, [Vector2(-0.091, 1.397), Vector2(0.007, 1.423), Vector2(0.096, 1.383),
		Vector2(0.067, 1.285), Vector2(-0.004, 1.216), Vector2(-0.065, 1.297)], 0.033, "m:" + OBSIDIAN, "m:" + FORGED_EDGE)
	_panel(m, "spine", -0.310, [Vector2(-0.035, 1.365), Vector2(0.015, 1.389), Vector2(0.039, 1.349),
		Vector2(0.009, 1.279)], 0.016, "e:" + CORE)


static func _pale_record(m) -> void:
	# A pale asymmetric collar catches the light above the long scholar's coat.
	_bevel(m, "spine", -0.193, [Vector2(-0.355, 1.47), Vector2(-0.267, 1.629), Vector2(-0.158, 1.591),
		Vector2(-0.080, 1.487), Vector2(0.045, 1.459), Vector2(0.196, 1.559), Vector2(0.284, 1.482),
		Vector2(0.274, 1.376), Vector2(0.077, 1.333), Vector2(-0.108, 1.352), Vector2(-0.259, 1.382)],
		0.051, BONE, RIME_CLOTH)
	for side: float in [-1.0, 1.0]:
		var thigh := "thigh_" + _side(side)
		_tapered_cloth(m, thigh, [[Vector3(side * 0.23, 0.886, -0.166), 0.138], [Vector3(side * 0.295, 0.657, -0.193), 0.157],
			[Vector3(side * 0.317, 0.401, -0.173), 0.153], [Vector3(side * 0.253, 0.253, -0.132), 0.077]], RIME_CLOTH, BONE)
		m.tube("head", Vector3(side * 0.166, 1.848, -0.095), Vector3(side * 0.131, 1.942, -0.168), 0.014, 0.013, BONE, 5)
		m.tube("head", Vector3(side * 0.131, 1.942, -0.168), Vector3(side * 0.009, 1.985, -0.225), 0.013, 0.011, BONE, 5)
		var clasp := Vector3(-0.611 + side * 0.230, 0.881, -0.296 + side * 0.048)
		m.box("hand_l", clasp, Vector3(0.032, 0.133, 0.024), "m:" + SCRIBE_IRON, Vector3(-0.52, side * 0.36, 0))
		m.tube("hand_l", clasp, clasp + Vector3(0.0, -0.061, -0.022), 0.009, 0.005, "e:" + SEAL_GLOW, 5)
	_bevel(m, "spine", -0.253, [Vector2(-0.079, 1.421), Vector2(-0.011, 1.466), Vector2(0.046, 1.401),
		Vector2(0.008, 1.312), Vector2(-0.059, 1.347)], 0.040, "m:" + SCRIBE_IRON, BONE)
	m.tube("spine", Vector3(-0.021, 1.445, -0.302), Vector3(0.0, 1.347, -0.303), 0.014, 0.004, "e:" + SEAL_GLOW, 5)


static func _tapered_cloth(m, joint: String, sections: Array, fabric: String, binding: String) -> void:
	var face := SurfaceTool.new()
	var seam := SurfaceTool.new()
	face.begin(Mesh.PRIMITIVE_TRIANGLES)
	seam.begin(Mesh.PRIMITIVE_TRIANGLES)
	var widths := [-1.0, -0.90, -0.42, 0.0, 0.42, 0.90, 1.0]
	for index in range(sections.size() - 1):
		var upper: Array = sections[index]
		var lower: Array = sections[index + 1]
		for column in range(widths.size() - 1):
			var left: float = widths[column]
			var right: float = widths[column + 1]
			var surface := seam if column == 0 or column == widths.size() - 2 else face
			_face(surface, _drape_point(upper, left), _drape_point(lower, left), _drape_point(lower, right), _drape_point(upper, right))
	for pair in [[face, fabric], [seam, binding]]:
		var surface: SurfaceTool = pair[0]
		surface.generate_normals()
		m._add(joint, Vector3.ZERO, Basis.IDENTITY, surface.commit(), pair[1], true)


static func _drape_point(section: Array, across: float) -> Vector3:
	var middle: Vector3 = section[0]
	var width: float = section[1]
	return middle + Vector3(across * width, 0.0, (absf(across) * 0.47 - 0.14 * cos(across * 8.0)) * width)
