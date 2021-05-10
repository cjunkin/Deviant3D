shader_type canvas_item;

uniform vec4 edge_color : hint_color = vec4(0.0, 0.0, 0.0, 1);
uniform vec2 resolution = vec2(1280.0, 720.0);

void fragment(){
    float width = resolution.x;
    float height = resolution.y;
	float thickness = 1.0; // (sin(TIME) + .75)
	 // Change numerator to adjust edge line thickness 
	float w = thickness / width;  
	float h = thickness / height;  

	vec4 n0 = texture(SCREEN_TEXTURE, SCREEN_UV + vec2( -w, -h));
	vec4 n1 = texture(SCREEN_TEXTURE, SCREEN_UV + vec2(0.0, -h));
	vec4 n2 = texture(SCREEN_TEXTURE, SCREEN_UV + vec2(  w, -h));
	vec4 n3 = texture(SCREEN_TEXTURE, SCREEN_UV + vec2( -w, 0.0));
	vec4 n4 = texture(SCREEN_TEXTURE, SCREEN_UV);
	vec4 n5 = texture(SCREEN_TEXTURE, SCREEN_UV + vec2(  w, 0.0));
	vec4 n6 = texture(SCREEN_TEXTURE, SCREEN_UV + vec2( -w, h));
	vec4 n7 = texture(SCREEN_TEXTURE, SCREEN_UV + vec2(0.0, h));
	vec4 n8 = texture(SCREEN_TEXTURE, SCREEN_UV + vec2(  w, h));

	vec4 sobel_edge_h = n2 + (2.0*n5) + n8 - (n0 + (2.0*n3) + n6);
  	vec4 sobel_edge_v = n0 + (2.0*n1) + n2 - (n6 + (2.0*n7) + n8);
	vec4 sobel = sqrt((sobel_edge_h * sobel_edge_h) + (sobel_edge_v * sobel_edge_v));
//	float alpha = sobel.r;
//	alpha += sobel.g;
//	alpha +=  sobel.b;
//	alpha /= 3.0;
	float alpha = (sobel.r + sobel.g + sobel.b) / 3.0;
	COLOR = vec4( edge_color.rgb, alpha );
}


// SOBEL W/ GAUSSIAN FILTER

//uniform float brightness = 0.8;
//uniform float contrast = 1.5;
//uniform float saturation = 1.8;
//
//void fragment() {
//	vec3 c = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0).rgb;
//
//	c.rgb = mix(vec3(0.0), c.rgb, brightness);
//	c.rgb = mix(vec3(0.5), c.rgb, contrast);
//	c.rgb = mix(vec3(dot(vec3(1.0), c.rgb) * 0.33333), c.rgb, saturation);
//
//	COLOR.rgb = c;
//}

//uniform float alpha : hint_range( 0.0, 1.0 ) = 1.0;
//
//vec3 gaussian5x5( sampler2D tex, vec2 uv, vec2 pix_size )
//{
//	vec3 p = vec3( 0.0, 0.0, 0.0 );
//	float coef[25] = { 0.00390625, 0.015625, 0.0234375, 0.015625, 0.00390625, 0.015625, 0.0625, 0.09375, 0.0625, 0.015625, 0.0234375, 0.09375, 0.140625, 0.09375, 0.0234375, 0.015625, 0.0625, 0.09375, 0.0625, 0.015625, 0.00390625, 0.015625, 0.0234375, 0.015625, 0.00390625 };
//
//	for( int y=-2; y<=2; y++ ) {
//		for( int x=-2; x<=2; x ++ ) {
//			p += ( texture( tex, uv + vec2( float( x ), float( y ) ) * pix_size ).rgb ) * coef[(y+2)*5 + (x+2)];
//		}
//	}
//
//	return p;
//}
//
//void fragment()
//{
//	vec3 pix[9];	// 3 x 3
//
//	for( int y=0; y<3; y ++ ) {
//		for( int x=0; x<3; x ++ ) {
//			pix[y*3+x] = gaussian5x5( SCREEN_TEXTURE, SCREEN_UV + vec2( float( x-1 ), float( y-1 ) ) * SCREEN_PIXEL_SIZE, SCREEN_PIXEL_SIZE );
//		}
//	}
//
//	vec3 sobel_src_x = (
//		pix[0] * -1.0
//	+	pix[3] * -2.0
//	+	pix[6] * -1.0
//	+	pix[2] * 1.0
//	+	pix[5] * 2.0
//	+	pix[8] * 1.0
//	);
//	vec3 sobel_src_y = (
//		pix[0] * -1.0
//	+	pix[1] * -2.0
//	+	pix[2] * -1.0
//	+	pix[6] * 1.0
//	+	pix[7] * 2.0
//	+	pix[8] * 1.0
//	);
//	vec3 sobel = sqrt( sobel_src_x * sobel_src_x + sobel_src_y * sobel_src_y );
//
//	COLOR = vec4( sobel, alpha );
//}