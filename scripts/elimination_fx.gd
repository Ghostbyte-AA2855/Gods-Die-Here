extends Node3D

var _blood: StandardMaterial3D
var _clot: StandardMaterial3D


func _ready() -> void:
	_blood = _material(Color("981328"))
	_clot = _material(Color("430d17"))


func play(pawn: Dictionary, at: Vector3, facing: Vector2, full_detail: bool) -> void:
	var scene := Node3D.new()
	add_child(scene)
	scene.position = at
	var live_rig: Node3D = pawn.rig
	var fallen := live_rig.duplicate() as Node3D
	scene.add_child(fallen)
	fallen.transform = live_rig.transform
	var heading := Vector3(facing.x, 0.0, facing.y)
	if heading.length_squared() < 0.1:
		heading = Vector3.FORWARD
	var axis := Vector3.UP.cross(heading).normalized()
	var rest := fallen.basis
	var flip := fallen.create_tween().set_parallel()
	flip.tween_method(func(t: float): fallen.basis = Basis(axis, -1.45 * t) * rest,
		0.0, 1.0, 0.41).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	flip.tween_property(fallen, "position", -heading * 0.48 + Vector3.UP * 0.30, 0.41)
	if full_detail:
		_burst(scene, heading)
	scene.create_tween().tween_interval(3.6).finished.connect(scene.queue_free)


func clear() -> void:
	for body in get_children():
		remove_child(body)
		body.queue_free()


func _burst(scene: Node3D, heading: Vector3) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var stains := Node3D.new()
	scene.add_child(stains)
	for i in 14:
		var offset := -heading * 0.35 + Vector3(rng.randf_range(-0.69, 0.69), 0.014 + i * 0.0004, rng.randf_range(-0.6, 0.6))
		var width := rng.randf_range(0.14, 0.49)
		_blob(stains, offset, Vector3(width, 0.009, width * rng.randf_range(0.5, 1.5)), _clot if i % 3 else _blood)
	stains.scale = Vector3(0.15, 1.0, 0.15)
	stains.create_tween().tween_property(stains, "scale", Vector3.ONE, 0.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	for i in 7:
		var fragment := _blob(scene, Vector3.UP * 1.11, Vector3(0.09, 0.065, 0.125), _clot)
		var direction := Vector3(rng.randf_range(-1.0, 1.0), 0.0, rng.randf_range(-1.0, 1.0)).normalized()
		var far := direction * rng.randf_range(0.48, 1.38)
		var spin := Vector3(rng.randf_range(1.0, 6.0), rng.randf_range(2.5, 6.5), 0.0)
		fragment.create_tween().tween_method(func(t: float):
			fragment.position = Vector3.UP * (lerpf(1.11, 0.05, t) + 0.72 * sin(t * PI)) + far * t
			fragment.rotation = spin * t,
			0.0, 1.0, 0.49)
	for i in 24:
		var start := Vector3(0, rng.randf_range(0.83, 1.48), 0)
		var travel := -heading * rng.randf_range(0.25, 1.7) + Vector3(rng.randf_range(-1.8, 1.8), 0.025, rng.randf_range(-1.6, 1.6))
		var drop := _blob(scene, start, Vector3(0.036, rng.randf_range(0.055, 0.13), 0.036), _blood)
		var jump := rng.randf_range(0.28, 1.12)
		var duration := rng.randf_range(0.29, 0.62)
		drop.create_tween().tween_method(func(t: float):
			drop.position = start.lerp(travel, t) + Vector3.UP * sin(t * PI) * jump
			drop.rotation.z = t * 8.0,
			0.0, 1.0, duration).finished.connect(func():
				var width := rng.randf_range(0.038, 0.10)
				drop.scale = Vector3(width, 0.008, width * 1.55)
				drop.rotation = Vector3.ZERO)


func _blob(parent: Node3D, at: Vector3, dimensions: Vector3, material: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radial_segments = 7
	mesh.rings = 4
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	instance.scale = dimensions
	parent.add_child(instance)
	return instance


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.36
	return material
