extends RefCounted

# Pilgrims of the crypt and things the crypt could no longer hold.
const MOURNING := "14121c"
const VELVET := "2e243f"
const SEAM := "6a587e"
const IVORY := "ac9480"
const MOON := "b5a2ff"
const TIN := "6a6374"

const SACKCLOTH := "211d21"
const RUSTED := "5c302a"
const GAOL_IRON := "33323a"
const ABRADED := "827982"
const SCAR := "9b6b60"
const ASH := "3a3c45"

const LEATHER := "16191d"
const INSULATION := "262c32"
const COPPER := "8c583a"
const OXIDE := "425a5a"
const CERAMIC := "82674a"
const ARC := "e9c266"

const CHITIN := "241a24"
const UNDERSHELL := "472a3b"
const VELUM := "543347"
const LINING := "84516c"
const EYE := "ca5e97"
const FANG := "94947b"


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
		_padded_shoulder(m, "upper_" + side_name, shoulder, side, MOURNING, SEAM, 0.98)
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
	var crown := Vector3(0.77, 1.86, -0.18)
	m.tube("hand_r", base, grip, 0.028, 0.048, MOURNING, 9)
	m.tube("hand_r", grip, crown - Vector3(0.0, 0.30, 0.0), 0.050, 0.034, "m:" + TIN, 10)
	m.tube("hand_r", base, base + Vector3.UP * 0.17, 0.02, 0.039, "m:" + TIN, 8)
	m.band("hand_r", crown, 0.302, 0.038, "m:" + TIN, 0.55, PI * 1.7)
	m.band("hand_r", crown + Vector3(0.068, 0.033, -0.02), 0.238, 0.025, "m:" + IVORY, 0.48, PI * 1.46)
	m.band("hand_r", crown, 0.228, 0.015, "m:" + TIN, 0.0, TAU, Vector3(0.0, PI * 0.5, 0.0))
	m.ellipsoid("hand_r", crown, Vector3(0.195, 0.216, 0.185), "e:" + MOON)
	for angle in [-1.72, -0.86, 0.18, 0.9, 1.7]:
		var radial := Vector3(cos(angle), sin(angle), 0.0)
		m.tube("hand_r", crown + radial * 0.29,
			crown + radial * 0.35, 0.017, 0.003, "m:" + IVORY, 6)

	_mara_outerwear(m)


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
	_padded_shoulder(m, "upper_l", Vector3(-0.35, 1.37, 0.012), -1.0, "m:" + GAOL_IRON, "m:" + RUSTED, 1.38)
	for i in range(3):
		var x := -0.34 - i * 0.05
		var y := 1.49 - i * 0.062
		m.tube("upper_l", Vector3(x, y, 0.03),
			Vector3(x - 0.15, y + 0.11 + i * 0.035, 0.025), 0.07, 0.012, "m:" + RUSTED, 5)
	_padded_shoulder(m, "upper_r", Vector3(0.33, 1.32, 0.0), 1.0, SACKCLOTH, "m:" + GAOL_IRON, 0.82)
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

	_tavren_restraints(m)


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
		_padded_shoulder(m, "upper_" + name, shoulder, side, "m:" + INSULATION, "m:" + COPPER, 1.24 if side < 0 else 0.90)
		m.tube("spine", Vector3(side * 0.17, 0.89, 0.405),
			Vector3(side * 0.26, 1.49, 0.36), 0.048, 0.045, "m:" + COPPER, 8)
		m.tube("spine", Vector3(side * 0.24, 1.44, 0.36),
			Vector3(side * 0.29, 1.86 + (0.08 if side < 0.0 else 0.24), 0.31), 0.057, 0.037, CERAMIC, 10)
		for ring in range(3):
			m.band("ornament", Vector3(side * (0.284 + 0.012 * ring), 1.56 + ring * 0.11, 0.32),
				0.061 - ring * 0.006, 0.009, "m:" + COPPER, 0.0, TAU, Vector3(PI * 0.5, 0, 0))
		var rod_tip := Vector3(side * 0.297, 1.86 + (0.08 if side < 0.0 else 0.24), 0.31)
		m.tube("ornament", rod_tip - Vector3.UP * 0.07,
			rod_tip + Vector3(side * 0.045, 0.136, 0.004), 0.058, 0.004, "m:" + COPPER, 5)
		m.tube("ornament", rod_tip - Vector3.UP * 0.039,
			rod_tip + Vector3(side * 0.026, 0.073, -0.042), 0.012, 0.004, "e:" + ARC, 5)
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
	_iskra_executioner(m)

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
		_padded_shoulder(m, "upper_" + name, Vector3(side * 0.32, 1.36, 0.018), side, CHITIN, VELUM, 0.92)
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

	_nim_carapace(m)


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


