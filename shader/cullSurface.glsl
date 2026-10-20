#[compute]
#version 450

// noise
layout(binding = 0 , rgba8) readonly uniform image2D input_noise; 
//threshold
layout(binding = 1 , std430) readonly buffer thresholdArr{
    float threshold;
    float offset;
};
// indices
layout(binding = 2 , std430) readonly buffer indices{
    int index[];
} my_indices;
//vertices
layout(binding = 3, std430) readonly buffer vertices {
    float vertex[];
} my_vertices;
//result
layout(binding = 4 , std430) writeonly restrict buffer output_indices{
    int out_index[];
} my_output;
// Invocations in the (x, y, z) dimension
layout(local_size_x = 8, local_size_y = 1, local_size_z = 1) in;


void main()
{
    uint face_idx = gl_GlobalInvocationID.x;
    uint idx_offset = face_idx * 3;

    // 1. Correct index bounds check
    if (idx_offset + 2 >= my_indices.index.length()) {
        return;
    }

    // Retrieve triangle vertex indices
    int i0 = my_indices.index[idx_offset];
    int i1 = my_indices.index[idx_offset + 1];
    int i2 = my_indices.index[idx_offset + 2];

    // Read vertex positions
    vec3 v0 = vec3(my_vertices.vertex[i0 * 3], my_vertices.vertex[i0 * 3 + 1], my_vertices.vertex[i0 * 3 + 2]);
    vec3 v1 = vec3(my_vertices.vertex[i1 * 3], my_vertices.vertex[i1 * 3 + 1], my_vertices.vertex[i1 * 3 + 2]);
    vec3 v2 = vec3(my_vertices.vertex[i2 * 3], my_vertices.vertex[i2 * 3 + 1], my_vertices.vertex[i2 * 3 + 2]);

    // 2. Compute actual centroid
    vec3 center = (v0 + v1 + v2) / 3.0;

    ivec3 iCenter = ivec3(center);
    ivec2 center2D = ivec2(iCenter.x, iCenter.z) + ivec2(int(offset), int(offset));
    vec4 noiseSample = imageLoad(input_noise, center2D);

    ivec2 size = imageSize(input_noise);

   if ((noiseSample.r < threshold) || (center2D.x >= size.x || center2D.y >= size.y)) {
        my_output.out_index[idx_offset] = 1;
        my_output.out_index[idx_offset + 1] = 1;
        my_output.out_index[idx_offset + 2] = 1;
    }
}