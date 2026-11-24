shader_type canvas_item;

uniform sampler2D noise_tex : repeat_enable, filter_linear;

uniform vec4 fog_color : source_color = vec4(0.62, 0.58, 0.52, 1.0);
uniform float opacity : hint_range(0.0, 1.0) = 0.3;

uniform vec2 speed1 = vec2(0.02, 0.002);
uniform vec2 speed2 = vec2(-0.015, -0.001);
uniform vec2 speed3 = vec2(0.035, 0.003);

uniform float low_edge : hint_range(0.0, 1.0) = 0.25;
uniform float high_edge : hint_range(0.0, 1.0) = 0.9;

// Cahaya dari atas
uniform vec4 light_color : source_color = vec4(1.0, 0.93, 0.8, 1.0);
uniform float light_strength : hint_range(0.0, 1.0) = 0.25;
uniform float top_bias : hint_range(0.0, 1.0) = 0.7;
uniform float fade_height : hint_range(0.1, 1.5) = 1.0;

void fragment() {
	float noise1 = texture(noise_tex, UV * 0.8 + speed1 * TIME).r * 0.55;
	float noise2 = texture(noise_tex, UV * 1.6 + speed2 * TIME).r * 0.35;
	float noise3 = texture(noise_tex, UV * 2.6 + speed3 * TIME).r * 0.10;

	float total_noise = noise1 + noise2 + noise3;
	float thick_fog = smoothstep(low_edge, high_edge, total_noise);

	float from_top = 1.0 - smoothstep(0.0, fade_height, UV.y);
	float height_mask = mix(1.0, from_top, top_bias);

	vec3 color = mix(fog_color.rgb, light_color.rgb, from_top * light_strength);

	COLOR = vec4(color, thick_fog * height_mask * opacity);
}