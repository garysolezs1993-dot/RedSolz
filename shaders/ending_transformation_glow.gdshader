shader_type canvas_item;
render_mode unshaded;

uniform float glow_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	// Preserve the death pose's alpha while moonlight obscures cursed details.
	COLOR.rgb = mix(COLOR.rgb, vec3(0.96, 0.99, 1.0), glow_amount);
}
