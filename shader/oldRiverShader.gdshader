shader_type spatial;
render_mode depth_draw_always;
// Water Color
uniform vec4 color : source_color = vec4(0.36, 0.66, 1.0, 1.0);
uniform vec4 deep_water: source_color = vec4(0.0, 0.33, 0.69, 1.0);

uniform float roughness : hint_range(0.0, 1.0) = 0.1;
uniform float metallic : hint_range(0.0, 1.0) = 0;

// Water Speed
uniform float speed: hint_range(-1, 1) = 0.1;
uniform vec2 dir = vec2(1.0, 1.0);

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// depth-fade 
uniform float beer_law_factor = 2.0;

// Water foam 
uniform vec4 edge_color: source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float edge_scale = 1.0; // Represents literal meters now

// Water Wave 
uniform float time_scale : hint_range(0.0, 0.2, 0.005) = 0.025;
uniform float height_scale = 0.15;
uniform float noise_scale = 10.0;

// Water Noise
uniform sampler2D noise1 : repeat_enable;
uniform sampler2D noise2 : repeat_enable;
uniform sampler2D wave : repeat_enable;
uniform sampler2D normalmap: hint_normal, repeat_enable;

// Varying variables
varying float height;
varying vec3 world_pos;

float fresnel(float amount, vec3 normal, vec3 view)
{
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0 )), amount);
}

// --- TRIPLANAR SAMPLING HELPER FUNCTIONS ---
vec4 sample_triplanar(sampler2D tex, vec3 packed_pos, vec3 blend) {
	float angle = atan(dir.y, dir.x);
	mat2 rotateMatrix = mat2(vec2(cos(angle), sin(angle)), vec2(-sin(angle), cos(angle)));
	vec4 x_tex = texture(tex, packed_pos.zy);
	vec4 y_tex = texture(tex, rotateMatrix * packed_pos.xz);
	vec4 z_tex = texture(tex, packed_pos.xy);
	return x_tex * blend.x + y_tex * blend.y + z_tex * blend.z;
}

vec3 sample_triplanar_normal(sampler2D tex, vec3 packed_pos, vec3 blend, vec3 base_normal) {
	vec3 x_tex = texture(tex, packed_pos.zy).rgb * 2.0 - 1.0;
	vec3 y_tex = texture(tex, packed_pos.xz).rgb * 2.0 - 1.0;
	vec3 z_tex = texture(tex, packed_pos.xy).rgb * 2.0 - 1.0;

	vec3 x_world = vec3(0.0, x_tex.y, x_tex.x);
	vec3 y_world = vec3(y_tex.x, 0.0, y_tex.y);
	vec3 z_world = vec3(z_tex.x, z_tex.y, 0.0);

	return normalize(base_normal + x_world * blend.x + y_world * blend.y + z_world * blend.z);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	height = texture(wave, world_pos.xz / noise_scale + TIME * time_scale).r;
	VERTEX.y += height * height_scale;
}

void fragment() {
	float time = TIME * speed;

	vec3 flow = vec3(normalize(dir).x, 4.0, -normalize(dir).y) * time;
	vec3 sinusoidal_orbit = vec3(sin(time * 2.0), 0.0, cos(time * 1.5)) * 0.15;
	vec3 flow_n2 = (flow * 0.2) + sinusoidal_orbit;

	vec3 w_normal = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 blend = abs(w_normal);
	blend /= (blend.x + blend.y + blend.z);

	vec3 tri_pos_n1 = (world_pos / noise_scale) + flow;
	vec3 tri_pos_n2 = (world_pos / noise_scale) + flow_n2; 
	vec3 tri_pos_normal = ((world_pos / noise_scale) * 4.0) + (flow * 4.0);

	vec3 n1 = sample_triplanar(noise1, tri_pos_n1, blend).rgb;
	vec3 n2 = sample_triplanar(noise2, tri_pos_n2, blend).rgb;
	float sum = (n1.r + n2.r) - 1.0;

	// --- FIXED: NATIVE GODOT 4 VIEW-SPACE DEPTH RECONSTRUCTION ---
	float depth_raw = texture(DEPTH_TEXTURE, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth_raw);
	vec4 view_pos = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view_pos.xyz /= view_pos.w;
	
	vec3 scene_world =
    (INV_VIEW_MATRIX * vec4(view_pos.xyz,1.0)).xyz;

	float scene_depth = -view_pos.z;
	float vertex_depth = -VERTEX.z;
	float diff = scene_depth - vertex_depth;

	// --- FIXED: BEER'S LAW DEPTH FADE ---
	float beer_fade = clamp(exp(-diff * beer_law_factor), 0.0, 1.0);
	vec4 gradientcolor = mix(deep_water, color, beer_fade);

	// Screen Refraction / Displacement
	vec2 displacement = vec2(sum * 0.01);
	vec4 alpha = texture(SCREEN_TEXTURE, SCREEN_UV + displacement);

	float foam_diff = diff + (displacement.x * 0.3); 
	float foam_mask = 1.0 - clamp(foam_diff / edge_scale, 0.0, 1.0);

	// Calculate Fresnel
	float fresnel_factor = fresnel(2.0, NORMAL, VIEW);
	vec4 surface_color = mix(color, deep_water, fresnel_factor);

	vec3 base_water_rgb = mix(gradientcolor.rgb, surface_color.rgb, fresnel_factor);
	vec3 final_water_rgb = mix(base_water_rgb, edge_color.rgb, foam_mask);

	// Procedural 3D peaks
	float fin = 0.0;
	if (sum > 0.0 && sum < 0.4) fin = 0.1;
	if (sum > 0.4 && sum < 0.8) fin = 0.0;
	if (sum > 0.8) fin = 1.0;

	// Blend water color with underlying screen background based on opacity
	float total_alpha = clamp(gradientcolor.a + foam_mask, 0.0, 1.0);
	ALBEDO = vec3(fin) + mix(alpha.rgb, final_water_rgb, total_alpha);

	// Compute stable world normal mappings
	vec3 world_nm = sample_triplanar_normal(normalmap, tri_pos_normal, blend, w_normal);
	NORMAL = (VIEW_MATRIX * vec4(world_nm, 0.0)).xyz;

	METALLIC = metallic;
	ROUGHNESS = roughness;
}