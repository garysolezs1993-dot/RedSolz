shader_type canvas_item;
render_mode unshaded;

uniform float blur_radius : hint_range(0.0, 2.0) = 1.0;
varying vec4 sprite_tint;

void vertex() {
	sprite_tint = COLOR;
}

vec4 premultiplied_sample(sampler2D source_texture, vec2 uv) {
	vec4 value = texture(source_texture, uv);
	return vec4(value.rgb * value.a, value.a);
}

void fragment() {
	vec2 step_size = TEXTURE_PIXEL_SIZE * blur_radius;
	vec4 soft = premultiplied_sample(TEXTURE, UV) * 0.4;
	soft += premultiplied_sample(TEXTURE, UV + vec2(step_size.x, 0.0)) * 0.15;
	soft += premultiplied_sample(TEXTURE, UV - vec2(step_size.x, 0.0)) * 0.15;
	soft += premultiplied_sample(TEXTURE, UV + vec2(0.0, step_size.y)) * 0.15;
	soft += premultiplied_sample(TEXTURE, UV - vec2(0.0, step_size.y)) * 0.15;
	COLOR = vec4(soft.rgb / max(soft.a, 0.0001), soft.a) * sprite_tint;
}
