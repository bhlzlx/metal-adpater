//
//  MTLDevice.h
//  MetalBegin
//
//  Created by mengxin on 15/6/24.
//  Copyright (c) 2015年 phantom. All rights reserved.
//

#ifndef __MetalBegin__MTLDevice__
#define __MetalBegin__MTLDevice__

#import <UIKit/UIKit.h>
#import <QuartzCore/CAMetalLayer.h>
#include "DeviceMTL.h"
#include "MTLBuffer.h"
#include "MTLEffect.h"

__block void OnCommandBufferCommitted(id<MTLCommandBuffer> commandBuffer);

MTLSamplerAddressMode AddressMode2MTL(GX_TEX_ADDRESS_MODE addressMode);

MTLSamplerMinMagFilter MinMagFilerMode2MTL(GX_TEX_FILTER filter);

MTLPixelFormat PixelFormat2MTL(GX_PIXEL_FORMAT pixelFormat);

MTLCullMode CullMode2MTL(GX_CULL_MODE mode);

MTLCompareFunction CompareFunction2MTL( GX_CMP_FUNC _func);

struct DeviceMTL : public IGXDevice
{
    // metal 的设备上下文
    CAMetalLayer*               m_metalLayer;
    //
    id<MTLDevice>               m_mtlDevice;
    id<MTLCommandQueue>         m_mtlCmdQueue;
    id<MTLCommandBuffer>        m_mtlDefaultCmdBuffer;
    // 默认FBO的render command encoder
    id<MTLRenderCommandEncoder> m_mtlRenderCmdEncoder;
    id<MTLRenderPipelineState>  m_mtlDefaultRenderPipeline;
    // viewport scissor
    GX_RECT                     m_viewport;
    GX_RECT                     m_scissor;
    
    IGXRenderPipeline*          m_pCurrentPipeline;
    IGXEffect*                  m_pCurrentEffect;
    
    float                       m_contentScale;
    
    id <CAMetalDrawable>        m_currentDrawable;
    
    dispatch_semaphore_t        m_inflight_semaphore;
    
    GX_BOOL                     m_layerShouldUpdte;
    GX_RECT                     m_layerCurrentSize;
    
    
    
    IGXVB * CreateVBO(const GX_VOID * _pData,GX_UINT32 _nSize);
    IGXIB * CreateIBO(const GX_VOID * _pData,GX_UINT32 _nSize);
    IGXVB * CreateDynVBO(GX_UINT32 _nSize);
    
    IGXTex * CreateTexture(GX_PIXEL_FORMAT _fmt, GX_VOID * _pData,GX_UINT32 _nWidth,GX_UINT32 _nHeight,GX_BOOL autoMip);
    IGXTex * CreateTextureDyn(GX_PIXEL_FORMAT _fmt, GX_UINT32 _nWidth,GX_UINT32 _nHeight);
    
    IGXDepthStencil * CreateDepthStencil(GX_DEPTH_STENCIL_DESC * pDesc);
    IGXRenderTarget * CreateRenderTarget(GX_RENDERTARGET_DESC * pDesc);
    
    IGXRenderPipeline * CreateRenderPipeline(GX_RENDERPIPELINE_DESC * _pDesc);
    
    IGXRenderPipeline * CreateCustomRenderPipeline(GX_RENDERPIPELINE_DESC * _pDesc);
    IGXRenderPipeline * CreateDefaultRenderPipeline(GX_RENDERPIPELINE_DESC * _pDesc);
    
    IGXEffect* CreateEffect(GX_EFFECT_DESC * _pDesc);
    
    GX_BOOL DrawIndexed( GX_DRAW _drawMode, IGXIB * _pIB, GX_UINT32 _NumVertices, GX_UINT32  _NumInstance );
    
    GX_BOOL DrawPrimitives(GX_DRAW _drawMode,GX_UINT32 _NumVertices, GX_UINT32 _NumInstance);
    
    void SetCurrentRenderPipeline(IGXRenderPipeline * pipeline);
    IGXRenderPipeline * GetCurrentRenderPipeline();
    void SetCurrentEffect(IGXEffect * pEffect);
    IGXEffect* GetCurrentEffect();
    
    void SetScissor(const GX_RECT * _pScissor);
    void SetViewport(const GX_RECT * _pViewport);
    
    void OnResize(GX_UINT16 nWidth,GX_UINT16 nHeight);
    
    id<CAMetalDrawable> currentDrawable();
    
    void BeginDrawing();
    void FlushDrawing();

    void Release();
};


extern DeviceMTL * internalDevice;

#endif /* defined(__MetalBegin__MTLDevice__) */
