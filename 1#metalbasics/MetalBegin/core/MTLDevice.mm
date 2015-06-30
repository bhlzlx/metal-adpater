//
//  MTLDevice.cpp
//  MetalBegin
//
//  Created by mengxin on 15/6/24.
//  Copyright (c) 2015年 phantom. All rights reserved.
//

#include "MTLDevice.h"
#include "MTLTexture.h"
#include "MTLRenderPipeline.h"
#include "EffectMTL.h"

MTLSamplerAddressMode AddressMode2MTL(GX_TEX_ADDRESS_MODE addressMode)
{
    switch (addressMode)
    {
        case GX_TEX_ADDRESS_REPEAT: return MTLSamplerAddressModeRepeat;
        case GX_TEX_ADDRESS_CLAMP: return MTLSamplerAddressModeClampToEdge;
        case GX_TEX_ADDRESS_MIRROR: return MTLSamplerAddressModeMirrorRepeat;
        case GX_TEX_ADDRESS_CALMP_TO_ZERO: return MTLSamplerAddressModeClampToZero;
        default: return MTLSamplerAddressModeRepeat;
    }
}

MTLSamplerMinMagFilter MinMagFilerMode2MTL(GX_TEX_FILTER filter)
{
    switch (filter)
    {
        case GX_TEX_FILTER_LINEAR: return MTLSamplerMinMagFilterLinear;
        case GX_TEX_FILTER_NEAREST: return MTLSamplerMinMagFilterNearest;
        default: return MTLSamplerMinMagFilterNearest;
    }
}

MTLPixelFormat PixelFormat2MTL(GX_PIXEL_FORMAT pixelFormat)
{
    switch (pixelFormat)
    {
        case GX_RAW_A8: return MTLPixelFormatA8Unorm;
        case GX_RAW_L8: return MTLPixelFormatA8Unorm;
        case GX_RAW_RGBA8888 : return  MTLPixelFormatRGBA8Unorm;
        case GX_RAW_RGB565: return MTLPixelFormatB5G6R5Unorm;
        case GX_RAW_RGBA5551: return MTLPixelFormatA1BGR5Unorm;
            
        default: return MTLPixelFormatRGBA8Unorm;
    }
}

MTLCompareFunction CompareFunction2MTL( GX_CMP_FUNC _func)
{
    switch (_func)
    {
        case GX_CMP_FUNC_ALWAYS:    return MTLCompareFunctionAlways;
        case GX_CMP_FUNC_EQUAL :    return MTLCompareFunctionEqual;
        case GX_CMP_FUNC_LEQUAL:    return MTLCompareFunctionLessEqual;
        case GX_CMP_FUNC_GREATER:   return MTLCompareFunctionGreater;
        case GX_CMP_FUNC_GEQUAL:    return MTLCompareFunctionGreaterEqual;
        case GX_CMP_FUNC_LESS:      return MTLCompareFunctionLess;
        case GX_CMP_FUNC_NEVER:     return MTLCompareFunctionNever;
        case GX_CMP_FUNC_NOT_EQUAL: return MTLCompareFunctionNotEqual;
            
        default:                    return MTLCompareFunctionLessEqual;
    }
}

MTLCullMode CullMode2MTL(GX_CULL_MODE mode)
{
    switch (mode)
    {
        case GX_CULL_MODE_NONE: return MTLCullModeNone;
        case GX_CULL_MODE_FRONT: return MTLCullModeFront;
        case GX_CULL_MODE_BACK: return MTLCullModeBack;
            
        default:    return MTLCullModeNone;
    }
}


void DeviceMTL::Release()
{
    m_mtlDevice = nil;
    delete this;
}

IGXVB * DeviceMTL::CreateVBO(const GX_VOID *_pData, GX_UINT32 _nSize)
{
    id<MTLBuffer> buffer = [m_mtlDevice newBufferWithBytes:_pData length:_nSize options:MTLResourceOptionCPUCacheModeDefault];
    if (buffer == nil)
    {
        return NULL;
    }
    
    MTLVBO * vbo = new MTLVBO();
    vbo->m_mtlBuffer = buffer;
    vbo->m_nLength = _nSize;
    vbo->m_bDynamic = GX_FALSE;
    return vbo;
}

IGXIB * DeviceMTL::CreateIBO(const GX_VOID *_pData, GX_UINT32 _nSize)
{
    id<MTLBuffer> buffer = [m_mtlDevice newBufferWithBytes:_pData length:_nSize options:MTLResourceOptionCPUCacheModeDefault];
    if (buffer == nil)
    {
        return NULL;
    }
    
    MTLIBO * ibo = new MTLIBO();
    ibo->m_bDynamic = GX_FALSE;
    ibo->m_nLength = _nSize;
    ibo->m_mtlBuffer = buffer;
    return ibo;
}

