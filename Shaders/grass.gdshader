shader_type spatial;

// Wind parameters
uniform float wind_strength : hint_range(0.0, 2.0) = 1.0;
uniform float wind_speed : hint_range(0.1, 5.0) = 1.5;
uniform vec2 wind_direction = vec2(1.0, 0.0);
uniform float wind_turbulence : hint_range(0.0, 1.0) = 0.3;

// Grass properties
uniform float grass_height : hint_range(0.1, 5.0) = 1.0;
uniform float bend_curve : hint_range(0.1, 3.0) = 1.5;
uniform sampler2D grass_texture : source_color;
uniform vec4 grass_color : source_color = vec4(0.3, 0.8, 0.2, 1.0);

varying vec3 world_position;
varying float vertex_height;

void vertex() {
    // Get world position
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

    // Calculate vertex height (0.0 at bottom, 1.0 at top)
    vertex_height = (VERTEX.y + grass_height * 0.5) / grass_height;
    vertex_height = clamp(vertex_height, 0.0, 1.0);

    // Only apply wind to upper parts of grass
    float wind_factor = vertex_height * vertex_height; // Quadratic falloff

    // Create wind waves using sine functions
    float time = TIME * wind_speed;

    // Main wind wave
    float wind_wave = sin(world_position.x * 0.3 + world_position.z * 0.2 + time) * 0.5 + 0.5;

    // Add turbulence with different frequencies
    float turbulence1 = sin(world_position.x * 0.8 + time * 1.3) * 0.3;
    float turbulence2 = sin(world_position.z * 0.6 + time * 0.8) * 0.2;

    // Combine wind effects
    float wind_intensity = (wind_wave + turbulence1 + turbulence2) * wind_turbulence;

    // Apply wind displacement
    vec3 wind_offset = vec3(
        wind_direction.x * wind_intensity * wind_strength,
        0.0,
        wind_direction.y * wind_intensity * wind_strength
    );

    // Apply bend curve (more bending at the top)
    float bend_amount = pow(vertex_height, bend_curve);

    // Apply the wind effect
    VERTEX += wind_offset * wind_factor * bend_amount;
}

void fragment() {
    // Sample grass texture
    vec4 tex_color = texture(grass_texture, UV);

    // Apply grass color tint
    vec3 final_color = tex_color.rgb * grass_color.rgb;

    // Add some variation based on height (darker at bottom)
    float height_variation = mix(0.7, 1.0, vertex_height);
    final_color *= height_variation;

    // Add subtle wind-based color variation
    float wind_highlight = sin(world_position.x * 0.5 + world_position.z * 0.3 + TIME * wind_speed) * 0.1 + 0.9;
    final_color *= wind_highlight;

    ALBEDO = final_color;
    ALPHA = tex_color.a * grass_color.a;

    // Make it slightly rough for a more natural look
    ROUGHNESS = 0.8;
    METALLIC = 0.0;
}