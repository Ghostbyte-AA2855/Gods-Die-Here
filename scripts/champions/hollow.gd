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
const GLASS := "m:675386"
const VIOLET := "c1a1ff"


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
	_orb(m, "spine", Vector3(0, 1.18, 0.03), Vector3(0.36, 0.48, 0.205), "242024")
	_orb(m, "head", Vector3(0, 1.67, 0.018), Vector3(0.24, 0.285, 0.205), SOOT)
	_plate(m, "head", [[-0.20, 1.71],[-0.13, 1.88],[0.04, 1.99],[0.21, 1.79],[0.20, 1.60],[0.09, 1.49],[-0.14, 1.54]], -0.154, 0.11, "2d2329")
	_plate(m, "head", [[-0.145, 1.70],[-0.08, 1.77],[0.06, 1.79],[0.15, 1.71],[0.08, 1.55],[-0.07, 1.55]], -0.228, 0.023, SOOT)
	for side: float in [-1.0, 1.0]:
		m.tube("head", Vector3(side * 0.150, 1.72, -0.265), Vector3(side * 0.085, 1.824, -0.254), 0.014, 0.008, RELIQUARY)
		_orb(m, "head", Vector3(side * 0.062, 1.684, -0.254), Vector3(0.034, 0.013, 0.017), FLAME, true)
		var upper := _side("upper", side)
		var fore := _side("fore", side)
		_orb(m, upper, Vector3(side * 0.379, 1.25, 0.04), Vector3(0.183, 0.259, 0.14), "232025")
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
		var boot := _side("foot", side)
		_orb(m, boot, Vector3(side * 0.182, 0.104, -0.111), Vector3(0.111, 0.087, 0.206), "211c23")
		_plate(m, boot, [[side * 0.18 - 0.092,0.090],[side * 0.18 + 0.083,0.080],[side * 0.18 + 0.067,0.144],[side * 0.18 - 0.068,0.145]], -0.271, 0.04, RELIQUARY)
		m.tube(_side("shin", side), Vector3(side * 0.18, 0.255, -0.015), Vector3(side * 0.18, 0.373, 0), 0.075, 0.098, "392a2c", 7)
		for i in range(3):
			var candle := Vector3(side * (0.211 + i * 0.077), 1.62 - 0.044 * i, 0.141 + i * 0.011)
			var end := candle + Vector3(side * 0.022, 0.123 + (i % 2) * 0.040, 0)
			_candle(m, "mantle", candle, end, 0.022)
			m.tube("mantle", candle - Vector3.UP * 0.034, candle, 0.042, 0.033, RELIQUARY, 6)
	for section in range(5):
		var x := -0.28 + section * 0.14
		var bottom: float = 0.19 + [0.11, 0.027, 0.0, 0.064, 0.18][section]
		_plate(m, "pelvis", [[x - 0.07, 0.94],[x + 0.08, 0.95],[x + 0.14, bottom + 0.09],[x + 0.05, bottom],[x - 0.08, bottom + 0.06]], -0.124 - absf(x) * 0.08, 0.19, "29252a" if section % 2 else SOOT)
		m.tube("pelvis", Vector3(x, 0.90, -0.228), Vector3(x + 0.01, bottom + 0.11, -0.228), 0.011, 0.006, "46403b", 5)
	m.box("pelvis", Vector3(0, 0.936, -0.234), Vector3(0.22, 0.114, 0.04), RELIQUARY)
	m.tube("spine", Vector3(-0.24, 1.40, -0.176), Vector3(0.21, 0.955, -0.233), 0.051, 0.042, "432b25", 5)
	for i in range(4):
		_orb(m, "spine", Vector3(-0.17 + i * 0.081, 1.32 - i * 0.075, -0.25), Vector3(0.025, 0.025, 0.012), RELIQUARY)
	_ossa_lantern(m)


