shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, shadows_disabled, depth_draw_never, fog_disabled;

uniform vec4 tint : source_color = vec4(1.0);
uniform float opacity : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	float edge = abs(UV.y * 2.0 - 1.0);
	float glow = (1.0 - smoothstep(0.04, 1.0, edge));
	float core = (1.0 - smoothstep(0.0, 0.64, edge));
	ALBEDO = mix(tint.rgb, mix(tint.rgb, vec3(1.0), 0.21), core);
	ALPHA = (glow * 0.49 + core * 0.48) * opacity;
}
