//
//  EffectMTL.h
//  MetalBegin
//
//  Created by mengxin on 15/6/26.
//  Copyright (c) 2015年 phantom. All rights reserved.
//

#ifndef __MetalBegin__EffectMTL__
#define __MetalBegin__EffectMTL__

#include "Graphics.h"
#import <Metal/Metal.h>

struct EffectMTL : public IGXEffect
{
    
    GX_EFFECT_DESC                  desc;
    id<MTLLibrary>                  library;
    MTLRenderPipelineDescriptor*    renderPipelineDesc;
    id<MTLRenderPipelineState>      renderPipelineState;
    id<MTLDepthStencilState>        depthStencilState;
    
    void SetVertexBuffer( IGXVB * _vbo,GX_UINT32 _index);
    void SetVertexBuffer( IGXIB * _ibo,GX_UINT32 _index);
    void SetVertexSamplerState(GX_SAMPLER_STATE * _pSamplerState,GX_UINT32 _index);
    void SetVertexTexture(IGXTex * _pTexture,GX_UINT32 _index);
        
    void SetFragmentBuffer(IGXVB * _vbo,GX_UINT32 _index) ;
    void SetFragmentSamplerState(GX_SAMPLER_STATE * _pSamplerState,GX_UINT32 _index);
    void SetFragmentTexture(IGXTex * _pTexture,GX_UINT32 _index);
    
    GX_BOOL Begin();
    GX_BOOL End();
    
    void Release();
};

#endif /* defined(__MetalBegin__EffectMTL__) */
