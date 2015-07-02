//
//  MTLRenderPipeline.h
//  MetalBegin
//
//  Created by mengxin on 15/6/25.
//  Copyright (c) 2015年 phantom. All rights reserved.
//

#ifndef __MetalBegin__MTLRenderPipeline__
#define __MetalBegin__MTLRenderPipeline__

#import <metal/metal.h>
#import <QuartzCore/CAMetalLayer.h>
#include "Graphics.h"

struct RenderTargetMTL:public IGXRenderTarget
{
    GX_RENDERTARGET_DESC    desc;
    IGXTex *                m_pTexture;
    
    
    const GX_RENDERTARGET_DESC * GetDesc();
    IGXTex * GetTexture();
    void Release();
};

struct DepthStencilMTL:public IGXDepthStencil
{
    GX_DEPTH_STENCIL_DESC   desc;
    IGXTex *                m_pTexture;
    
    const GX_DEPTH_STENCIL_DESC * GetDesc();
    IGXTex * GetTexture();
    void Release();
};

struct RenderPipelineMTL:public IGXRenderPipeline
{
    CAMetalLayer*                           contexRef;
    
    GX_RENDERPIPELINE_DESC                  m_desc;
    
    GX_BOOL                                 m_bDefaultPipeline;
    
    MTLRenderPassDescriptor *               m_renderPassDesc;
    
    id<MTLRenderCommandEncoder>             m_renderCmdEncoder;
    
    bool Begin();
    bool End();
    void Release();
    
    void Init();
};



#endif /* defined(__MetalBegin__MTLRenderPipeline__) */
