shader_type canvas_item;

uniform float brightness : hint_range(0.0, 1.0) = 0.85;
uniform vec4 shadow_tint : source_color = vec4(0.86, 0.88, 0.96, 1.0);
uniform float moon_castle_brightness : hint_range(0.0, 1.0) = 0.80;
uniform bool soften_moon_castle = false;

void fragment() {
	// Moon and castle are baked into the existing far texture. A soft mask in
	// source UV coordinates stays aligned through parallax, scaling and repeats.
	vec2 landmark_uv = (UV - vec2(0.785, 0.28)) / vec2(0.17, 0.22);
	float landmark = 1.0 - smoothstep(0.70, 1.25, length(landmark_uv));
	float value = soften_moon_castle ? mix(brightness, moon_castle_brightness, landmark) : brightness;
	COLOR.rgb *= shadow_tint.rgb * value;
}
