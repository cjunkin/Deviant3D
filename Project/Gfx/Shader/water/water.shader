shader_type spatial;
render_mode blend_mix, specular_phong, cull_disabled;

//uniform float speed : hint_range(-1,1) = 0.001;
const float speed = .001;

//colors
uniform sampler2D noise1; //add Godot noise here
uniform sampler2D noise2; //add Godot noise here
uniform sampler2D normalmap : hint_normal; //add Godot noise here, enable as_normalmap
uniform vec4 color : hint_color;
uniform vec4 edge_color : hint_color;

//foam
const float edge_scale = 2.0; //: hint_range(-1, 1) = 0.25;
const float near = 0.1;
const float far = 100f;

//waves
const vec2 wave_strength = vec2(0.5, 0.25);
const vec2 wave_frequency = vec2(12.0, 12.0);
const vec2 time_factor = vec2(1.0, 2.0);



float rim(float depth){
	depth = 2f * depth - 1f;
	return near * far / (far + depth * (near - far));
}


float waves(vec2 pos, float time){
	return (wave_strength.y * sin(pos.y * wave_frequency.y + time * time_factor.y)) + (wave_strength.x * sin(pos.x * wave_frequency.x + time * time_factor.x));
}

// rewritten, before it was kinda flat
void vertex(){
//	vec2 tex_position = VERTEX.xz / 2.0 + 0.5;
//	float height = texture(displacement, tex_position).x;
//	VERTEX.y += height * height_scale;
//	VERTEX += vec3(sin(TIME + UV.x), cos(TIME + UV.x), sin(TIME + UV.x));
	VERTEX.y += waves(VERTEX.xy, TIME);
}


void fragment(){
	float time = TIME * speed;
	vec3 n1 = texture(noise1, UV + time).rgb;
	vec3 n2 = texture(noise2, UV - time * 0.2).rgb;
	
	vec2 uv_movement = UV * 4f;
	uv_movement += TIME * speed * 4f;
	
	float sum = (n1.r + n2.r) - 1f;
	
	float z_depth = rim(texture(DEPTH_TEXTURE, SCREEN_UV).x);
	float z_pos = rim(FRAGCOORD.z);
	float diff = z_depth - z_pos;
	
	vec2 displacement = vec2(sum * 0.05);
	diff += displacement.x * 50f;
	
	vec4 alpha = texture(SCREEN_TEXTURE, SCREEN_UV + displacement);
	
	// optimized from if elses
	float fin = 0.1 * float(sum > 0.0 && sum <= 0.4) + 1.0 * float(sum > 0.8);
	
	ALBEDO = vec3(fin) + mix(
		alpha.rgb, 
		mix(edge_color, color, step(edge_scale, diff)).rgb, // color
		color.a
	);
	
	NORMALMAP = texture(normalmap, uv_movement).rgb;
	ROUGHNESS = 0.1;
	SPECULAR = 1f;
}