shader_type spatial;

uniform sampler2D heightmap;

float height(vec2 uv) {
	return texture(heightmap, uv).x;
}

void vertex() {
	VERTEX.y = height(UV);
}

void fragment() {
	int size = textureSize(heightmap, 0).x;
	vec2 delta = vec2(1.0 / (float(size) / 16.0), 0.0);
	float h1 = height(UV);
	float h2 = height(UV + delta);
	float h3 = height(UV + delta.yx);
	NORMAL = (INV_CAMERA_MATRIX * vec4(normalize(vec3(h1 - h2, delta.x, h1 - h3)), 0.0)).xyz;
}
