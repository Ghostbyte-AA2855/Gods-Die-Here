shader_type spatial;

uniform vec4 base : source_color;
uniform int design;
varying vec2 terrain;

float hash21(vec2 cell) {
	vec3 t = fract(cell.xyx * 0.1031);
	t += dot(t, t.yzx + 33.33);
	return fract((t.x + t.y) * t.z);
}

float noise21(vec2 p) {
	vec2 cell = floor(p);
	vec2 local = smoothstep(vec2(0.0), vec2(1.0), fract(p));
	return mix(
		mix(hash21(cell), hash21(cell + vec2(1.0, 0.0)), local.x),
		mix(hash21(cell + vec2(0.0, 1.0)), hash21(cell + vec2(1.0)), local.x),
		local.y
	);
}

void vertex() {
	terrain = VERTEX.xz;
}

void fragment() {
	vec2 p = terrain;
	float depth = smoothstep(12.0, 34.0, length(p));
	float cloud = noise21(p * 0.23);
	float grain = noise21(p * 2.3);
	vec3 floor_tone = base.rgb * (0.48 + cloud * 0.65 + grain * 0.22);
	ROUGHNESS = 0.90;
	SPECULAR = 0.22;
	if (design == 0) {
		float ripple_a = cos(p.y * 8.2 + 2.2 * sin(p.x * 0.71 + TIME * 0.72) - TIME * 1.1);
		float ripple_b = sin(p.y * 5.7 - p.x * 2.1 + 1.6 * sin(p.x * 1.31 + TIME * 0.84) - TIME * 1.6);
		float glint = smoothstep(0.65, 1.0, ripple_a * 0.75 + ripple_b * 0.25) * cloud;
		floor_tone += vec3(0.12, 0.31, 0.42) * glint * (1.0 - depth * 0.85);
		ROUGHNESS = 0.24 + 0.26 * grain;
	} else if (design == 1) {
		float slag = smoothstep(0.77, 0.88, grain * 0.8 + cloud * 0.38);
		floor_tone += vec3(0.23, 0.027, 0.009) * slag * (0.40 + 0.60 * sin(TIME * 0.58 + p.y) * sin(TIME * 0.58 + p.y));
	} else if (design == 4) {
		float seams = 1.0 - smoothstep(0.035, 0.070, abs(fract(cos(p.x * 0.45) * 0.3 + p.y * 0.7) - 0.5));
		floor_tone += vec3(0.09, 0.10, 0.17) * seams * cloud;
	}
	ALBEDO = floor_tone * (1.0 - depth * 0.62);
}
