shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 grass_color_1 : source_color = vec3(0.38, 0.46, 0.22);
uniform vec3 grass_color_2 : source_color = vec3(0.48, 0.52, 0.25);
uniform vec3 dirt_color : source_color = vec3(0.38, 0.28, 0.18);
uniform vec3 sand_color : source_color = vec3(0.56, 0.48, 0.36);

varying vec3 world_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 3; i++) {
		v += a * noise(p);
		p *= 2.1;
		a *= 0.5;
	}
	return v;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv_macro = world_pos.xz * 0.035;
	vec2 uv_micro = world_pos.xz * 0.4;

	float macro_n = fbm(uv_macro);
	float micro_n = noise(uv_micro);

	vec3 grass = mix(grass_color_1, grass_color_2, micro_n);
	float dirt_mask = smoothstep(0.45, 0.65, macro_n);
	vec3 ground_mix = mix(grass, dirt_color, dirt_mask);

	float sand_mask = smoothstep(0.7, 0.85, macro_n + micro_n * 0.2);
	vec3 final_color = mix(ground_mix, sand_color, sand_mask);

	ALBEDO = final_color;
	ROUGHNESS = mix(0.92, 0.78, sand_mask);
	SPECULAR = 0.18;

	float eps = 0.15;
	float nx = noise(uv_micro + vec2(eps, 0.0)) - noise(uv_micro - vec2(eps, 0.0));
	float nz = noise(uv_micro + vec2(0.0, eps)) - noise(uv_micro - vec2(0.0, eps));
	NORMAL = normalize(NORMAL + vec3(nx * 0.25, 0.0, nz * 0.25));
}
