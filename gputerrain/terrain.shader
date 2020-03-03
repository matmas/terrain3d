shader_type spatial;

uniform sampler2D heightmap;

void vertex() {
	vec4 hm = texture(heightmap, UV);
	VERTEX.y = hm.x;
}