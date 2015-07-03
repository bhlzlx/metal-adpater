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

DeviceMTL * internalDevice;

__block void OnCommandBufferCommitted(id<MTLCommandBuffer> commandBuffer)
{
    
}

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
        case GX_RAW_RGBA8888 : return  MTLPixelFormatBGRA8Unorm;
        case GX_RAW_RGB565: return MTLPixelFormatB5G6R5Unorm;
        case GX_RAW_RGBA5551: return MTLPixelFormatA1BGR5Unorm;
        case GX_RAW_DEPTH: return MTLPixelFormatDepth32Float;
            
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

GX_UINT32 BytesForPixelFormat(enum GX_PIXEL_FORMAT _fmt)
{
    switch (_fmt)
    {
        case GX_RAW_RGBA8888: return 4;
        case GX_RAW_A8      : return 1;
        case GX_RAW_L8      : return 1;
        case GX_RAW_RGB565  : return 2;
        case GX_RAW_RGBA5551: return 2;
            
        default:              return 0;
            break;
    }
    return 0;
}

MTLPrimitiveType PrimitiveType2MTL(GX_DRAW _drawType)
{
    switch (_drawType)
    {
        case GX_DRAW_TRIANGLE:
            return MTLPrimitiveTypeTriangle;
            break;
        case GX_DRAW_LINE: return MTLPrimitiveTypeLine;
        default:
            break;
    }
}


