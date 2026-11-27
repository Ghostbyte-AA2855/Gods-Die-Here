shader_type spatial;
render_mode unshaded, cull_back, blend_add, depth_draw_never, shadows_disabled;

uniform vec4 tint : source_color = vec4(0.56, 0.90, 1.0, 1.0);
uniform float strength : hint_range(0.0, 1.0) = 0.27;

void fragment() {
	float vertical = UV.y;
	float side = max(0.0, dot(normalize(NORMAL), normalize(VIEW)));
	float column = pow(side, 3.6);
	float trace = pow(0.5 + 0.5 * sin(6.2831853 * (vertical * 3.0 + UV.x * 2.0 + TIME * 0.58)), 16.0);
	float taper = smoothstep(0.00, 0.13, vertical) * (1.0 - smoothstep(0.78, 1.0, vertical));
	ALBEDO = tint.rgb;
	ALPHA = (0.28 * column + 0.29 * trace * side) * taper * strength;
}
