shader_type canvas_item;
render_mode unshaded;

uniform float progress : hint_range(0.0, 1.0) = 0.0;

float hash(vec2 point) {
	return fract(sin(dot(point, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 point) {
	vec2 cell = floor(point);
	vec2 fraction = fract(point);
	vec2 blend = fraction * fraction * (3.0 - 2.0 * fraction);
	return mix(mix(hash(cell), hash(cell + vec2(1.0, 0.0)), blend.x),
		mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0)), blend.x), blend.y);
}

void fragment() {
	vec2 drift = vec2(TIME * 0.12, -TIME * 0.06);
	float cloud = noise(UV * vec2(5.0, 3.0) + drift);
	float detail = noise(UV * vec2(13.0, 8.0) - drift * 0.7);
	float field = (1.0 - UV.y) * 0.46 + cloud * 0.42 + detail * 0.12;
	float density = smoothstep(field - 0.16, field + 0.16, progress * 1.6 - 0.3);
	float wisps = sin(progress * 3.14159265) * (0.35 + detail * 0.65);
	vec3 color = mix(vec3(0.008, 0.006, 0.018), vec3(0.075, 0.065, 0.105), wisps);
	COLOR = vec4(color, density);
}
