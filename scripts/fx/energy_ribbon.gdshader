shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, shadows_disabled, depth_draw_never, fog_disabled;

uniform vec4 tint : source_color = vec4(1.0);
uniform float opacity : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	float edge = abs(UV.y * 2.0 - 1.0);
	float silhouette = 1.0 - smoothstep(0.80, 1.0, edge);
	float body = 1.0 - smoothstep(0.47, 0.79, edge);
	float core = 1.0 - smoothstep(0.06, 0.40, edge);
	float glint = 0.5 + 0.5 * cos(UV.x * 14.0 - TIME * 11.0);
	vec3 shade = mix(vec3(0.016, 0.012, 0.022), tint.rgb, 0.16);
	vec3 bright = mix(tint.rgb, vec3(1.0), 0.55 + glint * 0.15);
	ALBEDO = mix(mix(shade, tint.rgb, body), bright, core);
	ALPHA = silhouette * opacity * tint.a;
}
