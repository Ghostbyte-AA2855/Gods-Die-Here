shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 relic_color : source_color = vec4(1.0, 0.79, 0.40, 1.0);
uniform vec4 claim_color : source_color = vec4(1.0, 0.79, 0.40, 1.0);
uniform vec4 ally_color : source_color = vec4(0.38, 0.92, 0.94, 1.0);
uniform vec4 rival_color : source_color = vec4(1.0, 0.51, 0.39, 1.0);
uniform int crest = 0;
uniform int phase = 0;
uniform float fraction : hint_range(0.0, 1.0) = 0.0;
uniform float claim_flash : hint_range(0.0, 1.0) = 0.0;

float band(float at, float center, float width) {
	return 1.0 - smoothstep(width, width + 0.014, abs(at - center));
}

float line_segment(vec2 p, vec2 a, vec2 b) {
	vec2 delta = b - a;
	float t = clamp(dot(p - a, delta) / max(dot(delta, delta), 0.001), 0.0, 1.0);
	return length(p - (a + t * delta));
}

float crest_distance(vec2 p, float r) {
	vec2 a = abs(p);
	if (crest == 0) {
		// A gate lantern over a pair of tidal crests.
		float lantern = abs(a.x * 1.17 + abs(p.y + 0.15) - 0.23);
		float tide = min(abs(p.y - 0.22 - cos(p.x * 11.0) * 0.050),
			abs(p.y - 0.37 - cos(p.x * 11.0) * 0.050));
		return min(lantern, max(tide, a.x - 0.39));
	}
	if (crest == 1) {
		// A four-toothed forge crown.
		float crown = line_segment(p, vec2(-0.30, 0.15), vec2(0.30, 0.15));
		crown = min(crown, line_segment(a, vec2(0.30, 0.15), vec2(0.38, 0.26)));
		crown = min(crown, line_segment(a, vec2(0.38, 0.26), vec2(0.20, 0.08)));
		crown = min(crown, line_segment(a, vec2(0.20, 0.08), vec2(0.0, 0.37)));
		return crown;
	}
	if (crest == 2) {
		// A branch that mirrors across the path into the point.
		float stem = line_segment(p, vec2(0.0, 0.42), vec2(0.0, -0.36));
		float leaf_a = line_segment(vec2(a.x, p.y), vec2(0.0, 0.15), vec2(0.31, -0.12));
		float leaf_b = line_segment(vec2(a.x, p.y), vec2(0.0, -0.04), vec2(0.22, -0.30));
		return min(stem, min(leaf_a, leaf_b));
	}
	if (crest == 3) {
		// A faceted keystone with a divided center.
		float diamond = abs(a.x + a.y * 0.80 - 0.37);
		return min(diamond, line_segment(p, vec2(-0.18, 0.15), vec2(0.19, -0.18)));
	}
	float star = min(line_segment(p, vec2(-0.35, 0.0), vec2(0.35, 0.0)),
		line_segment(p, vec2(0.0, -0.35), vec2(0.0, 0.35)));
	return min(star, abs(r - 0.29));
}

void fragment() {
	vec2 p = (UV - vec2(0.5)) * 2.0;
	float r = length(p);
	if (r > 1.0) {
		discard;
	}
	float clock = fract(atan(p.x, -p.y) / 6.2831853 + 1.0);
	float angle = clock * 6.2831853;
	float tick = step(0.22, fract(clock * 32.0)) * band(r, 0.901, 0.014);
	float edge = band(r, 0.977, 0.009);
	float engraving = band(r, 0.763, 0.009);
	float corners = step(0.89, abs(cos(angle * 2.0))) * band(r, 0.681, 0.042);
	float mark = 1.0 - smoothstep(0.014, 0.042, crest_distance(p, r));
	float pulse = 0.58 + sin(TIME * 4.1) * 0.16;
	vec3 claim = claim_color.rgb;
	float highlighted = band(r, 0.846, 0.031) * step(clock, fraction);
	float retained = 0.0;
	if (phase == 3) {
		claim = mix(ally_color.rgb, rival_color.rgb, step(0.5, clock));
		highlighted = band(r, 0.846, 0.030) * step(0.17, fract(clock * 12.0)) * pulse;
		retained = band(r, 0.774, 0.012) * step(clock, fraction);
	}
	if (phase == 0) {
		highlighted = band(r, 0.846, 0.018) * step(0.45, fract(clock * 12.0)) * 0.62;
	}
	float brightness = 0.48 + 0.52 * step(0.5, float(phase));
	if (phase == 4) {
		brightness = 0.56;
	}
	float rail = max(edge, tick);
	float subtle = max(mark * 0.65, max(engraving * 0.43, corners * 0.70));
	ALBEDO = mix(vec3(0.026, 0.021, 0.031), relic_color.rgb, clamp(0.14 + subtle * 0.72 + rail * 0.81, 0.0, 1.0));
	ALBEDO = mix(ALBEDO, claim, highlighted);
	ALBEDO = mix(ALBEDO, claim_color.rgb, retained);
	ALPHA = max(0.080 + subtle * 0.48 + rail * 0.59, max(highlighted * 0.91, retained * 0.74)) * brightness;
	if (claim_flash > 0.0) {
		float time = 1.0 - claim_flash;
		float wave = band(r, mix(0.25, 0.98, smoothstep(0.0, 0.65, time)), 0.026);
		float seal = max(wave * 0.88, mark * claim_flash * claim_flash);
		float light = seal * (1.0 - smoothstep(0.58, 1.0, time));
		ALBEDO = mix(ALBEDO, mix(claim_color.rgb, vec3(1.0, 0.94, 0.82), 0.30), light);
		ALPHA = max(ALPHA, light * 0.87);
	}
}
