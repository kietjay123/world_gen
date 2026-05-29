#[compute]
#version 450

// gradient
layout(binding = 0 , rgba8) readonly uniform image2D input_gradient; 
// noise
layout(binding = 1 , rgba8) readonly uniform image2D input_noise;
//result
layout(binding = 2 , rgba8) writeonly restrict uniform image2D output_gradient_map;
// Invocations in the (x, y, z) dimension
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

float remap( float num ) 
{
    return (num + 2) / 3.0;
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
    final.r = remap(final.r);
    final.g = remap(final.g);
    final.b = remap(final.b);




    imageStore(output_gradient_map, coord, final);
}