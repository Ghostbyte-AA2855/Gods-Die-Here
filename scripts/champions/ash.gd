extends RefCounted

# Rhuun's choir vestments use arterial reds over old silver.
const CASSOCK := "240e19"
const VERMILION := "6f1926"
const WINE := "481329"
const SILVER := "ba9b91"
const TARNISH := "654958"
const COAGULATE := "c63853"
const CHOIR_SKIN := "8d6b70"

# Hest's bronze is blackened except where the rain polishes the bell rims.
const BLACK_BRONZE := "332828"
const BRONZE := "72543d"
const BRASS := "bc9663"
const PATINA := "5b7d74"
const GRAVE_CLOTH := "23242a"
const TOLL_LIGHT := "dfb35f"

# Zarya wears split slag-glass plates that show the fire between them.
const OBSIDIAN := "271c24"
const CHAR := "45313a"
const SCALE := "674445"
const HEAT := "8b3328"
const FIRE := "ef683d"
const CORE := "ffd072"
const ASH_SKIN := "94696b"

# Eive's oath lets color survive only in the ice and the inventory seals.
const INDIGO := "191f30"
const RIME_CLOTH := "314452"
const SCRIBE_IRON := "53616a"
const BONE := "d6c8a9"
const PAPER := "bba986"
const ICE := "78aebe"
const SEAL_GLOW := "a1ecf4"

static func build(model, class_id: String) -> void:
	match class_id:
		"blood_cantor": _rhuun(model)
		"bellwarden": _hest(model)
		"ash_dancer": _zarya(model)
		"winter_scribe": _eive(model)


