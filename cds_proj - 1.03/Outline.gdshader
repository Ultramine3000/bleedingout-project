shader_type spatial;
render_mode unshaded;

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;
uniform sampler2D NORMAL_TEXTURE : hint_normal_roughness_texture;

uniform vec3 outline_color : source_color = vec3(0.0); // Color of the outline
uniform float outline_thickness = 1.0; // Thickness of the outline in pixels
uniform float outline_strength = 1.0; // Strength of the outline

void fragment() {
    vec2 pixel_size = 1.0 / VIEWPORT_SIZE.xy;

    float depth_center = texture(DEPTH_TEXTURE, SCREEN_UV).r;
    vec3 normal_center = texture(NORMAL_TEXTURE, SCREEN_UV).rgb;

    float outline_intensity = 0.0;

    for (float x = -outline_thickness; x <= outline_thickness; x++) {
        for (float y = -outline_thickness; y <= outline_thickness; y++) {
            if (x == 0.0 && y == 0.0) {
                continue;
            }

            vec2 offset = vec2(x, y) * pixel_size;
            float depth_sample = texture(DEPTH_TEXTURE, SCREEN_UV + offset).r;
            vec3 normal_sample = texture(NORMAL_TEXTURE, SCREEN_UV + offset).rgb;

            float depth_difference = abs(depth_center - depth_sample);
            float normal_difference = length(normal_center - normal_sample);

            outline_intensity += step(0.01, depth_difference) + step(0.1, normal_difference);
        }
    }

    outline_intensity = clamp(outline_intensity * outline_strength, 0.0, 1.0);

    vec3 base_color = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
    ALBEDO = mix(base_color, outline_color, outline_intensity);
}