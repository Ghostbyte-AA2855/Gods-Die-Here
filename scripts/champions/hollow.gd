extends RefCounted

# The four champions use separate costume shapes, metals, and spell implements.
# Their garments, masks, and weapons attach directly to the moving rig joints.

const SOOT := "151619"
const WAX := "c7b17e"
const RELIQUARY := "m:8f5632"
const FLAME := "ffc365"
const ROOT_BARK := "453124"
const RAW_HIDE := "524631"
const HORN := "9e9268"
const MOSS := "6c7853"
const TIDE := "203b39"
const SCUM := "5b8977"
const DROWNED_BONE := "aaa987"
const SALT := "85decb"
const OBSIDIAN := "262135"
const GLASS := "p:8067a0"
const VIOLET := "cbb1fc"


static func build(model, class_id: String) -> void:
	match class_id:
		"lamplighter":
			_ossa(model)
		"longwatch":
			_renn(model)
		"sluicecaller":
			_avar(model)
		"glassmage":
			_vellis(model)


static func _ossa(m) -> void:
	_carved(m, "spine", [
		[Vector3(0,0.94,0.013),Vector2(0.225,0.183)],
		[Vector3(0,1.18,0.004),Vector2(0.285,0.228)],
		[Vector3(0,1.36,0.018),Vector2(0.348,0.223)],
		[Vector3(0,1.51,0.037),Vector2(0.202,0.152)],
	], "2a2529")
	_plate(m, "spine", [[-0.26,1.366],[-0.19,1.429],[-0.06,1.351],[0,1.284],[0.065,1.35],[0.228,1.452],[0.274,1.342],[0.143,1.254],[0,1.213],[-0.176,1.277]], -0.221, 0.047, "412c27")
	m.tube("spine", Vector3(-0.18,1.392,-0.255), Vector3(0.124,1.17,-0.26), 0.013, 0.008, "m:aa754c")
	_carved(m, "head", [
		[Vector3(-0.006,1.48,0.039),Vector2(0.202,0.204)],
		[Vector3(-0.013,1.67,0.027),Vector2(0.186,0.220)],
		[Vector3(-0.033,1.85,0.042),Vector2(0.153,0.187)],
		[Vector3(-0.051,2.02,0.063),Vector2(0.073,0.101)],
		[Vector3(-0.039,2.09,0.056),Vector2(0.011,0.017)],
	], SOOT)
	_plate(m, "head", [[-0.167,1.70],[-0.08,1.755],[0.085,1.765],[0.166,1.703],[0.074,1.654],[-0.128,1.659]], -0.269, 0.047, "171015")
	_plate(m, "head", [[-0.117,1.672],[0.101,1.674],[0.093,1.554],[0.045,1.464],[-0.013,1.486],[-0.068,1.426],[-0.111,1.524]], -0.266, 0.037, "282128")
	for i in 5:
		var x := -0.085 + i * 0.039
		m.tube("head", Vector3(x,1.654,-0.288), Vector3(x * 0.72,1.483 + (i % 2) * 0.064,-0.285), 0.007, 0.003, "4d3334", 4)
	_plate(m, "head", [[-0.20, 1.71],[-0.13, 1.88],[0.04, 1.99],[0.21, 1.79],[0.20, 1.60],[0.09, 1.49],[-0.14, 1.54]], -0.154, 0.11, "2d2329")
	_plate(m, "head", [[-0.145, 1.70],[-0.08, 1.77],[0.06, 1.79],[0.15, 1.71],[0.08, 1.55],[-0.07, 1.55]], -0.228, 0.023, SOOT)
	for side: float in [-1.0, 1.0]:
		m.tube("head", Vector3(side * 0.150, 1.72, -0.265), Vector3(side * 0.085, 1.824, -0.254), 0.014, 0.008, RELIQUARY)
		m.tube("head", Vector3(side * 0.020,1.686,-0.295), Vector3(side * 0.106,1.704,-0.294), 0.007, 0.004, "e:e7a551", 4)
		var upper := _side("upper", side)
		var fore := _side("fore", side)
		_wrapped_limb(m, side, upper, 0.349, 1.433, 0.519, 1.103, 0.156, 0.089, "272429")
		var shoulder := side * 0.366
		_plate(m, upper, [[shoulder-side*0.124,1.382],[shoulder+side*0.047,1.489],[shoulder+side*0.169,1.389],[shoulder+side*0.157,1.256],[shoulder+side*0.09,1.198],[shoulder-side*0.08,1.31]], -0.085, 0.162, "30262f")
		_gauntlet(m, side, "37292b", "m:6f4d38", "554032")
		for pin in 4:
			var t := float(pin)/3.0
			var p := Vector3(side * lerpf(0.411,0.527,t),1.377 - t * 0.126,-0.168)
			m.tube(upper, p, p + Vector3(side * 0.029, 0.034, -0.014), 0.013, 0.009, "m:8e5b3d", 6)
		m.tube(fore, Vector3(side * 0.446, 1.09, -0.04), Vector3(side * 0.47, 0.94, -0.091), 0.10, 0.073, "3a2e29")
		for row in 3:
			for ix in range(4):
				var x := side * (0.15 + 0.080 * ix + 0.037 * row)
				var y := 1.47 - row * 0.14 - ix * 0.034
				var z := 0.17 + ix * 0.031 + row * 0.027
				var point := Vector3(x, y, z)
				m.tube("mantle", point, point + Vector3(side * 0.075, -0.26 + ix * 0.016, 0.06), 0.052, 0.001, "242127" if (row + ix) % 2 else SOOT, 5)
				if ix == 3:
					m.tube("mantle", point, point - Vector3(side * 0.021, 0.066, -0.021), 0.020, 0.004, RELIQUARY, 5)
		_boot(m, side, "251e25", "m:58413c", "43342e")
		m.tube(_side("shin", side), Vector3(side * 0.18, 0.255, -0.015), Vector3(side * 0.18, 0.373, 0), 0.075, 0.098, "392a2c", 7)
		for i in range(3):
			var candle := Vector3(side * (0.211 + i * 0.077), 1.62 - 0.044 * i, 0.141 + i * 0.011)
			var end := candle + Vector3(side * 0.022, 0.123 + (i % 2) * 0.040, 0)
			_candle(m, "mantle", candle, end, 0.022)
			m.tube("mantle", candle - Vector3.UP * 0.034, candle, 0.042, 0.033, RELIQUARY, 6)
	for section in range(5):
		var x := -0.28 + section * 0.14
		var bottom: float = 0.10 + [0.03, 0.077, 0.009, 0.025, 0.11][section]
		_plate(m, "pelvis", [[x * 0.84 - 0.076, 0.94],[x * 0.86 + 0.076, 0.95],[x * 1.26 + 0.12, bottom + 0.11],[x * 1.34 + 0.046, bottom],[x * 1.23 - 0.104, bottom + 0.04]], -0.124 - absf(x) * 0.08, 0.19, "29252a" if section % 2 else SOOT)
		m.tube("pelvis", Vector3(x, 0.90, -0.228), Vector3(x + 0.01, bottom + 0.11, -0.228), 0.011, 0.006, "46403b", 5)
	m.box("pelvis", Vector3(0, 0.936, -0.234), Vector3(0.22, 0.114, 0.04), RELIQUARY)
	m.tube("spine", Vector3(-0.24, 1.40, -0.176), Vector3(0.21, 0.955, -0.233), 0.051, 0.042, "432b25", 5)
	for i in range(4):
		_orb(m, "spine", Vector3(-0.17 + i * 0.081, 1.32 - i * 0.075, -0.25), Vector3(0.025, 0.025, 0.012), RELIQUARY)
	for side: float in [-1.0, 1.0]:
		var x := side * 0.305
		_plate(m, "mantle", [[side * 0.166,1.42],[side * 0.482,1.374],[side * 0.598,1.162],[side * 0.485,0.89],[side * 0.402,0.753],[side * 0.458,0.37],[side * 0.278,0.319],[side * 0.151,0.575],[side * 0.156,0.916]], 0.23, 0.082, "1c1b23")
		for crease in 3:
			var point := Vector3(x + side * (crease - 1) * 0.072, 1.28 - crease * 0.015, 0.278)
			m.tube("mantle", point, point + Vector3(side * 0.063, -0.78 + crease * 0.11, 0.008), 0.023, 0.006, "302630", 5)
	_ossa_lantern(m)


