extends RefCounted

# Pilgrims of the crypt and things the crypt could no longer hold.
const MOURNING := "271e34"
const VELVET := "493a64"
const SEAM := "796a97"
const IVORY := "cfc2ad"
const MOON := "c6bcfc"
const TIN := "756d7a"

const SACKCLOTH := "2f292f"
const RUSTED := "663a32"
const GAOL_IRON := "45434c"
const ABRADED := "99929a"
const SCAR := "9b6b60"
const ASH := "3a3c45"

const LEATHER := "22242b"
const INSULATION := "393c43"
const COPPER := "bc7344"
const OXIDE := "568781"
const CERAMIC := "ded0a4"
const ARC := "fada81"

const CHITIN := "382536"
const UNDERSHELL := "653b56"
const VELUM := "7e4d70"
const LINING := "ae729e"
const EYE := "f797d1"
const FANG := "a8ad88"


static func build(model, class_id: String) -> void:
	match class_id:
		"dream_shepherd": _mara(model)
		"chainrunner": _tavren(model)
		"coilwright": _iskra(model)
		"duskmoth": _nim(model)


static func _mara(m) -> void:
	# A waxed mourning habit, suspended cemetery bells and a captured cold moon.
	_xy(m, "spine", -0.21, 0.13, MOURNING, [
		Vector2(-0.30, 1.37), Vector2(-0.16, 1.52), Vector2(0.17, 1.52),
		Vector2(0.30, 1.30), Vector2(0.14, 0.89), Vector2(-0.16, 0.91)])
	_xy(m, "spine", -0.29, 0.018, VELVET, [
		Vector2(-0.27, 1.38), Vector2(0.27, 1.38), Vector2(0.15, 1.16),
		Vector2(0.0, 1.08), Vector2(-0.15, 1.16)])
	for side in [-1.0, 1.0]:
		var side_name := _side(side)
		var shoulder := Vector3(0.34 * side, 1.34, 0.01)
		m.ellipsoid("upper_" + side_name, shoulder, Vector3(0.35, 0.26, 0.42), MOURNING)
		m.tube("fore_" + side_name, Vector3(0.54 * side, 1.10, -0.015),
			Vector3(0.60 * side, 0.89, -0.04), 0.116, 0.082, VELVET, 9)
		m.band("fore_" + side_name, Vector3(0.585 * side, 0.94, -0.04),
			0.091, 0.010, "m:" + TIN, 0.0, TAU, Vector3(PI * 0.5, 0, 0))
		_xy(m, "head", -0.10, 0.15, MOURNING, [
			Vector2(side * 0.13, 1.90), Vector2(side * 0.24, 1.82),
			Vector2(side * 0.28, 1.54), Vector2(side * 0.12, 1.48),
			Vector2(side * 0.115, 1.63)])
		m.tube("head", Vector3(side * 0.112, 1.89, -0.198),
			Vector3(side * 0.22, 1.57, -0.192), 0.016, 0.006, SEAM, 6)
		# Clerical skirt panels are bound to each hip/thigh instead of welded below the waist.
		m.plate("thigh_" + side_name, PackedVector3Array([
			Vector3(side * 0.11, 0.89, -0.24), Vector3(side * 0.27, 0.88, -0.18),
			Vector3(side * 0.40, 0.30, -0.14), Vector3(side * 0.25, 0.20, -0.24),
			Vector3(side * 0.10, 0.37, -0.29)]), 0.038, VELVET)
		m.tube("thigh_" + side_name, Vector3(side * 0.23, 0.83, -0.24),
			Vector3(side * 0.35, 0.33, -0.18), 0.009, 0.007, SEAM, 5)
		m.plate("mantle", PackedVector3Array([
			Vector3(0.0, 1.44, 0.19), Vector3(side * 0.29, 1.43, 0.15),
			Vector3(side * 0.44, 0.89, 0.25), Vector3(side * 0.30, 0.23, 0.39),
			Vector3(side * 0.09, 0.32, 0.49), Vector3(0.0, 0.93, 0.31)]), 0.044, MOURNING)
		m.tube("mantle", Vector3(side * 0.12, 1.39, 0.25),
			Vector3(side * 0.23, 0.39, 0.43), 0.017, 0.006, SEAM, 6)
		for i in range(3):
			var x: float = side * (0.09 + 0.069 * i)
			var y := 1.11 + i * 0.045
			m.tube("spine", Vector3(x, y + 0.09, -0.29), Vector3(x, y, -0.31), 0.009, 0.009, "m:" + TIN, 6)
			m.tube("spine", Vector3(x, y, -0.32), Vector3(x, y - 0.052, -0.32), 0.016, 0.029, "m:" + TIN, 8)
	_xy(m, "head", -0.205, 0.08, MOURNING, [
		Vector2(-0.17, 1.8), Vector2(-0.13, 1.92), Vector2(0.10, 1.94),
		Vector2(0.165, 1.82), Vector2(0.14, 1.62), Vector2(0.0, 1.52), Vector2(-0.14, 1.63)])
	_xy(m, "head", -0.253, 0.018, VELVET, [
		Vector2(-0.14, 1.78), Vector2(0.14, 1.78), Vector2(0.108, 1.62),
		Vector2(0.018, 1.56), Vector2(-0.07, 1.59)])
	m.tube("head", Vector3(-0.125, 1.762, -0.269),
		Vector3(0.119, 1.762, -0.269), 0.006, 0.004, "e:" + MOON, 6)
	for i in range(4):
		var y := 1.72 - i * 0.036
		var width := 0.106 - i * 0.018
		m.tube("head", Vector3(-width, y, -0.274), Vector3(width, y - 0.008, -0.274), 0.008, 0.007, SEAM, 6)
	m.ellipsoid("spine", Vector3(0.0, 1.32, -0.324), Vector3(0.14, 0.17, 0.06), "m:" + TIN)
	m.band("spine", Vector3(0, 1.32, -0.363), 0.052, 0.008, "e:" + MOON, 0.1, PI * 1.65)
	var base := Vector3(0.64, 0.14, -0.10)
	var grip := Vector3(0.61, 0.88, -0.08)
	var crown := Vector3(0.69, 1.78, -0.21)
	m.tube("hand_r", base, grip, 0.028, 0.048, MOURNING, 9)
	m.tube("hand_r", grip, crown - Vector3(0.0, 0.30, 0.0), 0.050, 0.034, "m:" + TIN, 10)
	m.tube("hand_r", base, base + Vector3.UP * 0.17, 0.02, 0.039, "m:" + TIN, 8)
	m.band("hand_r", crown, 0.253, 0.033, "m:" + TIN, 0.55, PI * 1.7)
	m.band("hand_r", crown + Vector3(0.068, 0.033, -0.02), 0.197, 0.021, "m:" + IVORY, 0.48, PI * 1.46)
	m.band("hand_r", crown, 0.228, 0.015, "m:" + TIN, 0.0, TAU, Vector3(0.0, PI * 0.5, 0.0))
	m.ellipsoid("hand_r", crown, Vector3(0.195, 0.216, 0.185), "e:" + MOON)
	for angle in [-1.72, -0.86, 0.18, 0.9, 1.7]:
		var radial := Vector3(cos(angle), sin(angle), 0.0)
		m.tube("hand_r", crown + radial * 0.25,
			crown + radial * 0.296, 0.013, 0.003, "m:" + IVORY, 6)


