shader_type canvas_item;
render_mode unshaded;

uniform float progress : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	vec2 cell = floor(UV * 128.0);
	float noise = fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453);
	float threshold = mix(UV.y, noise, 0.35);
	float remaining = 1.0 - smoothstep(threshold, threshold + 0.07, progress * 1.08);
	float rim = (1.0 - remaining) * smoothstep(progress * 1.08 - 0.1, progress * 1.08, threshold);
	vec3 color = mix(source.rgb, vec3(0.85, 0.93, 1.0), rim);
	COLOR = vec4(color * COLOR.rgb, source.a * COLOR.a * remaining);
}
