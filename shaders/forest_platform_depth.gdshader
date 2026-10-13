shader_type canvas_item;

uniform float top_brightness : hint_range(0.0, 1.0) = 0.94;
uniform float underside_brightness : hint_range(0.0, 1.0) = 0.72;
uniform float surface_row = 0.20;
uniform float top_band = 0.10;

void fragment() {
	float depth = smoothstep(surface_row + top_band, min(1.0, surface_row + top_band + 0.30), UV.y);
	COLOR.rgb *= mix(top_brightness, underside_brightness, depth);
}
