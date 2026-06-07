shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float scale : hint_range(0.5, 5.0) = 1.0;
uniform vec4 color : source_color = vec4(0.08, 0.06, 0.05, 1.0);
uniform float threshold : hint_range(0.0, 1.0) = 0.22;

float luma(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 d = SCREEN_PIXEL_SIZE * scale;

	float tl = luma(texture(screen_texture, uv + vec2(-d.x, -d.y)).rgb);
	float tc = luma(texture(screen_texture, uv + vec2( 0.0, -d.y)).rgb);
	float tr = luma(texture(screen_texture, uv + vec2( d.x, -d.y)).rgb);
	float ml = luma(texture(screen_texture, uv + vec2(-d.x,  0.0)).rgb);
	float mr = luma(texture(screen_texture, uv + vec2( d.x,  0.0)).rgb);
	float bl = luma(texture(screen_texture, uv + vec2(-d.x,  d.y)).rgb);
	float bc = luma(texture(screen_texture, uv + vec2( 0.0,  d.y)).rgb);
	float br = luma(texture(screen_texture, uv + vec2( d.x,  d.y)).rgb);

	float gx = -tl - 2.0 * ml - bl + tr + 2.0 * mr + br;
	float gy = -tl - 2.0 * tc - tr + bl + 2.0 * bc + br;
	float outline = step(threshold, sqrt(gx * gx + gy * gy));

	vec4 screen = texture(screen_texture, uv);
	COLOR = mix(screen, color, outline);
}