static func _mara_outerwear(m) -> void:
	# Full, folded habit around the throat and temples. The face stays recessed.
	_loft(m, "head", MOURNING, [
		[Vector3(0, 1.55, 0.081), 0.242, 0.197],
		[Vector3(0, 1.72, 0.052), 0.250, 0.210],
		[Vector3(0, 1.93, 0.028), 0.200, 0.177],
		[Vector3(-0.035, 2.04, 0.085), 0.038, 0.084]], 0.036, 7, PI * 0.74)
	_ridged(m, "head", [
		Vector3(-0.158, 1.78, -0.25), Vector3(-0.106, 1.89, -0.27),
		Vector3(0.106, 1.89, -0.27), Vector3(0.158, 1.78, -0.25),
		Vector3(0.106, 1.63, -0.247), Vector3(0, 1.57, -0.222),
		Vector3(-0.115, 1.64, -0.247)], Vector3(0, 1.786, -0.326), 0.024, "332942")
	_edge(m, "head", [
		Vector3(-0.143, 1.777, -0.267), Vector3(-0.09, 1.802, -0.299),
		Vector3(0, 1.781, -0.327), Vector3(0.09, 1.802, -0.299),
		Vector3(0.143, 1.777, -0.267)], 0.007, "e:" + MOON)
	for side in [-1.0, 1.0]:
		var name := _side(side)
		_ridged(m, "fore_" + name, [
			Vector3(side * 0.462, 1.115, -0.095), Vector3(side * 0.616, 1.079, -0.07),
			Vector3(side * 0.719, 0.86, -0.096), Vector3(side * 0.612, 0.792, -0.116),
			Vector3(side * 0.509, 0.91, -0.12)],
			Vector3(side * 0.608, 0.973, -0.183), 0.036, "m:" + TIN)
		_loft(m, "thigh_" + name, VELVET, [
			[Vector3(0.148 * side, 0.92, 0.03), 0.19, 0.248],
			[Vector3(0.219 * side, 0.64, 0.017), 0.182, 0.238],
			[Vector3(0.238 * side, 0.30, 0.045), 0.244, 0.275]], 0.038, 7, TAU)
		_loft(m, "shin_" + name, MOURNING, [
			[Vector3(0.19 * side, 0.53, 0.034), 0.133, 0.151],
			[Vector3(0.206 * side, 0.30, 0.04), 0.156, 0.168],
			[Vector3(0.23 * side, 0.16, 0.09), 0.191, 0.241]], 0.033, 6, TAU)
		_edge(m, "thigh_" + name, [
			Vector3(0.08 * side, 0.86, -0.251), Vector3(0.100 * side, 0.63, -0.266),
			Vector3(0.115 * side, 0.32, -0.288)], 0.011, SEAM)
		_edge(m, "mantle", [
			Vector3(0.19 * side, 1.47, 0.194), Vector3(0.365 * side, 1.12, 0.238),
			Vector3(0.479 * side, 0.68, 0.353), Vector3(0.448 * side, 0.18, 0.418)], 0.02, VELVET)
		for i in range(3):
			var step := float(i)
			_ridged(m, "mantle", [
				Vector3(0.10 * side + step * 0.072 * side, 1.37 - step * 0.014, 0.30),
				Vector3(0.21 * side + step * 0.082 * side, 1.24 - step * 0.016, 0.31),
				Vector3(0.29 * side + step * 0.074 * side, 0.67 - step * 0.118, 0.40),
				Vector3(0.145 * side + step * 0.05 * side, 0.33 - step * 0.064, 0.48)],
				Vector3((0.16 + step * 0.076) * side, 0.9 - step * 0.12, 0.48), 0.036, MOURNING if i % 2 else VELVET)
		_boot(m, "foot_" + name, side, "302936", "m:" + TIN, 0.93)
	var stem := Vector3(0.72, 1.475, -0.188)
	_ridged(m, "hand_r", [
		stem + Vector3(-0.027, -0.12, 0), stem + Vector3(-0.108, 0.074, 0),
		stem + Vector3(-0.13, 0.192, 0), stem + Vector3(-0.091, 0.303, 0),
		stem + Vector3(-0.04, 0.18, 0), stem + Vector3(0.009, 0.143, 0),
		stem + Vector3(0.087, 0.23, 0), stem + Vector3(0.11, 0.085, 0),
		stem + Vector3(0.067, -0.03, 0)],
		stem + Vector3(0.004, 0.085, -0.035), 0.048, "m:" + IVORY)