static func _rhuun(m) -> void:
	# The choir's silhouette starts high and narrow, then descends into two uneven red panels.
	m.ellipsoid("spine", Vector3(0, 1.15, 0.025), Vector3(0.66, 0.60, 0.41), CASSOCK)
	m.tube("spine", Vector3(0, 0.94, 0.02), Vector3(0, 1.35, 0.02), 0.285, 0.33, WINE, 10)
	_panel(m, "spine", -0.224, [Vector2(-0.25, 1.37), Vector2(0, 1.28), Vector2(0.25, 1.37), Vector2(0.18, 0.97), Vector2(0, 0.9), Vector2(-0.18, 0.97)], 0.036, CASSOCK)
	m.tube("pelvis", Vector3(0, 0.76, 0.02), Vector3(0, 0.94, 0.02), 0.35, 0.29, CASSOCK, 9)
	_cord(m, "pelvis", Vector3(0, 0.89, 0.001), 0.31, 0.031, "m:" + TARNISH)
	_panel(m, "pelvis", -0.269, [Vector2(-0.16, 0.85), Vector2(0.15, 0.85), Vector2(0.095, 0.41), Vector2(0.01, 0.30), Vector2(-0.13, 0.48)], 0.024, VERMILION)
	_panel(m, "mantle", 0.20, [Vector2(-0.32, 1.42), Vector2(0.30, 1.41), Vector2(0.39, 0.69), Vector2(0.18, 0.19), Vector2(0.06, 0.28), Vector2(-0.17, 0.33), Vector2(-0.36, 0.53)], 0.045, WINE)
	for side in [-1.0, 1.0]:
		var suffix := _side(side)
		# Each silver rib curls into the cloth. Uneven heights imply bone rather than a uniform grille.
		for row in 5:
			var y := 1.32 - row * 0.066
			var elbow := Vector3(side * (0.16 + row * 0.008), y - 0.027, -0.233)
			m.tube("spine", Vector3(side * 0.031, y, -0.267), elbow, 0.021, 0.019, "m:" + SILVER, 6)
			m.tube("spine", elbow, Vector3(side * (0.30 - row * 0.012), y + 0.024, -0.149), 0.019, 0.010, "m:" + TARNISH, 6)
		m.ellipsoid("upper_" + suffix, Vector3(side * 0.345, 1.34, 0.018), Vector3(0.28, 0.25, 0.32), WINE)
		m.tube("upper_" + suffix, Vector3(side * 0.39, 1.28, -0.12), Vector3(side * 0.47, 1.12, -0.16), 0.028, 0.015, "m:" + TARNISH, 6)
		m.tube("fore_" + suffix, Vector3(side * 0.53, 1.08, 0.0), Vector3(side * 0.60, 0.88, -0.025), 0.103, 0.065, CASSOCK, 8)
		for cuff in 3:
			_cord(m, "fore_" + suffix, Vector3(side * (0.58 + cuff * 0.006), 0.97 - cuff * 0.032, -0.024), 0.076 - cuff * 0.003, 0.010, "m:" + SILVER)
		_panel(m, "thigh_" + suffix, -0.142, [Vector2(side * 0.10, 0.80), Vector2(side * 0.33, 0.83), Vector2(side * 0.34, 0.58), Vector2(side * 0.22, 0.37), Vector2(side * 0.115, 0.52)], 0.030, CASSOCK)
		m.box("foot_" + suffix, Vector3(side * 0.18, 0.105, -0.080), Vector3(0.145, 0.125, 0.27), WINE)
	# Gilded mitre, raised cartilage seam, and turned-up resonant mouth plate.
	m.ellipsoid("head", Vector3(0, 1.70, 0.005), Vector3(0.37, 0.39, 0.38), CHOIR_SKIN)
	m.ellipsoid("head", Vector3(0, 1.82, 0.05), Vector3(0.46, 0.24, 0.40), WINE)
	_panel(m, "head", -0.189, [Vector2(-0.222, 1.81), Vector2(-0.171, 2.02), Vector2(-0.06, 2.19), Vector2(0, 2.245), Vector2(0.12, 2.132), Vector2(0.206, 1.99), Vector2(0.218, 1.81)], 0.26, VERMILION)
	m.tube("head", Vector3(0, 1.83, -0.328), Vector3(0, 2.20, -0.328), 0.02, 0.013, "m:" + SILVER, 7)
	m.box("head", Vector3(0, 1.813, -0.308), Vector3(0.414, 0.031, 0.025), "m:" + TARNISH)
	for side in [-1.0, 1.0]:
		m.ellipsoid("head", Vector3(side * 0.078, 1.731, -0.181), Vector3(0.064, 0.030, 0.027), "e:" + COAGULATE)
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
	m.ellipsoid("spine", Vector3(0, 1.15, 0.055), Vector3(0.85, 0.66, 0.53), BLACK_BRONZE)
	_panel(m, "spine", -0.285, [Vector2(-0.37, 1.36), Vector2(-0.25, 1.46), Vector2(0.24, 1.46), Vector2(0.38, 1.34), Vector2(0.28, 0.96), Vector2(0, 0.89), Vector2(-0.29, 0.97)], 0.084, "m:" + BLACK_BRONZE)
	_panel(m, "spine", -0.335, [Vector2(-0.27, 1.36), Vector2(0.27, 1.36), Vector2(0.19, 1.05), Vector2(0, 1.00), Vector2(-0.19, 1.06)], 0.022, "m:" + BRONZE)
	m.band("spine", Vector3(0, 1.215, -0.356), 0.157, 0.025, "m:" + BRASS)
	m.ellipsoid("spine", Vector3(0, 1.215, -0.376), Vector3(0.187, 0.187, 0.041), PATINA)
	m.tube("spine", Vector3(0, 1.32, -0.41), Vector3(0, 1.12, -0.41), 0.014, 0.014, "e:" + TOLL_LIGHT, 7)
	m.tube("pelvis", Vector3(0, 0.74, 0), Vector3(0, 0.91, 0), 0.373, 0.332, GRAVE_CLOTH, 10)
	for i in range(-2, 3):
		var x := i * 0.132
		m.box("pelvis", Vector3(x, 0.84 - 0.014 * absf(i), -0.272 + 0.047 * absf(i)), Vector3(0.16, 0.15, 0.065), "m:" + BRONZE, Vector3(0.08, -0.19 * i, 0.012 * i))
		m.ellipsoid("pelvis", Vector3(x, 0.86 - 0.012 * absf(i), -0.316 + 0.047 * absf(i)), Vector3(0.044, 0.044, 0.023), "m:" + BRASS)
	# A three-piece bell helmet with a black mouth and pierced eye openings.
	m.tube("head", Vector3(0, 1.54, 0.04), Vector3(0, 1.63, 0.027), 0.31, 0.259, "m:" + BRONZE, 11)
	m.tube("head", Vector3(0, 1.63, 0.027), Vector3(0, 1.95, 0.018), 0.259, 0.19, "m:" + BLACK_BRONZE, 11)
	m.ellipsoid("head", Vector3(0, 1.93, 0.018), Vector3(0.393, 0.204, 0.385), "m:" + BLACK_BRONZE)
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
		for n in 3:
			m.ellipsoid("upper_" + suffix, Vector3(side * (0.37 + n * 0.051), 1.41 - n * 0.057, 0.025), Vector3(0.29, 0.13, 0.43 - n * 0.027), "m:" + (BRONZE if n == 0 else BLACK_BRONZE), Vector3(0, 0, -side * 0.30))
			m.ellipsoid("upper_" + suffix, Vector3(side * (0.4 + n * 0.053), 1.413 - n * 0.058, -0.184), Vector3(0.047, 0.047, 0.025), "m:" + BRASS)
		m.tube("fore_" + suffix, Vector3(side * 0.52, 1.095, 0), Vector3(side * 0.6, 0.885, -0.025), 0.13, 0.106, "m:" + BLACK_BRONZE, 8)
		_panel(m, "fore_" + suffix, -0.112, [Vector2(side * 0.403, 1.102), Vector2(side * 0.61, 1.09), Vector2(side * 0.692, 0.848), Vector2(side * 0.521, 0.864)], 0.043, "m:" + BRONZE)
		_panel(m, "thigh_" + suffix, -0.169, [Vector2(side * 0.04, 0.81), Vector2(side * 0.39, 0.81), Vector2(side * 0.35, 0.61), Vector2(side * 0.19, 0.46), Vector2(side * 0.084, 0.57)], 0.051, "m:" + BLACK_BRONZE)
		m.ellipsoid("shin_" + suffix, Vector3(side * 0.18, 0.48, -0.142), Vector3(0.218, 0.229, 0.109), "m:" + BRONZE)
		m.tube("shin_" + suffix, Vector3(side * 0.18, 0.43, -0.048), Vector3(side * 0.18, 0.18, -0.032), 0.118, 0.098, "m:" + BLACK_BRONZE, 7)
		m.box("foot_" + suffix, Vector3(side * 0.18, 0.101, -0.102), Vector3(0.214, 0.136, 0.32), "m:" + BLACK_BRONZE)
		m.box("foot_" + suffix, Vector3(side * 0.18, 0.108, -0.266), Vector3(0.201, 0.083, 0.041), "m:" + BRONZE)
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
	_bell(m, "hand_r", Vector3(0.65, 1.455, -0.159), 0.237, 0.321)
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
	m.ellipsoid("spine", Vector3(0, 1.17, 0.019), Vector3(0.57, 0.53, 0.39), CHAR)
	_panel(m, "spine", -0.195, [Vector2(-0.265, 1.35), Vector2(-0.12, 1.42), Vector2(0, 1.32), Vector2(0.19, 1.39), Vector2(0.27, 1.30), Vector2(0.154, 0.975), Vector2(-0.10, 0.975)], 0.052, "m:" + OBSIDIAN)
	m.tube("pelvis", Vector3(0, 0.80, 0.012), Vector3(0, 0.97, 0.012), 0.278, 0.22, CHAR, 8)
	_panel(m, "pelvis", -0.225, [Vector2(-0.17, 0.94), Vector2(0.03, 0.88), Vector2(0.19, 0.91), Vector2(0.143, 0.81), Vector2(-0.05, 0.765), Vector2(-0.19, 0.82)], 0.054, "m:" + SCALE)
	_slagline(m, "spine", [Vector3(-0.148, 1.394, -0.23), Vector3(0.016, 1.288, -0.238), Vector3(-0.025, 1.235, -0.24), Vector3(0.114, 1.152, -0.239), Vector3(0.069, 1.056, -0.231)], 0.012)
	m.ellipsoid("head", Vector3(0, 1.723, -0.026), Vector3(0.349, 0.391, 0.33), ASH_SKIN)
	_panel(m, "head", -0.178, [Vector2(-0.173, 1.865), Vector2(0, 1.92), Vector2(0.174, 1.855), Vector2(0.135, 1.679), Vector2(0.005, 1.589), Vector2(-0.155, 1.670)], 0.053, "m:" + OBSIDIAN)
	m.ellipsoid("head", Vector3(0.007, 1.84, 0.037), Vector3(0.36, 0.225, 0.372), OBSIDIAN)
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
		m.ellipsoid("foot_" + suffix, Vector3(side * 0.18, 0.111, -0.119), Vector3(0.173, 0.126, 0.292), "m:" + OBSIDIAN)
		m.tube("foot_" + suffix, Vector3(side * 0.174, 0.126, 0.013), Vector3(side * 0.174, 0.126, 0.151), 0.037, 0.001, "m:" + SCALE, 5)
		m.tube("head", Vector3(side * 0.046, 1.759, -0.213), Vector3(side * 0.127, 1.787, -0.208), 0.024, 0.013, HEAT, 5)
		m.tube("head", Vector3(side * 0.051, 1.763, -0.231), Vector3(side * 0.117, 1.787, -0.229), 0.009, 0.005, "e:" + CORE, 5)
		# Each half of the ember crown is a staggered row of obsidian splinters.
		for shard in 3:
			var base := Vector3(side * (0.067 + 0.045 * shard), 1.899 - 0.018 * shard, 0.047)
			m.tube("head", base, base + Vector3(side * (0.019 + 0.046 * shard), 0.32 - 0.057 * shard, 0.026 + 0.046 * shard), 0.05 - 0.007 * shard, 0.002, "m:" + OBSIDIAN, 5)
			m.tube("head", base + Vector3(0, 0.014, -0.04), base + Vector3(side * 0.021, 0.224 - 0.037 * shard, -0.019), 0.016 - 0.003 * shard, 0.002, "e:" + FIRE, 5)
		_hook_blade(m, "hand_" + suffix, side)
	# The short, singed fork of the pyre sash stays above the boots so kicks remain visible.
	_panel(m, "mantle", 0.173, [Vector2(-0.237, 0.933), Vector2(0.203, 0.935), Vector2(0.299, 0.460), Vector2(0.152, 0.563), Vector2(0.060, 0.386), Vector2(-0.09, 0.552), Vector2(-0.236, 0.471)], 0.027, HEAT)
	_slagline(m, "mantle", [Vector3(-0.224, 0.88, 0.198), Vector3(-0.125, 0.76, 0.198), Vector3(0.08, 0.755, 0.195), Vector3(0.202, 0.587, 0.194)], 0.007)


