shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, shadows_disabled, depth_draw_never, fog_disabled;

uniform vec4 tint : source_color = vec4(1.0);
uniform float opacity : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	float across = UV.y * 2.0 - 1.0;
	float edge = abs(across);
	float current = UV.x * TAU * 2.0 - TIME * 12.0;
	float glint = 0.5 + 0.5 * cos(current);
	float filament = abs(across - sin(current) * 0.135);
	float silhouette = 1.0 - smoothstep(0.79, 1.0, edge);
	float body = 1.0 - smoothstep(0.40, 0.84, edge);
	float core = 1.0 - smoothstep(0.065, 0.37, filament);
	float halo = (1.0 - smoothstep(0.030, 0.16, abs(edge - 0.64))) * (0.21 + 0.19 * glint);
	vec3 shade = mix(vec3(0.024, 0.015, 0.03), tint.rgb, 0.22);
	vec3 bright = mix(tint.rgb, vec3(1.0, 0.975, 0.92), 0.47 + glint * 0.24);
	ALBEDO = mix(mix(shade, tint.rgb, min(1.0, body + halo)), bright, core);
	ALPHA = silhouette * (0.80 + 0.20 * max(core, glint)) * opacity * tint.a;
}
