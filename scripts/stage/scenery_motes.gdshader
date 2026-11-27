shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, depth_draw_never;

uniform vec4 tint : source_color = vec4(0.72, 0.63, 0.48, 1.0);
uniform float drift = 0.18;
uniform float spark = 0.45;
varying float glimmer;

void vertex() {
	float seed = float(INSTANCE_ID) * 2.399963;
	float clock = TIME * (0.48 + 0.24 * fract(seed));
	vec3 movement = vec3(sin(seed + clock), 0.67 * cos(seed * 0.42 + clock), cos(seed + clock * 0.71)) * drift;
	float size = length(MODEL_MATRIX[0].xyz);
	vec3 center = (VIEW_MATRIX * vec4(MODEL_MATRIX[3].xyz + movement, 1.0)).xyz;
	VERTEX = center + vec3(VERTEX.xy * size, 0.0);
	POSITION = PROJECTION_MATRIX * vec4(VERTEX, 1.0);
	glimmer = 0.38 + 0.62 * sin(seed * 0.21 + clock * 1.7) * sin(seed * 0.21 + clock * 1.7);
}

void fragment() {
	vec2 uv = (UV - 0.5) * 2.0;
	float inward = 1.0 - clamp(length(uv * vec2(1.0, 1.12)), 0.0, 1.0);
	ALBEDO = tint.rgb * (0.67 + spark * inward * 0.70);
	ALPHA = inward * inward * glimmer * spark;
}