static func _tavren(m) -> void:
	# An escaped prisoner's silhouette: bare seam on one side, welded gaol iron on the other.
	_xy(m, "spine", -0.17, 0.14, SACKCLOTH, [
		Vector2(-0.29, 1.32), Vector2(0.24, 1.45), Vector2(0.32, 1.22),
		Vector2(0.20, 0.91), Vector2(-0.22, 0.91)])
	_xy(m, "spine", -0.24, 0.04, "m:" + GAOL_IRON, [
		Vector2(-0.27, 1.29), Vector2(-0.10, 1.46), Vector2(0.12, 1.38),
		Vector2(0.07, 1.15), Vector2(-0.12, 1.08), Vector2(-0.28, 1.13)])
	_xy(m, "spine", -0.27, 0.022, "m:" + RUSTED, [
		Vector2(-0.21, 1.23), Vector2(-0.13, 1.34), Vector2(-0.015, 1.31),
		Vector2(-0.08, 1.20), Vector2(-0.20, 1.14)])
	m.tube("spine", Vector3(-0.27, 1.40, -0.16), Vector3(0.22, 0.90, -0.24), 0.041, 0.048, RUSTED, 6)
	m.tube("spine", Vector3(0.26, 1.32, 0.18), Vector3(-0.24, 0.98, 0.19), 0.037, 0.044, RUSTED, 6)
	for point in [Vector3(-0.30, 1.37, -0.12), Vector3(-0.26, 1.19, -0.272),
		Vector3(-0.13, 1.11, -0.25), Vector3(-0.06, 1.32, -0.29), Vector3(0.06, 1.36, -0.27)]:
		m.ellipsoid("spine", point, Vector3(0.048, 0.051, 0.047), "m:" + ABRADED)
	m.ellipsoid("upper_l", Vector3(-0.35, 1.37, 0.012), Vector3(0.34, 0.29, 0.39), "m:" + GAOL_IRON)
	for i in range(3):
		var x := -0.34 - i * 0.05
		var y := 1.49 - i * 0.062
		m.tube("upper_l", Vector3(x, y, 0.03),
			Vector3(x - 0.15, y + 0.11 + i * 0.035, 0.025), 0.07, 0.012, "m:" + RUSTED, 5)
	m.ellipsoid("upper_r", Vector3(0.37, 1.30, 0.0), Vector3(0.234, 0.31, 0.25), SCAR)
	for i in range(3):
		var y := 1.34 - i * 0.074
		m.tube("upper_r", Vector3(0.33, y, -0.107), Vector3(0.45, y - 0.027, -0.113), 0.011, 0.009, RUSTED, 5)

	_xy(m, "head", -0.144, 0.11, "m:" + GAOL_IRON, [
		Vector2(-0.15, 1.86), Vector2(-0.035, 1.91), Vector2(0.02, 1.78),
		Vector2(0.018, 1.63), Vector2(-0.08, 1.57), Vector2(-0.151, 1.60)])
	_xy(m, "head", -0.213, 0.04, "m:" + RUSTED, [
		Vector2(-0.15, 1.69), Vector2(-0.08, 1.69), Vector2(0.12, 1.66),
		Vector2(0.126, 1.61), Vector2(-0.06, 1.56), Vector2(-0.15, 1.61)])
	m.tube("head", Vector3(-0.13, 1.78, -0.208), Vector3(-0.035, 1.77, -0.215),
		0.012, 0.01, "e:" + ABRADED, 6)
	m.tube("head", Vector3(0.058, 1.86, -0.112), Vector3(0.126, 1.74, -0.161),
		0.013, 0.016, RUSTED, 5)
	for side in [-1.0, 1.0]:
		var name := _side(side)
		var wrist := Vector3(0.59 * side, 0.92, -0.021)
		m.tube("fore_" + name, wrist + Vector3.UP * 0.116, wrist - Vector3.UP * 0.058,
			0.104, 0.115, "m:" + GAOL_IRON, 10)
		for y in [-0.06, 0.07]:
			m.band("fore_" + name, wrist + Vector3.UP * y, 0.116, 0.017,
				"m:" + RUSTED, 0.05, TAU, Vector3(PI * 0.5, 0, 0))
		m.box("fore_" + name, wrist + Vector3(0.094 * side, 0.0, -0.055),
			Vector3(0.090, 0.12, 0.079), "m:" + RUSTED, Vector3(0.17, side * 0.30, side * 0.21))
		for i in range(3):
			var ring := wrist + Vector3((0.08 + i * 0.064) * side, -0.13 - i * 0.073, 0.025 * i)
			m.band("hand_" + name, ring, 0.065, 0.014, "m:" + GAOL_IRON, 0.0,
				TAU if i < 2 else PI * 1.55, Vector3(i * PI * 0.48, i * 0.20, side * 0.27))
		m.tube("shin_" + name, Vector3(0.185 * side, 0.46, -0.014), Vector3(0.182 * side, 0.19, -0.035),
			0.115, 0.088, ASH, 7)
		m.box("foot_" + name, Vector3(0.185 * side, 0.098, -0.104),
			Vector3(0.19, 0.163, 0.36), "m:" + GAOL_IRON, Vector3(0.0, side * 0.08, 0.0))
	var blade_z := -0.11
	m.tube("hand_r", Vector3(0.64, 1.015, blade_z), Vector3(0.79, 0.51, blade_z),
		0.055, 0.047, SACKCLOTH, 9)
	for i in range(5):
		var y := 0.95 - i * 0.072
		m.band("hand_r", Vector3(0.655 + i * 0.027, y, blade_z), 0.052, 0.011,
			"m:" + RUSTED, 0.0, TAU, Vector3(PI * 0.5, 0, 0.30))
	_xy(m, "hand_r", blade_z, 0.086, "m:" + GAOL_IRON, [
		Vector2(0.73, 0.56), Vector2(0.78, 0.29), Vector2(0.96, 0.125),
		Vector2(1.17, 0.15), Vector2(1.28, 0.28), Vector2(1.26, 0.47),
		Vector2(1.13, 0.57), Vector2(1.18, 0.37), Vector2(1.09, 0.27),
		Vector2(0.98, 0.27), Vector2(0.86, 0.50)])
	_xy(m, "hand_r", blade_z - 0.043, 0.009, "m:" + ABRADED, [
		Vector2(0.91, 0.19), Vector2(1.11, 0.166), Vector2(1.247, 0.277),
		Vector2(1.229, 0.437), Vector2(1.13, 0.57), Vector2(1.19, 0.349), Vector2(1.078, 0.235)])
	m.ellipsoid("hand_r", Vector3(0.815, 0.435, blade_z - 0.053),
		Vector3(0.084, 0.081, 0.039), "m:" + RUSTED)


