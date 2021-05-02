shader_type spatial;
render_mode cull_disabled;

void fragment() {
	ALPHA = 0.5;
	ALBEDO = vec3(.2, .5, .8f);
	ROUGHNESS = 0.1;
	SPECULAR = 1f;
}

void vertex() {
	VERTEX += vec3(sin(TIME + UV.x), cos(TIME + UV.x) / 2f, sin(TIME + UV.x));
	
}
