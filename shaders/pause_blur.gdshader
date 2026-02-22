shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float blur_amount : hint_range(0.0, 10.0) = 10.0;

void fragment() {
	vec2 ps = SCREEN_PIXEL_SIZE * blur_amount;
	vec4 col = vec4(0.0);

	col += textureLod(screen_tex, SCREEN_UV + vec2(-2.0, -2.0) * ps, 0.0) * 0.0162;
	col += textureLod(screen_tex, SCREEN_UV + vec2(0.0, -2.0) * ps, 0.0) * 0.0405;
	col += textureLod(screen_tex, SCREEN_UV + vec2(2.0, -2.0) * ps, 0.0) * 0.0162;
	col += textureLod(screen_tex, SCREEN_UV + vec2(-1.0, -1.0) * ps, 0.0) * 0.0648;
	col += textureLod(screen_tex, SCREEN_UV + vec2(1.0, -1.0) * ps, 0.0) * 0.0648;
	col += textureLod(screen_tex, SCREEN_UV + vec2(-2.0, 0.0) * ps, 0.0) * 0.0405;
	col += textureLod(screen_tex, SCREEN_UV + vec2(-1.0, 0.0) * ps, 0.0) * 0.0810;
	col += textureLod(screen_tex, SCREEN_UV + vec2(0.0, 0.0) * ps, 0.0) * 0.1013;
	col += textureLod(screen_tex, SCREEN_UV + vec2(1.0, 0.0) * ps, 0.0) * 0.0810;
	col += textureLod(screen_tex, SCREEN_UV + vec2(2.0, 0.0) * ps, 0.0) * 0.0405;
	col += textureLod(screen_tex, SCREEN_UV + vec2(-1.0, 1.0) * ps, 0.0) * 0.0648;
	col += textureLod(screen_tex, SCREEN_UV + vec2(1.0, 1.0) * ps, 0.0) * 0.0648;
	col += textureLod(screen_tex, SCREEN_UV + vec2(0.0, 2.0) * ps, 0.0) * 0.0405;

	col.rgb *= 0.6;
	col.a = 1.0;
	COLOR = col;
}
