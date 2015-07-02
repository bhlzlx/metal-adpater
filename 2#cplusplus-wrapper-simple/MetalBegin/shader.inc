SHADER_TEXT(
\#include <metal_stdlib>\n
\#include <simd/simd.h>\n
using namespace metal;


struct vertex_t
{
packed_float3      vert;
packed_float2      uv;
};

struct VertexOut
{
float4 position[[position]];
float2 uv;
};

vertex VertexOut vertex_shader(   device vertex_t * vertices [[ buffer(0) ]],
unsigned int vid [[ vertex_id ]]
)
{
VertexOut out;
out.position = float4(vertices[vid].vert, 1.0);
out.uv = vertices[vid].uv;
return out;
}

fragment half4 fragment_shader( VertexOut in [[stage_in]],
                                texture2d<float> texture00 [[texture(0)]],
                                sampler sampler00 [[sampler(0)]] )
{
    float4 color = texture00.sample(sampler00,in.uv);
    return half4(color);
}

);