static func _ossa_lantern(m) -> void:
	var handle := Vector3(0.60, 0.866, -0.035)
	var staff_top := handle + Vector3(0.01, 0.82, -0.04)
	m.tube("hand_r", handle - Vector3.UP * 0.62, staff_top, 0.033, 0.023, "353235", 8)
	for i in range(5):
		var y := handle.y - 0.105 + 0.044 * i
		m.tube("hand_r", Vector3(handle.x, y, handle.z), Vector3(handle.x, y + 0.027, handle.z), 0.042, 0.042, RELIQUARY, 8)
	var arch := [staff_top, staff_top + Vector3(0.10, 0.16, -0.02), staff_top + Vector3(0.27, 0.16, -0.03), staff_top + Vector3(0.35, 0.065, -0.033), staff_top + Vector3(0.30, -0.034, -0.035)]
	_path(m, "hand_r", arch, 0.026, 0.016, RELIQUARY)
	var crown: Vector3 = arch[-1] - Vector3.UP * 0.019
	var deck := crown - Vector3.UP * 0.32
	m.tube("hand_r", deck - Vector3.UP * 0.038, deck, 0.104, 0.139, RELIQUARY, 6)
	m.tube("hand_r", crown - Vector3.UP * 0.096, crown, 0.132, 0.048, RELIQUARY, 6)
	for i in 6:
		var a := i * TAU / 6.0
		var outward := Vector3(cos(a), 0, sin(a))
		m.tube("hand_r", deck + outward * 0.124, crown + outward * 0.087 - Vector3.UP * 0.057, 0.015, 0.009, "9b6440", 6)
	_candle(m, "hand_r", deck + Vector3.UP * 0.015, deck + Vector3.UP * 0.137, 0.045)
	_orb(m, "hand_r", deck + Vector3.UP * 0.185, Vector3(0.054, 0.087, 0.051), "e3893e", true)


static func _renn(m) -> void:
	_orb(m, "spine", Vector3(0, 1.206, 0.026), Vector3(0.349, 0.374, 0.206), "312f2b")
	_orb(m, "head", Vector3(0, 1.66, 0.03), Vector3(0.207, 0.240, 0.190), "2c2e25")
	_plate(m, "head", [[-0.16, 1.83],[-0.063, 1.862],[0.126, 1.80],[0.152, 1.677],[0.045, 1.548],[-0.076, 1.57],[-0.15, 1.69]], -0.181, 0.055, HORN)
	_plate(m, "head", [[-0.142, 1.743],[-0.049, 1.749],[-0.014, 1.696],[-0.139, 1.691]], -0.216, 0.01, "222922")
	_plate(m, "head", [[0.034, 1.706],[0.057, 1.752],[0.128, 1.725],[0.120, 1.682]], -0.218, 0.011, "222922")
	_orb(m, "head", Vector3(0.091, 1.71, -0.229), Vector3(0.030, 0.011, 0.013), "b7da80", true)
	_orb(m, "head", Vector3(-0.074, 1.714, -0.228), Vector3(0.027, 0.012, 0.013), "b0c75e", true)
	_plate(m, "head", [[-0.012, 1.736],[0.041, 1.665],[0.003, 1.59],[-0.031, 1.658]], -0.224, 0.026, "beab83")
	for side: float in [-1.0, 1.0]:
		var fork := [Vector3(side * 0.132, 1.795, 0.056), Vector3(side * 0.250, 1.879, 0.102), Vector3(side * 0.320, 2.068, 0.129), Vector3(side * 0.395, 2.21, 0.178), Vector3(side * 0.432, 2.32, 0.115)]
		_path(m, "head", fork, 0.055, 0.009, HORN)
		_path(m, "head", [fork[1], Vector3(side * 0.415, 1.958, 0.093), Vector3(side * 0.518, 2.064, 0.038)], 0.041, 0.007, "887a58")
		_path(m, "head", [fork[2], Vector3(side * 0.259, 2.169, 0.103), Vector3(side * 0.217, 2.234, 0.037)], 0.030, 0.006, HORN)
		_path(m, "head", [fork[2], Vector3(side * 0.424, 2.103, 0.166), Vector3(side * 0.506, 2.182, 0.216)], 0.031, 0.007, HORN)
		_orb(m, _side("upper", side), Vector3(side * 0.344, 1.308, 0.021), Vector3(0.165, 0.215, 0.141), RAW_HIDE)
		m.tube(_side("fore", side), Vector3(side * 0.427, 1.118, -0.068), Vector3(side * 0.483, 0.932, -0.127), 0.091, 0.069, "322b21")
		for lace in range(4):
			var base := Vector3(side * 0.46, 0.957 + lace * 0.042, -0.128)
			m.tube(_side("fore", side), base, base + Vector3(side * 0.009, 0.021, 0.008), 0.084, 0.079, "48372a", 7)
		for i in 3:
			var lashing := Vector3(side * 0.18, 0.264 + i * 0.052, -0.003)
			m.tube(_side("shin", side), lashing, lashing + Vector3.UP * 0.026, 0.074 + i * 0.008, 0.078 + i * 0.008, "6b5139", 7)
			m.tube(_side("shin", side), lashing + Vector3(-0.055, -0.008, -0.064), lashing + Vector3(0.059, 0.034, -0.065), 0.010, 0.007, HORN, 5)
		_orb(m, _side("foot", side), Vector3(side * 0.182, 0.106, -0.122), Vector3(0.108, 0.073, 0.204), "423326")
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
	var quiver := Vector3(-0.26, 1.128, 0.273)
	m.tube("spine", quiver, quiver + Vector3(0.362, 0.45, 0.054), 0.102, 0.115, "422d29", 8)
	m.tube("spine", quiver + Vector3(0.32, 0.405, 0.044), quiver + Vector3(0.369, 0.464, 0.054), 0.124, 0.125, RELIQUARY, 8)
	for i in range(4):
		var arrow := quiver + Vector3(0.349 + 0.034 * i, 0.45, 0.032 + 0.017 * i)
		var tail := arrow + Vector3(0.129 + 0.016 * i, 0.178 + 0.021 * i, 0.031)
		m.tube("spine", arrow, tail, 0.011, 0.007, "a58f5c", 6)
		m.tube("spine", tail - Vector3(0.045, 0.042, 0.018), tail - Vector3(0.007, 0, 0.032), 0.026, 0.002, MOSS, 4)


