shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float diamond_size : hint_range(1.0, 100.0) = 40.0;

void fragment() {
	vec2 uv = SCREEN_UV;

	vec2 grid = fract(uv * vec2(1280.0, 720.0) / diamond_size);
	float diamond = abs(grid.x - 0.5) + abs(grid.y - 0.5);

	float sweep = (uv.x + uv.y) * 0.5;

	float combined = (sweep + diamond * 0.3) / 1.3;

	float threshold = mix(-0.02, 1.02, progress);
	float mask = step(combined, threshold);

	COLOR = vec4(0.0, 0.0, 0.0, mask);
}
