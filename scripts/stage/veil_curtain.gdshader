shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, fog_disabled;

uniform vec4 tint : source_color;

void fragment() {
	float height = 1.0 - UV.y;
	float soft_edge = smoothstep(0.0, 0.08, height) * (1.0 - smoothstep(0.56, 1.0, height));
	float sway = sin(UV.x * TAU * 8.0 - TIME * 1.1 + height * 4.0);
	float folds = smoothstep(0.38, 0.96, sway);
	float drift = 0.65 + 0.35 * sin(TIME * 1.3 + UV.x * TAU * 7.0 + height * 6.0);
	float gleam = sin(UV.x * TAU * 18.0 + TIME * 0.38 - height * 4.0);
	float threads = smoothstep(0.88, 1.0, gleam) * folds;
	ALBEDO = mix(tint.rgb * 0.40, tint.rgb, folds * 0.6 + threads * 0.4);
	ALPHA = soft_edge * (0.035 + folds * 0.075 + threads * 0.105) * drift;
}