static func _renn_bow(m) -> void:
	var grip := Vector3(-0.60, 0.87, -0.035)
	var core := [grip + Vector3(-0.08,-0.86,0.065), grip + Vector3(-0.20,-0.68,-0.06), grip + Vector3(-0.183,-0.44,-0.108), grip + Vector3(-0.06,-0.21,-0.065), grip, grip + Vector3(-0.06,0.22,-0.065), grip + Vector3(-0.183,0.45,-0.108), grip + Vector3(-0.20,0.70,-0.06), grip + Vector3(-0.08,0.88,0.065)]
	_path(m, "hand_l", core, 0.052, 0.042, ROOT_BARK)
	var laminate := []
	for point: Vector3 in core:
		laminate.append(point + Vector3(-0.018, 0.0, -0.027))
	_path(m, "hand_l", laminate, 0.020, 0.016, HORN)
	for tip: Vector3 in [core[0], core[-1]]:
		m.tube("hand_l", tip, tip + Vector3(0.083, 0.019 if tip.y > 1.0 else -0.019, -0.047), 0.048, 0.007, "7f8066", 6)
	for i in range(6):
		var y := grip.y - 0.118 + 0.042 * i
		m.tube("hand_l", Vector3(grip.x, y, grip.z), Vector3(grip.x, y + 0.021, grip.z), 0.063, 0.063, "242722", 8)
	m.tube("hand_l", core[0], core[-1], 0.007, 0.007, "d5bb81", 5)


