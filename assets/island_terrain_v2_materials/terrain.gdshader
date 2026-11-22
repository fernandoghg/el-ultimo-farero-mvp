shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec4 grass_dark : source_color = vec4(0.30, 0.40, 0.20, 1.0);
uniform vec4 grass_light : source_color = vec4(0.47, 0.54, 0.30, 1.0);
uniform vec4 soil : source_color = vec4(0.43, 0.36, 0.25, 1.0);
uniform vec4 rock_dark : source_color = vec4(0.37, 0.35, 0.31, 1.0);
uniform vec4 rock_light : source_color = vec4(0.57, 0.54, 0.47, 1.0);
varying vec3 world_position;
varying vec3 world_normal;
float hash(vec3 p) { return fract(sin(dot(p, vec3(127.1,311.7,74.7))) * 43758.5453); }
float noise3(vec3 p) {
 vec3 i = floor(p); vec3 f = fract(p); f = f*f*(3.0-2.0*f);
 return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);
}
void vertex() {
 world_position = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
 world_normal = MODEL_NORMAL_MATRIX * NORMAL;
}
void fragment() {
 vec3 p = world_position;
 float broad = noise3(p*0.38 + vec3(13.7,4.1,7.3));
 float medium = noise3(p*1.35 + vec3(4.2,12.1,1.8));
 float fine = noise3(p*7.0 + vec3(19.1,2.7,8.4));
 float variation = clamp(broad*0.73 + medium*0.27,0.0,1.0);
 vec3 grass = mix(grass_dark.rgb,grass_light.rgb,smoothstep(0.12,0.85,variation));
 float patch = smoothstep(0.68,0.86,noise3(p*0.63+vec3(5.3,0.0,19.4)));
 grass = mix(grass,soil.rgb,patch*0.85);
 float strata = sin(p.y*4.2 + broad*4.0 + medium*0.8)*0.045;
 vec3 stone = mix(rock_dark.rgb,rock_light.rgb,clamp(variation+strata,0.0,1.0));
 float grass_mask = smoothstep(0.72,0.96,normalize(world_normal).y) * smoothstep(-0.42,-0.015,p.y);
 // Sparse weathered patches blend smoothly without holes or displacement.
 float exposed = smoothstep(0.76,0.93,noise3(p*0.46+vec3(22.1,3.0,2.3)));
 grass_mask *= 1.0-exposed*0.75;
 ALBEDO = mix(stone,grass,grass_mask) * (0.97+fine*0.06);
 ROUGHNESS = 0.96;
 METALLIC = 0.0;
 SPECULAR = 0.18;
}
