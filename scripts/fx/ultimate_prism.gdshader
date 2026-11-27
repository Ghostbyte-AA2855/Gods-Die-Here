shader_type spatial;
render_mode unshaded, cull_back, depth_draw_opaque, fog_disabled, shadows_disabled;

uniform vec4 tint : source_color = vec4(0.56, 0.86, 1.0, 1.0);
varying vec3 local_point;
varying vec3 local_normal;

void vertex() {
	local_point = VERTEX;
	local_normal = NORMAL;
}

void fragment() {
	float facing = abs(dot(normalize(NORMAL), normalize(VIEW)));
	float glint = pow(1.0 - facing, 2.4);
	float hue = sin(10.0 * local_normal.x + 9.0 * local_normal.z + 1.9 * local_point.y);
	vec3 indigo = vec3(0.21, 0.34, 0.63);
	vec3 rose = vec3(0.88, 0.36, 0.68);
	vec3 glass = mix(indigo, rose, smoothstep(-0.58, 0.88, hue));
	float color_ribbon = 0.50 + 0.50 * sin(local_point.y * 8.7 + local_point.x * 12.3 + local_normal.z * 9.2);
	float refraction = 0.22 + 0.64 * pow(color_ribbon, 5.0) + glint * 0.6;
	ALBEDO = mix(glass * 0.78, mix(tint.rgb, vec3(1.0, 0.96, 0.75), glint), min(refraction, 1.0));
}
