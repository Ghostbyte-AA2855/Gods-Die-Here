extends RefCounted

# Leather, cloth, glove highlight, and exposed skin colors follow each champion's clothing.
const PALETTES := {
	"breakwater": ["273b41", "17292e", "45626a", "9cafa1"],
	"threadkeeper": ["524253", "281f32", "887080", "b3a096"],
	"echo_duelist": ["3b3556", "262138", "5b526f", "a597aa"],
	"forgecaller": ["514346", "302529", "896350", "a27867"],
	"lamplighter": ["4c3c34", "2e2420", "836751", "b1977a"],
	"longwatch": ["49483a", "332d24", "757357", "a59873"],
	"sluicecaller": ["364744", "1c3131", "537775", "8ca5a3"],
	"glassmage": ["43435c", "282739", "6b6a84", "a8a0b2"],
	"blood_cantor": ["57363f", "352229", "8e5660", "b38b82"],
	"bellwarden": ["453b36", "2e2625", "776449", "aa9180"],
	"ash_dancer": ["5b3b40", "362629", "976055", "a77d70"],
	"winter_scribe": ["41485c", "242c41", "697a92", "b0bac6"],
	"dream_shepherd": ["514858", "302838", "7b7189", "b69cae"],
	"chainrunner": ["514546", "30282d", "816255", "9e7669"],
	"coilwright": ["534340", "31282c", "886953", "ac8475"],
	"duskmoth": ["553d54", "342635", "886480", "a488a4"],
}

# Jaw width, cheek scale, brow slope, and bridge rise lend different profiles to the adult heads.
const FACES := {
	"breakwater": [1.06, 1.02, 0.20, 1.0],
	"threadkeeper": [0.87, 0.98, -0.09, 0.74],
	"echo_duelist": [0.94, 0.98, 0.23, 1.12],
	"forgecaller": [1.12, 1.08, 0.24, 1.18],
	"lamplighter": [0.88, 0.98, 0.11, 1.05],
	"longwatch": [1.03, 1.05, 0.41, 1.30],
	"sluicecaller": [0.90, 0.94, 0.08, 0.81],
	"glassmage": [0.92, 1.02, 0.28, 1.10],
	"blood_cantor": [1.07, 1.04, 0.07, 0.91],
	"bellwarden": [1.12, 1.07, 0.24, 1.09],
	"ash_dancer": [0.91, 1.01, 0.34, 0.86],
	"winter_scribe": [0.86, 0.94, 0.15, 1.13],
	"dream_shepherd": [0.90, 0.99, -0.14, 0.82],
	"chainrunner": [1.10, 1.00, 0.38, 1.22],
	"coilwright": [1.02, 1.03, 0.18, 0.77],
	"duskmoth": [0.87, 1.06, 0.31, 0.68],
}
const VEILED := ["breakwater", "forgecaller", "lamplighter", "longwatch", "sluicecaller",
	"glassmage", "bellwarden", "dream_shepherd", "coilwright", "duskmoth"]


static func dress(m, class_id: String, archetype: String) -> void:
	var palette: Array = PALETTES[class_id]
	var power_build := 1.10 if archetype == "guard" else 1.0
	var drape := 0.93 if archetype in ["healer", "ranged"] else 1.0
	var taper := 0.87 if class_id in ["echo_duelist", "ash_dancer", "duskmoth"] else 1.0
	var leather: String = palette[0]
	var cloth: String = palette[1]
	var seam: String = palette[2]
	var skin: String = palette[3]
	_torso(m, leather, cloth, seam, power_build, drape * taper)
	_head(m, skin, cloth, FACES[class_id], class_id not in VEILED)
	for side in [-1.0, 1.0]:
		var suffix := "_l" if side < 0 else "_r"
		_sleeve(m, suffix, side, leather, cloth, seam, power_build)
		_glove(m, suffix, side, leather, cloth, seam, power_build)
		_leg(m, suffix, side, leather, cloth, seam, power_build * drape)


