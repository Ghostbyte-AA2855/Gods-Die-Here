shader_type spatial;

uniform vec4 stone : source_color = vec4(0.29, 0.28, 0.31, 1.0);
uniform float plate_metal = 0.0;
uniform int finish = 0;
varying vec3 world;
varying vec3 face;

float fleck(vec2 cell) {
	vec3 key = fract(cell.xyx * vec3(0.1031, 0.1030, 0.0973));
	key += dot(key, key.yzx + 33.33);
	return fract((key.x + key.y) * key.z);
}

float stone_noise(vec2 point) {
	vec2 cell = floor(point);
	vec2 corner = fract(point);
	vec2 weight = corner * corner * (3.0 - 2.0 * corner);
	float straight = mix(fleck(cell), fleck(cell + vec2(1.0, 0.0)), weight.x);
	float offset = mix(fleck(cell + vec2(0.0, 1.0)), fleck(cell + 1.0), weight.x);
	return mix(straight, offset, weight.y);
}

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	face = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
	vec3 normal_axis = abs(normalize(face));
	vec2 side = mix(world.xy, world.zy, step(normal_axis.z, normal_axis.x));
	float top = smoothstep(0.53, 0.87, normal_axis.y);
	vec2 surface = mix(side, world.xz, top);
	float weather = stone_noise(surface * 1.13);
	float tooth = stone_noise(surface * 7.8);
	float moisture = 1.0 - smoothstep(-0.57, 0.77, world.y + weather * 0.48);
	vec3 tone = stone.rgb * (0.74 + weather * 0.36 + tooth * 0.22);
	ROUGHNESS = 0.83 + tooth * 0.14;
	SPECULAR = 0.28;

	if (finish == 0) {
		vec2 course = side * vec2(0.74, 1.53);
		course.x += mod(floor(course.y), 2.0) * 0.5;
		vec2 joints = 0.5 - abs(fract(course) - 0.5);
		float cut = min(joints.x * 1.6, joints.y) + (tooth - 0.5) * 0.027;
		float mortar = 1.0 - smoothstep(0.015, 0.041, cut);
		float rim = (smoothstep(0.012, 0.042, cut) - smoothstep(0.040, 0.074, cut)) * (1.0 - top);
		tone *= 1.0 - mortar * (1.0 - top) * 0.50;
		tone += stone.rgb * rim * 0.18;
		tone = mix(tone, tone * vec3(0.63, 0.70, 0.72), moisture * 0.43);
	} else if (finish == 1) {
		float oxidation = smoothstep(0.42, 0.76, weather * 0.71 + tooth * 0.29);
		float scratch = smoothstep(0.75, 0.96, stone_noise(surface * vec2(39.0, 3.0)));
		tone = mix(tone, tone * vec3(0.63, 0.81, 0.76), oxidation * 0.63);
		tone += stone.rgb * scratch * 0.32;
		ROUGHNESS = 0.43 + oxidation * 0.37;
		METALLIC = plate_metal;
		SPECULAR = 0.46;
	} else if (finish == 2) {
		float fibers = stone_noise(surface * vec2(24.0, 1.7));
		tone *= 0.64 + fibers * 0.54 + weather * 0.15;
		tone *= 1.0 - moisture * 0.13;
	} else {
		float breaks = smoothstep(0.50, 0.82, weather * 0.73 + tooth * 0.27);
		tone *= 0.88 + 0.24 * breaks;
	}
	ALBEDO = tone;
}
