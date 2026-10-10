shader_type spatial;
render_mode cull_disabled;
uniform sampler2D skin_texture : source_color, filter_nearest;
varying vec3 local_position;

void vertex() { local_position = VERTEX; }

void fragment() {
    vec3 skin = texture(skin_texture, UV).rgb;
    float stain = sin(local_position.x * 57.0 + sin(local_position.y * 41.0) * 3.0);
    stain *= sin(local_position.z * 67.0 + local_position.y * 26.0);
    float blood = smoothstep(0.15, 0.8, stain) * 0.7;
    ALBEDO = mix(skin, vec3(0.22, 0.009, 0.015), blood);
    ROUGHNESS = mix(0.78, 0.24, blood);
    SPECULAR = 0.4;
}
