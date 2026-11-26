shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 dust_tint : source_color = vec4(0.62, 0.52, 0.42, 1.0);
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float skid : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float border = 1.0 - smoothstep(0.70, 1.0, length(p));
	float strength = (1.0 - smoothstep(0.12, 1.0, progress)) * border;
	vec2 motion = p + vec2(0.0, progress * 0.38);
	float center = exp(-dot(motion * vec2(3.9, 2.25), motion * vec2(3.9, 2.25)));
	vec2 grain_at = p * vec2(14.0, 20.0) - vec2(2.0, 5.0) * progress;
	vec2 grain_cell = floor(grain_at);
	vec2 grain_seed = fract(sin(vec2(
		dot(grain_cell, vec2(41.9, 23.8)),
		dot(grain_cell, vec2(91.2, 12.7))
	)) * 4375.69);
	float grains = (1.0 - smoothstep(0.06, 0.22, distance(fract(grain_at), mix(vec2(0.28), vec2(0.72), grain_seed))))
		* smoothstep(0.18, 0.93, grain_seed.x);
	float flank = exp(-32.0 * abs(abs(p.x) - 0.31) - 2.2 * abs(p.y + progress * 0.64));
	float scuff = center * 0.23 + grains * 0.35 * (center + flank * skid) + flank * 0.61 * skid;
	ALBEDO = mix(dust_tint.rgb, dust_tint.rgb * 1.32, grains);
	ALPHA = scuff * strength;
}