static func _tavren_restraints(m) -> void:
	# Layered plates have a sloping ridge, a deliberately jagged outer edge and lapped cuirass skirts.
	_ridged(m, "spine", [
		Vector3(-0.302, 1.42, -0.22), Vector3(-0.121, 1.47, -0.21),
		Vector3(0.145, 1.378, -0.22), Vector3(0.351, 1.30, -0.211),
		Vector3(0.311, 1.14, -0.214), Vector3(0.148, 1.012, -0.227),
		Vector3(-0.18, 1.06, -0.259), Vector3(-0.327, 1.20, -0.244)],
		Vector3(-0.061, 1.22, -0.373), 0.065, "m:" + GAOL_IRON)
	for i in range(3):
		var y := 1.09 - i * 0.101
		_ridged(m, "spine", [
			Vector3(-0.29 + i * 0.019, y + 0.051, -0.232),
			Vector3(0.308 - i * 0.04, y + 0.076, -0.211),
			Vector3(0.24 - i * 0.037, y - 0.044, -0.236),
			Vector3(-0.25 + i * 0.015, y - 0.086, -0.254)],
			Vector3(-0.012, y, -0.321), 0.037, "m:" + RUSTED if i == 1 else "m:" + GAOL_IRON)
	_loft(m, "head", SACKCLOTH, [
		[Vector3(0, 1.56, 0.026), 0.227, 0.198],
		[Vector3(-0.009, 1.69, 0.041), 0.222, 0.225],
		[Vector3(0.017, 1.873, 0.040), 0.173, 0.173],
		[Vector3(0.027, 1.976, 0.031), 0.060, 0.104]], 0.04, 7, PI * 0.81)
	_ridged(m, "head", [
		Vector3(-0.187, 1.802, -0.208), Vector3(-0.076, 1.918, -0.198),
		Vector3(0.066, 1.879, -0.214), Vector3(0.158, 1.796, -0.199),
		Vector3(0.155, 1.663, -0.202), Vector3(-0.026, 1.553, -0.188),
		Vector3(-0.173, 1.635, -0.186)],
		Vector3(-0.049, 1.76, -0.304), 0.041, "m:" + GAOL_IRON)
	_edge(m, "head", [Vector3(-0.137, 1.788, -0.24),
		Vector3(-0.063, 1.81, -0.296), Vector3(0.005, 1.793, -0.29)], 0.009, "e:9e5246")
	_edge(m, "head", [Vector3(0.041, 1.808, -0.278), Vector3(0.127, 1.779, -0.233)], 0.007, "e:9e5246")
	for side in [-1.0, 1.0]:
		var name := _side(side)
		_ridged(m, "thigh_" + name, [
			Vector3(side * 0.075, 0.88, -0.226), Vector3(side * 0.35, 0.922, -0.167),
			Vector3(side * 0.368, 0.736, -0.164), Vector3(side * 0.255, 0.546, -0.179),
			Vector3(side * 0.143, 0.609, -0.202)],
			Vector3(side * 0.22, 0.737, -0.273), 0.044, "m:" + GAOL_IRON)
		_ridged(m, "shin_" + name, [
			Vector3(side * 0.071, 0.46, -0.098), Vector3(side * 0.178, 0.52, -0.093),
			Vector3(side * 0.298, 0.449, -0.089), Vector3(side * 0.278, 0.177, -0.098),
			Vector3(side * 0.171, 0.132, -0.123), Vector3(side * 0.082, 0.188, -0.098)],
			Vector3(side * 0.196, 0.312, -0.19), 0.045, "m:" + GAOL_IRON)
		_boot(m, "foot_" + name, side, "392f38", "m:" + GAOL_IRON, 1.13)
		_loft(m, "fore_" + name, "m:" + GAOL_IRON, [
			[Vector3(side * 0.513, 1.104, 0), 0.137, 0.122],
			[Vector3(side * 0.61, 0.964, -0.021), 0.158, 0.143],
			[Vector3(side * 0.627, 0.832, -0.018), 0.138, 0.123]], 0.031, 7, TAU)
		_loft(m, "hand_" + name, ASH, [
			[Vector3(side * 0.607, 0.880, -0.035), 0.105, 0.089],
			[Vector3(side * 0.64, 0.801, -0.047), 0.117, 0.107],
			[Vector3(side * 0.665, 0.747, -0.049), 0.085, 0.074]], 0.025, 6, TAU)
		for idx in range(4):
			var at := Vector3(side * (0.582 + idx * 0.036), 0.805 - idx * 0.009, -0.139)
			m.box("hand_" + name, at, Vector3(0.031, 0.074, 0.034), "m:" + RUSTED, Vector3(0.24, side * 0.12, side * -0.17))
	_ridged(m, "hand_r", [
		Vector3(0.76, 0.63, -0.129), Vector3(0.84, 0.562, -0.131),
		Vector3(0.92, 0.285, -0.14), Vector3(1.058, 0.214, -0.139),
		Vector3(1.248, 0.292, -0.113), Vector3(1.301, 0.467, -0.102),
		Vector3(1.232, 0.593, -0.105), Vector3(1.369, 0.468, -0.104),
		Vector3(1.352, 0.267, -0.111), Vector3(1.214, 0.111, -0.128),
		Vector3(0.963, 0.098, -0.16), Vector3(0.766, 0.272, -0.163)],
		Vector3(0.887, 0.236, -0.186), 0.041, "m:" + RUSTED)
	# The broad hook blade is closed around a forged socket, not suspended on an edge.
	m.tube("hand_r", Vector3(0.646, 0.936, -0.126), Vector3(0.815, 0.523, -0.134),
		0.057, 0.081, "m:" + GAOL_IRON, 7)
	m.tube("hand_r", Vector3(0.794, 0.555, -0.135), Vector3(0.875, 0.328, -0.149),
		0.085, 0.069, "m:" + RUSTED, 7)
	_ridged(m, "hand_r", [
		Vector3(0.789, 0.546, -0.167), Vector3(0.876, 0.491, -0.166),
		Vector3(0.918, 0.325, -0.156), Vector3(1.035, 0.249, -0.150),
		Vector3(1.176, 0.267, -0.139), Vector3(1.282, 0.355, -0.126),
		Vector3(1.293, 0.241, -0.126), Vector3(1.191, 0.134, -0.137),
		Vector3(1.002, 0.117, -0.156), Vector3(0.829, 0.257, -0.175),
		Vector3(0.755, 0.466, -0.173)],
		Vector3(0.891, 0.251, -0.228), 0.066, "m:" + GAOL_IRON)
	_edge(m, "hand_r", [Vector3(0.64, 0.908, -0.173),
		Vector3(0.782, 0.576, -0.186), Vector3(0.863, 0.317, -0.218)],
		0.015, "m:" + ABRADED)
	_edge(m, "hand_r", [Vector3(0.766, 0.268, -0.186), Vector3(0.961, 0.097, -0.183),
		Vector3(1.209, 0.109, -0.149), Vector3(1.353, 0.267, -0.133),
		Vector3(1.366, 0.466, -0.127), Vector3(1.231, 0.595, -0.126)], 0.013, "m:" + ABRADED)