static func _torso(m, leather: String, cloth: String, seam: String, build: float, taper: float) -> void:
	m.loft("pelvis", [
		[Vector3(0, 0.70, 0.022), 0.12, 0.11],
		[Vector3(0, 0.77, 0.018), 0.224 * build, 0.159],
		[Vector3(0, 0.85, 0.017), 0.244 * build * taper, 0.177],
		[Vector3(0, 0.94, 0.010), 0.195 * build * taper, 0.150],
		[Vector3(0, 1.04, 0.000), 0.184 * build * taper, 0.138],
	], cloth, 16)
	m.loft("spine", [
		[Vector3(0, 0.91, 0.008), 0.170 * build * taper, 0.133],
		[Vector3(0, 1.00, 0.000), 0.193 * build * taper, 0.149],
		[Vector3(0, 1.12, -0.006), 0.233 * build, 0.179],
		[Vector3(0, 1.27, 0.012), 0.301 * build, 0.183],
		[Vector3(0, 1.39, 0.024), 0.323 * build, 0.151],
		[Vector3(0, 1.48, 0.025), 0.239 * build, 0.117],
		[Vector3(0, 1.52, 0.013), 0.105, 0.081],
	], leather, 16)
	for side in [-1.0, 1.0]:
		# Stitched shaping darts follow the ribs into the tucked waist.
		for index in range(3):
			var y := 1.01 + float(index) * 0.039
			m.tube("spine", Vector3(side * 0.172 * build, y, -0.078),
				Vector3(side * (0.073 + float(index) * 0.009), y - 0.039, -0.158),
				0.009, 0.006, cloth, 5)
		m.tube("spine", Vector3(side * 0.095, 1.474, -0.095),
			Vector3(side * 0.265 * build, 1.403, -0.074), 0.015, 0.010, seam, 6)
	m.loft("pelvis", [
		[Vector3(0, 0.875, 0.009), 0.237 * build * taper, 0.171],
		[Vector3(0, 0.913, 0.003), 0.234 * build * taper, 0.175],
		[Vector3(0, 0.940, 0.003), 0.211 * build * taper, 0.166],
	], leather, 16)


static func _sleeve(m, suffix: String, side: float, leather: String, cloth: String, seam: String, build: float) -> void:
	var upper := "upper" + suffix
	var fore := "fore" + suffix
	m.loft(upper, [
		[Vector3(side * 0.523, 1.043, -0.009), 0.082 * build, 0.075],
		[Vector3(side * 0.496, 1.112, -0.016), 0.104 * build, 0.097],
		[Vector3(side * 0.447, 1.204, -0.012), 0.133 * build, 0.121],
		[Vector3(side * 0.391, 1.308, 0.004), 0.126 * build, 0.111],
		[Vector3(side * 0.342, 1.390, 0.008), 0.111 * build, 0.087],
		[Vector3(side * 0.331, 1.437, 0.009), 0.071 * build, 0.080],
	], leather)
	m.loft(fore, [
		[Vector3(side * 0.600, 0.837, -0.028), 0.061, 0.061],
		[Vector3(side * 0.583, 0.903, -0.017), 0.070 * build, 0.073],
		[Vector3(side * 0.565, 0.962, -0.001), 0.103 * build, 0.092],
		[Vector3(side * 0.540, 1.030, 0.005), 0.110 * build, 0.093],
		[Vector3(side * 0.520, 1.094, 0.002), 0.088 * build, 0.083],
	], cloth)
	# A cuff and highlighted seam emphasize the change from forearm to the articulated wrist.
	m.loft(fore, [
		[Vector3(side * 0.598, 0.839, -0.026), 0.069, 0.066],
		[Vector3(side * 0.596, 0.858, -0.025), 0.076, 0.074],
		[Vector3(side * 0.589, 0.879, -0.021), 0.076, 0.074],
		[Vector3(side * 0.585, 0.893, -0.019), 0.068, 0.068],
	], leather)
	m.tube(fore, Vector3(side * 0.612, 0.871, -0.085),
		Vector3(side * 0.597, 0.886, -0.083), 0.011, 0.009, seam, 5)


