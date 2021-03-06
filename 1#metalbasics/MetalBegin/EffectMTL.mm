//
//  EffectMTL.cpp
//  MetalBegin
//
//  Created by mengxin on 15/6/26.
//  Copyright (c) 2015年 phantom. All rights reserved.
//
#include "MTLDevice.h"
#include "EffectMTL.h"
#include "MTLRenderPipeline.h"
#include "MTLBuffer.h"
#include "MTLTexture.h"

void EffectMTL::SetVertexBuffer( IGXVB * _vbo,GX_UINT32 _index)
{
    // 获取当前pipeline,取得pipeline的renderEncoder
    RenderPipelineMTL * pCurrentPipeline = (RenderPipelineMTL *)pGlobalDevice->GetCurrentRenderPipeline();
    MTLVBO * vbo = (MTLVBO*)_vbo;
    
    [pCurrentPipeline->m_renderCmdEncoder setVertexBuffer:vbo->m_mtlBuffer offset:0 atIndex:_index];
}

void EffectMTL::SetVertexBuffer( IGXIB * _ibo,GX_UINT32 _index)
{
    // 获取当前pipeline,取得pipeline的renderEncoder
    RenderPipelineMTL * pCurrentPipeline = (RenderPipelineMTL *)pGlobalDevice->GetCurrentRenderPipeline();
    MTLVBO * vbo = (MTLVBO*)_ibo;
    
    [pCurrentPipeline->m_renderCmdEncoder setVertexBuffer:vbo->m_mtlBuffer offset:0 atIndex:_index];
}

void EffectMTL::SetVertexSamplerState(GX_SAMPLER_STATE * _pSamplerState,GX_UINT32 _index)
{
    // 获取当前pipeline,取得pipeline的renderEncoder
    id<MTLDevice> device = internalDevice->m_mtlDevice;
    RenderPipelineMTL * pCurrentPipeline = (RenderPipelineMTL *)pGlobalDevice->GetCurrentRenderPipeline();
    MTLSamplerDescriptor * desc = [[MTLSamplerDescriptor alloc] init];
    desc.minFilter = MinMagFilerMode2MTL(_pSamplerState->MinFilter);
    desc.magFilter = MinMagFilerMode2MTL(_pSamplerState->MagFilter);
    desc.sAddressMode = AddressMode2MTL(_pSamplerState->AddressU);
    desc.tAddressMode = AddressMode2MTL(_pSamplerState->AddressV);
    id<MTLSamplerState> samplerState = [device newSamplerStateWithDescriptor:desc];
    
    [pCurrentPipeline->m_renderCmdEncoder setVertexSamplerState:samplerState atIndex:_index];
}

void EffectMTL::SetVertexTexture(IGXTex * _pTexture,GX_UINT32 _index)
{
    // 获取当前pipeline,取得pipeline的renderEncoder
    TextureMTL * texture = (TextureMTL *)_pTexture;
    RenderPipelineMTL * pCurrentPipeline = (RenderPipelineMTL *)pGlobalDevice->GetCurrentRenderPipeline();
    [pCurrentPipeline->m_renderCmdEncoder setVertexTexture:texture->m_mtlTexture atIndex:_index];
}

void EffectMTL::SetFragmentBuffer(IGXVB * _vbo,GX_UINT32 _index)
{
    // 获取当前pipeline,取得pipeline的renderEncoder
    RenderPipelineMTL * pCurrentPipeline = (RenderPipelineMTL *)pGlobalDevice->GetCurrentRenderPipeline();
    MTLVBO * vbo = (MTLVBO*)_vbo;
    [pCurrentPipeline->m_renderCmdEncoder setFragmentBuffer:vbo->m_mtlBuffer offset:0 atIndex:_index];
}

void EffectMTL::SetFragmentSamplerState(GX_SAMPLER_STATE * _pSamplerState,GX_UINT32 _index)
{
    // 获取当前pipeline,取得pipeline的renderEncoder
    id<MTLDevice> device = internalDevice->m_mtlDevice;
    RenderPipelineMTL * pCurrentPipeline = (RenderPipelineMTL *)pGlobalDevice->GetCurrentRenderPipeline();
    MTLSamplerDescriptor * desc = [[MTLSamplerDescriptor alloc] init];
    desc.minFilter = MinMagFilerMode2MTL(_pSamplerState->MinFilter);
    desc.magFilter = MinMagFilerMode2MTL(_pSamplerState->MagFilter);
    desc.sAddressMode = AddressMode2MTL(_pSamplerState->AddressU);
    desc.tAddressMode = AddressMode2MTL(_pSamplerState->AddressV);
    id<MTLSamplerState> samplerState = [device newSamplerStateWithDescriptor:desc];
    [pCurrentPipeline->m_renderCmdEncoder setFragmentSamplerState:samplerState atIndex:_index];
}

void EffectMTL::SetFragmentTexture(IGXTex * _pTexture,GX_UINT32 _index)
{
    // 获取当前pipeline,取得pipeline的renderEncoder
    TextureMTL * texture = (TextureMTL *)_pTexture;
    RenderPipelineMTL * pCurrentPipeline = (RenderPipelineMTL *)pGlobalDevice->GetCurrentRenderPipeline();
    [pCurrentPipeline->m_renderCmdEncoder setVertexTexture:texture->m_mtlTexture atIndex:_index];
}

GX_BOOL EffectMTL::Begin()
{
    RenderPipelineMTL * pCurrentPipeline = (RenderPipelineMTL *)pGlobalDevice->GetCurrentRenderPipeline();
    id<MTLRenderCommandEncoder> encoder = pCurrentPipeline->m_renderCmdEncoder;
    // shader alpha 混合等
    [encoder setRenderPipelineState:this->renderPipelineState];
    // 深度缓冲区状态
    [encoder setDepthStencilState:this->depthStencilState];
    [encoder setCullMode: CullMode2MTL( this->desc.pRenderState->CullMode)];
    // cull
    if(this->desc.pRenderState->CullMode != GX_CULL_MODE_NONE)
    {
        GX_RECT & rect = internalDevice->m_scissor;
        MTLScissorRect scissor_rect;
        scissor_rect.x = rect.x;
        scissor_rect.y = rect.y;
        scissor_rect.width = rect.dx;
        scissor_rect.height = rect.dy;
        [encoder setScissorRect: scissor_rect];
    }
    // viewport
    GX_RECT & rect = internalDevice->m_viewport;
    MTLViewport viewport;
    viewport.width      = rect.dx;
    viewport.height     = rect.dy;
    viewport.originX    = rect.x;
    viewport.originY    = rect.y;
    viewport.znear      = 0.01;
    viewport.zfar       = 10000;
    [encoder setViewport:viewport];
    
    return GX_TRUE;
}

GX_BOOL EffectMTL::End()
{
    return GX_TRUE;
}