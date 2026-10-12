shader_type canvas_item;
// Scene 2 screen effect: almost blind in the dark, only the center visible; blood drips run
// down the screen and everything turns red, then dark red and black as `blood` reaches 1.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float blood : hint_range(0.0, 1.0) = 0.0;
// Seconds since the scene started, and the time until death; drips start spread across it.
uniform float elapsed = 0.0;
uniform float time_limit = 90.0;
// How much of the screen you can see at the start (0-1, from the center).
uniform float view_radius = 0.45;

float hash(float n) {
	return fract(sin(n * 127.1) * 43758.5453);
}

// One layer of drips: each screen column gets a drip that starts at a random time, runs down
// to a random length, tapers, and ends in a bead.
float drips(vec2 uv, float columns, float seed, float aspect) {
	float cell = floor(uv.x * columns);
	float fx = fract(uv.x * columns) - 0.5;
	float r1 = hash(cell + seed);
	float r2 = hash(cell * 1.7 + seed + 3.1);
	float r3 = hash(cell * 2.3 + seed + 7.7);
	float age = elapsed - r1 * time_limit * 0.9;
	if (age <= 0.0) {
		return 0.0;
	}
	float len = min(age * mix(0.01, 0.035, r2), mix(0.25, 1.1, r3));
	float wobble = sin(uv.y * 22.0 + r1 * 30.0) * 0.07;
	float width = mix(0.07, 0.2, r2) * (1.0 - clamp(uv.y / len, 0.0, 1.0) * 0.45);
	float streak = smoothstep(width, width * 0.5, abs(fx + wobble)) * step(uv.y, len);
	float dy = (uv.y - len) * columns / aspect;
	float bead = smoothstep(width * 1.6, width * 1.1, length(vec2(fx + wobble, dy)));
	return max(streak, bead);
}

void fragment() {
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	vec3 scene = texture(screen_tex, SCREEN_UV).rgb;

	// The world drains toward red.
	scene = mix(scene, scene * vec3(1.1, 0.3, 0.25), blood);

	// Only a patch in the middle is visible, and it closes in as you weaken. The darkness
	// around it turns dark red.
	float dist = length((UV - 0.5) * vec2(aspect, 1.0));
	float radius = view_radius * (1.0 - blood * 0.8);
	float visible_amount = 1.0 - smoothstep(radius * 0.35, radius, dist);
	vec3 col = scene * visible_amount + vec3(0.09, 0.0, 0.0) * blood * (1.0 - visible_amount);
	col = mix(col, vec3(0.2, 0.0, 0.0), smoothstep(0.5, 1.0, blood) * 0.6 * visible_amount);

	// Blood running down over everything, like it's on your eyes.
	float d = max(drips(UV, 21.0, 0.0, aspect), drips(UV, 43.0, 13.0, aspect) * 0.85);
	vec3 drip_color = mix(vec3(0.45, 0.03, 0.03), vec3(0.2, 0.0, 0.0), blood);
	col = mix(col, drip_color, d * 0.85);

	// The very end: nothing but dark red fading to black.
	col = mix(col, vec3(0.07, 0.0, 0.0) * (1.0 - smoothstep(0.0, 0.5, dist)), smoothstep(0.93, 1.0, blood));
	COLOR = vec4(col, 1.0);
}
