extends RefCounted

const SIZE := 128
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
	material.normal_scale = 0.76 if forged else 0.42
	material.metallic_specular = 0.65 if forged else 0.32
	if forged:
		material.metallic *= 0.88


static func _make_finish(result: Array[ImageTexture], forged: bool) -> void:
	var staining := FastNoiseLite.new()
	staining.seed = 356 if forged else 580
	staining.frequency = 0.043
	var grain := FastNoiseLite.new()
	grain.seed = 971 if forged else 901
	grain.frequency = 0.22 if forged else 0.19
	var tint := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGB8)
	var roughness := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGB8)
	var normals := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGB8)
	var height := PackedFloat32Array()
	height.resize(SIZE * SIZE)
	for y in SIZE:
		for x in SIZE:
			var broad := _tile(staining, x, y)
			var fine := _tile(grain, x, y)
			var worn := _stamped_iron(x, y, broad, fine) if forged else _woven_hide(x, y, broad, fine)
			height[y * SIZE + x] = worn.z
			var brightness := worn.x
			var rough := worn.y
			var oxide := smoothstep(-0.48, 0.25, -broad)
			var warm := oxide * (0.12 if forged else 0.04)
			tint.set_pixel(x, y, Color(brightness, brightness * (1.0 - warm * 0.37), brightness * (1.0 - warm)))
			roughness.set_pixel(x, y, Color(rough, rough, rough))
	for y in SIZE:
		for x in SIZE:
			var dx := height[y * SIZE + (x + 1) % SIZE] - height[y * SIZE + posmod(x - 1, SIZE)]
			var dy := height[((y + 1) % SIZE) * SIZE + x] - height[posmod(y - 1, SIZE) * SIZE + x]
			var normal := Vector3(-dx, dy, 2.0).normalized()
			normals.set_pixel(x, y, Color(normal.x * 0.5 + 0.5, normal.y * 0.5 + 0.5, normal.z * 0.5 + 0.5))
	tint.generate_mipmaps()
	roughness.generate_mipmaps()
	normals.generate_mipmaps(true)
	result.append(ImageTexture.create_from_image(tint))
	result.append(ImageTexture.create_from_image(roughness))
	result.append(ImageTexture.create_from_image(normals))


static func _stamped_iron(x: int, y: int, broad: float, fine: float) -> Vector3:
	# Bright faces catch the light. Corroded hammer pits stay matte, and a few
	# shallow file marks run past them rather than forming a repeating grid.
	var pits := smoothstep(0.10, 0.55, -fine)
	var polish := smoothstep(-0.35, 0.46, broad)
	var stripe := absf(sin(TAU * (6 * x + 11 * y) / SIZE + broad))
	var scratches := smoothstep(0.79, 1.0, stripe) * smoothstep(0.07, 0.43, fine + broad * 0.28)
	var brightness := clampf(0.81 + polish * 0.21 - pits * 0.23 + scratches * 0.11, 0.59, 1.0)
	var roughness := clampf(0.62 - polish * 0.27 + pits * 0.18 - scratches * 0.08, 0.30, 0.83)
	return Vector3(brightness, roughness, fine * 0.38 - pits * 0.34 - scratches * 0.15 + broad * 0.25)


static func _woven_hide(x: int, y: int, broad: float, fine: float) -> Vector3:
	var warp := sin(TAU * float(x * 24) / SIZE)
	var weft := sin(TAU * float(y * 24) / SIZE)
	var weave := maxf(warp, weft) * 0.62 + warp * weft * 0.38
	var flecks := smoothstep(0.16, 0.57, -fine)
	var brightness := clampf(0.91 + broad * 0.16 + weave * 0.048 - flecks * 0.10, 0.65, 1.0)
	var roughness := clampf(0.79 - broad * 0.14 + weave * 0.04 + flecks * 0.08, 0.65, 0.96)
	return Vector3(brightness, roughness, weave * 0.12 + fine * 0.19 + broad * 0.14)


static func _tile(source: FastNoiseLite, x: int, y: int) -> float:
	var across := float(x) / SIZE
	var down := float(y) / SIZE
	var top := lerpf(source.get_noise_2d(x, y), source.get_noise_2d(x - SIZE, y), across)
	var bottom := lerpf(source.get_noise_2d(x, y - SIZE), source.get_noise_2d(x - SIZE, y - SIZE), across)
	return lerpf(top, bottom, down)
