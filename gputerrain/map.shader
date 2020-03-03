shader_type canvas_item;
render_mode unshaded;

float saturate(float x) {
	return max(0, min(1, x));
}

void fragment() {
	// Radial gradient texture
	vec3 center = vec3(0.5, 0.5, 0.5);
	float dist = distance(vec3(UV, 0.0), center);
	float value = 1.0 - dist * sqrt(2.0);
	
	COLOR = vec4(value, value, value, 1.0);
}