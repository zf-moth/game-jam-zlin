shader_type canvas_item;

// 0.0 = no vignette, 1.0 = full intensity
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
// How far inward the red reaches (lower = thicker border)
uniform float vignette_radius : hint_range(0.0, 1.0) = 0.4;
// Softness of the gradient edge
uniform float softness : hint_range(0.01, 1.0) = 0.3;
// Vignette color
uniform vec4 vignette_color : source_color = vec4(0.8, 0.0, 0.0, 0.7);

void fragment() {
	// Centered UV: 0,0 = center, edges = 0.5
	vec2 uv = UV - 0.5;

	// Elliptical distance from center (1.0 at corners)
	float dist = length(uv * 2.0);

	// Vignette mask: 0 at center, 1 at edges
	float vignette = smoothstep(vignette_radius, vignette_radius + softness, dist);

	// Apply intensity
	float alpha = vignette * intensity * vignette_color.a;

	COLOR = vec4(vignette_color.rgb, alpha);
}
