shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// Qoraqum Sarobi Sahrosi - Qum va qum to'lqinlari shaderi (Procedural Desert Dune Shader)
uniform vec3 sand_color_base : source_color = vec3(0.86, 0.64, 0.35); // Oltin-sariq qum
uniform vec3 sand_color_dune : source_color = vec3(0.95, 0.76, 0.45); // Quyosh tushgan qum qiri
uniform vec3 sand_color_shadow : source_color = vec3(0.72, 0.48, 0.24); // Qum soyasi

uniform float ripple_frequency = 8.0;
uniform float ripple_strength = 0.35;
uniform float rough_base = 0.85;

varying vec3 v_world_pos;
varying vec3 v_world_normal;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz;
}

void fragment() {
	// Qum to'lqinlari (Wind dune ripples)
	vec2 uv = v_world_pos.xz * 0.15;
	float ripples = sin(uv.x * ripple_frequency + sin(uv.y * 3.0) * 1.5) * 0.5 + 0.5;
	ripples = pow(ripples, 2.0);

	// Normal qiyaligiga qarab qum soyasi va nurlanishini hisoblash
	float slope = clamp(dot(v_world_normal, vec3(0.0, 1.0, 0.0)), 0.0, 1.0);
	vec3 col = mix(sand_color_shadow, sand_color_base, slope);
	col = mix(col, sand_color_dune, ripples * ripple_strength);

	// Yengil issiqlik porlashi (Heat shimmer subtle specular)
	ALBEDO = col;
	ROUGHNESS = mix(rough_base, 0.6, ripples * 0.4);
	METALLIC = 0.05;
	SPECULAR = 0.2;
}