static func _ossa_lantern(m) -> void:
	var handle := Vector3(0.60, 0.866, -0.035)
	var staff_top := handle + Vector3(0.02, 1.08, -0.062)
	m.tube("hand_r", handle - Vector3.UP * 0.75, staff_top, 0.033, 0.023, "353235", 8)
	for i in range(5):
		var y := handle.y - 0.105 + 0.044 * i
		m.tube("hand_r", Vector3(handle.x, y, handle.z), Vector3(handle.x, y + 0.027, handle.z), 0.042, 0.042, RELIQUARY, 8)
	var arch := [staff_top, staff_top + Vector3(0.10, 0.20, -0.02), staff_top + Vector3(0.32, 0.16, -0.03), staff_top + Vector3(0.40, 0.052, -0.033), staff_top + Vector3(0.34, -0.064, -0.035)]
	_path(m, "hand_r", arch, 0.026, 0.016, RELIQUARY)
	var crown: Vector3 = arch[-1] - Vector3.UP * 0.019
	var deck := crown - Vector3.UP * 0.405
	m.tube("hand_r", deck - Vector3.UP * 0.038, deck, 0.104, 0.139, RELIQUARY, 6)
	m.tube("hand_r", crown - Vector3.UP * 0.096, crown, 0.132, 0.048, RELIQUARY, 6)
	for i in 6:
		var a := i * TAU / 6.0
		var outward := Vector3(cos(a), 0, sin(a))
		m.tube("hand_r", deck + outward * 0.124, crown + outward * 0.087 - Vector3.UP * 0.057, 0.015, 0.009, "9b6440", 6)
	_candle(m, "hand_r", deck + Vector3.UP * 0.015, deck + Vector3.UP * 0.137, 0.045)
	_orb(m, "hand_r", deck + Vector3.UP * 0.185, Vector3(0.054, 0.087, 0.051), "e3893e", true)
	for i in 6:
		var theta := (i + 0.5) * TAU / 6.0
		var radial := Vector3(cos(theta),0,sin(theta))
		m.tube("hand_r", deck + Vector3.DOWN * 0.036 + radial * 0.098, deck + Vector3.DOWN * 0.107 + radial * 0.152, 0.025, 0.003, RELIQUARY, 5)
		m.tube("hand_r", deck + Vector3.UP * 0.158 + radial * 0.111,
			deck + Vector3.UP * 0.222 + radial * 0.099, 0.010, 0.004, "e:6e412b", 5)


