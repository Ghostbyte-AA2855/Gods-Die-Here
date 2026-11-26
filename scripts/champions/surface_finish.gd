extends RefCounted

const SIZE := 96
static var _metal: Array[ImageTexture] = []
static var _hide: Array[ImageTexture] = []


static func weather(material: StandardMaterial3D, forged: bool) -> void:
	var finish: Array[ImageTexture] = _metal if forged else _hide
	if finish.is_empty():
		_make_finish(finish, forged)
	material.albedo_texture = finish[0]
	material.roughness = 1.0
	material.roughness_texture = finish[1]
	material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	material.normal_enabled = true
	material.normal_texture = finish[2]
	material.normal_scale = 0.48 if forged else 0.29


static func _make_finish(result: Array[ImageTexture], forged: bool) -> void:
	var staining := FastNoiseLite.new()
	staining.seed = 356 if forged else 580
	staining.frequency = 0.043
	var grain := FastNoiseLite.new()
	grain.seed = 971 if forged else 901
	grain.frequency = 0.18
	var tint := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGB8)
	var roughness := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGB8)
	var normals := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGB8)
	for y in SIZE:
		for x in SIZE:
			var broad := _tile(staining, x, y, 1.0, 1.0)
			var fine := _tile(grain, x, y, 3.1 if forged else 1.8, 0.54 if forged else 1.8)
			var detail := absf(sin(TAU * x / 3.0) * sin(TAU * y / 4.0)) if not forged else 0.0
			var brightness := clampf(0.87 + broad * 0.21 + fine * 0.12 - detail * 0.055, 0.55, 1.0)
			var rough := clampf((0.52 if forged else 0.83) - broad * 0.19 + detail * 0.06 + fine * 0.065, 0.32, 0.95)
			var grain_x := 3.1 if forged else 1.8
			var grain_y := 0.54 if forged else 1.8
			var dhx := _tile(grain, x + 1, y, grain_x, grain_y) - fine
			var dhy := _tile(grain, x, y + 1, grain_x, grain_y) - fine
			var normal := Vector3(-dhx * 0.42, dhy * 0.42, 1.0).normalized()
			normals.set_pixel(x, y, Color(normal.x * .5 + .5, normal.y * .5 + .5, normal.z * .5 + .5))
			tint.set_pixel(x, y, Color(brightness, brightness, brightness))
			roughness.set_pixel(x, y, Color(rough, rough, rough))
	tint.generate_mipmaps()
	roughness.generate_mipmaps()
	normals.generate_mipmaps(true)
	result.append(ImageTexture.create_from_image(tint))
	result.append(ImageTexture.create_from_image(roughness))
	result.append(ImageTexture.create_from_image(normals))


static func _tile(source: FastNoiseLite, x: int, y: int, stretch_x: float, stretch_y: float) -> float:
	var across := float(x) / SIZE
	var down := float(y) / SIZE
	var sample_x := x * stretch_x
	var sample_y := y * stretch_y
	var top := lerpf(source.get_noise_2d(sample_x, sample_y), source.get_noise_2d(sample_x - SIZE * stretch_x, sample_y), across)
	var bottom := lerpf(source.get_noise_2d(sample_x, sample_y - SIZE * stretch_y), source.get_noise_2d(sample_x - SIZE * stretch_x, sample_y - SIZE * stretch_y), across)
	return lerpf(top, bottom, down)
