shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

uniform vec4 tint : source_color;
uniform int kind;
uniform int phase;
uniform vec2 flow;
uniform float until_change;

float band(float edge, float width) {
	return 1.0 - smoothstep(width * 0.42, width, abs(edge));
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float d = length(p);
	if (d > 1.0) { discard; }
	float angle = atan(p.y, p.x);
	float perimeter = band(d - 0.967, 0.021);
	float hatch = band(d - 0.91, 0.054) * smoothstep(0.40, 0.57, abs(sin(angle * 17.0 + d * 44.0)));
	float pulse = 0.64 + 0.36 * sin(TIME * 6.1 - d * 13.0);
	float ink;
	if (kind == 0) {
		float flame = fract(p.y * 5.1 + sin(p.x * 9.3 + p.y * 2.9) * 0.23 - TIME * 0.72);
		ink = band(flame - 0.5, 0.11) * pulse * smoothstep(0.18, 0.65, cos(p.x * 14.0 + p.y * 6.0));
	} else if (kind == 1) {
		vec2 axis = length(flow) > 0.001 ? normalize(flow) : vec2(1.0, 0.0);
		float along = dot(p, axis);
		float cross = dot(p, vec2(-axis.y, axis.x));
		ink = band(fract(2.35 * (along + abs(cross)) - TIME * 1.42) - 0.5, 0.13)
			* (1.0 - smoothstep(0.44, 0.59, abs(cross)));
	} else if (kind == 2) {
		float chevron = fract(3.8 * (p.y + abs(p.x)) - TIME * 0.38);
		ink = band(chevron - 0.5, 0.09) * (1.0 - smoothstep(0.58, 0.68, abs(p.x)));
	} else if (kind == 3) {
		vec2 drift = vec2(0.25 * cos(TIME * 1.1), 0.22 * sin(TIME * 1.1));
		ink = band(length(p - drift) - 0.56, 0.043) * 0.76;
		ink += band(d - 0.78, 0.037) * smoothstep(0.52, 0.85, sin(angle * 4.0 - TIME * 1.6));
	} else {
		float swell = fract(3.5 * p.y + 0.27 * sin(6.0 * p.x + TIME * 0.67) + TIME * 0.54);
		ink = band(swell - 0.5, 0.12) * 0.86;
	}

	float edge = smoothstep(0.0, 0.024, 1.0 - d);
	ALBEDO = tint.rgb;
	if (phase == 0) {
		ALPHA = edge * (perimeter * 0.10 + hatch * 0.065);
	} else if (phase == 1) {
		float warning = band(d - mix(0.96, 0.15, clamp(until_change * 0.5, 0.0, 1.0)), 0.042);
		ALPHA = edge * (0.035 + perimeter * 0.78 + hatch * 0.34 + warning * 0.64);
	} else {
		float highlight = max(ink, perimeter);
		ALBEDO = mix(tint.rgb, vec3(1.0, 0.95, 0.84), 0.24 * highlight);
		ALPHA = edge * (0.10 + highlight * 0.68 + 0.18 * hatch);
	}
}