static func _iskra_executioner(m) -> void:
	# The shrine plates close over the front, with a split robe and a conductor for a polearm.
	_ridged(m, "spine", [
		Vector3(-0.351, 1.375, -0.165), Vector3(-0.172, 1.477, -0.196),
		Vector3(0.180, 1.466, -0.186), Vector3(0.348, 1.326, -0.158),
		Vector3(0.286, 1.12, -0.215), Vector3(0.121, 1.025, -0.243),
		Vector3(-0.174, 1.047, -0.243), Vector3(-0.326, 1.166, -0.195)],
		Vector3(0.016, 1.264, -0.346), 0.053, "m:" + INSULATION)
	_edge(m, "spine", [
		Vector3(-0.331, 1.375, -0.198), Vector3(-0.17, 1.413, -0.284),
		Vector3(0.015, 1.265, -0.382), Vector3(0.19, 1.4, -0.259),
		Vector3(0.326, 1.335, -0.191)], 0.014, "m:" + COPPER)
	_loft(m, "head", LEATHER, [
		[Vector3(0, 1.516, 0.039), 0.254, 0.207],
		[Vector3(0, 1.680, 0.040), 0.242, 0.236],
		[Vector3(0, 1.889, 0.022), 0.197, 0.202],
		[Vector3(-0.022, 2.011, 0.07), 0.127, 0.147],
		[Vector3(-0.021, 2.121, 0.084), 0.018, 0.052]], 0.039, 8, PI * 1.35)
	_ridged(m, "head", [
		Vector3(-0.194, 1.841, -0.231), Vector3(-0.117, 1.963, -0.187),
		Vector3(0.0, 2.01, -0.198), Vector3(0.122, 1.95, -0.190),
		Vector3(0.187, 1.820, -0.224), Vector3(0.151, 1.647, -0.239),
		Vector3(0.016, 1.548, -0.242), Vector3(-0.153, 1.644, -0.223)],
		Vector3(0, 1.764, -0.364), 0.034, "m:" + INSULATION)
	_edge(m, "head", [
		Vector3(-0.163, 1.794, -0.263), Vector3(-0.104, 1.828, -0.318),
		Vector3(0, 1.791, -0.37), Vector3(0.105, 1.827, -0.314),
		Vector3(0.158, 1.794, -0.259)], 0.010, "e:" + ARC)
	for side in [-1.0, 1.0]:
		var name := _side(side)
		m.tube("head", Vector3(side * 0.17, 1.92, 0.024), Vector3(side * 0.224, 2.110, -0.025),
			0.041, 0.004, "m:" + COPPER, 6)
		for i in range(3):
			var x: float = side * (0.037 + i * 0.034)
			var z := -0.326 + i * 0.02
			m.tube("head", Vector3(x, 1.697 + i * 0.012, z), Vector3(x + 0.02 * side, 1.634 + i * 0.014, z + 0.02),
				0.008, 0.005, "m:" + COPPER, 5)
		_ridged(m, "mantle", [
			Vector3(side * 0.18, 1.512, 0.221), Vector3(side * 0.398, 1.445, 0.233),
			Vector3(side * 0.513, 1.18, 0.297), Vector3(side * 0.421, 0.394, 0.48),
			Vector3(side * 0.277, 0.222, 0.45), Vector3(side * 0.126, 0.443, 0.514),
			Vector3(side * 0.146, 0.997, 0.494)],
			Vector3(side * 0.307, 0.93, 0.589), 0.036, LEATHER)
		_loft(m, "thigh_" + name, INSULATION, [
			[Vector3(side * 0.167, 0.924, 0.024), 0.184, 0.224],
			[Vector3(side * 0.225, 0.729, 0.022), 0.173, 0.187],
			[Vector3(side * 0.231, 0.520, 0.087), 0.196, 0.207]], 0.033, 7, TAU)
		_edge(m, "thigh_" + name, [
			Vector3(side * 0.30, 0.87, -0.188), Vector3(side * 0.35, 0.714, -0.155),
			Vector3(side * 0.35, 0.536, -0.07)], 0.012, "m:" + COPPER)
		_ridged(m, "fore_" + name, [
			Vector3(side * 0.404, 1.113, -0.123), Vector3(side * 0.594, 1.112, -0.104),
			Vector3(side * 0.758, 0.943, -0.147), Vector3(side * 0.735, 0.84, -0.143),
			Vector3(side * 0.515, 0.854, -0.129)], Vector3(side * 0.595, 0.975, -0.244),
			0.045, "m:" + INSULATION)
		_edge(m, "fore_" + name, [
			Vector3(side * 0.434, 1.066, -0.154), Vector3(side * 0.611, 0.972, -0.254),
			Vector3(side * 0.742, 0.938, -0.168)], 0.010, "m:" + COPPER)
		_boot(m, "foot_" + name, side, INSULATION, "m:" + LEATHER, 1.11)
	var grip := Vector3(0.615, 0.854, -0.128)
	var axis := Vector3(0.23, 0.95, -0.19)
	m.tube("hand_r", grip - axis * 0.66, grip + axis * 1.11, 0.047, 0.044, "m:" + INSULATION, 8)
	m.tube("hand_r", grip - axis * 0.75, grip - axis * 0.40, 0.032, 0.055, "m:" + COPPER, 8)
	m.tube("hand_r", grip + axis * 0.03, grip + axis * 0.78, 0.054, 0.048, "m:" + COPPER, 9)
	var top := grip + axis * 1.12
	_ridged(m, "hand_r", [
		top + Vector3(0.020, -0.162, 0.013), top + Vector3(-0.09, 0.002, 0.012),
		top + Vector3(-0.317, 0.081, -0.012), top + Vector3(-0.422, 0.299, -0.024),
		top + Vector3(-0.261, 0.202, -0.041), top + Vector3(-0.031, 0.163, -0.018),
		top + Vector3(0.241, 0.255, 0.014), top + Vector3(0.155, 0.119, -0.039),
		top + Vector3(0.059, 0.027, -0.031)],
		top + Vector3(-0.065, 0.103, -0.086), 0.081, "m:" + INSULATION)
	m.tube("hand_r", top + Vector3(0.0, 0.04, -0.008), top + Vector3(0.088, 0.346, -0.04),
		0.071, 0.007, "m:" + COPPER, 6)
	_edge(m, "hand_r", [
		top + Vector3(-0.415, 0.293, -0.059), top + Vector3(-0.310, 0.077, -0.069),
		top + Vector3(-0.066, 0.092, -0.111), top + Vector3(0.138, 0.134, -0.077),
		top + Vector3(0.237, 0.246, -0.018)], 0.014, "e:" + ARC)


