//
//  shader.metal
//  MetalBegin
//
//  Created by mengxin on 15/6/23.
//  Copyright (c) 2015年 phantom. All rights reserved.
//

#include <metal_stdlib>
#include <simd/simd.h>
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

// Vertex shader function
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


