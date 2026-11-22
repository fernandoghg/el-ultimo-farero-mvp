shader_type spatial;
render_mode unshaded, fog_disabled, cull_disabled;
uniform vec4 deep : source_color = vec4(0.32, 0.48, 0.56, 1.0);
uniform vec4 haze : source_color = vec4(0.51, 0.66, 0.68, 1.0);
uniform vec4 cloud : source_color = vec4(0.79, 0.80, 0.72, 1.0);
uniform sampler2D cloud_map : filter_linear_mipmap, repeat_enable;
varying vec2 world_xz;

void vertex() {
	world_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	vec2 p = world_xz * vec2(0.011, 0.015) + vec2(0.32, 0.46);
	float billows = texture(cloud_map, p).r;
	float side = texture(cloud_map, p + vec2(-0.007, 0.008)).r;
	float relief = clamp((billows - side) * 2.0, -0.15, 0.22);
	float cloud_cover = smoothstep(0.42, 0.78, billows);
	float light = pow(clamp(1.0 - distance(SCREEN_UV, vec2(0.20, -0.12)) * 0.80, 0.0, 1.0), 1.5);
	vec3 low = mix(deep.rgb, haze.rgb, light * 0.76 + 0.13);
	vec3 high = cloud.rgb * (0.89 + light * 0.29 + relief);
	ALBEDO = mix(low, high, cloud_cover * 0.75 + 0.04);
}