static func _renn(m) -> void:
	_carved(m, "spine", [
		[Vector3(0,0.93,0.024),Vector2(0.218,0.169)],
		[Vector3(0,1.115,0.028),Vector2(0.262,0.205)],
		[Vector3(0,1.39,0.027),Vector2(0.331,0.228)],
		[Vector3(0,1.489,0.034),Vector2(0.221,0.181)],
	], "312f2b")
	_plate(m, "spine", [[-0.245,1.36],[-0.167,1.444],[-0.026,1.268],[0.018,1.092],[-0.102,0.998],[-0.223,1.09]], -0.201, 0.062, "39372a")
	_plate(m, "spine", [[0.037,1.33],[0.236,1.421],[0.273,1.302],[0.207,1.11],[0.074,1.057],[0.051,1.165]], -0.198, 0.074, "4a3d2e")
	_carved(m, "head", [
		[Vector3(0,1.515,-0.008),Vector2(0.104,0.103)],
		[Vector3(-0.001,1.625,-0.015),Vector2(0.143,0.146)],
		[Vector3(0.001,1.776,0.016),Vector2(0.148,0.157)],
		[Vector3(-0.014,1.857,0.043),Vector2(0.09,0.115)],
	], "24271f")
	_plate(m, "head", [[-0.136,1.772],[-0.078,1.86],[0.041,1.87],[0.152,1.765],[0.102,1.659],[0.020,1.484],[-0.068,1.505],[-0.104,1.625]], -0.208, 0.064, "92825e")
	_plate(m, "head", [[-0.027,1.721],[0.035,1.713],[0.063,1.577],[0.025,1.506],[-0.045,1.514],[-0.070,1.562]], -0.253, 0.041, "b1a077")
	_plate(m, "head", [[-0.16, 1.83],[-0.063, 1.862],[0.126, 1.80],[0.152, 1.677],[0.045, 1.548],[-0.076, 1.57],[-0.15, 1.69]], -0.181, 0.055, HORN)
	_plate(m, "head", [[-0.142, 1.743],[-0.070, 1.745],[-0.036, 1.701],[-0.124, 1.686]], -0.252, 0.012, "191c19")
	_plate(m, "head", [[0.046, 1.702],[0.063, 1.749],[0.128, 1.725],[0.120, 1.685]], -0.252, 0.012, "191c19")
	m.tube("head", Vector3(0.062, 1.706, -0.264), Vector3(0.102, 1.713, -0.263), 0.006, 0.003, "e:9ca95f", 5)
	m.tube("head", Vector3(-0.106, 1.716, -0.26), Vector3(-0.065, 1.706, -0.266), 0.004, 0.007, "e:9ca95f", 5)
	_plate(m, "head", [[-0.012, 1.736],[0.041, 1.665],[0.003, 1.59],[-0.031, 1.658]], -0.224, 0.026, "beab83")
	for side: float in [-1.0, 1.0]:
		var fork := [Vector3(side * 0.132, 1.795, 0.056), Vector3(side * 0.250, 1.879, 0.102), Vector3(side * 0.320, 2.068, 0.129), Vector3(side * 0.395, 2.21, 0.178), Vector3(side * 0.432, 2.32, 0.115)]
		_path(m, "head", fork, 0.055, 0.009, HORN)
		_path(m, "head", [fork[1], Vector3(side * 0.415, 1.958, 0.093), Vector3(side * 0.518, 2.064, 0.038)], 0.041, 0.007, "887a58")
		_path(m, "head", [fork[2], Vector3(side * 0.259, 2.169, 0.103), Vector3(side * 0.217, 2.234, 0.037)], 0.030, 0.006, HORN)
		_path(m, "head", [fork[2], Vector3(side * 0.424, 2.103, 0.166), Vector3(side * 0.506, 2.182, 0.216)], 0.031, 0.007, HORN)
		var arm := _side("upper", side)
		_wrapped_limb(m, side, arm, 0.329, 1.43, 0.524, 1.093, 0.137, 0.093, "36332a")
		if side < 0.0:
			_plate(m, arm, [[-0.24,1.46],[-0.429,1.515],[-0.56,1.405],[-0.557,1.294],[-0.469,1.213],[-0.335,1.32]], -0.092, 0.199, "m:73624b")
			for shard in range(4):
				var base := Vector3(-0.356 - 0.043 * shard,1.445 - 0.043 * shard,-0.158)
				m.tube(arm, base, base + Vector3(-0.074,0.109,-0.034), 0.031, 0.003, HORN, 5)
		else:
			_plate(m, arm, [[0.263,1.388],[0.405,1.451],[0.524,1.352],[0.52,1.25],[0.492,1.208],[0.359,1.286]], -0.104, 0.147, RAW_HIDE)
		_gauntlet(m, side, "322a21", "m:73624b", ROOT_BARK)
		m.tube(_side("fore", side), Vector3(side * 0.427, 1.118, -0.068), Vector3(side * 0.483, 0.932, -0.127), 0.091, 0.069, "322b21")
		for lace in range(4):
			var base := Vector3(side * 0.46, 0.957 + lace * 0.042, -0.128)
			m.tube(_side("fore", side), base, base + Vector3(side * 0.009, 0.021, 0.008), 0.084, 0.079, "48372a", 7)
		for i in 3:
			var lashing := Vector3(side * 0.18, 0.264 + i * 0.052, -0.003)
			m.tube(_side("shin", side), lashing, lashing + Vector3.UP * 0.026, 0.074 + i * 0.008, 0.078 + i * 0.008, "6b5139", 7)
			m.tube(_side("shin", side), lashing + Vector3(-0.055, -0.008, -0.064), lashing + Vector3(0.059, 0.034, -0.065), 0.010, 0.007, HORN, 5)
		_boot(m, side, "332b24", "m:685133", "463722")
		var knee := side * 0.183
		_plate(m, _side("shin",side), [[knee-0.094,0.484],[knee-0.042,0.578],[knee+0.044,0.562],[knee+0.094,0.465],[knee+0.033,0.393],[knee-0.045,0.401]], -0.086, 0.117, "574731")
		_plate(m, _side("shin",side), [[knee-0.053,0.444],[knee+0.055,0.457],[knee+0.077,0.261],[knee+0.037,0.178],[knee-0.045,0.195]], -0.091, 0.095, "302a22")
		for i in 3:
			var x := side * (0.10 + 0.081 * i)
			_plate(m, _side("thigh", side), [[x - 0.067, 0.929],[x + 0.063, 0.92],[x + 0.103, 0.55 + 0.029 * i],[x + 0.041, 0.458 + 0.079 * i],[x - 0.071, 0.558]], -0.125, 0.08, "443930" if i % 2 else "302925")
	_plate(m, "mantle", [[-0.42, 1.35],[-0.36, 1.49],[0.05, 1.503],[0.391, 1.415],[0.392, 1.197],[0.282, 1.099],[0.173, 1.149],[0.039, 1.003],[-0.125, 0.958],[-0.215, 1.029],[-0.360, 1.009]], 0.18, 0.115, RAW_HIDE)
	for i in range(8):
		var x := -0.34 + 0.088 * i
		m.tube("mantle", Vector3(x, 1.398 - absf(x) * 0.12, 0.258), Vector3(x * 1.07, 1.149 - absf(x) * 0.23, 0.276), 0.059, 0.003, MOSS if i % 3 == 0 else ROOT_BARK, 6)
	m.tube("spine", Vector3(-0.29, 1.427, -0.162), Vector3(0.263, 0.939, -0.215), 0.045, 0.043, "423329", 6)
	for i in range(9):
		var p := Vector3(-0.27 + i * 0.058, 1.412 - i * 0.049, -0.223)
		m.tube("spine", p, p + Vector3(0.017, -0.034, -0.012), 0.011, 0.017, "b19d6b", 5)
	_renn_bow(m)
	var quiver := Vector3(-0.28, 1.065, 0.314)
	m.tube("spine", quiver, quiver + Vector3(0.362, 0.45, 0.054), 0.102, 0.115, "422d29", 8)
	m.tube("spine", quiver + Vector3(0.32, 0.405, 0.044), quiver + Vector3(0.369, 0.464, 0.054), 0.124, 0.125, RELIQUARY, 8)
	for i in range(4):
		var arrow := quiver + Vector3(0.349 + 0.034 * i, 0.45, 0.032 + 0.017 * i)
		var tail := arrow + Vector3(0.129 + 0.016 * i, 0.178 + 0.021 * i, 0.031)
		m.tube("spine", arrow, tail, 0.011, 0.007, "a58f5c", 6)
		m.tube("spine", tail - Vector3(0.045, 0.042, 0.018), tail - Vector3(0.007, 0, 0.032), 0.026, 0.002, MOSS, 4)


