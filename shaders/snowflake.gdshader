shader_type spatial;
render_mode unshaded, cull_disabled;
// Snowflake quad that faces the camera while its long side follows the direction the flake
// flies (the particle's Y axis, set by align_y in SnowStorm), so stretched flakes streak.

uniform sampler2D flake_tex : source_color, filter_linear;
uniform vec4 color : source_color = vec4(1.0);

void vertex() {
	vec3 center = MODEL_MATRIX[3].xyz;
	vec3 along = MODEL_MATRIX[1].xyz;
	float width = length(MODEL_MATRIX[0].xyz);
	float len = length(along);
	along /= max(len, 0.0001);

	vec3 to_camera = normalize(CAMERA_POSITION_WORLD - center);
	vec3 side = cross(along, to_camera);
	// Looking straight down the flight path: fall back to the screen's horizontal.
	side = length(side) > 0.001 ? normalize(side) : INV_VIEW_MATRIX[0].xyz;

	vec3 world = center + side * VERTEX.x * width + along * VERTEX.y * len;
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(world, 1.0);
}

void fragment() {
	vec4 tex = texture(flake_tex, UV);
	ALBEDO = color.rgb * tex.rgb;
	ALPHA = color.a * tex.a;
}