IGXVB * DeviceMTL::CreateDynVBO(GX_UINT32 _nSize)
{
    id<MTLBuffer> buffer = [m_mtlDevice newBufferWithLength:_nSize options:MTLResourceOptionCPUCacheModeDefault];
    if (buffer == nil)
    {
        return NULL;
    }
    MTLVBO * vbo = new MTLVBO();
    vbo->m_mtlBuffer = buffer;
    vbo->m_nLength = _nSize;
    vbo->m_bDynamic = GX_TRUE;
    return vbo;
}

IGXTex * DeviceMTL::CreateTexture(GX_PIXEL_FORMAT _fmt, GX_VOID * _pData,GX_UINT32 _nWidth,GX_UINT32 _nHeight,GX_BOOL autoMip)
{
    TextureMTL * pTexture = new TextureMTL();
    pTexture->m_bDynamic = GX_FALSE;
    pTexture->m_desc.eFormat = _fmt;
    pTexture->m_desc.eClass = GX_TEX_CLASS_STATIC_RAW;
    pTexture->m_desc.nHeight = _nHeight;
    pTexture->m_desc.nWidth = _nWidth;
    if (autoMip == GX_TRUE)
    {
        pTexture->m_nMipmapLevel = 4;
    }
    else
    {
        pTexture->m_nMipmapLevel = 0;
    }
    MTLTextureDescriptor * texDesc = [[MTLTextureDescriptor alloc] init];
    texDesc.mipmapLevelCount = pTexture->m_nMipmapLevel;
    texDesc.width = pTexture->m_desc.nWidth;
    texDesc.height = pTexture->m_desc.nHeight;
    texDesc.pixelFormat = PixelFormat2MTL(pTexture->m_desc.eFormat);
    
    pTexture->m_mtlTexture = [m_mtlDevice newTextureWithDescriptor:texDesc];
    
    MTLRegion region;
    region.origin.x = 0;
    region.origin.y = 0;
    region.origin.z = 0;
    
    region.size.width = _nWidth;
    region.size.height = _nHeight;
    region.size.depth = 0;
    
    GX_UINT64 bytesPerRow = BytesForPixelFormat(pTexture->m_desc.eFormat) * _nWidth;
    [pTexture->m_mtlTexture replaceRegion:region
                              mipmapLevel:pTexture->m_nMipmapLevel
                                withBytes:_pData
                              bytesPerRow:(NSUInteger)bytesPerRow];
    
    return pTexture;
}

IGXTex * DeviceMTL::CreateTextureDyn(GX_PIXEL_FORMAT _fmt, GX_VOID * _pData,GX_UINT32 _nWidth,GX_UINT32 _nHeight)
{
    TextureMTL * pTexture = new TextureMTL();
    pTexture->m_bDynamic = GX_FALSE;
    pTexture->m_desc.eFormat = _fmt;
    pTexture->m_desc.eClass = GX_TEX_CLASS_STATIC_RAW;
    pTexture->m_desc.nHeight = _nHeight;
    pTexture->m_desc.nWidth = _nWidth;
    pTexture->m_nMipmapLevel = 0;
    
    MTLTextureDescriptor * texDesc = [[MTLTextureDescriptor alloc] init];
    texDesc.mipmapLevelCount = pTexture->m_nMipmapLevel;
    texDesc.width = pTexture->m_desc.nWidth;
    texDesc.height = pTexture->m_desc.nHeight;
    texDesc.pixelFormat = PixelFormat2MTL(pTexture->m_desc.eFormat);
    
    pTexture->m_mtlTexture = [m_mtlDevice newTextureWithDescriptor:texDesc];
    return pTexture;
}

IGXDepthStencil * DeviceMTL::CreateDepthStencil(GX_DEPTH_STENCIL_DESC * pDesc)
{
    DepthStencilMTL * depthStencil = new DepthStencilMTL();
    memcpy(&depthStencil->desc,pDesc,sizeof(GX_DEPTH_STENCIL_DESC));
    return depthStencil;
}

IGXRenderTarget * DeviceMTL::CreateRenderTarget(GX_RENDERTARGET_DESC * pDesc)
{
    RenderTargetMTL * renderTarget = new RenderTargetMTL();
    memcpy(&renderTarget->desc,pDesc,sizeof(GX_RENDERTARGET_DESC));
    
    
    return nullptr;
}

void SetScissor(const GX_RECT * _pScissor)
{
    
}