static func _renn_bow(m) -> void:
	var grip := Vector3(-0.60, 0.87, -0.035)
	var core := [grip + Vector3(-0.14,-0.93,0.092), grip + Vector3(-0.20,-0.68,-0.06), grip + Vector3(-0.183,-0.44,-0.108), grip + Vector3(-0.06,-0.21,-0.065), grip, grip + Vector3(-0.06,0.22,-0.065), grip + Vector3(-0.183,0.45,-0.108), grip + Vector3(-0.20,0.70,-0.06), grip + Vector3(-0.15,1.06,0.095)]
	_path(m, "hand_l", core, 0.065, 0.051, ROOT_BARK)
	var laminate := []
	for point: Vector3 in core:
		laminate.append(point + Vector3(-0.018, 0.0, -0.027))
	_path(m, "hand_l", laminate, 0.020, 0.016, HORN)
	for tip: Vector3 in [core[0], core[-1]]:
		var barbed := tip + Vector3(0.131, 0.063 if tip.y > 1.0 else -0.037, -0.081)
		m.tube("hand_l", tip, barbed, 0.063, 0.007, "m:7f8066", 6)
		m.tube("hand_l", tip + Vector3(-0.029,0.016,-0.006), barbed + Vector3(-0.042,0.066,-0.012), 0.034, 0.003, "m:9f956d", 5)
	for i in range(6):
		var y := grip.y - 0.118 + 0.042 * i
		m.tube("hand_l", Vector3(grip.x, y, grip.z), Vector3(grip.x, y + 0.021, grip.z), 0.063, 0.063, "242722", 8)
	m.tube("hand_l", core[0], core[-1], 0.007, 0.007, "d5bb81", 5)