static func _nim_carapace(m) -> void:
	# Chitin transitions from pliable abdominal rings to hard, swept killing claws.
	_loft(m, "head", CHITIN, [
		[Vector3(0, 1.52, 0.006), 0.162, 0.180],
		[Vector3(0, 1.68, 0.035), 0.206, 0.222],
		[Vector3(0, 1.84, 0.047), 0.197, 0.206],
		[Vector3(0, 1.965, 0.10), 0.078, 0.134]], 0.034, 8, PI)
	_ridged(m, "head", [
		Vector3(-0.146, 1.92, -0.156), Vector3(0.0, 1.973, -0.184),
		Vector3(0.152, 1.933, -0.166), Vector3(0.204, 1.819, -0.165),
		Vector3(0.118, 1.787, -0.233), Vector3(0.031, 1.821, -0.241),
		Vector3(-0.109, 1.787, -0.23), Vector3(-0.201, 1.816, -0.158)],
		Vector3(0.0, 1.869, -0.297), 0.036, CHITIN)
	# Pressed black chitin covers the under-hood and leaves four eye slits in shadow.
	m.loft("head", [
		[Vector3(0, 1.526, -0.053), 0.12, 0.14],
		[Vector3(0, 1.628, -0.034), 0.188, 0.19],
		[Vector3(0, 1.784, -0.015), 0.226, 0.216],
		[Vector3(0, 1.921, 0.049), 0.158, 0.174],
		[Vector3(0, 2.013, 0.101), 0.031, 0.075]], "221824", 9)
	for side in [-1.0, 1.0]:
		var name := _side(side)
		_ridged(m, "head", [
			Vector3(side * 0.094, 1.901, -0.19), Vector3(side * 0.173, 1.867, -0.170),
			Vector3(side * 0.213, 1.784, -0.144), Vector3(side * 0.158, 1.742, -0.193),
			Vector3(side * 0.05, 1.777, -0.227)], Vector3(side * 0.102, 1.817, -0.277),
			0.025, CHITIN)
		for i in range(2):
			var drift := float(i) * .039
			_edge(m, "head", [Vector3(side * 0.038, 1.765 + drift, -0.25),
				Vector3(side * 0.101, 1.767 + drift, -0.285),
				Vector3(side * 0.163, 1.778 + drift, -0.24)], 0.009 if i == 0 else 0.005, "e:" + EYE)
		_ridged(m, "head", [
			Vector3(side * 0.151, 1.777, -0.211), Vector3(side * 0.205, 1.746, -0.17),
			Vector3(side * 0.15, 1.622, -0.18), Vector3(side * 0.025, 1.52, -0.225),
			Vector3(side * 0.044, 1.657, -0.224)], Vector3(side * 0.103, 1.658, -0.286),
			0.033, UNDERSHELL)
		m.tube("head", Vector3(side * 0.127, 1.678, -0.258), Vector3(side * 0.057, 1.553, -0.328),
			0.035, 0.006, "m:" + FANG, 6)
		_ridged(m, "thigh_" + name, [
			Vector3(side * 0.08, 0.92, -0.183), Vector3(side * 0.291, 0.874, -0.167),
			Vector3(side * 0.379, 0.803, -0.121), Vector3(side * 0.277, 0.567, -0.127),
			Vector3(side * 0.144, 0.595, -0.180)], Vector3(side * 0.211, 0.772, -0.248),
			0.045, CHITIN)
		_ridged(m, "shin_" + name, [
			Vector3(side * 0.061, 0.461, -0.10), Vector3(side * 0.205, 0.551, -0.129),
			Vector3(side * 0.32, 0.433, -0.113), Vector3(side * 0.295, 0.249, -0.082),
			Vector3(side * 0.204, 0.125, -0.135), Vector3(side * 0.08, 0.217, -0.115)],
			Vector3(side * 0.192, 0.339, -0.206), 0.044, UNDERSHELL)
		_boot(m, "foot_" + name, side, CHITIN, "m:" + FANG, 0.86)
		_ridged(m, "fore_" + name, [
			Vector3(side * 0.427, 1.106, -0.109), Vector3(side * 0.581, 1.170, -0.08),
			Vector3(side * 0.742, 0.981, -0.096), Vector3(side * 0.722, 0.850, -0.098),
			Vector3(side * 0.59, 0.804, -0.123), Vector3(side * 0.48, 0.98, -0.105)],
			Vector3(side * 0.579, 1.003, -0.224), 0.045, CHITIN)
		for i in range(2):
			var x: float = side * (0.619 + i * 0.081)
			var y := 0.866 - i * 0.060
			_ridged(m, "hand_" + name, [
				Vector3(x - side * 0.06, y, -0.144), Vector3(x + side * 0.08, y - 0.038, -0.116),
				Vector3(x + side * 0.087, y - 0.237, -0.239), Vector3(x - side * 0.014, y - 0.36, -0.334),
				Vector3(x - side * 0.009, y - 0.223, -0.27), Vector3(x - side * 0.046, y - 0.124, -0.19)],
				Vector3(x + side * 0.029, y - 0.145, -0.26), 0.034, "m:" + FANG)


