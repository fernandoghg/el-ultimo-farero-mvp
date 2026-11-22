shader_type spatial;
#include "noise.gdshaderinc"

uniform vec4 grass_shadow : source_color = vec4(0.31, 0.41, 0.22, 1.0);
uniform vec4 grass_sun : source_color = vec4(0.53, 0.57, 0.32, 1.0);
uniform vec4 turf_edge : source_color = vec4(0.40, 0.40, 0.27, 1.0);
uniform vec4 path_earth : source_color = vec4(0.57, 0.48, 0.34, 1.0);
uniform vec4 dust : source_color = vec4(0.68, 0.59, 0.44, 1.0);
varying vec2 field;

float segment(vec2 point, vec2 start, vec2 finish) {
	vec2 leg = finish - start;
	return length(point - start - leg * clamp(dot(point - start, leg) / dot(leg, leg), 0.0, 1.0));
}

void vertex() {
	field = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	vec2 p = field;
	float broad = noise2(p * 0.48 + 8.4);
	float medium = noise2(p * 2.1 - 3.2);
	float speckle = noise2(p * 15.0);
	vec3 grass = mix(grass_shadow.rgb, grass_sun.rgb, smoothstep(0.15, 0.83, broad * 0.74 + medium * 0.26));

	float road = segment(p, vec2(-3.4, 3.8), vec2(-1.8, 2.7)) - 0.55;
	road = min(road, segment(p, vec2(-1.8, 2.7), vec2(1.45, 1.38)) - 0.63);
	road = min(road, segment(p, vec2(1.45, 1.38), vec2(1.74, -1.35)) - 0.50);
	road = min(road, segment(p, vec2(1.74, -1.35), vec2(3.75, -2.3)) - 0.63);
	road = min(road, segment(p, vec2(3.75, -2.3), vec2(4.75, -3.0)) - 0.64);
	road = min(road, segment(p, vec2(4.75, -3.0), vec2(6.1, -3.0)) - 0.65);
	road = min(road, segment(p, vec2(1.45, 1.38), vec2(3.9, 3.8)) - 0.55);
	road = min(road, segment(p, vec2(1.74, -1.35), vec2(-1.1, -3.8)) - 0.47);
	road = min(road, segment(p, vec2(-1.8, 2.7), vec2(-4.6, 1.8)) - 0.44);
	road = min(road, segment(p, vec2(11.8, -3.0), vec2(16.2, -3.0)) - 0.62);
	float track = 1.0 - smoothstep(-0.19, 0.20, road + (medium - 0.5) * 0.45 + (broad - 0.5) * 0.38);
	float edge = p.x > 9.0 ? max(abs(p.x - 15.0), abs(p.y + 3.0)) - 3.0 :
		max(abs(p.x), abs(p.y)) - 5.82;
	grass = mix(grass, turf_edge.rgb, smoothstep(-0.57, 0.02, edge + medium * 0.24) * 0.83);
	vec3 path = mix(path_earth.rgb, dust.rgb, smoothstep(0.24, 0.91, medium * 0.63 + broad * 0.37));
	ALBEDO = mix(grass, path, track * 0.90) * mix(0.90, 1.09, speckle);
	ROUGHNESS = 0.96;
	SPECULAR = 0.13;
}
