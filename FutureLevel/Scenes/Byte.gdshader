shader_type canvas_item;

uniform vec4 albedo_color = vec4(1.0, 0.843, 0.0, 1.0); // Gold color
uniform float metallic = 1.0; // Fully metallic-like effect
uniform float roughness = 0.1; // Smooth reflections
uniform sampler2D noise_texture;

void fragment() {
    // Base metallic gold color
    vec4 tex_color = texture(TEXTURE, UV);
    COLOR = tex_color * albedo_color;

    // Add some noise for surface imperfections
    float noise = texture(noise_texture, UV * 5.0).r;
    COLOR.rgb += vec3(noise * 0.1);

    // Slight emission for a glowing gold effect
    COLOR.rgb += albedo_color.rgb * 0.1;
}
