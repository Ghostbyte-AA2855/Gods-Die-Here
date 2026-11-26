shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, fog_disabled;

uniform vec4 tint : source_color;
uniform int kind;
uniform int phase;
uniform vec2 flow;
uniform float warning_fraction;

float band(float distance_to_edge, float width) {
	float softness = clamp(fwidth(distance_to_edge), 0.002, width * 0.75);
	return 1.0 - smoothstep(width - softness, width + softness, abs(distance_to_edge));
}

float segment(vec2 point, vec2 start, vec2 end) {
	vec2 edge = end - start;
	vec2 offset = point - start;
	return length(offset - edge * clamp(dot(offset, edge) / dot(edge, edge), 0.0, 1.0));
}

float arrow(vec2 p, float reach) {
	float head = min(
		segment(p, vec2(reach - 0.22, -0.22), vec2(reach, 0.0)),
		segment(p, vec2(reach - 0.22, 0.22), vec2(reach, 0.0))
	);
	return min(head, segment(p, vec2(-reach, 0.0), vec2(reach, 0.0)));
}

float fire_sign(vec2 p) {
	float crown = min(
		segment(p, vec2(-0.37, 0.12), vec2(-0.17, -0.23)),
		segment(p, vec2(-0.17, -0.23), vec2(-0.08, -0.05))
	);
	crown = min(crown, segment(p, vec2(-0.08, -0.05), vec2(0.05, -0.55)));
	crown = min(crown, segment(p, vec2(0.05, -0.55), vec2(0.38, 0.03)));
	float bowl = min(
		segment(p, vec2(0.38, 0.03), vec2(0.27, 0.32)),
		segment(p, vec2(0.27, 0.32), vec2(0.0, 0.43))
	);
	bowl = min(bowl, segment(p, vec2(0.0, 0.43), vec2(-0.29, 0.32)));
	bowl = min(bowl, segment(p, vec2(-0.29, 0.32), vec2(-0.37, 0.12)));
	float heart = min(
		segment(p, vec2(-0.14, 0.24), vec2(0.03, 0.00)),
		segment(p, vec2(0.03, 0.00), vec2(0.16, 0.24))
	);
	return min(min(crown, bowl), heart);
}

float slab_sign(vec2 p) {
	float ascent = arrow(vec2(-p.y - 0.17, p.x), 0.32);
	float base = segment(p, vec2(-0.43, 0.48), vec2(0.43, 0.48));
	float step_edge = min(
		segment(p, vec2(-0.34, 0.32), vec2(0.34, 0.32)),
		segment(p, vec2(-0.25, 0.21), vec2(0.25, 0.21))
	);
	return min(ascent, min(base, step_edge));
}

float veil_sign(vec2 p) {
	float eye = max(
		abs(abs(p.y) - max(0.0, 0.26 - p.x * p.x * 0.95)),
		abs(p.x) - 0.52
	);
	float pupil = abs(length(p) - 0.105);
	float slash = segment(p, vec2(-0.50, 0.40), vec2(0.50, -0.40));
	return min(min(eye, pupil), slash);
}

float tide_sign(vec2 p) {
	float wave = min(abs(p.y + 0.42 - sin(p.x * 8.4) * 0.057), abs(p.y + 0.21 - sin(p.x * 8.4) * 0.057));
	wave = max(wave, abs(p.x) - 0.49);
	float down = arrow(vec2(p.y - 0.23, p.x), 0.23);
	return min(wave, down);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float radius = length(p);
	if (radius > 1.0) { discard; }

	// The outer rim tracks the simulation radius. Thick dashed marks warn;
	// two continuous rims mean the area is already affecting the fight.
	float angle = atan(p.x, -p.y);
	float around = fract(angle / TAU);
	float rim = band(radius - 0.960, 0.029);
	float under = band(radius - 0.938, 0.063);
	float ticks = smoothstep(0.26, 0.36, fract(around * 16.0));
	float inner_rim = band(radius - 0.852, 0.012);
	float countdown = step(around + 0.002, warning_fraction) * band(radius - 0.826, 0.018);
	float active_fade = 0.82 + 0.18 * sin(TIME * 2.3 - radius * 5.0);
	float glyph_distance = 2.0;
	float texture_ink = 0.0;

	if (kind == 0) {
		glyph_distance = fire_sign(p);
		float ember = sin(18.0 * p.x + sin(p.y * 7.0 - TIME * 2.0) * 1.25) * cos(p.y * 23.0 - TIME * 3.0);
		texture_ink = smoothstep(0.55, 0.89, ember) * smoothstep(0.64, 0.78, radius);
	} else if (kind == 1) {
		vec2 axis = length(flow) > 0.001 ? normalize(flow) : vec2(1.0, 0.0);
		vec2 travel = vec2(dot(p, axis), dot(p, vec2(-axis.y, axis.x)));
		glyph_distance = arrow(travel, 0.56);
		float wisp = abs(fract((travel.x + abs(travel.y) * 0.65) * 2.3 - TIME * 1.1) - 0.5);
		texture_ink = band(wisp, 0.105) * smoothstep(0.26, 0.49, abs(travel.y)) * (1.0 - smoothstep(0.52, 0.70, abs(travel.y)));
	} else if (kind == 2) {
		glyph_distance = slab_sign(p);
		float split = band(abs(abs(p.x) - abs(p.y) * 0.44) - 0.47, 0.025);
		texture_ink = split * smoothstep(0.60, 0.78, radius) * active_fade;
	} else if (kind == 3) {
		glyph_distance = veil_sign(p);
		float arc = abs(fract(around * 6.0 + radius * 1.43 - TIME * 0.21) - 0.5);
		texture_ink = band(arc, 0.095) * band(radius - 0.72, 0.086);
	} else {
		glyph_distance = tide_sign(p);
		float swell = fract(3.2 * p.y + 0.15 * sin(7.0 * p.x - TIME * 0.82) + TIME * 0.58);
		texture_ink = band(swell - 0.5, 0.12) * smoothstep(0.57, 0.74, radius);
	}

	float glyph = band(glyph_distance, 0.047);
	float inset = band(glyph_distance, 0.084);
	vec3 dark = tint.rgb * 0.09;
	float line = 0.0;
	float shade = 0.0;
	if (phase == 0) {
		line = max(rim * 0.31, glyph * 0.13);
		shade = max(under * 0.27, inset * 0.25);
	} else if (phase == 1) {
		line = max(max(rim * ticks, countdown * 0.76), glyph * 0.95);
		shade = max(max(under * 0.83, inset * 0.92), 0.12);
	} else {
		line = max(max(rim, inner_rim * 0.68), max(glyph, texture_ink * 0.60 * active_fade));
		shade = max(max(under * 0.86, inset * 0.92), 0.22);
	}
	float edge = 1.0 - smoothstep(0.988, 1.0, radius);
	ALBEDO = mix(dark, mix(tint.rgb, vec3(1.0), glyph * 0.43), line);
	ALPHA = edge * max(shade, line * 0.94);
}
