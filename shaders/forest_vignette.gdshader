shader_type canvas_item;
render_mode unshaded;

uniform float strength : hint_range(0.0, 0.15) = 0.045;

void fragment() {
	vec2 distance_from_center = abs(SCREEN_UV - vec2(0.5)) * 2.0;
	float edge = max(distance_from_center.x, distance_from_center.y);
	// The central 75% is completely clear; only the outer fringe is affected.
	COLOR = vec4(0.008, 0.006, 0.015, strength * smoothstep(0.75, 1.0, edge));
}