static func _glove(m, suffix: String, side: float, leather: String, cloth: String, seam: String, build: float) -> void:
	var hand := "hand" + suffix
	var center := side * 0.62
	m.loft(hand, [
		[Vector3(center, 0.768, -0.016), 0.049 * build, 0.047],
		[Vector3(center, 0.793, -0.007), 0.067 * build, 0.054],
		[Vector3(center - 0.007 * side, 0.830, -0.009), 0.066 * build, 0.055],
		[Vector3(center - 0.020 * side, 0.878, -0.024), 0.057 * build, 0.052],
	], leather)
	for digit in range(4):
		var offset := (float(digit) - 1.5) * 0.032 * build * side
		var tip_y := 0.700 + absf(float(digit) - 1.25) * 0.012
		var knuckle := Vector3(center + offset, 0.788 - float(digit) * 0.004, -0.009)
		var bend := Vector3(center + offset + side * 0.004, tip_y + 0.027, -0.030)
		var tip := Vector3(center + offset - side * 0.008, tip_y, -0.067)
		var radius := 0.0145 * build - float(digit) * 0.0009
		m.tube(hand, knuckle, bend, radius, radius * 0.88, leather, 7)
		m.tube(hand, bend, tip, radius * 0.91, radius * 0.73, cloth, 7)
		m.ellipsoid(hand, knuckle + Vector3(0, 0, 0.010),
			Vector3(radius * 1.68, 0.028, 0.025), seam)
		m.ellipsoid(hand, tip, Vector3(radius * 1.43, 0.022, 0.021), cloth)
	var thumb_base := Vector3(center - side * 0.048, 0.821, -0.039)
	var thumb_bend := Vector3(center - side * 0.080, 0.782, -0.077)
	m.tube(hand, thumb_base, thumb_bend, 0.022, 0.018, leather, 8)
	m.tube(hand, thumb_bend, Vector3(center - side * 0.051, 0.753, -0.089),
		0.018, 0.013, leather, 8)
	m.tube(hand, Vector3(center - side * 0.035, 0.840, 0.040),
		Vector3(center + side * 0.046, 0.793, 0.047), 0.008, 0.006, seam, 5)


static func _leg(m, suffix: String, side: float, leather: String, cloth: String, seam: String, build: float) -> void:
	var thigh := "thigh" + suffix
	var shin := "shin" + suffix
	var foot := "foot" + suffix
	m.loft(thigh, [
		[Vector3(side * 0.180, 0.477, -0.005), 0.090, 0.082],
		[Vector3(side * 0.179, 0.548, -0.010), 0.110 * build, 0.099],
		[Vector3(side * 0.178, 0.650, -0.019), 0.142 * build, 0.123],
		[Vector3(side * 0.174, 0.763, -0.005), 0.153 * build, 0.140],
		[Vector3(side * 0.167, 0.855, 0.005), 0.146 * build, 0.129],
		[Vector3(side * 0.162, 0.907, 0.015), 0.101 * build, 0.111],
	], cloth)
	m.loft(shin, [
		[Vector3(side * 0.18, 0.153, -0.005), 0.074, 0.074],
		[Vector3(side * 0.18, 0.228, -0.001), 0.075, 0.079],
		[Vector3(side * 0.18, 0.309, 0.013), 0.100 * build, 0.108],
		[Vector3(side * 0.18, 0.403, 0.021), 0.120 * build, 0.119],
		[Vector3(side * 0.18, 0.472, -0.001), 0.107 * build, 0.103],
		[Vector3(side * 0.18, 0.541, -0.009), 0.089 * build, 0.083],
	], leather)
	# Folded leather above the ankle and a separate patella cover disguise the hinge seam.
	for index in range(3):
		var y := 0.23 + float(index) * 0.024
		m.tube(shin, Vector3(side * 0.112, y, -0.054),
			Vector3(side * 0.249, y + 0.006, -0.055), 0.010, 0.006, cloth, 6)
	m.ellipsoid(shin, Vector3(side * 0.180, 0.510, -0.092),
		Vector3(0.156 * build, 0.116, 0.061), leather)
	# Heeled boots with a broad toe box, a tapered instep and a believable sole plane.
	var at := side * 0.18
	m.loft(foot, [
		[Vector3(at, 0.018, -0.075), 0.096 * build, 0.172],
		[Vector3(at, 0.033, -0.077), 0.111 * build, 0.182],
		[Vector3(at, 0.060, -0.077), 0.111 * build, 0.182],
		[Vector3(at, 0.082, -0.069), 0.106 * build, 0.170],
	], cloth, 16)
	m.loft(foot, [
		[Vector3(at, 0.057, -0.072), 0.106 * build, 0.172],
		[Vector3(at, 0.088, -0.076), 0.108 * build, 0.172],
		[Vector3(at, 0.123, -0.074), 0.101 * build, 0.161],
		[Vector3(at, 0.163, -0.041), 0.081 * build, 0.119],
		[Vector3(at, 0.198, -0.011), 0.074, 0.079],
		[Vector3(at, 0.232, -0.004), 0.072, 0.071],
	], leather, 16)
	m.ellipsoid(foot, Vector3(at, 0.113, -0.177),
		Vector3(0.169 * build, 0.066, 0.134), seam)
	for index in range(3):
		var y := 0.146 + float(index) * 0.023
		var z := -0.147 + float(index) * 0.021
		m.tube(foot, Vector3(at - 0.057, y, z), Vector3(at + 0.057, y - 0.012, z - 0.006),
			0.009, 0.008, cloth, 5)


