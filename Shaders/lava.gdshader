shader_type spatial;

uniform sampler2D lava_texture : source_color;
uniform sampler2D noise_texture : hint_normal;
uniform float emission_strength : hint_range(0.0, 10.0) = 2.0;
uniform vec3 lava_color : source_color = vec3(1.0, 0.3, 0.0);
uniform vec3 hot_color : source_color = vec3(1.0, 0.8, 0.0);
uniform float flow_speed : hint_range(0.0, 2.0) = 0.3;
uniform float distortion_amount : hint_range(0.0, 0.5) = 0.1;
uniform float wave_scale : hint_range(0.1, 5.0) = 2.0;
uniform float hot_spots_threshold : hint_range(0.0, 1.0) = 0.7;
uniform float fresnel_power : hint_range(0.0, 5.0) = 2.0;

varying vec3 world_pos;
varying vec3 world_normal;

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);

    float wave = sin(world_pos.x * wave_scale + TIME * flow_speed) *
                 cos(world_pos.z * wave_scale + TIME * flow_speed * 0.8);
    VERTEX.y += wave * distortion_amount * 0.1;
}

void fragment() {
    vec2 base_uv = UV;

    vec2 flow_offset = vec2(TIME * flow_speed * 0.1, TIME * flow_speed * 0.15);
    vec2 distorted_uv = base_uv + flow_offset;

    vec3 noise = texture(noise_texture, distorted_uv * 2.0).rgb;
    vec2 final_uv = base_uv + (noise.xy - 0.5) * distortion_amount;

    vec4 lava_tex = texture(lava_texture, final_uv + flow_offset);

    float hot_spots = smoothstep(hot_spots_threshold - 0.1, hot_spots_threshold + 0.1, lava_tex.r);
    vec3 color = mix(lava_color, hot_color, hot_spots);

    float secondary_noise = texture(noise_texture, final_uv * 4.0 + flow_offset * 2.0).r;
    color = mix(color, hot_color * 1.2, secondary_noise * 0.3);

    vec3 view_dir = normalize(CAMERA_POSITION_WORLD - world_pos);
    float fresnel = pow(1.0 - max(dot(world_normal, view_dir), 0.0), fresnel_power);
    color += hot_color * fresnel * 0.5;

    ALBEDO = color;
    EMISSION = color * emission_strength;
    METALLIC = 0.0;
    ROUGHNESS = 0.8;
    SPECULAR = 0.2;

    float glow_intensity = hot_spots * 0.5 + fresnel * 0.3 + secondary_noise * 0.2;
    EMISSION += hot_color * glow_intensity * emission_strength * 0.5;
}