void SetViewport(const GX_RECT * _pViewport)
{
    
}

GX_BOOL DeviceMTL::DrawIndexed( GX_DRAW _drawMode, IGXIB * _pIB, GX_UINT32 _NumVertices, GX_UINT32  _NumInstance )
{
    MTLIBO * pIBO =(MTLIBO *)_pIB;
    [m_mtlRenderCmdEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle indexCount:_NumVertices indexType:MTLIndexTypeUInt32 indexBuffer:pIBO->m_mtlBuffer indexBufferOffset:0 instanceCount:_NumInstance];
    return GX_TRUE;
}

IGXRenderPipeline * DeviceMTL::CreateCustomRenderPipeline(GX_RENDERPIPELINE_DESC * _pDesc)
{
    
    return nullptr;
}

IGXRenderPipeline * DeviceMTL::CreateDefaultRenderPipeline(GX_RENDERPIPELINE_DESC * _pDesc)
{
    RenderPipelineMTL * pRenderPipeline = new RenderPipelineMTL();
    pRenderPipeline->m_bDefaultPipeline = GX_TRUE;
    
    assert(internalDevice->m_metalLayer != nil);
    m_metalLayer = internalDevice->m_metalLayer;
    
    MTLRenderPassDescriptor * renderPassDesc = [[MTLRenderPassDescriptor alloc] init];
    pRenderPipeline->m_renderPassDesc = renderPassDesc;
    
    memcpy(&pRenderPipeline->m_desc, _pDesc, sizeof(GX_RENDERPIPELINE_DESC));
    return nullptr;
}


IGXDevice * CreateDevice( void * deviceContext )
{
    if (pGlobalDevice)
    {
        return pGlobalDevice;
    }
    
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    if (device == NULL)
    {
        return NULL;
    }
    DeviceMTL * pMTLDevice = new DeviceMTL();
    pMTLDevice->m_mtlDevice = device;
    pMTLDevice->m_metalLayer = (__bridge CAMetalLayer*)deviceContext;
    
    internalDevice = pMTLDevice;
    pGlobalDevice = pMTLDevice;
    return pMTLDevice;
}

IGXEffect* CreateEffect(GX_EFFECT_DESC * _pDesc)
{
    EffectMTL * pEffect = new EffectMTL();
    memcpy(&pEffect->desc,_pDesc,sizeof(GX_EFFECT_DESC));
    MTLCompileOptions * cpOption = [[MTLCompileOptions alloc] init];
    NSError * error = nil;
    pEffect->library = [internalDevice->m_mtlDevice newLibraryWithSource:[NSString stringWithUTF8String:_pDesc->szLibrarySource]
                                                                 options:cpOption
                                                                   error:&error];
    assert(error == nil);
    
    MTLRenderPipelineDescriptor *pipelineDesc = [[MTLRenderPipelineDescriptor alloc] init];
    
    [pipelineDesc setVertexFunction: [pEffect->library newFunctionWithName:@"shader_vertex"]];
    [pipelineDesc setFragmentFunction: [pEffect->library newFunctionWithName:@"shader_fragment"]];
    
    [pipelineDesc setAlphaToCoverageEnabled:YES];
    [pipelineDesc setDepthAttachmentPixelFormat:MTLPixelFormatDepth32Float];
    [pipelineDesc setAlphaToOneEnabled:YES];
    [pipelineDesc setSampleCount:1];

    RenderPipelineMTL * renderPipeline = (RenderPipelineMTL *)internalDevice->GetCurrentRenderPipeline();
    
    for (int i = 0; i<renderPipeline->m_desc.nRenderTargets; ++i)
    {
        RenderTargetMTL * pRenderTarget = (RenderTargetMTL *)renderPipeline->m_desc.pRenderTargets[i];
        pipelineDesc.colorAttachments[i].pixelFormat =  PixelFormat2MTL(pRenderTarget->desc.eFormat);
    }
    pEffect->renderPipelineState = [internalDevice->m_mtlDevice newRenderPipelineStateWithDescriptor:pipelineDesc error:&error];
    assert(error == nil);
    
    MTLDepthStencilDescriptor * depthDesc   =   [[MTLDepthStencilDescriptor alloc] init];
    depthDesc.depthCompareFunction          =   CompareFunction2MTL(_pDesc->pRenderState->DepthFunc);
    depthDesc.depthWriteEnabled             =   _pDesc->pRenderState->DepthWriteEnable;
    
    pEffect->depthStencilState = [internalDevice->m_mtlDevice newDepthStencilStateWithDescriptor:depthDesc];
    
    return pEffect;
}

IGXDevice * pGlobalDevice;
