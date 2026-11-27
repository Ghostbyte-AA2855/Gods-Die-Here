shader_type spatial;
render_mode cull_disabled;

uniform vec4 blaze : source_color = vec4(1.0, 0.39, 0.075, 1.0);
varying vec3 object_point;

void vertex() {
	object_point = VERTEX;
}

float hash_at(vec2 point) {
	return fract(sin(dot(point, vec2(91.53, 159.71))) * 42758.56);
}

float mineral(vec2 point) {
	vec2 cell = floor(point);
	vec2 offset = fract(point);
	vec2 smooth_offset = offset * offset * (3.0 - 2.0 * offset);
	return mix(mix(hash_at(cell), hash_at(cell + vec2(1.0, 0.0)), smooth_offset.x),
		mix(hash_at(cell + vec2(0.0, 1.0)), hash_at(cell + vec2(1.0, 1.0)), smooth_offset.x),
		smooth_offset.y);
}

void fragment() {
	vec2 surface_point = vec2(object_point.x + object_point.z * 0.71, object_point.y + object_point.z * 0.32);
	float surface_rough = mineral(surface_point * 11.3);
	float strata = mineral(surface_point * 3.6);
	float brushed = mineral(surface_point * vec2(42.0, 11.0));
	float wobble = (strata - 0.5) * 0.32;
	float split = min(abs(surface_point.y - (0.27 * sin(surface_point.x * 3.1) - 0.08 + wobble)),
		abs(surface_point.x + (surface_point.y - 0.49) * 1.43 + 0.61 + wobble));
	float recent = 1.0 - smoothstep(0.016, 0.044, split);
	float old = 1.0 - smoothstep(0.036, 0.085, split);
	float core = 1.0 - smoothstep(0.006, 0.014, split);
	float flicker = 0.84 + 0.16 * sin(TIME * 14.0 + strata * 10.0);
	vec3 iron = vec3(0.08, 0.055, 0.048) + vec3(0.16, 0.11, 0.067) * brushed * strata;
	ALBEDO = mix(iron, blaze.rgb * 0.62, old);
	ROUGHNESS = mix(0.43, 0.77, surface_rough);
	METALLIC = 0.32 * (1.0 - old);
	EMISSION = (blaze.rgb * (old * 0.12 + recent * 0.64) + vec3(1.0, 0.85, 0.62) * core * 0.53) * flicker;
}