static func _avar(m) -> void:
	_carved(m, "spine", [
		[Vector3(0,0.929,0.022),Vector2(0.214,0.132)],
		[Vector3(0,1.082,0.034),Vector2(0.248,0.157)],
		[Vector3(0,1.358,0.035),Vector2(0.295,0.198)],
		[Vector3(0,1.464,0.013),Vector2(0.236,0.166)],
	], "1a2927")
	_plate(m, "spine", [[-0.253,1.43],[-0.174,1.47],[0.038,1.423],[0.272,1.466],[0.259,1.358],[0.136,1.283],[0.014,1.324],[-0.141,1.3]], -0.154, 0.081, "33534f")
	_plate(m, "spine", [[-0.05, 1.047],[-0.064, 1.419],[0.0, 1.52],[0.065, 1.415],[0.053, 1.055]], -0.178, 0.036, DROWNED_BONE)
	_carved(m, "head", [
		[Vector3(0.004,1.515,-0.03),Vector2(0.084,0.105)],
		[Vector3(0.004,1.62,-0.037),Vector2(0.115,0.129)],
		[Vector3(-0.003,1.758,0.012),Vector2(0.153,0.159)],
		[Vector3(-0.021,1.847,0.031),Vector2(0.132,0.135)],
		[Vector3(-0.055,1.883,0.021),Vector2(0.063,0.085)],
	], "a19e7e")
	_plate(m, "head", [[-0.13,1.76],[-0.072,1.797],[-0.023,1.762],[-0.041,1.701],[-0.127,1.701]], -0.175, 0.036, "272827")
	_plate(m, "head", [[0.025,1.723],[0.042,1.773],[0.116,1.777],[0.148,1.727],[0.117,1.683],[0.067,1.687]], -0.17, 0.036, "262a27")
	_path(m, "head", [Vector3(-0.093,1.883,-0.036),Vector3(-0.067,1.809,-0.137),Vector3(-0.09,1.773,-0.157),Vector3(-0.048,1.725,-0.188)], 0.011, 0.003, "4a5140")
	_plate(m, "head", [[-0.113,1.662],[-0.062,1.634],[0.079,1.644],[0.118,1.691],[0.095,1.608],[0.047,1.563],[-0.075,1.562]], -0.195, 0.024, "252324")
	_plate(m, "head", [[-0.113, 1.703],[-0.091, 1.565],[-0.058, 1.516],[0.063, 1.516],[0.105, 1.561],[0.124, 1.687],[0.065, 1.613],[-0.057, 1.613]], -0.145, 0.067, "c1bd95")
	_plate(m, "head", [[-0.034, 1.70],[0.020, 1.72],[0.032, 1.656],[-0.029, 1.64]], -0.166, 0.031, "272d27")
	for i in range(6):
		var x := -0.069 + 0.029 * i
		m.tube("head", Vector3(x, 1.625, -0.174), Vector3(x + 0.002, 1.582 + 0.005 * (i % 2), -0.171), 0.015, 0.009, "c3bc92", 5)
	for side: float in [-1.0, 1.0]:
		m.tube("head", Vector3(side * 0.142,1.695,-0.16), Vector3(side * 0.093,1.637,-0.194), 0.032, 0.012, "a9a789", 5)
		m.tube("head", Vector3(side * 0.092,1.742,-0.195),Vector3(side * 0.054,1.731,-0.199), 0.009, 0.005, "e:" + SALT, 5)
		m.tube("head", Vector3(side * 0.113, 1.82, -0.114), Vector3(side * 0.152, 1.95, -0.067), 0.026, 0.005, SCUM)
		for rib in range(6):
			var y := 1.378 - rib * 0.057
			var turn := side * (0.252 - 0.012 * rib)
			var from_back := [Vector3(0.044 * side, y + 0.054, 0.106), Vector3(turn, y + 0.041, 0.08), Vector3(turn, y - 0.039, -0.142), Vector3(0.109 * side, y - 0.081, -0.206), Vector3(0.026 * side, y - 0.049, -0.209)]
			_path(m, "spine", from_back, 0.022, 0.012, DROWNED_BONE if rib % 2 == 0 else "8f9b82")
		var upper := _side("upper", side)
		_wrapped_limb(m, side, upper, 0.332, 1.43, 0.529, 1.098, 0.143, 0.085, TIDE)
		_gauntlet(m, side, "203632", "m:62745c", "486354")
		var x_edge := side * 0.343
		_plate(m, upper, [[x_edge-side*0.112,1.354],[x_edge+side*0.044,1.503],[x_edge+side*0.174,1.403],[x_edge+side*0.12,1.303],[x_edge+side*0.095,1.181],[x_edge-side*0.09,1.29]], -0.087, 0.119, "32574f")
		m.tube(_side("fore", side), Vector3(0.502 * side, 1.08, -0.03), Vector3(0.591 * side, 0.901, -0.04), 0.079, 0.04, "637a6c")
		for i in range(4):
			var x := side * (0.27 + i * 0.044)
			m.tube(upper, Vector3(x, 1.304 + i * 0.025, 0.076), Vector3(x + side * 0.088, 1.532 + i * 0.034, 0.145), 0.065 - i * 0.008, 0.002, SCUM, 5)
		var shin := _side("shin", side)
		m.tube(shin, Vector3(side * 0.18, 0.431, -0.068), Vector3(side * 0.194, 0.22, -0.075), 0.073, 0.037, DROWNED_BONE, 6)
		for bead in 3:
			var point := Vector3(side * (0.17 + bead * 0.025), 0.28 - bead * 0.022, -0.121 + bead * 0.016)
			m.tube(shin, point, point + Vector3(side * 0.026, 0.036, -0.026), 0.023, 0.013, "91a381", 6)
		_boot(m, side, "273b35", "m:687563", "9b956f")
		_plate(m, shin, [[side*0.18-0.052,0.439],[side*0.18+0.02,0.534],[side*0.18+0.099,0.453],[side*0.18+0.08,0.272],[side*0.18+0.02,0.189],[side*0.18-0.057,0.273]], -0.095, 0.106, "395a51")
		for strip in range(3):
			var x := side * (0.111 + strip * 0.081)
			_plate(m, "mantle", [[x-side*0.093,1.191],[x+side*0.134,1.207],[x+side*0.18,0.713],[x+side*0.13,0.462],[x+side*0.14,0.283],[x+side*0.057,0.369],[x+side*0.019,0.257],[x-side*0.04,0.51],[x-side*0.089,0.786]], 0.205 + strip*0.037, 0.056, "263d35" if strip%2==0 else "314e43")
		for j in range(3):
			var x := side * (0.18 + j * 0.071)
			var y := 0.965 - j * 0.011
			_plate(m, _side("thigh", side), [[x - 0.086, y],[x + 0.081, y],[x + 0.057, y - 0.345 - j * 0.027],[x + 0.001, y - 0.471 - j * 0.044],[x - 0.061, y - 0.22]], -0.048 - j * 0.035, 0.023, TIDE if j % 2 == 0 else "294b43")
			m.tube("mantle", Vector3(x, 1.21 - j * 0.012, 0.154), Vector3(x + side * 0.066, 0.611 - j * 0.064, 0.229), 0.048, 0.003, "315148", 5)
	for i in range(6):
		var a := i * TAU / 6.0
		var salt := Vector3(cos(a) * 0.155, 1.834 + (i % 2) * 0.013, sin(a) * 0.146)
		m.tube("head", salt, salt + Vector3(cos(a) * 0.094, 0.162 - (i % 3) * 0.022, sin(a) * 0.092), 0.045, 0.002, "517468", 5)
		if i % 2 == 0:
			_orb(m, "head", salt, Vector3(0.036, 0.031, 0.035), "b3ac82")
	_avar_trident(m)