static func _avar(m) -> void:
	_orb(m, "spine", Vector3(0, 1.195, 0.035), Vector3(0.285, 0.335, 0.146), "1b2d2c")
	_plate(m, "spine", [[-0.05, 1.047],[-0.064, 1.419],[0.0, 1.52],[0.065, 1.415],[0.053, 1.055]], -0.178, 0.036, DROWNED_BONE)
	_orb(m, "head", Vector3(0, 1.711, 0.018), Vector3(0.185, 0.221, 0.176), DROWNED_BONE)
	_plate(m, "head", [[-0.113, 1.703],[-0.091, 1.565],[-0.058, 1.516],[0.063, 1.516],[0.105, 1.561],[0.124, 1.687],[0.065, 1.613],[-0.057, 1.613]], -0.145, 0.067, "c1bd95")
	_plate(m, "head", [[-0.034, 1.70],[0.020, 1.72],[0.032, 1.656],[-0.029, 1.64]], -0.166, 0.031, "272d27")
	for i in range(6):
		var x := -0.069 + 0.029 * i
		m.tube("head", Vector3(x, 1.625, -0.174), Vector3(x + 0.002, 1.582 + 0.005 * (i % 2), -0.171), 0.015, 0.009, "c3bc92", 5)
	for side: float in [-1.0, 1.0]:
		_orb(m, "head", Vector3(side * 0.076, 1.738, -0.146), Vector3(0.059, 0.034, 0.023), "252c26")
		_orb(m, "head", Vector3(side * 0.075, 1.736, -0.171), Vector3(0.022, 0.012, 0.010), SALT, true)
		m.tube("head", Vector3(side * 0.113, 1.82, -0.114), Vector3(side * 0.152, 1.95, -0.067), 0.026, 0.005, SCUM)
		for rib in range(6):
			var y := 1.405 - rib * 0.053
			var turn := side * (0.252 - 0.012 * rib)
			var from_back := [Vector3(0.044 * side, y + 0.054, 0.106), Vector3(turn, y + 0.041, 0.08), Vector3(turn, y - 0.022, -0.127), Vector3(0.092 * side, y - 0.050, -0.183), Vector3(0.023 * side, y - 0.043, -0.186)]
			_path(m, "spine", from_back, 0.022, 0.012, DROWNED_BONE if rib % 2 == 0 else "8f9b82")
		var upper := _side("upper", side)
		m.tube(upper, Vector3(0.35 * side, 1.363, 0.04), Vector3(0.503 * side, 1.101, -0.016), 0.105, 0.045, TIDE)
		m.tube(_side("fore", side), Vector3(0.502 * side, 1.08, -0.03), Vector3(0.591 * side, 0.901, -0.04), 0.079, 0.04, "637a6c")
		for i in range(4):
			var x := side * (0.27 + i * 0.044)
			m.tube(upper, Vector3(x, 1.304 + i * 0.025, 0.076), Vector3(x + side * 0.088, 1.532 + i * 0.034, 0.145), 0.065 - i * 0.008, 0.002, SCUM, 5)
		var shin := _side("shin", side)
		m.tube(shin, Vector3(side * 0.18, 0.431, -0.068), Vector3(side * 0.194, 0.22, -0.075), 0.073, 0.037, DROWNED_BONE, 6)
		for bead in 3:
			var point := Vector3(side * (0.17 + bead * 0.025), 0.28 - bead * 0.022, -0.121 + bead * 0.016)
			m.tube(shin, point, point + Vector3(side * 0.026, 0.036, -0.026), 0.023, 0.013, "91a381", 6)
		_orb(m, _side("foot", side), Vector3(side * 0.181, 0.107, -0.117), Vector3(0.108, 0.076, 0.186), "31473f")
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
	var collar := Vector3(0.66, 1.69, -0.048)
	var crown := collar + Vector3(0.024, 0.19, -0.016)
	m.tube("hand_r", grip - Vector3.UP * 0.74, collar, 0.039, 0.030, "m:646749", 8)
	for i in range(5):
		var loop := grip + Vector3(0, -0.085 + i * 0.046, 0)
		m.tube("hand_r", loop, loop + Vector3.UP * 0.025, 0.047, 0.040, "68533b", 8)
	for i in range(3):
		var ring := collar + Vector3.UP * (0.037 * i)
		m.tube("hand_r", ring, ring + Vector3.UP * 0.028, 0.066 - i * 0.008, 0.068 - i * 0.008, "m:8f784b", 7)
	for side: float in [-1.0, 1.0]:
		var arm := [collar, collar + Vector3(side * 0.168, 0.098, 0), crown + Vector3(side * 0.215, 0.038, -0.014), crown + Vector3(side * 0.232, 0.273, -0.02)]
		_path(m, "hand_r", arm, 0.037, 0.008, "m:8c956e")
		m.tube("hand_r", arm[2], arm[2] + Vector3(side * 0.09, 0.123, -0.009), 0.024, 0.001, SCUM, 5)
	m.tube("hand_r", crown - Vector3.UP * 0.134, crown + Vector3(0, 0.43, -0.025), 0.041, 0.001, "m:b4b189", 5)
	m.tube("hand_r", crown + Vector3(0, 0.124, -0.054), crown + Vector3(0, 0.38, -0.061), 0.012, 0.001, "e:" + SALT, 5)
	for i in range(4):
		var link := collar - Vector3(0.038 + (i % 2) * 0.022, 0.13 + i * 0.101, 0.045)
		m.band("hand_r", link, 0.044, 0.005, "m:86784e", 0.0, TAU, Vector3(0, (i % 2) * 0.72, 0.25))
		m.tube("hand_r", link - Vector3(0,0,0.013), link - Vector3(0,0,0.031), 0.031, 0.031, "m:ab8b58", 8)


