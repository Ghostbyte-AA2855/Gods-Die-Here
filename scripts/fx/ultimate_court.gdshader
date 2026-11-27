shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, fog_disabled, shadows_disabled;

uniform vec4 tint : source_color = vec4(1.0, 0.7, 0.2, 1.0);
uniform vec4 edge_ink : source_color = vec4(1.0, 0.26, 0.18, 1.0);
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float strength : hint_range(0.0, 1.0) = 1.0;
uniform float warning : hint_range(0.0, 1.0) = 1.0;
uniform float seed = 0.0;
uniform float line_half_length = 0.0;
uniform float line_half_width = 1.0;

float line_at(float position, float radius, float width) {
	float aa = max(fwidth(position) * 0.85, 0.005);
	return 1.0 - smoothstep(width - aa, width + aa, abs(position - radius));
}

void fragment() {
	vec2 at = UV * 2.0 - 1.0;
	vec2 from_path = at;
	if (line_half_length > 0.0) {
		from_path.y = sign(at.y) * max(0.0, abs(at.y) * (line_half_length + line_half_width) - line_half_length) / line_half_width;
	}
	float r = length(from_path);
	if (r > 1.0) {
		discard;
	}
	float angle = atan(at.x, -at.y);
	float clockwise = fract(angle / TAU + 0.5);
	float number_of_runes = 6.0 + mod(seed, 7.0);
	float sector = abs(fract(clockwise * number_of_runes) - 0.5);
	float gap = smoothstep(0.11, 0.18, sector);
	float border = line_at(r, 0.956, 0.019);
	float warning_outline = line_at(r, 0.954, 0.040);
	float track = line_at(r, 0.87, 0.017);
	float countdown = 1.0 - smoothstep(progress - 0.025, progress + 0.007, clockwise);
	float rune_r = 0.67 + sector * (0.21 + mod(seed, 4.0) * 0.027);
	float runes = line_at(r, rune_r, 0.018) * step(sector, 0.27);
	float core = line_at(r, 0.23 + sector * 0.29, 0.027) + line_at(r, 0.105, 0.023);
	float floor_burn = 1.0 - smoothstep(0.12, 0.98, r);
	float grit = sin(angle * 7.0 + r * 20.0 + seed) * sin(angle * 3.0 - r * 17.0);
	floor_burn *= 0.52 + 0.48 * grit;
	float theta = mod(seed, 3.0);
	float wave_radius = 0.07 + progress * (0.94 - theta * 0.036);
	float shock = line_at(r, wave_radius, 0.065 - 0.035 * progress);
	float caustic = line_at(r, max(0.01, wave_radius - 0.095), 0.018);

	float telegraph = max(border * (0.45 + 0.55 * gap), track * countdown);
	float warning_fill = min(0.36, (0.15 + 0.20 * progress) * floor_burn + 0.09 * (1.0 - r));
	float warning_glyph = max(0.50 * runes, 0.72 * core);
	float burn_glyph = max(0.54 * runes * (1.0 - progress), 0.35 * core);
	float burn = max(max(shock, caustic * 0.67), burn_glyph);
	float marker = mix(burn, max(telegraph, warning_glyph), warning);
	float alpha = (marker * 0.90 + mix(floor_burn * 0.23, warning_fill, warning) + warning_outline * warning * 0.52) * strength;

	vec3 dark = mix(edge_ink.rgb * 0.20, tint.rgb * 0.26, 1.0 - warning);
	vec3 marked = mix(tint.rgb, edge_ink.rgb, telegraph * warning * 0.82);
	vec3 white_hot = mix(marked, vec3(1.0, 0.96, 0.85), max(track * countdown * warning, shock * (1.0 - warning)) * 0.64);
	ALBEDO = mix(dark, white_hot, clamp(marker + floor_burn * 0.10, 0.0, 1.0));
	ALPHA = alpha;
}
