extends RefCounted

const Pantheon = preload("res://scripts/pantheon.gd")


static func dress(view, rig: Node3D, class_id: String) -> void:
	var god: Array = Pantheon.GODS[class_id]
	var color := Color(str(god[5]))
	var metal: StandardMaterial3D = view._material(Color("292431").lerp(color.darkened(0.72), 0.55))
	metal.metallic = 0.72
	metal.roughness = 0.31
	var bone: StandardMaterial3D = view._material(Color("c2aa8e").lerp(color, 0.23))
	var rune: StandardMaterial3D = view._material(color, color, true)
	var dark: StandardMaterial3D = view._material(Color("14121b"))
	# Overlapping plates leave the original joint meshes free to articulate.
	for side in [-1.0, 1.0]:
		for i in 3:
			var plate: MeshInstance3D = view._cone(rig, Vector3(side * (0.24 + 0.05 * i), 1.22 - 0.17 * i, -0.24), 0.05, 0.29 - 0.03 * i, 0.24, metal, 5)
			plate.rotation.z = side * (0.42 + i * 0.11)
		view._box(rig, Vector3(side * 0.13, 1.61, -0.235), Vector3(0.095, 0.026, 0.044), rune).rotate_z(side * 0.24)
		view._cone(rig, Vector3(side * 0.20, 0.72, 0.255), 0.055, 0.22, 0.92, dark, 4).rotate_z(side * 0.18)
	view._cone(rig, Vector3(0, 1.49, -0.202), 0.19, 0.065, 0.26, bone, 5)
	view._sphere(rig, Vector3(0, 1.11, -0.34), 0.094, rune)
	match str(god[6]):
		"crown", "embers", "icicles":
			var top := 0.48 if god[6] == "icicles" else 0.27
			for i in range(-2, 3):
				_spike(view, rig, Vector3(i * 0.105, 1.83 + (2 - abs(i)) * 0.045, -0.03), Vector3(i * 0.07, top - abs(i) * 0.035, 0.025), bone if god[6] == "crown" else rune, 0.071)
		"loom", "split", "moon":
			_arc(view, rig, Vector3(0, 1.59, 0.32), 0.57, 1.9 if god[6] == "split" else 3.95, bone)
			if god[6] == "loom":
				for i in range(-3, 4):
					_link(view, rig, Vector3(i * 0.14, 1.25, 0.35), Vector3(-i * 0.1, 2.10, 0.35), 0.018, rune)
			elif god[6] == "moon":
				_arc(view, rig, Vector3(0.1, 1.65, 0.33), 0.44, 2.8, rune)
		"kiln", "rods", "candles", "bells":
			for i in range(-2, 3):
				var height: float = 0.36 + absf(i) * 0.16
				var point := Vector3(i * 0.19, 1.48, 0.28)
				var thick := 0.105 if god[6] in ["kiln", "bells"] else 0.038
				_link(view, rig, point, point + Vector3(0, height, 0), thick, metal)
				view._sphere(rig, point + Vector3.UP * height, thick * 0.73, rune)
				if god[6] == "rods":
					view._ring(rig, point + Vector3.UP * height * 0.75, thick * 1.3, thick * 2.4, bone)
		"antlers", "fins", "wings":
			for side in [-1.0, 1.0]:
				for i in 4:
					var point := Vector3(side * (0.19 + i * 0.095), 1.63 + i * 0.105, 0.16)
					var direction := Vector3(side * (0.25 + i * 0.038), 0.24 + i * 0.049, 0.12)
					if god[6] == "wings":
						direction = Vector3(side * 0.62, 0.45 - i * 0.21, 0.28)
						point.y -= i * 0.22
					_spike(view, rig, point, direction, bone if god[6] == "antlers" else rune, 0.1 if god[6] == "wings" else 0.062)
		"prism":
			for i in range(7):
				var a := float(i) * TAU / 7.0
				var point := Vector3(cos(a) * 0.66, 1.56 + sin(a) * 0.61, 0.32)
				_spike(view, rig, point, Vector3(cos(a), sin(a), 0.0) * 0.32, rune, 0.084)
		"reliquary":
			for side in [-1.0, 1.0]:
				for i in 4:
					view._box(rig, Vector3(side * 0.38, 1.23 - i * 0.14, -0.19), Vector3(0.30, 0.038, 0.32), bone).rotate_z(side * 0.32)
			_spike(view, rig, Vector3(0, 1.79, 0), Vector3(0, 0.43, 0.08), rune, 0.195)
		"chains":
			for i in range(7):
				view._ring(rig, Vector3(0.39 - 0.12 * i, 1.59 - 0.11 * i, -0.29), 0.051, 0.082, bone).rotate_x(1.4 if i % 2 == 0 else 0.82)


static func _arc(view, rig: Node3D, center: Vector3, radius: float, span: float, material: Material) -> void:
	for i in range(11):
		var a := -span * 0.5 + span * float(i) / 11
		var b := a + span / 11
		_link(view, rig, center + Vector3(sin(a), cos(a), 0) * radius, center + Vector3(sin(b), cos(b), 0) * radius, 0.025, material)


static func _spike(view, rig: Node3D, start: Vector3, direction: Vector3, material: Material, width: float) -> void:
	var blade: MeshInstance3D = view._cone(rig, start + direction * 0.5, 0.0, width, direction.length(), material, 5)
	blade.quaternion = Quaternion(Vector3.UP, direction.normalized())


static func _link(view, rig: Node3D, start: Vector3, finish: Vector3, thickness: float, material: Material) -> void:
	var piece: MeshInstance3D = view._cylinder(rig, start.lerp(finish, 0.5), thickness, start.distance_to(finish), material, 6)
	piece.quaternion = Quaternion(Vector3.UP, (finish - start).normalized())