static func _vellis(m) -> void:
	_orb(m, "spine", Vector3(0, 1.18, 0.022), Vector3(0.268, 0.331, 0.173), "2b2440")
	_plate(m, "spine", [[-0.318, 1.40],[-0.15, 1.486],[-0.012, 1.29],[-0.027, 1.068],[-0.183, 0.964],[-0.25, 1.18]], -0.174, 0.073, "332a48")
	_plate(m, "spine", [[0.015, 1.291],[0.176, 1.433],[0.312, 1.376],[0.232, 1.113],[0.061, 0.951]], -0.194, 0.084, GLASS)
	_plate(m, "spine", [[-0.032, 1.26],[0.084, 1.377],[0.129, 1.328],[0.041, 1.17],[-0.003, 1.11]], -0.259, 0.017, "e:986bc9")
	_orb(m, "head", Vector3(0, 1.69, 0.034), Vector3(0.198, 0.241, 0.164), OBSIDIAN)
	_plate(m, "head", [[-0.177, 1.766],[-0.093, 1.891],[-0.031, 1.867],[0.028, 1.702],[-0.024, 1.57],[-0.123, 1.601]], -0.17, 0.074, "m:78609d")
	_plate(m, "head", [[-0.032, 1.88],[0.101, 1.849],[0.169, 1.745],[0.10, 1.738],[0.044, 1.705]], -0.143, 0.062, "4c3c68")
	_plate(m, "head", [[0.056, 1.718],[0.166, 1.744],[0.14, 1.625],[0.043, 1.571],[0.011, 1.618]], -0.151, 0.071, OBSIDIAN)
	_path(m, "head", [Vector3(-0.042,1.867,-0.208), Vector3(0.002,1.755,-0.229), Vector3(-0.023,1.72,-0.237), Vector3(0.016,1.655,-0.234), Vector3(-0.025,1.587,-0.206)], 0.012, 0.006, "e:" + VIOLET)
	_plate(m, "head", [[-0.14, 1.737],[-0.057, 1.735],[-0.024, 1.715],[-0.122, 1.709]], -0.236, 0.011, "e:dfc2ff")
	_plate(m, "head", [[0.047, 1.718],[0.126, 1.723],[0.134, 1.704]], -0.213, 0.013, "e:ba87ed")
	for side: float in [-1.0, 1.0]:
		var upper := _side("upper", side)
		var fore := _side("fore", side)
		m.tube(upper, Vector3(side * 0.34, 1.36, 0.03), Vector3(side * 0.511, 1.09, -0.017), 0.125, 0.066, OBSIDIAN, 7)
		m.tube(fore, Vector3(side * 0.512, 1.08, -0.012), Vector3(side * 0.59, 0.915, -0.026), 0.072, 0.049, "413355", 6)
		for i in range(3):
			var x := side * (0.317 + i * 0.05)
			var y := 1.385 - i * 0.105
			_crystal(m, upper, Vector3(x, y, -0.132), Vector3(side * 0.12, 0.27 - i * 0.027, 0.003), 0.069 - i * 0.009, "m:5f4d7d", "e:9871cf")
		for i in 3:
			var at := Vector3(side * 0.183, 0.26 + i * 0.081, -0.088)
			_crystal(m, _side("shin", side), at, Vector3(side * 0.053, 0.137, -0.005), 0.055, "m:453955", "e:8053b3")
		_plate(m, _side("foot", side), [[side * 0.18 - 0.107,0.077],[side * 0.18 + 0.093,0.053],[side * 0.18 + 0.071,0.127],[side * 0.18 - 0.022,0.145]], -0.232, 0.104, "m:4f4163")
		for i in range(3):
			var x := side * (0.075 + i * 0.105)
			var edge := 0.39 - i * 0.064
			_plate(m, "pelvis", [[x - 0.071, 0.955],[x + 0.075, 0.943],[x + side * 0.071, edge],[x - side * 0.097, edge + 0.212]], -0.113 - i * 0.028, 0.081, "403452" if i % 2 else OBSIDIAN)
		for i in range(3):
			var angle := radians_for_shard(i)
			var point := Vector3(side * (0.39 + sin(angle) * 0.28), 1.26 + cos(angle) * 0.63, 0.279 + 0.03 * i)
			var vector := Vector3(side * sin(angle) * 0.20, cos(angle) * 0.35 + 0.032, 0.042)
			_crystal(m, "ornament", point, vector, 0.075 + i * 0.015, GLASS if i == 0 else "m:4b3a70", "e:" + VIOLET)
	_crystal(m, "ornament", Vector3(0.093, 2.038, 0.28), Vector3(-0.10, 0.312, 0.047), 0.103, "m:8270a0", "e:c599fa")
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
	m.tube(joint, center - length * 0.44, center, 0.002, width * 0.83, shell, 4)
	m.tube(joint, center, center + length * 0.56, width * 0.83, 0.001, shell, 4)
	var ridge := Vector3(0, 0, -width * 0.60)
	m.tube(joint, center - length * 0.48, center + ridge, 0.002, width * 0.12, edge, 3)
	m.tube(joint, center + ridge, center + length * 0.56, width * 0.12, 0.001, edge, 3)
