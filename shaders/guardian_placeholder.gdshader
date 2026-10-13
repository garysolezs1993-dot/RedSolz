shader_type canvas_item;
render_mode unshaded;

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float light = dot(source.rgb, vec3(0.299, 0.587, 0.114));
	vec3 silver = mix(vec3(0.58, 0.69, 0.82), vec3(0.98, 0.99, 1.0), light);
	COLOR = vec4(silver, source.a * COLOR.a);
}