static func _head(m, skin: String, cloth: String, face: Array, exposed: bool) -> void:
	var jaw: float = face[0]
	var cheek: float = face[1]
	var brow: float = face[2]
	var bridge: float = face[3]
	m.loft("head", [
		[Vector3(0, 1.492, 0.027), 0.083, 0.072],
		[Vector3(0, 1.539, 0.014), 0.084, 0.078],
		[Vector3(0, 1.590, 0.006), 0.080, 0.074],
		[Vector3(0, 1.637, 0.010), 0.092, 0.081],
	], cloth)
	m.loft("head", [
		[Vector3(0, 1.548, -0.044), 0.038 * jaw, 0.059],
		[Vector3(0, 1.581, -0.024), 0.077 * jaw, 0.095],
		[Vector3(0, 1.625, -0.006), 0.104 * jaw, 0.117],
		[Vector3(0, 1.679, 0.000), 0.127 * cheek, 0.128],
		[Vector3(0, 1.732, 0.001), 0.139 * cheek, 0.133],
		[Vector3(0, 1.784, 0.007), 0.132, 0.136],
		[Vector3(0, 1.826, 0.013), 0.118, 0.128],
		[Vector3(0, 1.875, 0.024), 0.083, 0.098],
		[Vector3(0, 1.896, 0.031), 0.034, 0.051],
	], skin, 16)
	if not exposed:
		return
	var shadow := Color(skin).darkened(0.33).to_html(false)
	var light := Color(skin).lightened(0.13).to_html(false)
	for side in [-1.0, 1.0]:
		m.ellipsoid("head", Vector3(side * 0.131, 1.678, -0.006),
			Vector3(0.042, 0.079, 0.042), shadow, Vector3(0, 0, side * 0.17))
		m.ellipsoid("head", Vector3(side * 0.084 * cheek, 1.668, -0.107),
			Vector3(0.078, 0.041, 0.058), skin, Vector3(0, side * -0.5, side * 0.18))
		m.ellipsoid("head", Vector3(side * 0.059, 1.719, -0.129),
			Vector3(0.068, 0.030, 0.025), shadow, Vector3(0, -side * 0.27, -side * brow))
		m.ellipsoid("head", Vector3(side * 0.059, 1.719, -0.143),
			Vector3(0.032, 0.011, 0.008), "817779")
		m.ellipsoid("head", Vector3(side * 0.057, 1.719, -0.148),
			Vector3(0.012, 0.011, 0.005), "18141e")
		m.tube("head", Vector3(side * 0.029, 1.739, -0.143),
			Vector3(side * 0.093, 1.748 + brow * 0.019, -0.117),
			0.009, 0.005, shadow, 6)
	m.tube("head", Vector3(0, 1.747, -0.133), Vector3(0, 1.671, -0.163 * bridge),
		0.019, 0.029, light, 7)
	m.ellipsoid("head", Vector3(0, 1.672, -0.156 * bridge),
		Vector3(0.063, 0.040, 0.046), skin)
	m.tube("head", Vector3(-0.037 * jaw, 1.624, -0.112),
		Vector3(0.037 * jaw, 1.625, -0.112), 0.009, 0.009, shadow, 7)
	m.ellipsoid("head", Vector3(0, 1.595, -0.086), Vector3(0.094 * jaw, 0.067, 0.062), skin)
