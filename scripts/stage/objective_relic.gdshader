shader_type spatial;
render_mode cull_disabled;

uniform vec4 tint : source_color = vec4(0.58, 0.87, 1.0, 1.0);
uniform float intensity : hint_range(0.0, 2.0) = 0.65;
varying vec3 object_position;

void vertex() {
	object_position = VERTEX;
}

void fragment() {
	float rim = pow(1.0 - clamp(abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0), 2.15);
	float stratum = sin(object_position.y * 23.0 + object_position.x * 9.5 - TIME * 2.6);
	float rune = smoothstep(0.76, 0.99, stratum) * 0.14;
	ALBEDO = tint.rgb * (0.32 + rim * 0.41 + rune);
	ROUGHNESS = 0.31;
	METALLIC = 0.34;
	EMISSION = tint.rgb * (0.13 + rim * 0.69 + rune) * intensity;
}
