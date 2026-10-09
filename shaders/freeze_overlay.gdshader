shader_type canvas_item;
// Full-screen cold effect driven by FreezeEffect: frost creeping in from the edges,
// darkening, and eyelids closing from top and bottom.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D frost_tex : repeat_enable, filter_linear;
uniform float frost : hint_range(0.0, 1.0) = 0.0;
uniform float darkness : hint_range(0.0, 1.0) = 0.0;
uniform float eyelids : hint_range(0.0, 1.0) = 0.0;
uniform vec3 frost_color : source_color = vec3(0.78, 0.88, 1.0);

void fragment() {
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	vec2 centered = (UV - 0.5) * vec2(aspect, 1.0);
	// 0 at the center, 1 in the corners.
	float dist = length(centered) / length(vec2(aspect, 1.0) * 0.5);

	vec2 frost_uv = UV * vec2(aspect, 1.0);
	float coarse = texture(frost_tex, frost_uv * 0.8).r;
	float fine = texture(frost_tex, frost_uv * 4.0).r;

	// Frost edge moves inward as frost grows, broken up by noise so it looks crystalline.
	float reach = 1.05 - frost * 0.9;
	float frost_mask = smoothstep(reach, reach + 0.3, dist + (coarse - 0.5) * 0.45);
	frost_mask = clamp(frost_mask * (0.6 + fine * 0.6), 0.0, 1.0);

	// Frozen parts of the view are blurred and refracted.
	vec2 refract = (vec2(coarse, fine) - 0.5) * 0.02 * frost_mask;
	vec3 scene = textureLod(screen_tex, SCREEN_UV + refract, frost_mask * 4.0).rgb;

	// Cold, washed-out colors as the body freezes.
	float grey = dot(scene, vec3(0.299, 0.587, 0.114));
	scene = mix(scene, grey * vec3(0.85, 0.95, 1.1), frost * 0.7);

	vec3 ice = frost_color * (0.45 + 0.55 * fine);
	vec3 col = mix(scene, ice * max(grey * 2.5, 0.35), frost_mask * 0.85);

	// Everything dims, the edges first.
	float vignette = smoothstep(0.1, 1.0, dist);
	col *= 1.0 - darkness * mix(0.75, 1.0, vignette);

	// Eyelids: curved, closing from top and bottom; fully black at 1.
	float soft = 0.06;
	// Starts fully off-screen when the eyes are open.
	float lid = mix(-soft * 1.5, 0.56, eyelids) - centered.x * centered.x * 0.35 * eyelids * (1.0 - eyelids);
	float open_top = smoothstep(lid - soft, lid + soft, UV.y);
	float open_bottom = smoothstep(lid - soft, lid + soft, 1.0 - UV.y);
	col *= open_top * open_bottom * (1.0 - step(0.999, eyelids));

	COLOR = vec4(col, 1.0);
}