static func _padded_shoulder(m, joint: String, center: Vector3, side: float, color: String, trim: String, scale: float) -> void:
	var outline: Array[Vector3] = [
		center + Vector3(side * -0.15, 0.08, -0.135) * scale,
		center + Vector3(side * 0.002, 0.179, -0.089) * scale,
		center + Vector3(side * 0.15, 0.144, -0.054) * scale,
		center + Vector3(side * 0.251, 0.075, -0.016) * scale,
		center + Vector3(side * 0.174, -0.109, -0.112) * scale,
		center + Vector3(side * 0.04, -0.153, -0.147) * scale,
		center + Vector3(side * -0.12, -0.098, -0.119) * scale]
	_ridged(m, joint, outline, center + Vector3(side * 0.058, 0.019, -0.252) * scale, 0.047, color)
	_edge(m, joint, outline.slice(0, 5), 0.011 * scale, trim)
	_loft(m, joint, color, [
		[center + Vector3(side * 0.025, 0.135, 0.03) * scale, 0.095 * scale, 0.125 * scale],
		[center + Vector3(side * 0.035, 0.034, 0.025) * scale, 0.212 * scale, 0.17 * scale],
		[center + Vector3(side * 0.061, -0.12, 0.022) * scale, 0.138 * scale, 0.139 * scale]], 0.044, 7, PI * 1.08)