static func _iskra(m) -> void:
	# The buried storm lives in a copper spine wrapped in ceramic insulation.
	_xy(m, "spine", -0.195, 0.15, LEATHER, [
		Vector2(-0.31, 1.37), Vector2(-0.17, 1.49), Vector2(0.19, 1.46),
		Vector2(0.32, 1.32), Vector2(0.21, 0.94), Vector2(-0.15, 0.92)])
	_xy(m, "spine", -0.278, 0.038, INSULATION, [
		Vector2(-0.247, 1.35), Vector2(0.22, 1.40), Vector2(0.23, 1.17),
		Vector2(0.041, 0.99), Vector2(-0.19, 1.05)])
	m.ellipsoid("spine", Vector3(-0.025, 1.24, -0.318), Vector3(0.17, 0.20, 0.065), "m:" + COPPER)
	m.band("spine", Vector3(-0.025, 1.24, -0.360), 0.062, 0.013, "m:" + OXIDE)
	m.ellipsoid("spine", Vector3(-0.025, 1.24, -0.372), Vector3(0.077, 0.091, 0.024), "e:" + ARC)
	m.box("spine", Vector3(0.0, 1.20, 0.268), Vector3(0.34, 0.64, 0.36), "m:" + OXIDE)
	m.box("spine", Vector3(0.0, 1.20, 0.447), Vector3(0.16, 0.57, 0.04), LEATHER)
	for i in range(6):
		var y := 0.94 + 0.104 * i
		m.tube("spine", Vector3(-0.18, y, 0.41), Vector3(0.18, y, 0.41),
			0.037, 0.037, "m:" + COPPER, 9)
		m.box("spine", Vector3(0.0, y, 0.450), Vector3(0.054, 0.031, 0.018), "e:" + ARC)
	for side in [-1.0, 1.0]:
		var name := _side(side)
		var shoulder := Vector3(side * 0.33, 1.38, 0.01)
		m.ellipsoid("upper_" + name, shoulder, Vector3(0.288, 0.225, 0.341), INSULATION)
		m.tube("spine", Vector3(side * 0.17, 0.89, 0.405),
			Vector3(side * 0.26, 1.49, 0.36), 0.048, 0.045, "m:" + COPPER, 8)
		m.tube("spine", Vector3(side * 0.24, 1.44, 0.36),
			Vector3(side * 0.29, 1.86 + (0.08 if side < 0.0 else 0.24), 0.31), 0.057, 0.037, CERAMIC, 10)
		for ring in range(3):
			m.band("ornament", Vector3(side * (0.284 + 0.012 * ring), 1.56 + ring * 0.11, 0.32),
				0.061 - ring * 0.006, 0.009, "m:" + COPPER, 0.0, TAU, Vector3(PI * 0.5, 0, 0))
		m.ellipsoid("ornament", Vector3(side * 0.295, 1.90 + (0.08 if side < 0.0 else 0.24), 0.31),
			Vector3(0.102, 0.13, 0.102), "e:" + ARC)
		var glove_joint := "fore_" + name
		m.tube(glove_joint, Vector3(side * 0.516, 1.115, 0.00),
			Vector3(side * 0.598, 0.894, 0.005), 0.093, 0.124, INSULATION, 9)
		m.ellipsoid(glove_joint, Vector3(side * 0.613, 0.955, -0.047),
			Vector3(0.205, 0.192, 0.194), "m:" + COPPER)
		for i in range(3):
			var x: float = side * (0.554 + i * 0.046)
			m.tube("hand_" + name, Vector3(x, 0.93, -0.099), Vector3(x, 0.767 - (0.016 if i == 1 else 0.0), -0.148),
				0.024, 0.013, CERAMIC, 6)
			m.ellipsoid("hand_" + name, Vector3(x, 0.783 - (0.017 if i == 1 else 0.0), -0.157),
				Vector3(0.016, 0.037, 0.026), "e:" + ARC)
		m.tube("shin_" + name, Vector3(0.183 * side, 0.47, -0.019),
			Vector3(0.182 * side, 0.145, -0.034), 0.101, 0.089, LEATHER, 10)
		m.box("foot_" + name, Vector3(0.184 * side, 0.099, -0.13),
			Vector3(0.212, 0.165, 0.385), INSULATION)
		for i in range(3):
			m.box("foot_" + name, Vector3(0.184 * side, 0.033, -0.265 + 0.09 * i),
				Vector3(0.212, 0.031, 0.038), "m:" + OXIDE)
	_xy(m, "head", -0.167, 0.084, "m:" + OXIDE, [
		Vector2(-0.156, 1.847), Vector2(-0.097, 1.895), Vector2(0.117, 1.882),
		Vector2(0.163, 1.801), Vector2(0.133, 1.655), Vector2(-0.105, 1.632)])
	m.box("head", Vector3(0.0, 1.780, -0.220), Vector3(0.252, 0.068, 0.037), "m:" + COPPER)
	m.box("head", Vector3(0.0, 1.782, -0.247), Vector3(0.201, 0.026, 0.017), "e:" + ARC)
	for i in range(-2, 3):
		m.box("head", Vector3(i * 0.037, 1.684, -0.232),
			Vector3(0.014, 0.035 + (2 - abs(i)) * 0.012, 0.015), "m:" + COPPER)


