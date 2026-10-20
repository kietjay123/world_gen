shader_type spatial;
render_mode blend_mix, depth_draw_opaque, diffuse_burley, specular_schlick_ggx, cull_disabled;

uniform float density = 300.0;
uniform float sparistyRamp = 0.1;
uniform int currentLayer = 0;
uniform int layerCount = 7;
uniform vec4[5] colors : source_color;

float rand(vec2 c) {
    return fract(sin(dot(c.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

vec3 randALBEDO(float seed) {
	int index = int(floor(seed * float(colors.length())));
	return colors[index].rgb;
}

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec2 seed = floor(UV * density);
	float sampler = rand(seed);
	if (sampler > 0.3 + (sparistyRamp * float(currentLayer))) {
		ALBEDO = randALBEDO(sampler);
	}else{
		discard;
	}
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