static func _hook_blade(m, joint: String, side: float) -> void:
	var grip := Vector3(side * 0.60, 0.865, -0.047)
	m.tube(joint, grip + Vector3(-side * 0.04, 0.126, 0.0), grip + Vector3(side * 0.042, -0.13, -0.01), 0.029, 0.024, CHAR, 7)
	m.tube(joint, grip + Vector3(-side * 0.11, -0.086, -0.02), grip + Vector3(side * 0.10, -0.12, -0.017), 0.028, 0.023, "m:" + SCALE, 6)
	var outline := [Vector2(side * 0.52, 0.748), Vector2(side * 0.71, 0.743), Vector2(side * 0.84, 0.575), Vector2(side * 0.918, 0.309), Vector2(side * 0.87, 0.147), Vector2(side * 0.704, 0.088), Vector2(side * 0.778, 0.219), Vector2(side * 0.734, 0.349), Vector2(side * 0.614, 0.455)]
	_panel(m, joint, -0.076, outline, 0.053, "m:" + OBSIDIAN)
	_slagline(m, joint, [Vector3(side * 0.696, 0.704, -0.109), Vector3(side * 0.804, 0.554, -0.109), Vector3(side * 0.867, 0.31, -0.108), Vector3(side * 0.836, 0.172, -0.106), Vector3(side * 0.755, 0.126, -0.105)], 0.018)
	m.tube(joint, Vector3(side * 0.65, 0.704, -0.108), Vector3(side * 0.766, 0.475, -0.111), 0.012, 0.002, "e:" + CORE, 5)


