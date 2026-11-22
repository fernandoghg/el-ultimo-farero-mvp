shader_type spatial;
#include "noise.gdshaderinc"

uniform vec4 upper_stone : source_color = vec4(0.44, 0.47, 0.44, 1.0);
uniform vec4 deep_stone : source_color = vec4(0.23, 0.30, 0.35, 1.0);
uniform vec4 seam : source_color = vec4(0.64, 0.58, 0.47, 1.0);
uniform vec4 moss : source_color = vec4(0.43, 0.49, 0.28, 1.0);

varying vec3 world_position;
varying vec3 world_normal;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = MODEL_NORMAL_MATRIX * NORMAL;
}

void fragment() {
	vec3 p = world_position;
	float facing_up = max(normalize(world_normal).y, 0.0);
	float landscape = noise2(p.xz * 0.33 + 8.3);
	float grain = noise2(p.xz * 4.8 + p.y * vec2(3.3, 2.1));
	float fracture = noise2(p.xz * 1.25 + p.y * vec2(0.66, -0.49));
	float elevation = smoothstep(-5.8, -0.35, p.y + landscape * 1.6);
	vec3 rock = mix(deep_stone.rgb, upper_stone.rgb, elevation);
	float tilted = p.y + p.x * 0.10 - p.z * 0.065 + landscape * 0.55 + fracture * 0.20;
	float band = abs(fract(tilted * 1.58) - 0.47);
	float exposed = smoothstep(0.31, 0.73, landscape * 0.57 + fracture * 0.45 + grain * 0.14);
	rock = mix(rock, seam.rgb, (1.0 - smoothstep(0.03, 0.17, band)) * exposed * 0.54);
	rock *= 0.80 + landscape * 0.25 + fracture * 0.17 + grain * 0.10;
	float turf = smoothstep(-0.30, 0.04, p.y + (fracture - 0.5) * 0.59) *
		smoothstep(0.22, 0.69, fracture + facing_up * 0.34);
	float lichen = smoothstep(0.56, 0.80, grain * 0.52 + landscape * 0.38 + facing_up * 0.23) *
		smoothstep(-3.1, -0.6, p.y) * 0.43;
	ALBEDO = mix(rock, moss.rgb, max(turf, lichen));
	ROUGHNESS = 0.96;
	SPECULAR = 0.12;
}