static func _avar_trident(m) -> void:
	var grip := Vector3(0.60, 0.866, -0.035)
	var collar := Vector3(0.67, 1.83, -0.062)
	var crown := collar + Vector3(0.024, 0.19, -0.016)
	m.tube("hand_r", grip - Vector3.UP * 0.8, collar, 0.038, 0.035, "m:4a5143", 8)
	for i in range(5):
		var loop := grip + Vector3(0, -0.085 + i * 0.046, 0)
		m.tube("hand_r", loop, loop + Vector3.UP * 0.025, 0.047, 0.040, "68533b", 8)
	for i in range(3):
		var ring := collar + Vector3.UP * (0.037 * i)
		m.tube("hand_r", ring, ring + Vector3.UP * 0.028, 0.066 - i * 0.008, 0.068 - i * 0.008, "m:8f784b", 7)
	for side: float in [-1.0, 1.0]:
		var arm := [collar, collar + Vector3(side * 0.168, 0.098, 0), crown + Vector3(side * 0.215, 0.038, -0.014), crown + Vector3(side * (0.242 if side < 0 else 0.293), 0.319 - (0.069 if side < 0 else 0.0), -0.034)]
		_path(m, "hand_r", arm, 0.051, 0.007, "m:8c956e")
		m.tube("hand_r", arm[2], arm[2] + Vector3(side * 0.09, 0.123, -0.009), 0.024, 0.001, SCUM, 5)
	m.tube("hand_r", crown - Vector3.UP * 0.134, crown + Vector3(0, 0.43, -0.025), 0.041, 0.001, "m:b4b189", 5)
	m.tube("hand_r", crown + Vector3(0, 0.124, -0.054), crown + Vector3(0, 0.38, -0.061), 0.012, 0.001, "e:" + SALT, 5)
	for i in range(4):
		var link := collar - Vector3(0.038 + (i % 2) * 0.022, 0.13 + i * 0.101, 0.045)
		m.band("hand_r", link, 0.044, 0.005, "m:86784e", 0.0, TAU, Vector3(0, (i % 2) * 0.72, 0.25))
		m.tube("hand_r", link - Vector3(0,0,0.013), link - Vector3(0,0,0.031), 0.031, 0.031, "m:ab8b58", 8)


