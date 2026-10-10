shader_type canvas_item;
uniform float blood_intensity : hint_range(0.0, 1.0) = 0.28;

void fragment() {
    vec2 p = (UV - 0.5) * vec2(1.0, 0.85);
    float edge = smoothstep(0.22, 0.62, length(p));
    float grain = fract(sin(dot(UV * vec2(1920.0, 1080.0), vec2(12.9898, 78.233))) * 43758.5453);
    float streak = sin(UV.x * 57.0 + sin(UV.y * 18.0) * 1.8) * 0.5 + 0.5;
    float smear = smoothstep(0.56, 0.93, streak) * smoothstep(0.27, 0.61, length(p));
    vec3 tint = mix(vec3(0.009, 0.006, 0.008), vec3(0.16, 0.008, 0.027), smear * blood_intensity * 2.0);
    COLOR = vec4(tint + grain * 0.01, edge * 0.65 + 0.035 + smear * blood_intensity * 0.35);
}
