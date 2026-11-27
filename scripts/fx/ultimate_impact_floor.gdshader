shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, fog_disabled, shadows_disabled;

uniform vec4 tint : source_color = vec4(1.0, 0.45, 0.1, 1.0);
uniform int motif = 0;
uniform float age = 0.0;

float ink_line(float value, float width) {
	float softness = max(0.004, fwidth(value));
	return 1.0 - smoothstep(width, width + softness, abs(value));
}

void fragment() {
	vec2 point = UV * 2.0 - 1.0;
	float radius = length(point);
	if (radius > 1.0) {
		discard;
	}
	float angle = atan(point.y, point.x);
	float coverage = 0.0;
	vec3 ink = tint.rgb;
	float glow = 0.0;
	if (motif == 0) {
		float shock = min(1.0, 0.08 + pow(age, 0.72) * 2.38);
		float inward = sin(radius * 19.0 + angle * 6.0) * 0.16 + sin(radius * 38.0 - angle * 3.0) * 0.08;
		float seam = abs(sin(angle * 6.0 + inward * (0.92 + 2.7 * radius)));
		float fissure = ink_line(seam, 0.07) * (1.0 - smoothstep(0.86, 0.98, radius)) * (1.0 - smoothstep(shock, shock + 0.05, radius));
		float incandescent = ink_line(radius - shock, 0.037) * max(0.0, 1.0 - age * 2.9);
		float charred = (1.0 - smoothstep(0.13, 0.92, radius)) * (0.15 + 0.16 * sin(angle * 9.0 + radius * 13.0));
		glow = max(fissure * (1.0 - age * 0.59), incandescent);
		ink = mix(vec3(0.065, 0.025, 0.015), mix(tint.rgb, vec3(1.0, 0.92, 0.59), incandescent * 0.75), glow);
		coverage = max(charred, glow);
	} else if (motif == 1) {
		float corona = 0.65 + sin(angle * 7.0 - age * 9.0) * 0.041 + sin(angle * 11.0 + age * 15.0) * 0.022;
		float solar = 1.0 - smoothstep(0.39, corona, radius);
		float ring = ink_line(radius - corona, 0.038);
		float tongues = clamp(0.49 + 0.46 * sin(angle * 7.0 - age * 9.0) + 0.1 * cos(angle * 13.0), 0.0, 1.0);
		float flare = max(0.0, 1.0 - abs(radius - corona) * (7.0 + tongues * 11.0)) * (0.28 + 0.35 * tongues);
		float flash = ink_line(radius - min(0.98, 0.34 + age * 2.8), 0.017) * max(0.0, 1.0 - age * 3.5);
		glow = max(max(ring, flare), flash);
		ink = mix(vec3(0.024, 0.010, 0.026), mix(tint.rgb * 0.92, vec3(1.0, 0.89, 0.61), ring * 0.78 + flash * 0.16), glow);
		coverage = max(solar * 0.74, glow);
	} else {
		float window_angle = angle + PI * 0.125;
		vec2 diagonals = vec2(cos(window_angle), sin(window_angle)) * radius;
		float lead = max(abs(diagonals.x), abs(diagonals.y));
		float double_square = min(abs(lead - 0.48), abs((abs(point.x) + abs(point.y)) - 0.70));
		float ribs = ink_line(sin(angle * 8.0), 0.055) * (1.0 - smoothstep(0.58, 0.92, radius));
		float vesica = ink_line(double_square, 0.018) * (1.0 - smoothstep(0.67, 0.91, radius));
		float pulse = ink_line(radius - min(0.96, 0.09 + age * 3.5), 0.028) * max(0.0, 1.0 - age * 3.3);
		float stained_glass = (1.0 - smoothstep(0.42, 0.93, radius)) * (0.21 + 0.14 * sin(angle * 8.0 + radius * 7.0));
		vec3 stained = mix(vec3(0.17, 0.34, 0.54), vec3(0.65, 0.22, 0.58), sin(angle * 4.0 + radius * 6.0) * 0.5 + 0.5);
		glow = max(max(ribs, vesica), pulse);
		ink = mix(stained, mix(tint.rgb, vec3(1.0, 0.93, 0.99), pulse * 0.77), glow);
		coverage = max(stained_glass, glow);
	}
	ALBEDO = ink;
	ALPHA = clamp(coverage * (1.0 - smoothstep(0.39, 1.0, age)), 0.0, 1.0);
}
