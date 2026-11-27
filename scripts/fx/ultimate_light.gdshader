shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, fog_disabled, shadows_disabled;

uniform vec4 tint : source_color = vec4(1.0, 0.7, 0.2, 1.0);
uniform float strength : hint_range(0.0, 1.0) = 1.0;
uniform float phase = 0.0;

void fragment() {
	float across = abs(UV.y - 0.5) * 2.0;
	float envelope = 1.0 - smoothstep(0.51, 1.0, across);
	float white_core = 1.0 - smoothstep(0.04, 0.63, across);
	float band = 0.52 + 0.48 * pow(max(0.0, 0.5 + 0.5 * cos(TAU * (UV.x - phase))), 2.0);
	vec3 rim = tint.rgb * (0.39 + 0.53 * envelope);
	ALBEDO = mix(rim, mix(tint.rgb, vec3(1.0, 0.98, 0.92), 0.78), white_core * (0.70 + 0.30 * band));
	ALPHA = min(1.0, envelope * (0.71 + 0.29 * band)) * strength;
}
