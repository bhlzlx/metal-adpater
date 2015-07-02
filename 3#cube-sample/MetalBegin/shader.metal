#include <metal_stdlib>
#include <simd/simd.h>
using namespace metal;


struct vertex_t
{
    packed_float3      vert;
    packed_float3      normal;
    packed_float2      uv;
};

struct matrices
{
    float4x4    model;
    float4x4    view;
    float4x4    projection;
};

struct sceneData
{
    float4 lightPosition;
    float4 lightColor;
};

struct VertexOut
{
    float4 position[[position]];
    float2 uv;
    float  diffuse;
    float4 color;
};

vertex VertexOut vertex_shader(   device vertex_t   * _vertices [[buffer(0)]],
                                  device matrices   * _matrices[[buffer(1)]],
                                  device sceneData  * _sceneData[[buffer(2)]],
                                  unsigned int vid [[ vertex_id ]]
                               )
{
    VertexOut out;
    // 计算位置
    float4 worldPosition = _matrices->model * float4(_vertices[vid].vert, 1.0);
    out.position =  _matrices->projection * _matrices->view * worldPosition;
    // 计算漫反射系数
    out.diffuse = dot(normalize((_sceneData->lightPosition - worldPosition).xyz),normalize(_vertices->normal));
    out.uv = _vertices[vid].uv;
    out.color = float4(1.0,1.0,1.0,1.0);
    return out;
}

fragment half4 fragment_shader( VertexOut in [[stage_in]],
                               texture2d<float> texture00 [[texture(0)]],
                               sampler sampler00 [[sampler(0)]] )
{
    float4 color = texture00.sample(sampler00,in.uv);
    color = color * in.diffuse;
    return half4(color);
}