void DeviceMTL::Release()
{
    [m_mtlDevice release];
    [m_mtlCmdQueue release];
    [m_mtlDefaultCmdBuffer release];
    [m_metalLayer release];
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
    vbo->m_mtlBuffer = [buffer retain];
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
    ibo->m_mtlBuffer = [buffer retain];
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
    vbo->m_mtlBuffer = [buffer retain];
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
    
    pTexture->m_mtlTexture = [[m_mtlDevice newTextureWithDescriptor:texDesc] retain];
    [texDesc release];
    
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

IGXTex * DeviceMTL::CreateTextureDyn(GX_PIXEL_FORMAT _fmt,GX_UINT32 _nWidth,GX_UINT32 _nHeight)
{
    TextureMTL * pTexture = new TextureMTL();
    pTexture->m_bDynamic = GX_FALSE;
    pTexture->m_desc.eFormat = _fmt;
    pTexture->m_desc.eClass = GX_TEX_CLASS_STATIC_RAW;
    pTexture->m_desc.nHeight = _nHeight;
    pTexture->m_desc.nWidth = _nWidth;
    pTexture->m_nMipmapLevel = 1;
    
    MTLTextureDescriptor * texDesc = [MTLTextureDescriptor  texture2DDescriptorWithPixelFormat:PixelFormat2MTL(pTexture->m_desc.eFormat)
                                                                                         width:_nWidth
                                                                                        height:_nHeight
                                                                                     mipmapped:NO];
    pTexture->m_mtlTexture = [[m_mtlDevice newTextureWithDescriptor:texDesc] retain];
    return pTexture;
}

IGXTex * DeviceMTL::CreateChessTexture()
{
    static const unsigned while_color = 0xffffffff;
    static const unsigned black_color = 0xffff0000;
    
    unsigned bitmap[64][64];
    
    int _s,_ss,_w,_ww;
    
    for(int i = 0;i<64;++i)
    {
        _ss = 1;
        _s = i/4;
        if( _s % 2 == 0)
        {
            _ss = 0;
        }
        for(int j = 0;j<64;++j)
        {
            _ww = 1;
            _w  = j/4;
            if( _w % 2 == 0)
            {
                _ww = 0;
            }
            if(_ww == _ss)
            {
                bitmap[i][j] = while_color;
            }
            else
            {
                bitmap[i][j] = black_color;
            }
        }
    }
    
    TextureMTL * pTexture = new TextureMTL();
    pTexture->m_bDynamic = GX_FALSE;
    pTexture->m_desc.eFormat = GX_RAW_RGBA8888;
    pTexture->m_desc.eClass = GX_TEX_CLASS_STATIC_RAW;
    pTexture->m_desc.nHeight = 64;
    pTexture->m_desc.nWidth = 64;
    pTexture->m_nMipmapLevel = 4;
    
    MTLTextureDescriptor * texDesc = [MTLTextureDescriptor  texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm
                                                                                         width:64
                                                                                        height:64
                                                                                     mipmapped:YES];
    
    
    MTLRegion region = MTLRegionMake2D(0, 0, 64, 64);
    
    pTexture->m_mtlTexture = [[m_mtlDevice newTextureWithDescriptor:texDesc] retain];
    [pTexture->m_mtlTexture replaceRegion:region
                              mipmapLevel:0
                                withBytes:bitmap
                              bytesPerRow:64 * 4];
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
    
    
    return renderTarget;
}

void DeviceMTL::SetScissor(const GX_RECT * _pScissor)
{
    memcpy(&this->m_scissor,_pScissor,sizeof(GX_RECT));
}

void DeviceMTL::SetViewport(const GX_RECT * _pViewport)
{
    memcpy(&this->m_viewport,_pViewport,sizeof(GX_RECT));
}

GX_BOOL DeviceMTL::DrawIndexed( GX_DRAW _drawMode, IGXIB * _pIB, GX_UINT32 _NumVertices, GX_UINT32  _NumInstance )
{
    MTLIBO * pIBO =(MTLIBO *)_pIB;
    RenderPipelineMTL * pipeline = (RenderPipelineMTL * )this->GetCurrentRenderPipeline();
    [pipeline->m_renderCmdEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle indexCount:_NumVertices indexType:MTLIndexTypeUInt32 indexBuffer:pIBO->m_mtlBuffer indexBufferOffset:0 instanceCount:_NumInstance];
    return GX_TRUE;
}

GX_BOOL DeviceMTL::DrawPrimitives(GX_DRAW _drawMode,GX_UINT32 _NumVertices, GX_UINT32 _NumInstance)
{
    RenderPipelineMTL * pipeline = (RenderPipelineMTL * )this->GetCurrentRenderPipeline();
    [pipeline->m_renderCmdEncoder drawPrimitives:PrimitiveType2MTL(_drawMode)
                                     vertexStart:0
                                     vertexCount:_NumVertices
                                   instanceCount:_NumInstance];
    return GX_TRUE;
}

void DeviceMTL::SetCurrentRenderPipeline(IGXRenderPipeline * pipeline)
{
    this->m_pCurrentPipeline = pipeline;
}

IGXRenderPipeline * DeviceMTL::CreateRenderPipeline(GX_RENDERPIPELINE_DESC * _pDesc)
{
    RenderPipelineMTL * pRenderPipeline = new RenderPipelineMTL();
    
    pRenderPipeline->m_bDefaultPipeline = _pDesc->bMainPipeline;
    
    assert(internalDevice->m_metalLayer != nil);
    
    MTLRenderPassDescriptor * renderPassDesc = [[MTLRenderPassDescriptor alloc] init];
    pRenderPipeline->m_renderPassDesc = renderPassDesc;
    
    memcpy(&pRenderPipeline->m_desc, _pDesc, sizeof(GX_RENDERPIPELINE_DESC));
    
    pRenderPipeline->Init();
    
    return pRenderPipeline;
}

IGXEffect* DeviceMTL::CreateEffect(GX_EFFECT_DESC * _pDesc)
{
    EffectMTL * pEffect = new EffectMTL();
    memcpy(&pEffect->desc,_pDesc,sizeof(GX_EFFECT_DESC));
    MTLCompileOptions * cpOption = [[MTLCompileOptions alloc] init];
    NSError * error = nil;
    pEffect->library = [[internalDevice->m_mtlDevice newLibraryWithSource:[NSString stringWithUTF8String:_pDesc->szLibrarySource]
                                                                 options:cpOption
                                                                   error:&error] retain];
    [cpOption release];
    //assert(error == nil);
    
    MTLRenderPipelineDescriptor *pipelineDesc = [[MTLRenderPipelineDescriptor alloc] init];
    
    id<MTLFunction> vertexFunction = [pEffect->library newFunctionWithName:@"vertex_shader"];
    id<MTLFunction> fragmentFunction = [pEffect->library newFunctionWithName:@"fragment_shader"];
    [pipelineDesc setVertexFunction: vertexFunction];
    [pipelineDesc setFragmentFunction: fragmentFunction];
    [vertexFunction release];
    [fragmentFunction release];
    
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
    
    if (renderPipeline->m_desc.nRenderTargets == 0)
    {
        pipelineDesc.colorAttachments[0].pixelFormat = MTLPixelFormatInvalid;
    }

//#############
    pEffect->renderPipelineState = [[internalDevice->m_mtlDevice newRenderPipelineStateWithDescriptor:pipelineDesc error:&error] retain];
//#############
    pEffect->renderPipelineDesc = pipelineDesc;
    
    assert(error == nil);
    
    MTLDepthStencilDescriptor * depthDesc   =   [[MTLDepthStencilDescriptor alloc] init];
    depthDesc.depthCompareFunction          =   CompareFunction2MTL(_pDesc->renderState.DepthFunc);
    depthDesc.depthWriteEnabled             =   _pDesc->renderState.DepthWriteEnable;
//#############
    pEffect->depthStencilState = [[internalDevice->m_mtlDevice newDepthStencilStateWithDescriptor:depthDesc] retain];
    [depthDesc release];
    
    return pEffect;
}

IGXRenderPipeline * DeviceMTL::GetCurrentRenderPipeline()
{
    return m_pCurrentPipeline;
}

void DeviceMTL::SetCurrentEffect(IGXEffect * pEffect)
{
    m_pCurrentEffect = pEffect;
}

IGXEffect* DeviceMTL::GetCurrentEffect()
{
    return m_pCurrentEffect;
}

void DeviceMTL::OnResize(GX_UINT16 nWidth,GX_UINT16 nHeight)
{
    m_layerShouldUpdte = GX_TRUE;
    
    m_layerCurrentSize.dx = nWidth;
    m_layerCurrentSize.dy = nHeight;
    m_layerCurrentSize.x = m_layerCurrentSize.y = 0;
}

void DeviceMTL::BeginDrawing()
{
    dispatch_semaphore_wait(m_inflight_semaphore, DISPATCH_TIME_FOREVER);
    if (m_layerShouldUpdte == GX_TRUE)
    {
        CGFloat nativeScale = [[UIScreen mainScreen] nativeScale];
        [this->m_metalLayer setFrame: CGRectMake(0, 0, m_layerCurrentSize.dx, m_layerCurrentSize.dy)];
        this->m_metalLayer.drawableSize = CGSizeMake(m_layerCurrentSize.dx * nativeScale, m_layerCurrentSize.dy * nativeScale);
        m_viewport.dx = m_layerCurrentSize.dx * nativeScale;
        m_viewport.dy = m_layerCurrentSize.dy * nativeScale;
        m_layerShouldUpdte = GX_FALSE;
    }
    m_currentDrawable = m_metalLayer.nextDrawable;
}

void DeviceMTL::FlushDrawing()
{
    [m_mtlDefaultCmdBuffer addCompletedHandler: ^(id <MTLCommandBuffer> buffer )
     {
         dispatch_semaphore_signal( m_inflight_semaphore );
         [buffer release];
     }];
    [m_mtlDefaultCmdBuffer presentDrawable:m_currentDrawable];
    // Finalize rendering here & push the command buffer to the GPU
    [m_mtlDefaultCmdBuffer commit];
    m_mtlDefaultCmdBuffer = [[m_mtlCmdQueue commandBuffer] retain];
}

void DeviceMTL::EmptyFlush()
{
    dispatch_semaphore_signal( m_inflight_semaphore );
}

id<CAMetalDrawable> DeviceMTL::currentDrawable()
{
    return this->m_currentDrawable;
}

IGXDevice * CreateDevice( void * deviceContext )
{
    if (pGlobalDevice)
    {
        return pGlobalDevice;
    }
    
    id<MTLDevice> device = MTLCreateSystemDefaultDevice().retain;
    if (device == NULL)
    {
        return NULL;
    }
    DeviceMTL * pMTLDevice = new DeviceMTL();
    pMTLDevice->m_mtlDevice = device;
    pMTLDevice->m_metalLayer = [(CAMetalLayer*)deviceContext retain];
    pMTLDevice->m_metalLayer.device = device;
    pMTLDevice->m_metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    pMTLDevice->m_metalLayer.framebufferOnly = YES;
    pMTLDevice->m_contentScale = [[UIScreen mainScreen] scale];
    // 控制command buffer 的 commit数目，如果commit太多没有完成，则等待
    pMTLDevice->m_inflight_semaphore = dispatch_semaphore_create(3);
    
    CGRect layerSize =  pMTLDevice->m_metalLayer.bounds;
    
    pMTLDevice->m_metalLayer.drawableSize = CGSizeMake(layerSize.size.width * pMTLDevice->m_contentScale, layerSize.size.height * pMTLDevice->m_contentScale);
    
    pMTLDevice->m_mtlCmdQueue = [[device newCommandQueue] retain];
    pMTLDevice->m_mtlDefaultCmdBuffer = [[pMTLDevice->m_mtlCmdQueue commandBuffer] retain];
    
    internalDevice = pMTLDevice;
    pGlobalDevice = pMTLDevice;
    
    return pMTLDevice;
}


IGXDevice * pGlobalDevice;