static func _vellis(m) -> void:
	_carved(m, "spine", [
		[Vector3(0,0.946,0.011),Vector2(0.202,0.152)],
		[Vector3(0,1.112,0.009),Vector2(0.217,0.184)],
		[Vector3(-0.017,1.318,0.031),Vector2(0.289,0.219)],
		[Vector3(-0.023,1.484,0.055),Vector2(0.244,0.171)],
		[Vector3(-0.006,1.55,0.091),Vector2(0.148,0.122)],
	], "252033")
	_plate(m, "spine", [[-0.318, 1.40],[-0.15, 1.486],[-0.012, 1.29],[-0.027, 1.068],[-0.183, 0.964],[-0.25, 1.18]], -0.174, 0.073, "332a48")
	_plate(m, "spine", [[0.015, 1.291],[0.176, 1.433],[0.312, 1.376],[0.232, 1.113],[0.061, 0.951]], -0.194, 0.084, GLASS)
	_plate(m, "spine", [[-0.032, 1.26],[0.084, 1.377],[0.129, 1.328],[0.041, 1.17],[-0.003, 1.11]], -0.259, 0.017, "e:986bc9")
	_path(m, "spine", [Vector3(0.026, 1.089, -0.254), Vector3(0.162, 1.166, -0.255), Vector3(0.237, 1.306, -0.253), Vector3(0.196, 1.406, -0.250)], 0.006, 0.014, "p:b6ade0")
	_path(m, "spine", [Vector3(-0.278, 1.395, -0.227), Vector3(-0.182, 1.444, -0.229), Vector3(-0.031, 1.302, -0.231)], 0.012, 0.006, "p:8985b5")
	_carved(m, "head", [
		[Vector3(0.016,1.511,-0.017),Vector2(0.075,0.127)],
		[Vector3(0.011,1.594,0.005),Vector2(0.107,0.139)],
		[Vector3(0.016,1.728,0.018),Vector2(0.154,0.152)],
		[Vector3(0.01,1.852,0.06),Vector2(0.129,0.136)],
		[Vector3(-0.033,1.929,0.09),Vector2(0.063,0.075)],
	], OBSIDIAN)
	_plate(m, "head", [[-0.155,1.737],[-0.181,1.836],[-0.095,1.923],[-0.036,1.907],[-0.001,1.829],[-0.026,1.736]], -0.177, 0.083, "m:554367")
	_plate(m, "head", [[0.006,1.692],[0.071,1.704],[0.142,1.67],[0.098,1.572],[0.032,1.505],[-0.056,1.563],[-0.018,1.639]], -0.184, 0.063, "504064")
	for sliver in 4:
		var x := -0.028 + sliver * 0.028
		m.tube("head",Vector3(x,1.63 - sliver*0.006,-0.221), Vector3(x*0.72,1.551+sliver*0.012,-0.215), 0.011, 0.003, "m:77708c", 5)
	_plate(m, "head", [[-0.177, 1.766],[-0.093, 1.891],[-0.031, 1.867],[0.028, 1.702],[-0.024, 1.57],[-0.123, 1.601]], -0.17, 0.074, "p:8a7ba8")
	_plate(m, "head", [[-0.032, 1.88],[0.101, 1.849],[0.169, 1.745],[0.10, 1.738],[0.044, 1.705]], -0.143, 0.062, "p:655080")
	_plate(m, "head", [[-0.151,1.775],[-0.091,1.885],[-0.04,1.854],[-0.102,1.789]], -0.215, 0.014, "p:b4a9cb")
	_plate(m, "head", [[0.056, 1.718],[0.166, 1.744],[0.14, 1.625],[0.043, 1.571],[0.011, 1.618]], -0.151, 0.071, OBSIDIAN)
	_path(m, "head", [Vector3(-0.042,1.867,-0.208), Vector3(0.002,1.755,-0.229), Vector3(-0.023,1.72,-0.237), Vector3(0.016,1.655,-0.234), Vector3(-0.025,1.587,-0.206)], 0.012, 0.006, "e:" + VIOLET)
	_plate(m, "head", [[-0.14, 1.737],[-0.057, 1.735],[-0.024, 1.715],[-0.122, 1.709]], -0.236, 0.011, "e:dfc2ff")
	_plate(m, "head", [[0.047, 1.718],[0.126, 1.723],[0.134, 1.704]], -0.213, 0.013, "e:ba87ed")
	for side: float in [-1.0, 1.0]:
		var upper := _side("upper", side)
		var fore := _side("fore", side)
		_wrapped_limb(m, side, upper, 0.334, 1.438, 0.531, 1.085, 0.129, 0.088, OBSIDIAN)
		_gauntlet(m, side, OBSIDIAN, "m:655279", "5b4a73")
		var shoulder := side * 0.378
		_plate(m, upper, [[shoulder-side*0.167,1.382],[shoulder-side*0.097,1.512],[shoulder+side*0.168,1.525],[shoulder+side*0.131,1.351],[shoulder+side*0.085,1.212],[shoulder-side*0.081,1.306]], -0.112, 0.128, "m:504260")
		m.tube(fore, Vector3(side * 0.512, 1.08, -0.012), Vector3(side * 0.59, 0.915, -0.026), 0.072, 0.049, "413355", 6)
		for i in range(3):
			var x := side * (0.317 + i * 0.05)
			var y := 1.385 - i * 0.105
			_crystal(m, upper, Vector3(x, y, -0.132), Vector3(side * 0.12, 0.27 - i * 0.027, 0.003), 0.069 - i * 0.009, GLASS, "e:a689ce")
		for i in 3:
			var at := Vector3(side * 0.183, 0.26 + i * 0.081, -0.088)
			_crystal(m, _side("shin", side), at, Vector3(side * 0.053, 0.137, -0.005), 0.055, "m:453955", "e:8053b3")
		_plate(m, _side("foot", side), [[side * 0.18 - 0.107,0.077],[side * 0.18 + 0.093,0.053],[side * 0.18 + 0.071,0.127],[side * 0.18 - 0.022,0.145]], -0.232, 0.104, "m:4f4163")
		for i in range(3):
			var x := side * (0.075 + i * 0.105)
			var edge := 0.29 - i * 0.053
			_plate(m, "pelvis", [[x - 0.071, 0.955],[x + 0.075, 0.943],[x + side * 0.071, edge],[x - side * 0.097, edge + 0.212]], -0.113 - i * 0.028, 0.081, "403452" if i % 2 else OBSIDIAN)
		for fold in 3:
			var x := side * (0.10 + fold*0.088)
			_plate(m, "mantle", [[x-side*0.093,1.399],[x+side*0.124,1.437],[x+side*0.235,0.922],[x+side*0.286,0.621],[x+side*0.178,0.684],[x+side*0.160,0.196+fold*0.071],[x+side*0.053,0.242+fold*0.08],[x-side*0.014,0.702]], 0.221+fold*0.042, 0.075, "2d253d" if fold%2==0 else "3e3152")
			m.tube("mantle", Vector3(x+side*0.065,1.35,0.274+fold*0.042),
				Vector3(x+side*0.17,0.58-fold*0.10,0.278+fold*0.042),0.017,0.005,"4d3a66",5)
		_boot(m,side,"282435","m:554664","6a5280")
		for i in range(3):
			var angle := radians_for_shard(i)
			var point := Vector3(side * (0.39 + sin(angle) * 0.28), 1.26 + cos(angle) * 0.63, 0.279 + 0.03 * i)
			var vector := Vector3(side * sin(angle) * 0.26, cos(angle) * 0.44 + 0.031, 0.066 * (i - 1))
			_crystal(m, "ornament", point, vector, 0.094 + i * 0.012, GLASS if i == 0 else "p:62568a", "e:" + VIOLET)
			_crystal(m, "ornament", point + Vector3(side * 0.10, -0.079, 0.070), vector * 0.43, 0.031, "p:a296c1", "e:" + VIOLET)
	_crystal(m, "ornament", Vector3(0.093, 2.038, 0.28), Vector3(-0.10, 0.333, 0.047), 0.121, "p:a597c4", "e:c599fa")
	for i in range(3):
		_crystal(m, "hand_r", Vector3(0.57 + i * 0.061, 0.88 + i * 0.07, -0.13 - i * 0.025), Vector3(0.061 + i * 0.016, 0.12 + 0.02 * i, -0.04), 0.027, GLASS, "e:e1c6ff")


static func radians_for_shard(index: int) -> float:
	return 0.49 + index * 0.59


static func _side(bone: String, side: float) -> String:
	return bone + ("_l" if side < 0.0 else "_r")


static func _orb(m, joint: String, center: Vector3, radii: Vector3, color: String, glow: bool = false) -> void:
	m.ellipsoid(joint, center, radii * 2.0, ("e:" + color) if glow else color)


static func _plate(m, joint: String, xy: Array, z: float, depth: float, color: String) -> void:
	var points := PackedVector3Array()
	for point: Array in xy:
		points.append(Vector3(float(point[0]), float(point[1]), z))
	m.plate(joint, points, depth, color)


