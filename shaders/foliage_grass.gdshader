shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform vec3 base_color : source_color = vec3(0.24, 0.34, 0.12);
uniform vec3 tip_color : source_color = vec3(0.62, 0.72, 0.26);
uniform vec3 flower_color : source_color = vec3(0.92, 0.18, 0.18);
uniform float wind_speed = 2.4;
uniform float wind_strength = 0.22;

varying vec3 world_pos;
varying float is_flower;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float rnd = hash(MODEL_MATRIX[3].xz * 0.1);
	is_flower = step(0.88, rnd); // Taxminan 12% o'tlar lola/gul bo'ladi

	// Faqat o'tning yuqori qismi shamolda tebranadi (UV.y = 0 tepa, UV.y = 1 asos)
	float sway_factor = clamp(1.0 - UV.y, 0.0, 1.0);
	float wave = sin(TIME * wind_speed + world_pos.x * 0.7 + world_pos.z * 0.5);
	float gust = cos(TIME * (wind_speed * 0.6) + world_pos.z * 0.4);

	VERTEX.x += (wave + gust * 0.5) * wind_strength * sway_factor;
	VERTEX.z += (wave * 0.7) * wind_strength * sway_factor;
	VERTEX.y -= abs(wave) * 0.06 * sway_factor; // Egilish
}

void fragment() {
	float t = clamp(1.0 - UV.y, 0.0, 1.0);
	vec3 grass_col = mix(base_color, tip_color, t * t);

	// Agar gul bo'lsa, tepasiga qizil lola rangi beriladi
	vec3 final_col = mix(grass_col, flower_color, is_flower * smoothstep(0.6, 0.95, t));

	ALBEDO = final_col;
	ROUGHNESS = 0.85;
	SPECULAR = 0.2;
	BACKLIGHT = vec3(0.25, 0.35, 0.15); // Quyosh nuri o't ichidan o'tishi (translucency)
}
