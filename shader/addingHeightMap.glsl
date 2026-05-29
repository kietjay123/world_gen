#[compute]
#version 450

// gradient
layout(binding = 0 , rgba8) readonly uniform image2D input_gradient; 
// noise
layout(binding = 1 , rgba8) readonly uniform image2D input_noise;
//result
layout(binding = 2 , rgba8) writeonly restrict uniform image2D output_height_map;
//params
layout(binding = 3 , std430) readonly buffer levels{
    float sea_level;
    float land_level;
};
// Invocations in the (x, y, z) dimension
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

float remap( int num ) 
{
    return num / 255.0;
}


void main()
{
    ivec2 coord = ivec2(gl_GlobalInvocationID.xy);

    ivec2 size = imageSize(input_noise);
    if (coord.x >= size.x || coord.y >= size.y) {
        return;
    }

    vec4 final = imageLoad(input_noise, coord);
    vec4 gradientSample = imageLoad(input_gradient, coord);
    final.rgb -= gradientSample.rgb;

    if (final.r <= sea_level) {
        final.rgb = vec3(0, 0, 1.0);
    } else if (final.r <= land_level) {
        final.rgb = vec3(0, 1.0, 0);
    } else {
        final.rgb = vec3(remap(108), remap(123), remap(109));
    }
    

    imageStore(output_height_map, coord, final);
}