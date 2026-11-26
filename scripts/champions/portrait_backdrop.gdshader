shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;

uniform vec4 patron_tint : source_color = vec4(0.65, 0.46, 0.56, 1.0);
uniform float stage_aspect = 1.5;
uniform float invocation = 0.0;
uniform bool dais_ground = false;

float grain(vec2 point) {
	return fract(sin(dot(point, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	float patina = grain(floor(UV * vec2(660.0, 500.0))) - 0.5;
	if (dais_ground) {
		vec2 ground = (UV - vec2(0.5)) * 14.0;
		float dist = length(ground * vec2(1.0, 0.72));
		float shade = exp(-dist * dist * 0.095) * smoothstep(1.18, 1.89, dist);
		float stone_join = 1.0 - smoothstep(0.007, 0.028, abs(fract((ground.x + ground.y) * 0.50) - 0.5));
		ALBEDO = vec3(0.036, 0.031, 0.047) + patron_tint.rgb * shade * (0.054 + 0.021 * invocation);
		ALBEDO += vec3(patina * 0.012 - stone_join * shade * 0.006);
	} else {
		vec2 point = (UV - vec2(0.5, 0.55)) * vec2(stage_aspect, 1.0);
		float edge = 1.0 - smoothstep(0.12, 0.89, length(point * vec2(1.15, 0.82)));
		vec2 query = point + vec2(0.16, 0.14);
		float upper_light = exp(-dot(query, query) * 4.1);
		float lower_haze = exp(-abs(point.y - 0.30) * 7.0 - abs(point.x) * 2.8);

		// Nested stone arches stay quiet behind the champion's weapon silhouette.
		float span = abs(point.x);
		float arch = length(vec2(span, max(-point.y - 0.02, 0.0) * 1.34));
		float outer_cut = 1.0 - smoothstep(0.003, 0.018, abs(arch - 0.465));
		float inner_cut = 1.0 - smoothstep(0.002, 0.014, abs(arch - 0.433));
		float seam = pow(abs(sin(point.y * 83.0 + span * 22.0)), 18.0);
		float recess = smoothstep(0.334, 0.42, span) * (1.0 - smoothstep(0.53, 0.68, span));
		vec3 stone = vec3(0.038, 0.032, 0.047);
		stone += vec3(0.038, 0.032, 0.047) * edge;
		stone += patron_tint.rgb * (0.064 * upper_light + (0.053 + invocation * 0.081) * lower_haze);
		stone += vec3(0.097, 0.066, 0.045) * edge * (outer_cut * 0.69 + inner_cut * 0.46);
		stone -= vec3(0.016, 0.016, 0.015) * recess * seam;
		ALBEDO = stone + patina * 0.011;
	}
}
