// NOTE: Shader automatically converted from Godot Engine 4.7.2.stable's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;
//stencil_mode write, compare_always, 1;

uniform bool vertexColor;

uniform sampler2D dirt_tex  : source_color, repeat_enable, filter_linear_mipmap;
uniform vec4 albedo_dirt : source_color;
uniform float mul_dirt;
uniform sampler2D sand_tex  : source_color, repeat_enable, filter_linear_mipmap;
uniform vec4 albedo_sand : source_color;
uniform float mul_sand;
uniform sampler2D grass_tex : source_color, repeat_enable, filter_linear_mipmap;
uniform vec4 albedo_grass : source_color;
uniform float mul_grass;
uniform sampler2D rock_tex  : source_color, repeat_enable, filter_linear_mipmap;
uniform vec4 albedo_rock : source_color;
uniform float mul_rock;
uniform sampler2D top_tex  : source_color, repeat_enable, filter_linear_mipmap;
uniform vec4 albedo_top : source_color;
uniform float mul_top;
uniform sampler2D road_tex  : source_color, repeat_enable, filter_linear_mipmap;
uniform vec4 albedo_road : source_color;
uniform float mul_road;

// Each material's band in the red channel: x = min, y = max
uniform vec2 sand_range  = vec2(0.98, 1.0);
uniform vec2 dirt_range  = vec2(0.21, 0.25);
uniform vec2 grass_range = vec2(0.08, 0.12);
uniform vec2 rock_range  = vec2(0.13, 0.17);
uniform vec2 top_range  = vec2(0.33, 0.37);
uniform vec2 road_range  = vec2(0.04, 0.08);

uniform float tolerance = 0.005; // absorbs 8-bit quantization / float error

varying flat float mask;
varying vec3 world_pos;
varying vec3 world_normal;
uniform float tile_size = 4.0;

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform ivec2 albedo_texture_size;
uniform float point_size : hint_range(0.1, 128.0, 0.1);

uniform float roughness : hint_range(0.0, 1.0);
uniform sampler2D texture_metallic : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness : hint_roughness_r, filter_linear_mipmap, repeat_enable;

uniform float specular : hint_range(0.0, 1.0, 0.01);
uniform float metallic : hint_range(0.0, 1.0, 0.01);

uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

void vertex() {
	UV = UV * uv1_scale.xy + uv1_offset.xy;
	mask = COLOR.r;
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

float in_range(float m, vec2 r) {
    return step(r.x - tolerance, m) * step(m, r.y + tolerance);
}


vec3 triplanar(sampler2D tex, vec3 p, vec3 n) {
    vec3 w = pow(abs(n), vec3(4.0));   // higher = sharper blend
    w /= (w.x + w.y + w.z);
    vec3 x = texture(tex, p.zy / tile_size).rgb;
    vec3 y = texture(tex, p.xz / tile_size).rgb;
    vec3 z = texture(tex, p.xy / tile_size).rgb;
    return x * w.x + y * w.y + z * w.z;
}

void fragment() {
	vec2 base_uv = UV;

	vec4 albedo_tex = texture(texture_albedo, base_uv);

	// Vertex Color Use as Albedo: Enabled
	if (vertexColor) {
		albedo_tex *= COLOR;
	} else {
		vec3 col = vec3(0.0);
		col += triplanar(dirt_tex,  world_pos, world_normal) * in_range(mask, dirt_range) * albedo_dirt.rgb * mul_dirt;
		col += triplanar(sand_tex,  world_pos, world_normal) * in_range(mask, sand_range) * albedo_sand.rgb * mul_sand;
		col += triplanar(grass_tex, world_pos, world_normal) * in_range(mask, grass_range) * albedo_grass.rgb * mul_grass;
		col += triplanar(rock_tex,  world_pos, world_normal) * in_range(mask, rock_range) * albedo_rock.rgb * mul_rock;
		col += triplanar(top_tex,  world_pos, world_normal) * in_range(mask, top_range) * albedo_top.rgb * mul_top;
		col += triplanar(road_tex,  world_pos, world_normal) * in_range(mask, road_range) * albedo_road.rgb * mul_road;
		albedo_tex.rgb = col;
	}
	

	ALBEDO = albedo.rgb * albedo_tex.rgb;

	float metallic_tex = dot(texture(texture_metallic, base_uv), metallic_texture_channel);
	METALLIC = metallic_tex * metallic;
	SPECULAR = specular;

	vec4 roughness_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
	float roughness_tex = dot(texture(texture_roughness, base_uv), roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;
}
