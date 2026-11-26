extends Node3D

const SURFACE := preload("res://scripts/fx/ground_contact.gdshader")
const MAX_MARKS := 12

var _mesh := QuadMesh.new()
var _marks: Array[Dictionary] = []
var _dust := Color("a99178")


func _ready() -> void:
	_mesh.size = Vector2(2.0, 2.0)
	set_process(false)


func set_surface_color(value: Color) -> void:
	_dust = value


func footstep(at: Vector3, heading: Vector2) -> void:
	_place(at, heading, Vector2(0.72, 1.02), 0.35, 0.0)


func dodge(origin: Vector3, landing: Vector3) -> void:
	var extension := landing - origin
	var distance := extension.length()
	if distance < 0.14:
		return
	_place(origin.lerp(landing, 0.46), Vector2(extension.x, extension.z), Vector2(1.18, distance + 0.68), 0.47, 1.0)


func hard_landing(at: Vector3, heading: Vector2) -> void:
	_place(at, heading, Vector2(2.0, 2.38), 0.56, 0.0)


func clear() -> void:
	for mark in _marks:
		mark.mesh.hide()
		mark.remaining = 0.0
	set_process(false)


func _process(delta: float) -> void:
	var running := false
	for mark in _marks:
		if mark.remaining <= 0.0:
			continue
		mark.remaining = maxf(0.0, mark.remaining - delta)
		if mark.remaining <= 0.0:
			mark.mesh.hide()
			continue
		var progress := 1.0 - float(mark.remaining) / float(mark.duration)
		mark.material.set_shader_parameter("progress", progress)
		running = true
	set_process(running)


func _place(at: Vector3, heading: Vector2, size: Vector2, seconds: float, skid: float) -> void:
	var mark: Dictionary
	for candidate in _marks:
		if mark.is_empty() or candidate.remaining < mark.remaining:
			mark = candidate
		if candidate.remaining <= 0.0:
			break
	if _marks.size() < MAX_MARKS and (mark.is_empty() or mark.remaining > 0.0):
		mark = _create_mark()
		_marks.append(mark)
	var mesh: MeshInstance3D = mark.mesh
	mesh.position = Vector3(at.x, 0.035, at.z)
	mesh.rotation = Vector3(-PI * 0.5, atan2(-heading.x, -heading.y), 0.0)
	mesh.scale = Vector3(size.x * 0.5, size.y * 0.5, 1.0)
	mesh.show()
	var color := _dust.lerp(Color("d4d9df"), skid * 0.42)
	mark.material.set_shader_parameter("dust_tint", color)
	mark.material.set_shader_parameter("progress", 0.0)
	mark.material.set_shader_parameter("skid", skid)
	mark.duration = seconds
	mark.remaining = seconds
	set_process(true)


func _create_mark() -> Dictionary:
	var mesh := MeshInstance3D.new()
	mesh.mesh = _mesh
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := ShaderMaterial.new()
	material.shader = SURFACE
	mesh.material_override = material
	add_child(mesh)
	return {"mesh": mesh, "material": material, "remaining": 0.0, "duration": 1.0}