static func _boot(m, joint: String, side: float, upper: String, sole: String, scale: float) -> void:
	var center := Vector3(side * 0.183, 0.083, -0.09)
	var points: Array[Vector3] = []
	for point: Vector2 in [
		Vector2(-0.092, 0.149), Vector2(0.095, 0.144), Vector2(0.129, -0.092),
		Vector2(0.104, -0.184), Vector2(0.017, -0.234), Vector2(-0.105, -0.187),
		Vector2(-0.128, -0.078)]:
		points.append(center + Vector3(point.x * scale, -0.036, point.y * scale))
	m.plate(joint, PackedVector3Array(points), 0.073, sole)
	_ridged(m, joint, points, center + Vector3(0.0, 0.112, -0.058), 0.043, upper)
	_edge(m, joint, [
		center + Vector3(-0.10 * scale, 0.019, -0.146 * scale),
		center + Vector3(0, 0.056, -0.213 * scale),
		center + Vector3(0.108 * scale, 0.028, -0.16 * scale)], 0.011, sole)


static func _ridged(m, joint: String, perimeter: Array, ridge: Vector3, depth: float, color: String) -> void:
	for i in perimeter.size():
		var next := (i + 1) % perimeter.size()
		m.plate(joint, PackedVector3Array([perimeter[i], perimeter[next], ridge]), depth, color)


static func _loft(m, joint: String, color: String, rings: Array, thickness: float, sectors: int, span: float) -> void:
	for level in range(rings.size() - 1):
		var lower: Array = rings[level]
		var upper: Array = rings[level + 1]
		for sector in sectors:
			var start := PI * 0.5 - span * 0.5 + span * float(sector) / sectors
			var finish := start + span / sectors
			m.plate(joint, PackedVector3Array([
				_ring_point(lower, start), _ring_point(lower, finish),
				_ring_point(upper, finish), _ring_point(upper, start)]), thickness, color)


static func _ring_point(ring: Array, angle: float) -> Vector3:
	var center: Vector3 = ring[0]
	return center + Vector3(cos(angle) * float(ring[1]), 0.0, sin(angle) * float(ring[2]))


static func _edge(m, joint: String, points: Array, radius: float, color: String) -> void:
	for i in range(points.size() - 1):
		m.tube(joint, points[i], points[i + 1], radius, radius, color, 6)
