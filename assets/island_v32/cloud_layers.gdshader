shader_type spatial;
render_mode unshaded, fog_disabled, cull_disabled, depth_draw_never;

uniform sampler2D cloud_map : filter_linear_mipmap, repeat_enable;
uniform vec2 field_scale = vec2(0.010, 0.014);
uniform vec2 field_offset = vec2(0.0);
uniform vec2 coverage = vec2(0.42, 0.74);
uniform float opacity = 0.66;
uniform vec4 cloud_shadow : source_color = vec4(0.55, 0.67, 0.69, 1.0);
uniform vec4 cloud_light : source_color = vec4(0.94, 0.88, 0.73, 1.0);
varying vec2 world_xz;

void vertex() {
	world_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	vec2 uv = world_xz * field_scale + field_offset;
	float banks = texture(cloud_map, uv).r;
	float sun_side = texture(cloud_map, uv + vec2(-0.012, 0.008)).r;
	float detail = texture(cloud_map, vec2(-uv.y, uv.x) * 2.13 + 0.23).r;
	float density = banks * 0.84 + detail * 0.16;
	float illumination = smoothstep(-0.10, 0.18, banks - sun_side + (detail - 0.5) * 0.15);
	ALBEDO = mix(cloud_shadow.rgb, cloud_light.rgb, illumination);
	ALPHA = smoothstep(coverage.x, coverage.y, density) * opacity;
}
