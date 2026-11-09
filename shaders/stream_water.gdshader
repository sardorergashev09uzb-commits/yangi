shader_type spatial;
render_mode blend_mix, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 water_deep : source_color = vec4(0.12, 0.35, 0.48, 0.88);
uniform vec4 water_shallow : source_color = vec4(0.25, 0.58, 0.65, 0.75);
uniform vec4 foam_color : source_color = vec4(0.92, 0.96, 1.0, 0.9);
uniform float flow_speed = 0.45;
uniform float wave_strength = 0.06;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float wave1 = sin(world_pos.x * 2.5 + TIME * (flow_speed * 4.0));
	float wave2 = cos(world_pos.z * 3.0 + TIME * (flow_speed * 3.0));
	VERTEX.y += (wave1 + wave2) * wave_strength * 0.5;
}

void fragment() {
	vec2 uv_flow = world_pos.xz * 0.25 + vec2(TIME * flow_speed, TIME * (flow_speed * 0.4));
	vec2 uv_cross = world_pos.xz * 0.3 - vec2(TIME * (flow_speed * 0.5), -TIME * (flow_speed * 0.3));

	float ripple1 = sin(uv_flow.x * 12.0 + uv_flow.y * 8.0);
	float ripple2 = cos(uv_cross.x * 10.0 - uv_cross.y * 14.0);
	float foam_pattern = smoothstep(0.65, 0.95, (ripple1 + ripple2) * 0.5);

	vec4 base_water = mix(water_deep, water_shallow, (ripple1 + 1.0) * 0.25);
	vec4 final_water = mix(base_water, foam_color, foam_pattern * 0.55);

	ALBEDO = final_water.rgb;
	ALPHA = final_water.a;
	ROUGHNESS = 0.08;
	SPECULAR = 0.82;

	// Suv yuzasi normal to'lqinlari
	vec3 norm_offset = vec3(ripple1 * 0.15, 1.0, ripple2 * 0.15);
	NORMAL = normalize(norm_offset);
}
