shader_type spatial;
render_mode cull_disabled;

uniform sampler2D tissue_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 tissue_tint : source_color = vec4(0.28, 0.105, 0.083, 1.0);
uniform float texture_scale = 2.1;
uniform float wetness : hint_range(0.0, 1.0) = 0.7;
uniform float life = 0.6;
uniform float phase = 0.0;
varying vec3 tissue_position;
varying vec3 tissue_normal;

void vertex() {
    tissue_position = VERTEX;
    tissue_normal = NORMAL;
    // Small wall contraction; the floor remains a dependable crawl surface.
    float wall = 1.0 - smoothstep(0.65, 0.95, NORMAL.y);
    VERTEX += NORMAL * sin(phase - VERTEX.z * 3.0) * 0.005 * life * wall;
}

vec3 tissue_sample(vec3 p, vec3 weights) {
    return texture(tissue_texture, p.yz * texture_scale).rgb * weights.x
         + texture(tissue_texture, p.xz * texture_scale).rgb * weights.y
         + texture(tissue_texture, p.xy * texture_scale).rgb * weights.z;
}

void fragment() {
    vec3 weights = pow(abs(normalize(tissue_normal)), vec3(4.0));
    weights /= max(dot(weights, vec3(1.0)), 0.001);
    vec3 tex = tissue_sample(tissue_position, weights);
    // The source is brightly lit red: use its structure at restrained contrast.
    float relief = dot(tex, vec3(0.6, 0.25, 0.15));
    ALBEDO = tissue_tint.rgb * (0.65 + relief * 0.65);
    ROUGHNESS = mix(0.72, 0.40, wetness) + (1.0 - relief) * 0.08;
    SPECULAR = 0.32;
    float pulse = pow(max(sin(phase - tissue_position.z * 2.0), 0.0), 4.0);
    EMISSION = vec3(0.16, 0.003, 0.012) * life * (0.25 + pulse * 0.75);
}