static func _nim(m) -> void:
	# Split forewings hang like a funeral veil, held by a segmented scavenger shell.
	_xy(m, "spine", -0.185, 0.14, CHITIN, [
		Vector2(-0.24, 1.38), Vector2(-0.11, 1.49), Vector2(0.14, 1.47),
		Vector2(0.25, 1.34), Vector2(0.17, 1.05), Vector2(0.0, 0.91), Vector2(-0.17, 1.05)])
	for side in [-1.0, 1.0]:
		var name := _side(side)
		for i in range(4):
			var y := 1.36 - float(i) * 0.102
			_xy(m, "spine", -0.271 - float(i % 2) * 0.011, 0.032, UNDERSHELL if i % 2 == 0 else CHITIN, [
				Vector2(side * 0.019, y + 0.07), Vector2(side * (0.25 - 0.024 * i), y + 0.01),
				Vector2(side * (0.15 - 0.017 * i), y - 0.104), Vector2(side * 0.029, y - 0.054)])
		m.ellipsoid("upper_" + name, Vector3(side * 0.335, 1.358, 0.025),
			Vector3(0.279, 0.217, 0.34), UNDERSHELL)
		m.tube("fore_" + name, Vector3(side * 0.505, 1.09, -0.021),
			Vector3(side * 0.616, 0.873, -0.043), 0.098, 0.091, CHITIN, 7)
		for i in range(3):
			var x: float = side * (0.59 + 0.049 * i)
			var offset := float(i - 1) * 0.077
			m.tube("hand_" + name, Vector3(x, 0.88 + offset, -0.107),
				Vector3(x + 0.082 * side, 0.65 - 0.060 * i + offset, -0.19 - 0.01 * i),
				0.031, 0.008, "m:" + FANG, 6)
		m.tube("shin_" + name, Vector3(side * 0.181, 0.46, -0.018),
			Vector3(side * 0.182, 0.16, -0.031), 0.106, 0.070, CHITIN, 7)
		m.tube("foot_" + name, Vector3(side * 0.182, 0.08, -0.014),
			Vector3(side * 0.189, 0.073, -0.295), 0.094, 0.030, UNDERSHELL, 6)
		_xy(m, "head", -0.168, 0.079, CHITIN, [
			Vector2(side * 0.008, 1.887), Vector2(side * 0.136, 1.869),
			Vector2(side * 0.195, 1.755), Vector2(side * 0.151, 1.637), Vector2(side * 0.012, 1.574)])
		for lens in range(3):
			var eye_at := Vector3(side * (0.075 + 0.044 * lens), 1.760 + 0.023 * sin(lens), -0.229 + 0.010 * lens)
			m.ellipsoid("head", eye_at, Vector3(0.072 - lens * 0.013, 0.053, 0.043),
				"e:" + EYE if lens == 0 else "m:" + LINING)
		m.tube("head", Vector3(side * 0.085, 1.658, -0.228),
			Vector3(side * 0.037, 1.557, -0.286), 0.030, 0.003, FANG, 6)
		var antenna_base := Vector3(side * 0.10, 1.875, -0.018)
		var antenna_joint := Vector3(side * 0.23, 2.062, 0.058)
		var antenna_tip := Vector3(side * 0.32, 2.105, 0.126)
		m.tube("head", antenna_base, antenna_joint, 0.024, 0.014, CHITIN, 8)
		m.tube("head", antenna_joint, antenna_tip, 0.016, 0.009, UNDERSHELL, 7)
		m.ellipsoid("head", antenna_tip, Vector3(0.038, 0.034, 0.031), "e:" + EYE)
		_wing(m, side)


