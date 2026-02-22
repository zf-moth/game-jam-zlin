shader_type canvas_item;

uniform float health_ratio : hint_range(0.0, 1.0) = 1.0;
uniform float min_brightness : hint_range(0.0, 1.0) = 0.25;
uniform float saturation_threshold : hint_range(0.0, 1.0) = 0.15;
uniform float lightness_threshold : hint_range(0.0, 1.0) = 0.25;
uniform float blend_sharpness : hint_range(1.0, 20.0) = 10.0;

vec2 rgb_to_sl(vec3 c) {
	float max_c = max(c.r, max(c.g, c.b));
	float min_c = min(c.r, min(c.g, c.b));
	float l = (max_c + min_c) * 0.5;
	float s = 0.0;
	if (max_c != min_c) {
		float d = max_c - min_c;
		s = l > 0.5 ? d / (2.0 - max_c - min_c) : d / (max_c + min_c);
	}
	return vec2(s, l);
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);

	vec2 sl = rgb_to_sl(tex.rgb);
	float sat = sl.x;
	float lightness = sl.y;

	float sat_mask = 1.0 - clamp((sat - saturation_threshold) * blend_sharpness, 0.0, 1.0);
	float light_mask = clamp((lightness - lightness_threshold) * blend_sharpness, 0.0, 1.0);
	float white_mask = sat_mask * light_mask;

	float brightness = mix(min_brightness, 1.0, health_ratio);

	vec3 dimmed = tex.rgb * brightness;
	vec3 final_color = mix(tex.rgb, dimmed, white_mask);

	COLOR = vec4(final_color, tex.a);
}
