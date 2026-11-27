shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, shadows_disabled, depth_draw_never, fog_disabled;

uniform vec4 tint : source_color = vec4(1.0);
uniform vec4 team_tint : source_color = vec4(1.0);
uniform int crest = 0;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float opacity : hint_range(0.0, 1.0) = 1.0;
uniform bool windup = false;
uniform bool support = false;

float segment(vec2 p, vec2 a, vec2 b) {
	vec2 d = b - a;
	return length(p - a - d * clamp(dot(p - a, d) / dot(d, d), 0.0, 1.0));
}

float outline(vec2 p) {
	vec2 a = abs(p);
	if (crest == 0) { // Breakwater: split gate shield
		float top = segment(vec2(a.x, p.y), vec2(0.0, 0.16), vec2(0.32, 0.30));
		float wall = segment(vec2(a.x, p.y), vec2(0.32, 0.30), vec2(0.26, -0.09));
		float point = segment(vec2(a.x, p.y), vec2(0.26, -0.09), vec2(0.0, -0.37));
		return min(min(top, wall), min(point, segment(p, vec2(-0.20, 0.02), vec2(0.20, 0.02))));
	}
	if (crest == 1) { // Threadkeeper: wound thread and needle
		float loop = abs(length(vec2(a.x - 0.18, p.y * 1.25 + p.x * 0.40)) - 0.19);
		return min(loop, segment(p, vec2(-0.27, -0.33), vec2(0.26, 0.31)));
	}
	if (crest == 2) { // Echo Duelist: staggered slashes
		float slash = segment(p, vec2(-0.39, -0.12), vec2(0.12, 0.33));
		slash = min(slash, segment(p, vec2(-0.34, -0.29), vec2(0.34, 0.30)));
		return min(slash, segment(p, vec2(-0.13, -0.33), vec2(0.39, 0.12)));
	}
	if (crest == 3) { // Forgecaller: anvil and stem
		float cheek = segment(p, vec2(-0.37, 0.17), vec2(0.37, 0.17));
		float foot = segment(p, vec2(-0.21, -0.23), vec2(0.22, -0.23));
		return min(min(cheek, foot), segment(vec2(a.x, p.y), vec2(0.27, 0.14), vec2(0.08, -0.19)));
	}
	if (crest == 4) { // Lamplighter: crown of fire
		float cup = abs(length(vec2(p.x, p.y + 0.04)) - 0.23);
		float peak = segment(vec2(a.x, p.y), vec2(0.22, -0.06), vec2(0.0, 0.38));
		return min(max(cup, p.y + 0.04), peak);
	}
	if (crest == 5) { // Longwatch: barbed arrow
		float shaft = segment(p, vec2(-0.28, -0.31), vec2(0.29, 0.31));
		float barb = min(segment(p, vec2(0.29, 0.31), vec2(0.02, 0.25)), segment(p, vec2(0.29, 0.31), vec2(0.25, 0.03)));
		return min(min(shaft, barb), segment(p, vec2(-0.33, -0.13), vec2(-0.13, -0.29)));
	}
	if (crest == 6) { // Sluicecaller: three breaking waves
		float flow = p.y + 0.085 * cos(p.x * 10.0);
		return max(abs(mod(flow + 0.08, 0.16) - 0.08), max(a.x - 0.36, abs(flow) - 0.23));
	}
	if (crest == 7) { // Glassmage: divided crystal
		float edge = abs(a.x * 1.38 + a.y - 0.36);
		return min(edge, segment(p, vec2(0.0, -0.36), vec2(0.0, 0.36)));
	}
	if (crest == 8) { // Blood Cantor: suspended blood drop
		float cup = abs(length(vec2(p.x, p.y + 0.14)) - 0.23);
		return min(max(cup, p.y + 0.105), segment(vec2(a.x, p.y), vec2(0.23, -0.12), vec2(0.0, 0.34)));
	}
	if (crest == 9) { // Bellwarden: cast bell and clapper
		float crown = abs(length(vec2(p.x, p.y - 0.05)) - 0.17);
		float flare = segment(vec2(a.x, p.y), vec2(0.17, 0.05), vec2(0.32, -0.22));
		float rim = segment(p, vec2(-0.32, -0.22), vec2(0.32, -0.22));
		return min(min(max(crown, 0.05 - p.y), flare), min(rim, abs(length(p + vec2(0.0, 0.31)) - 0.05)));
	}
	if (crest == 10) { // Ash Dancer: broken sun and fangs
		float sun = abs(length(p) - 0.21);
		float fang = segment(a, vec2(0.16, 0.11), vec2(0.29, 0.31));
		return min(sun + 0.18 * step(0.8, abs(cos(atan(p.y, p.x) * 2.0))), fang);
	}
	if (crest == 11) { // Winter Scribe: iceflake
		float angle = atan(p.y, p.x);
		float sector = mod(angle + PI / 6.0, PI / 3.0) - PI / 6.0;
		vec2 point = length(p) * vec2(cos(sector), sin(sector));
		return min(segment(point, vec2(0.0), vec2(0.37, 0.0)), segment(abs(point), vec2(0.18, 0.0), vec2(0.27, 0.14)));
	}
	if (crest == 12) { // Dream Shepherd: split crescent
		float collar = abs(length(p + vec2(0.04, 0.0)) - 0.32);
		float bow = abs(length(p - vec2(0.14, 0.06)) - 0.27);
		return min(min(max(collar, 0.14 - length(p - vec2(0.12, 0.04))), max(bow, length(p + vec2(0.04, 0.0)) - 0.32)), abs(abs(p.x - 0.23) + abs(p.y - 0.20) - 0.10));
	}
	if (crest == 13) { // Chainrunner: linked iron
		vec2 u = vec2(p.x + p.y, p.y - p.x) * 0.707;
		return abs(length(vec2((abs(u.x) - 0.17) * 0.80, u.y)) - 0.14);
	}
	if (crest == 14) { // Coilwright: lightning tooth
		float top = segment(p, vec2(0.09, 0.37), vec2(-0.17, 0.04));
		float bend = segment(p, vec2(-0.17, 0.04), vec2(0.16, 0.03));
		return min(min(top, bend), segment(p, vec2(0.16, 0.03), vec2(-0.11, -0.38)));
	}
	// Duskmoth: paired wings and a needle-thin body.
	vec2 both = vec2(a.x, p.y);
	float crown = segment(both, vec2(0.0, -0.04), vec2(0.36, 0.26));
	float wing = segment(both, vec2(0.36, 0.26), vec2(0.25, -0.21));
	return min(min(crown, wing), segment(both, vec2(0.25, -0.21), vec2(0.0, -0.09)));
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	if (r > 1.0) {
		discard;
	}
	float angle = atan(p.y, p.x);
	float ring = 1.0 - smoothstep(0.013, 0.037, abs(r - 0.65));
	float dash = smoothstep(0.73, 0.91, cos(angle * (support ? 8.0 : 4.0) - TIME * 2.5));
	float tick = (1.0 - smoothstep(0.024, 0.055, abs(r - 0.83))) * dash;
	float line = 1.0 - smoothstep(0.024, 0.048, outline(p));
	float rush_radius = mix(0.89, 0.16, progress);
	if (!windup) {
		rush_radius = mix(0.27, 0.94, progress);
	}
	float rush = (1.0 - smoothstep(0.010, 0.035, abs(r - rush_radius))) * (windup ? 0.65 : 1.0 - progress);
	float smoke = (1.0 - smoothstep(0.05, 0.86, r)) * (windup ? 0.20 : 0.09);
	vec3 light = mix(tint.rgb, vec3(1.0, 0.96, 0.88), line * (0.42 + 0.18 * sin(TIME * 6.0)));
	light = mix(light, team_tint.rgb, clamp(ring * 0.50 + tick + rush * 0.38, 0.0, 1.0));
	ALBEDO = mix(vec3(0.027, 0.017, 0.035), light, clamp(max(line, max(ring, max(tick, rush))) * 1.45, 0.0, 1.0));
	ALPHA = max(smoke, max(line, max(ring * 0.62, max(tick * 0.85, rush)))) * opacity;
}
