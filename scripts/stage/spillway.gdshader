shader_type spatial;
render_mode diffuse_burley, cull_disabled;

uniform vec4 water : source_color = vec4(0.18, 0.40, 0.43, 1.0);
uniform float run = 0.0;

void fragment() {
	float fall = UV.y * 2.4 - TIME * 0.59 + run;
	float runnels = cos(UV.x * 46.0 + sin(fall * 6.0) * 1.9) + cos(UV.x * 22.0 + fall * 8.2) * 0.44;
	float foam = smoothstep(0.47, 1.01, runnels) * (0.48 + 0.52 * smoothstep(0.42, 0.98, sin(fall * 13.0)));
	float side = smoothstep(0.0, 0.15, min(UV.x, 1.0 - UV.x));
	float pool = smoothstep(0.75, 1.0, UV.y) * 0.42;
	ALBEDO = water.rgb * (0.40 + side * (0.55 + foam * 0.91 + pool));
	EMISSION = water.rgb * (foam * 0.12 + pool * 0.28) * side;
	ROUGHNESS = 0.27 + foam * 0.18;
	SPECULAR = 0.55;
}
