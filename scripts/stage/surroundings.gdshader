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
	vec3 ambient = vec3(0.0);
	if (design == 0) {
		float ripple_a = cos(p.y * 7.8 + 2.2 * sin(p.x * 0.71 + TIME * 0.72) - TIME * 1.1);
		float ripple_b = sin(p.y * 6.3 - p.x * 2.1 + 1.6 * sin(p.x * 1.31 + TIME * 0.84) - TIME * 1.6);
		float glint = smoothstep(0.68, 0.97, ripple_a * 0.72 + ripple_b * 0.28) * cloud;
		float shoal = smoothstep(0.54, 0.81, cloud) * smoothstep(0.60, 0.89, ripple_b);
		floor_tone = mix(floor_tone, base.rgb * vec3(0.71, 1.43, 1.50), shoal * (1.0 - depth) * 0.42);
		floor_tone += vec3(0.11, 0.28, 0.36) * glint;
		ambient = vec3(0.025, 0.071, 0.081) * glint * (1.0 - depth);
		ROUGHNESS = 0.24 + 0.26 * grain;
	} else if (design == 1) {
		float slag = smoothstep(0.77, 0.91, grain * 0.8 + cloud * 0.38);
		float heat = 0.6 + 0.4 * cos(TIME * 0.7 + p.y * 0.31 + p.x * 0.2);
		floor_tone += vec3(0.23, 0.058, 0.014) * slag * heat;
		ambient = vec3(0.17, 0.021, 0.006) * slag * heat * (1.0 - depth);
	} else if (design == 2) {
		float litter = smoothstep(0.79, 0.94, grain) * (0.30 + 0.70 * cloud);
		floor_tone = mix(floor_tone, vec3(0.36, 0.23, 0.11), litter * 0.54);
		floor_tone *= 0.80 + 0.29 * smoothstep(0.20, 0.67, cloud);
	} else if (design == 3) {
		float strata = fract(p.y * 0.79 + p.x * 0.25 + cloud * 1.6);
		float layer_edge = 1.0 - smoothstep(0.031, 0.071, abs(strata - 0.25));
		floor_tone = mix(floor_tone, vec3(0.22, 0.19, 0.135), layer_edge * grain * 0.44);
	} else if (design == 4) {
		vec2 scrawl = p * 0.64;
		float star = hash21(floor(scrawl));
		vec2 centered = fract(scrawl) - 0.5;
		float pin = (1.0 - smoothstep(0.025, 0.092, length(centered))) * smoothstep(0.69, 0.98, star);
		float vapor = smoothstep(0.45, 0.84, cloud) * (0.55 + grain * 0.45);
		floor_tone += vec3(0.046, 0.045, 0.096) * vapor;
		ambient = vec3(0.22, 0.24, 0.50) * pin * (0.55 + 0.45 * sin(TIME * 1.08 + star * TAU));
	}
	ALBEDO = floor_tone * (1.0 - depth * 0.62);
	EMISSION = ambient * (1.0 - depth * 0.72);
}
