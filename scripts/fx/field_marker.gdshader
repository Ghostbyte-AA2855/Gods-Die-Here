shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 tint : source_color = vec4(0.8, 0.9, 1.0, 1.0);
uniform int motif = 0;

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	float disk = 1.0 - smoothstep(0.96, 1.0, r);
	float angle = atan(p.y, p.x);
	float ticks = step(0.41, fract(angle * 4.0)) * (1.0 - smoothstep(0.010, 0.034, abs(r - 0.86)));
	vec2 q = abs(p);
	float mark = 0.0;
	if (motif == 0) {
		// Crossed strokes for a field that deals damage.
		mark = (1.0 - smoothstep(0.037, 0.065, abs(q.x - q.y))) * (1.0 - smoothstep(0.23, 0.29, q.x + q.y));
	} else if (motif == 1) {
		// Healing plus.
		mark = (1.0 - smoothstep(0.044, 0.066, min(q.x, q.y))) * (1.0 - smoothstep(0.19, 0.22, max(q.x, q.y)));
	} else if (motif == 2) {
		// An angular shield.
		float top = abs(p.y - 0.17);
		float sides = abs(q.x + max(0.0, 0.055 - p.y) * 0.72 - 0.15);
		mark = (1.0 - smoothstep(0.022, 0.042, min(top, sides))) * (1.0 - smoothstep(0.15, 0.19, q.x)) * smoothstep(-0.18, -0.13, p.y);
	} else {
		// Two downward chevrons signal a movement slow.
		float arms = min(abs(p.y + 0.07 - q.x * 0.70), abs(p.y - 0.07 - q.x * 0.70));
		mark = (1.0 - smoothstep(0.021, 0.049, arms)) * (1.0 - smoothstep(0.15, 0.20, q.x));
	}
	ALBEDO = mix(tint.rgb * 0.50, tint.rgb, max(ticks, mark));
	ALPHA = disk * (0.16 + ticks * 0.47 + mark * 0.72);
}
