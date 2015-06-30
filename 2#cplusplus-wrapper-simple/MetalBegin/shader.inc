SHADER_TEXT(
\#include <metal_stdlib>\n
\#include <simd/simd.h>\n
using namespace metal;


struct vertex_t
{
    packed_float3      vert;
    packed_float3      color;
};

struct VertexOut
{
    float4 position[[position]];
    float3 color;
};
            
vertex VertexOut vertex_shader(   device vertex_t * vertices [[ buffer(0) ]],
                               unsigned int vid [[ vertex_id ]]
                               )
{
    VertexOut out;
    out.position = float4(vertices[vid].vert, 1.0);
    out.color = vertices[vid].color;
    return out;
}

fragment half4 fragment_shader( VertexOut in [[stage_in]] )
{
    return half4(in.color.x,in.color.y,in.color.z,1.0f);
}
            
);