shader_type spatial;
#include "noise.gdshaderinc"

uniform vec4 slate : source_color = vec4(0.47, 0.51, 0.48, 1.0);
uniform vec4 limestone : source_color = vec4(0.66, 0.64, 0.53, 1.0);
uniform vec2 course_size = vec2(0.61, 0.23);
varying vec3 world_position;
varying vec3 world_normal;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = MODEL_NORMAL_MATRIX * NORMAL;
}

void fragment() {
	vec3 p = world_position;
	vec3 n = abs(normalize(world_normal));
	vec2 face = vec2(n.x > n.z ? p.z : p.x, p.y);
	if (n.y > 0.72) {
		face = p.xz;
	}
	vec2 brick = face / course_size;
	brick.x += mod(floor(brick.y), 2.0) * 0.5;
	vec2 index = floor(brick);
	vec2 local = fract(brick);
	float grain = noise2(face * 16.0);
	vec2 gap = min(local, 1.0 - local);
	float joint = smoothstep(0.025, 0.092, min(gap.x * 1.9, gap.y) + (grain - 0.5) * 0.045);
	float tint = hash21(index) * 0.69 + noise2(face * 2.6) * 0.31;
	vec3 surface = mix(slate.rgb, limestone.rgb, smoothstep(0.17, 0.87, tint));
	ALBEDO = surface * mix(0.53, 1.0, joint) * mix(0.92, 1.08, grain);
	ROUGHNESS = 0.89;
	SPECULAR = 0.15;
}