static func _wing(m, side: float) -> void:
	var root := Vector3(side * 0.132, 1.395, 0.225)
	var crown := Vector3(side * 0.705, 1.826, 0.414)
	var apex := Vector3(side * 1.121, 1.752, 0.565)
	var lower := Vector3(side * 0.89, 1.10, 0.635)
	var foot := Vector3(side * 0.63, 0.58, 0.47)
	m.plate("mantle", PackedVector3Array([
		root, crown, apex, Vector3(side * 0.954, 1.526, 0.566),
		Vector3(side * 1.059, 1.434, 0.612), lower,
		Vector3(side * 0.764, 1.183, 0.595), Vector3(side * 0.753, 0.942, 0.558),
		Vector3(side * 0.525, 0.909, 0.480), Vector3(side * 0.329, 1.012, 0.420)]),
		0.031, VELUM)
	m.plate("mantle", PackedVector3Array([
		root - Vector3.UP * 0.15, Vector3(side * 0.618, 1.195, 0.522),
		Vector3(side * 0.771, 0.818, 0.588), foot,
		Vector3(side * 0.552, 0.76, 0.51), Vector3(side * 0.484, 0.614, 0.45),
		Vector3(side * 0.266, 0.804, 0.35)]), 0.030, UNDERSHELL)
	m.tube("mantle", root, crown, 0.040, 0.021, CHITIN, 6)
	m.tube("mantle", crown, apex, 0.026, 0.010, CHITIN, 6)
	m.tube("mantle", root, lower, 0.023, 0.012, LINING, 5)
	m.tube("mantle", root - Vector3.UP * 0.08, foot, 0.026, 0.009, LINING, 5)
	for i in range(4):
		var along := float(i + 1) / 5.0
		var ray_base := root.lerp(crown, along)
		var ray_tip := lower.lerp(apex, along)
		m.tube("mantle", ray_base - Vector3(0, 0, 0.018),
			ray_tip - Vector3(0, 0, 0.025), 0.016, 0.005, CHITIN, 5)
	for i in range(3):
		var dot := root.lerp(apex, 0.53 + i * 0.11) - Vector3(0, 0.13 + i * 0.023, 0.034)
		m.ellipsoid("mantle", dot, Vector3(0.067 + i * 0.019, 0.071 + i * 0.021, 0.017), LINING)
		m.ellipsoid("mantle", dot - Vector3(0, 0, 0.013), Vector3(0.027, 0.037, 0.015), "e:" + EYE)


static func _side(side: float) -> String:
	return "l" if side < 0.0 else "r"


static func _xy(m, joint: String, z: float, depth: float, color: String, outline: Array) -> void:
	var vertices := PackedVector3Array()
	for point: Vector2 in outline:
		vertices.append(Vector3(point.x, point.y, z))
	m.plate(joint, vertices, depth, color)
