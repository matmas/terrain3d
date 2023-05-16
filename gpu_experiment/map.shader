shader_type canvas_item;
render_mode unshaded;

vec3 hash(vec3 p) {
	p = vec3(dot(p, vec3(127.1, 311.7, 74.7)),
			dot(p, vec3(269.5, 183.3, 246.1)),
			dot(p, vec3(113.5, 271.9, 124.6)));
	return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

float noise3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	vec3 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(dot(hash(i + vec3(0.0, 0.0, 0.0)), f - vec3(0.0, 0.0, 0.0)),
						dot(hash(i + vec3(1.0, 0.0, 0.0)), f - vec3(1.0, 0.0, 0.0)), u.x),
					mix(dot(hash(i + vec3(0.0, 1.0, 0.0)), f - vec3(0.0, 1.0, 0.0)),
						dot(hash(i + vec3(1.0, 1.0, 0.0)), f - vec3(1.0, 1.0, 0.0)), u.x), u.y),
				mix(mix(dot(hash(i + vec3(0.0, 0.0, 1.0)), f - vec3(0.0, 0.0, 1.0)),
						dot(hash(i + vec3(1.0, 0.0, 1.0)), f - vec3(1.0, 0.0, 1.0)), u.x),
					mix(dot(hash(i + vec3(0.0, 1.0, 1.0)), f - vec3(0.0, 1.0, 1.0)),
						dot(hash(i + vec3(1.0, 1.0, 1.0)), f - vec3(1.0, 1.0, 1.0)), u.x), u.y), u.z);
}

const mat2 m2 = mat2(vec2(0.80, 0.60),
					vec2(-0.60, 0.80));

float hash1(vec2 p) {
    p  = 50.0 * fract(p * 0.3183099);
    return fract(p.x * p.y * (p.x + p.y));
}

float noise(in vec2 x) {
    vec2 p = floor(x);
    vec2 w = fract(x);
    vec2 u = w*w*w*(w*(w*6.0-15.0)+10.0);

    float a = hash1(p+vec2(0,0));
    float b = hash1(p+vec2(1,0));
    float c = hash1(p+vec2(0,1));
    float d = hash1(p+vec2(1,1));

    return -1.0+2.0*( a + (b-a)*u.x + (c-a)*u.y + (a - b - c + d)*u.x*u.y );
}

float fbm_9(in vec2 x) {
    float f = 1.9;
    float s = 0.55;
    float a = 0.0;
    float b = 0.5;
    for( int i=0; i<9; i++ )
    {
        float n = noise(x);
        a += b*n;
        b *= s;
        x = f*m2*x;
    }
	return a;
}


float saturate(float x) {
	return max(0, min(1, x));
}

float radial_gradient(vec2 uv) {
	vec3 center = vec3(0.5, 0.5, 0.5);
	float dist = distance(vec3(uv, 0.0), center);
	return 1.0 - dist * sqrt(2.0);
}

float cell_noise(vec2 uv, float cell_count, float non_uniformity) {
	float closest_distance = 1.0;
	for (float y = 0.0; y < cell_count; y++) {
		for (float x = 0.0; x < cell_count; x++) {
			vec2 cell_center = (vec2(x, y) + 0.5) / cell_count;
			cell_center += non_uniformity * hash(vec3(cell_center, 0.0)).xz;
			float dist = distance(uv, cell_center);
			closest_distance = min(dist, closest_distance);
		}
	}
	return closest_distance * closest_distance * cell_count * cell_count * 4.0;
}

void fragment() {
	float value = 0.0;
	value = (1.0 + 0.3 * fbm_9(UV * 20.0)) / 2.0;

	float frequency = 2.0;
	float octaves = 4.0;
	float lacunarity = 1.0;
	for (float o = 0.0; o < octaves; o++) {
		value += 0.1 * lacunarity * o * noise(UV * frequency * (octaves + 1.0));
	}
	
	value += 0.1 * cell_noise(UV, 2.0, 0.1);
	value += 0.2 * cell_noise(UV, 4.0, 0.1);
	value += 0.4 * cell_noise(UV, 8.0, 0.1);

	value *= 0.25;
	value *= radial_gradient(UV);
	COLOR = vec4(value, value, value, 1.0);
}
