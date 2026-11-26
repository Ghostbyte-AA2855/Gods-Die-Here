shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec4 base : source_color;
uniform vec4 seam : source_color;
uniform vec4 inlay : source_color;
uniform int design;
varying vec2 tile_pos;

float hash21(vec2 cell) {
	vec3 n = fract(cell.xyx * 0.1031);
	n += dot(n, n.yzx + 33.33);
	return fract((n.x + n.y) * n.z);
}

float stone_noise(vec2 p) {
	vec2 lattice = floor(p);
	vec2 uv = fract(p);
	uv *= uv * (3.0 - 2.0 * uv);
	return mix(
		mix(hash21(lattice), hash21(lattice + vec2(1.0, 0.0)), uv.x),
		mix(hash21(lattice + vec2(0.0, 1.0)), hash21(lattice + vec2(1.0)), uv.x),
		uv.y
	);
}

float engraved(float distance_to_edge, float width) {
	float edge_softness = clamp(fwidth(distance_to_edge), 0.004, width * 1.4);
	return 1.0 - smoothstep(width - edge_softness, width + edge_softness, distance_to_edge);
}

void vertex() {
	tile_pos = VERTEX.xz;
}

void fragment() {
	vec2 p = tile_pos;
	float stain = stone_noise(p * 0.61);
	float grain = stone_noise(p * 7.0);
	float grit = hash21(floor(p * 20.0));
	float worn = clamp(stain * 0.70 + grain * 0.23 + grit * 0.07, 0.0, 1.0);
	float radius = length(p);
	float radial_fade = mix(1.04, 0.78, smoothstep(7.0, 15.0, radius));
	vec3 face = base.rgb * radial_fade * (0.71 + 0.53 * worn);
	float metal = 0.02;
	float rough = 0.86;
	float mark = 0.0;
	float tile = 1.0;

	if (design == 3) {
		float seam_curve = p.y * 0.51 + p.x * 0.24 + (stone_noise(p * 0.7) - 0.5) * 0.24;
		float mineral_vein = abs(fract(seam_curve) - 0.5);
		float dark_layer = engraved(mineral_vein, 0.028);
		float quartz_edge = engraved(abs(mineral_vein - 0.062), 0.008) * stain;
		face = mix(face, seam.rgb, dark_layer * 0.54);
		face = mix(face, inlay.rgb, quartz_edge * 0.28);
	} else {
		vec2 dimensions = vec2(1.9, 1.12);
		if (design == 0) { dimensions = vec2(2.28, 1.37); }
		if (design == 2) { dimensions = vec2(1.18, 1.03); }
		if (design == 4) { dimensions = vec2(2.82, 2.82); }
		vec2 block_pos = p / dimensions;
		block_pos.x += design == 4 ? 0.0 : 0.5 * mod(floor(block_pos.y), 2.0);
		float cell_tint = hash21(floor(block_pos));
		vec2 local_pos = fract(block_pos);
		vec2 edge = min(local_pos, 1.0 - local_pos);
		float grout = min(edge.x, edge.y) + (grain - 0.55) * 0.034;
		float groove_width = max(fwidth(grout), 0.006);
		tile = smoothstep(0.019 - groove_width, 0.027 + groove_width, grout);
		float bevel = 1.0 - smoothstep(0.035, 0.09, grout);
		float top_left = step(local_pos.x + local_pos.y, 1.0);
		face *= 0.86 + 0.24 * cell_tint + (top_left * 0.31 - 0.19) * bevel;
		face = mix(seam.rgb, face, tile);
		if (design == 0) {
			rough = 0.72;
			float pooled = smoothstep(0.50, 0.86, stain) * tile;
			face = mix(face, face * vec3(0.80, 0.93, 1.02), pooled * 0.45);
			rough -= 0.25 * pooled;
		} else if (design == 1) {
			face = mix(face, face * vec3(1.28, 0.72, 0.57), smoothstep(0.46, 0.84, stain) * tile * 0.50);
			mark = engraved(abs(abs(p.x) - 3.60), 0.022) * smoothstep(6.7, 9.0, abs(p.y));
		} else if (design == 2) {
			float path = min(abs(p.x * 0.65 + p.y * 0.76 + 0.58 * sin(p.x * 0.39)), abs(-p.x * 0.65 + p.y * 0.76 - 0.63 * sin(p.x * 0.39)));
			float moss = smoothstep(0.54, 0.79, stain * 0.58 + grain * 0.42 + smoothstep(0.54, 2.6, path) * 0.16);
			vec3 loam = face * vec3(1.28, 1.0, 0.77);
			face = mix(loam, face * vec3(0.76, 1.04, 0.66), moss * 0.89);
		} else {
			rough = 0.62 - stain * 0.17;
			float ecliptic = min(abs(radius - 5.28), min(abs(radius - 8.05), abs(radius - 11.80)));
			float degree_mark = abs(sin(atan(p.y, p.x) * 16.0)) * radius * 0.0625;
			mark = max(engraved(ecliptic, 0.023), engraved(degree_mark, 0.019) * (1.0 - smoothstep(0.11, 0.37, ecliptic)));
			mark = max(mark, engraved(abs(radius - 11.63), 0.018));
		}
	}
	ALBEDO = mix(face, inlay.rgb * (0.72 + 0.48 * worn), mark * 0.67);
	ROUGHNESS = clamp(mix(0.95, rough - grain * 0.075, tile), 0.31, 0.98);
	METALLIC = metal + mark * 0.33;
	SPECULAR = 0.30;
}