static func _eive(m) -> void:
	# Iron backed court coat and oversized scholar's collar under a broken glacial crown.
	m.ellipsoid("spine", Vector3(0, 1.165, 0.047), Vector3(0.63, 0.59, 0.40), INDIGO)
	_panel(m, "spine", -0.196, [Vector2(-0.25, 1.39), Vector2(-0.04, 1.323), Vector2(0.21, 1.402), Vector2(0.28, 1.30), Vector2(0.14, 0.947), Vector2(-0.164, 0.938)], 0.064, "m:" + SCRIBE_IRON)
	_panel(m, "spine", -0.239, [Vector2(-0.17, 1.316), Vector2(-0.033, 1.274), Vector2(0.106, 1.322), Vector2(0.104, 1.01), Vector2(0, 0.945), Vector2(-0.146, 1.018)], 0.022, RIME_CLOTH)
	m.tube("pelvis", Vector3(0, 0.748, 0.052), Vector3(0, 0.94, 0.025), 0.359, 0.275, INDIGO, 10)
	_cord(m, "pelvis", Vector3(0, 0.90, 0.022), 0.286, 0.018, "m:" + SCRIBE_IRON)
	# The narrow coat panels are split onto the thighs to articulate during a run.
	for side in [-1.0, 1.0]:
		var suffix := _side(side)
		var shoulder := "upper_" + suffix
		var forearm := "fore_" + suffix
		m.ellipsoid(shoulder, Vector3(side * 0.359, 1.335, 0.02), Vector3(0.316, 0.228, 0.353), INDIGO, Vector3(0, 0, -side * 0.23))
		for chip in 4:
			var star := Vector3(side * (0.269 + chip * 0.058), 1.420 - chip * 0.016, 0.033 + 0.008 * chip)
			m.tube(shoulder, star, star + Vector3(side * (0.08 + 0.008 * chip), 0.191 - chip * 0.021, 0.049), 0.038 - 0.003 * chip, 0.001, ICE, 5)
		m.tube(forearm, Vector3(side * 0.521, 1.074, 0.012), Vector3(side * 0.594, 0.884, -0.017), 0.111, 0.069, RIME_CLOTH, 8)
		m.box(forearm, Vector3(side * 0.56, 0.988, -0.088), Vector3(0.122, 0.16, 0.054), "m:" + SCRIBE_IRON, Vector3(0, 0, side * 0.216))
		for knot in 3:
			m.ellipsoid(forearm, Vector3(side * (0.558 + knot * 0.015), 1.023 - 0.038 * knot, -0.129), Vector3(0.027, 0.028, 0.022), "e:" + SEAL_GLOW)
		_panel(m, "thigh_" + suffix, -0.157, [Vector2(side * 0.031, 0.858), Vector2(side * 0.303, 0.849), Vector2(side * 0.326, 0.505), Vector2(side * 0.176, 0.30), Vector2(side * 0.087, 0.532)], 0.040, INDIGO)
		_panel(m, "thigh_" + suffix, -0.183, [Vector2(side * 0.092, 0.823), Vector2(side * 0.239, 0.807), Vector2(side * 0.254, 0.539), Vector2(side * 0.173, 0.391)], 0.015, RIME_CLOTH)
		m.box("foot_" + suffix, Vector3(side * 0.183, 0.111, -0.079), Vector3(0.155, 0.14, 0.282), INDIGO)
		m.tube("foot_" + suffix, Vector3(side * 0.109, 0.123, -0.198), Vector3(side * 0.249, 0.123, -0.198), 0.014, 0.014, "m:" + SCRIBE_IRON, 6)
	# Hair, collar and scalloped nose bridge leave an unmistakably narrow skull.
	m.ellipsoid("spine", Vector3(0, 1.417, 0.076), Vector3(0.554, 0.22, 0.428), RIME_CLOTH)
	m.ellipsoid("head", Vector3(0, 1.701, 0.022), Vector3(0.325, 0.386, 0.317), BONE)
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
	_panel(m, "mantle", 0.206, [Vector2(-0.331, 1.478), Vector2(0.29, 1.48), Vector2(0.43, 1.07), Vector2(0.235, 1.083), Vector2(0.25, 0.64), Vector2(0.08, 0.77), Vector2(-0.12, 0.661), Vector2(-0.245, 0.828), Vector2(-0.385, 0.991)], 0.035, INDIGO)
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
