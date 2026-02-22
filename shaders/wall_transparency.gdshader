shader_type canvas_item;

uniform vec2 player_pos = vec2(0.0, 0.0);
uniform bool player_under_wall = false;
uniform float inner_radius = 40.0;
uniform float outer_radius = 120.0;
uniform float min_alpha = 0.3;

varying vec2 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);

	if (player_under_wall) {
		float dist = distance(world_position, player_pos);
		if (dist < outer_radius) {
			float alpha_factor = smoothstep(inner_radius, outer_radius, dist);
			float final_alpha = mix(min_alpha, 1.0, alpha_factor);
			COLOR = vec4(tex_color.rgb, tex_color.a * final_alpha);
		} else {
			COLOR = tex_color;
		}
	} else {
		COLOR = tex_color;
	}
}
