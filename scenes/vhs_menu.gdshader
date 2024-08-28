shader_type canvas_item;

uniform float scanline_count : hint_range(0, 1800) = 50.0;
uniform float scanline_alpha : hint_range(0.0, 1.0) = 0.5;
uniform float scanline_speed : hint_range(-10.0, 10.0) = 1.0;

uniform float red_offset : hint_range(-50.0, 30.0) = 0.0;
uniform float green_offset : hint_range(-50.0, 30.0) = 3.0;
uniform float blue_offset : hint_range(-50.0, 30.0) = -3.0;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

vec2 uv_curve(vec2 uv) {
	uv = (uv - 0.5) * 2.0;

	// Modify the numbers to experiment with different values
	uv.x *= 1.0 + pow(abs(uv.y) / 3.0, 2.0);
	uv.y *= 1.0 + pow(abs(uv.x) / 3.0, 2.0);

	// Scale (optional, can be removed)
	uv /= 1.2;

	uv = (uv / 2.0) + 0.5;
	return uv;
}

void fragment() {

	// Modify *3.0, *-3.0 for bigger or smaller effect
	float r = texture(SCREEN_TEXTURE, vec2(red_offset, 0.0)).r;
    float g = texture(SCREEN_TEXTURE, vec2(green_offset, 0.0)).g;
    float b = texture(SCREEN_TEXTURE, vec2(blue_offset, 0.0)).b;

	//float r = 0.0;
	//float g = 0.0;
	//float b = 0.0;

	// Optional scanlines effect
	float s = sin((uv_curve(SCREEN_UV).y + TIME * scanline_speed) * scanline_count * PI * 2.0);
	s = (s * 1.0 + 0.5) * 0.9 + 0.1;
	vec4 scan_line = vec4(vec3(pow(s, 0.25)), scanline_alpha);

	COLOR = vec4(r, g, b, 1.0) * scan_line;
}
