shader_type fog;
// Drifting patches of snow cloud, driven by SnowStorm.

uniform sampler3D noise_tex : repeat_enable;
uniform float density = 0.4;
uniform vec3 emission : source_color = vec3(0.4, 0.45, 0.5);
uniform float coverage = 0.4;
uniform float noise_scale = 0.05;
uniform vec3 offset = vec3(0.0);

void fog() {
	vec3 p = (WORLD_POSITION - offset) * noise_scale;
	// Second, slower layer so the clouds billow instead of just sliding.
	float n = texture(noise_tex, p).r * 0.65 + texture(noise_tex, p * 2.3 + vec3(0.0, TIME * 0.03, 0.0)).r * 0.35;
	float cloud = smoothstep(coverage, 1.0, n);
	// Thicker near the ground, fading out toward the top and the sides of the volume.
	float height_fade = 1.0 - smoothstep(0.3, 1.0, UVW.y);
	vec2 edge = min(UVW.xz, 1.0 - UVW.xz);
	float edge_fade = smoothstep(0.0, 0.15, min(edge.x, edge.y));
	DENSITY = density * cloud * height_fade * edge_fade;
	ALBEDO = vec3(1.0);
	EMISSION = emission;
}