static func _path(m, joint: String, points: Array, start: float, end: float, color: String) -> void:
	for step in range(points.size() - 1):
		var tip := float(step + 1) / float(points.size() - 1)
		var base := float(step) / float(points.size() - 1)
		m.tube(joint, points[step], points[step + 1], lerpf(start, end, base), lerpf(start, end, tip), color, 7)


static func _candle(m, joint: String, start: Vector3, end: Vector3, radius: float) -> void:
	m.tube(joint, start, end, radius, radius * 0.88, WAX, 6)
	m.tube(joint, end - Vector3(radius * 0.75, 0.042, 0), end - Vector3(radius * 0.75, 0.009, 0), radius * 0.45, radius * 0.43, "b29a6d", 5)
	_orb(m, joint, end + Vector3.UP * radius * 1.17, Vector3(radius * 0.6, radius * 1.27, radius * 0.59), FLAME, true)


static func _crystal(m, joint: String, center: Vector3, length: Vector3, width: float, shell: String, edge: String) -> void:
	# The faces meet along a split ridge, with an off-center break near the heel.
	var axis := length.normalized()
	var across := axis.cross(Vector3.FORWARD).normalized() * width
	var front := across.normalized().cross(axis) * width
	var heel := center - length * 0.46 - across * 0.19
	var tip := center + length * 0.57 + across * 0.08
	var collar := PackedVector3Array([
		center + front * 0.61 + across * 0.18,
		center + across * 0.93,
		center - front * 0.46 + across * 0.30,
		center - front * 0.30 - across * 0.58,
		center - across * 0.92 + front * 0.19 + length * 0.11,
	])
	var faces := PackedVector3Array()
	for index in collar.size():
		var next := (index + 1) % collar.size()
		faces.append_array(PackedVector3Array([heel, collar[index], collar[next], tip, collar[next], collar[index]]))
	m.facets(joint, faces, shell)
	var ridge := collar[0] + front * 0.026
	m.tube(joint, heel, ridge, 0.001, width * 0.09, edge, 3)
	m.tube(joint, ridge, tip, width * 0.09, 0.001, edge, 3)


# Broad beveled sections build the major facial and torso planes.
static func _carved(m, joint: String, rings: Array, color: String) -> void:
	var sections: Array = []
	for ring: Array in rings:
		var radii: Vector2 = ring[1]
		sections.append([ring[0], radii.x, radii.y])
	m.loft(joint, sections, color, 10)


static func _wrapped_limb(m, side: float, joint: String, top_x: float, top_y: float, bottom_x: float, bottom_y: float, top_radius: float, bottom_radius: float, color: String) -> void:
	_carved(m, joint, [
		[Vector3(side*bottom_x,bottom_y,0.004),Vector2(bottom_radius,bottom_radius)],
		[Vector3(side*lerpf(bottom_x,top_x,0.33),lerpf(bottom_y,top_y,0.33),0.001),Vector2(lerpf(bottom_radius,top_radius,0.49),top_radius*0.77)],
		[Vector3(side*lerpf(bottom_x,top_x,0.7),lerpf(bottom_y,top_y,0.7),0.009),Vector2(top_radius,top_radius*0.82)],
		[Vector3(side*top_x,top_y,0.027),Vector2(top_radius*0.83,top_radius*0.69)],
	], color)


static func _gauntlet(m, side: float, leather: String, metal: String, seams: String) -> void:
	var arm := _side("fore", side)
	var palm := _side("hand", side)
	_wrapped_limb(m, side, arm, 0.515, 1.129, 0.598, 0.872, 0.104, 0.077, leather)
	_plate(m, arm, [[side*0.432,1.072],[side*0.559,1.155],[side*0.628,1.047],[side*0.647,0.896],[side*0.58,0.865],[side*0.503,0.94]], -0.077, 0.116, metal)
	for rivet in 3:
		var p := Vector3(side*(0.557 + rivet*0.017),1.064-rivet*0.055,-0.144)
		m.tube(arm,p,p+Vector3(0.011,0.016,-0.018),0.015,0.011,seams,5)
	_carved(m, palm, [
		[Vector3(side*0.627,0.742,-0.051),Vector2(0.04,0.054)],
		[Vector3(side*0.607,0.781,-0.056),Vector2(0.070,0.067)],
		[Vector3(side*0.609,0.851,-0.031),Vector2(0.065,0.061)],
		[Vector3(side*0.601,0.892,-0.022),Vector2(0.049,0.052)],
	], leather)
	for finger in 4:
		var x := side*(0.563 + finger*0.031)
		var knuckle := Vector3(x,0.817-absf(finger-1.4)*0.009,-0.111)
		m.tube(palm,knuckle,knuckle+Vector3(side*0.004,-0.047,-0.012),0.014,0.008,seams,5)
	m.tube(palm,Vector3(side*0.551,0.837,-0.057),Vector3(side*0.549,0.783,-0.087),0.021,0.012,leather,6)


static func _boot(m, side: float, leather: String, trim: String, welt: String) -> void:
	var x := side*0.182
	var foot := _side("foot",side)
	_carved(m, foot, [
		[Vector3(x,0.024,-0.104),Vector2(0.111,0.224)],
		[Vector3(x,0.061,-0.111),Vector2(0.112,0.222)],
		[Vector3(x,0.113,-0.105),Vector2(0.107,0.206)],
		[Vector3(x,0.171,-0.052),Vector2(0.092,0.137)],
		[Vector3(x,0.245,-0.012),Vector2(0.076,0.087)],
	], leather)
	_plate(m,foot,[[x-0.093,0.04],[x+0.084,0.043],[x+0.09,0.101],[x+0.043,0.143],[x-0.053,0.137],[x-0.097,0.100]],-0.282,0.097,trim)
	for strap in 3:
		var p := Vector3(x-0.085,0.129+strap*0.021,-0.231+strap*0.031)
		m.tube(foot,p,p+Vector3(0.166,-0.008,0.017),0.014,0.011,welt,6)
