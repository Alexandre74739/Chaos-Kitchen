shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float saturation : hint_range(0.5, 2.0) = 1.3;
uniform float warmth : hint_range(0.0, 1.0) = 0.5;
uniform float dither_strength : hint_range(0.0, 1.0) = 0.18;

float luma(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

float bayer(ivec2 p) {
	p = p % 4;
	int i = p.y * 4 + p.x;
	if (i ==  0) return  0.0 / 16.0;
	if (i ==  1) return  8.0 / 16.0;
	if (i ==  2) return  2.0 / 16.0;
	if (i ==  3) return 10.0 / 16.0;
	if (i ==  4) return 12.0 / 16.0;
	if (i ==  5) return  4.0 / 16.0;
	if (i ==  6) return 14.0 / 16.0;
	if (i ==  7) return  6.0 / 16.0;
	if (i ==  8) return  3.0 / 16.0;
	if (i ==  9) return 11.0 / 16.0;
	if (i == 10) return  1.0 / 16.0;
	if (i == 11) return  9.0 / 16.0;
	if (i == 12) return 15.0 / 16.0;
	if (i == 13) return  7.0 / 16.0;
	if (i == 14) return 13.0 / 16.0;
	             return  5.0 / 16.0;
}

void fragment() {
	vec4 col = texture(screen_texture, SCREEN_UV);
	vec3 result = col.rgb;

	// Dithering léger
	ivec2 px = ivec2(SCREEN_UV / SCREEN_PIXEL_SIZE);
	float t = (bayer(px) - 0.5) * dither_strength;
	vec3 quantized = floor(result * 8.0 + t + 0.5) / 8.0;
	result = mix(result, quantized, dither_strength);

	// Boost saturation (pop cartoon)
	float l = luma(result);
	result = mix(vec3(l), result, saturation);

	// Teinte brun ambré style années 80
	vec3 shadow_tone = vec3(0.55, 0.38, 0.22);
	float l2 = luma(result);
	vec3 tinted = mix(shadow_tone * l2 * 1.6, result * vec3(1.10, 0.93, 0.72), smoothstep(0.1, 0.6, l2));
	result = mix(result, tinted, warmth);

	COLOR = vec4(clamp(result, 0.0, 1.0), col.a);
}
