//
//  Graphics.h
//  MetalBegin
//
//  Created by mengxin on 15/6/25.
//  Copyright (c) 2015年 phantom. All rights reserved.
//

#ifndef MetalBegin_Graphics_h
#define MetalBegin_Graphics_h

typedef unsigned char       GX_BOOL;
const GX_BOOL               GX_TRUE = 1;
const GX_BOOL               GX_FALSE = 0;

typedef void                GX_VOID;
typedef unsigned char       GX_UINT8;
typedef unsigned short      GX_UINT16;
typedef unsigned int        GX_UINT32;
typedef unsigned long long  GX_UINT64;

typedef char                GX_INT8;
typedef short               GX_INT16;
typedef int                 GX_INT32;
typedef long long           GX_INT64;

#define GX_RENDERTARGETS_MAX 4

#define GX_COLOR_BUFFER_BITS        0b1
#define GX_DEPTH_BUFFER_BITS        0b10
#define GX_STENCIL_BUFFER_BITS      0b100

#define SHADER_TEXT(text) #text

struct GX_RECT
{
    GX_UINT16   x,y,dx,dy;
};


enum GX_TEX_ADDRESS_MODE
{
    GX_TEX_ADDRESS_REPEAT,
    GX_TEX_ADDRESS_MIRROR,
    GX_TEX_ADDRESS_CLAMP,      // 其实有clamp to edge 和 clamp to zero 甚至 clamp to one几种
    GX_TEX_ADDRESS_CALMP_TO_ZERO,
    
    GX_TEX_ADDRESS_COUNT,
    GX_TEX_ADDRESS_FORCE_DWORD = 0x7fffffff
};

enum GX_TEX_FILTER
{
    GX_TEX_FILTER_NEAREST,
    GX_TEX_FILTER_LINEAR,
    GX_TEX_FILTER_MIP_NEAREST,
    GX_TEX_FILTER_MIP_LINEAR,
    
    GX_TEX_FILTER_COUNT,
    GX_TEX_FILTER_FORCE_DWORD = 0x7fffffff
};

struct GX_SAMPLER_STATE
{
    enum GX_TEX_ADDRESS_MODE     AddressU;
    enum GX_TEX_ADDRESS_MODE     AddressV;
    
    enum GX_TEX_FILTER   MinFilter;
    enum GX_TEX_FILTER   MagFilter;
};

enum GX_TEX_CLASS
{
    // 普通贴图，初化一次就不再改变，其实技术上可以改变
    GX_TEX_CLASS_STATIC_RAW,
    // 压缩贴图，比如PVRTC,生成之后改变不了
    GX_TEX_CLASS_STATIC_COMPRESSED,
    // 可以初始化为空的
    GX_TEX_CLASS_DYNAMIC,
    // 这类贴图是给FrameBufferObject,RendererBufferObject用的
    GX_TEX_CLASS_RENDERTARGET,
    // NO USE~
    GX_TEX_CLASS_COUNT,
    GX_TEX_CLASS_FORCE_DWORD = 0x7fffffff
};

enum GX_PIXEL_FORMAT
{
    // 几种常用标准非压缩格式
    GX_RAW_RGBA8888,
    GX_RAW_A8,
    GX_RAW_L8,
    GX_RAW_RGB565,
    GX_RAW_RGBA5551,
    GX_RAW_DEPTH,
    // 压缩格式
    GX_ROM_DDS,
    GX_ROM_PVRT,
    //
    GX_TEX_FORMAT_COUNT,
    GX_TEX_FORMAT_FORCE_DWORD = 0x7fffffff
};

GX_UINT32 BytesForPixelFormat(enum GX_PIXEL_FORMAT _fmt);

struct GX_TEX_DESC
{
    enum GX_TEX_CLASS        eClass;
    enum GX_PIXEL_FORMAT     eFormat;
    GX_UINT32           nWidth;
    GX_UINT32           nHeight;
};


enum GX_CMP_FUNC
{
    GX_CMP_FUNC_LESS,
    GX_CMP_FUNC_LEQUAL,
    GX_CMP_FUNC_EQUAL,
    GX_CMP_FUNC_GREATER,
    GX_CMP_FUNC_GEQUAL,
    GX_CMP_FUNC_NOT_EQUAL,
    GX_CMP_FUNC_NEVER,
    GX_CMP_FUNC_ALWAYS
};

enum GX_BLEND
{
    GX_BLEND_ZERO,
    GX_BLEND_ONE,
    GX_BLEND_SRCCOLOR,
    GX_BLEND_INVSRCCOLOR,
    GX_BLEND_SRCALPHA,
    GX_BLEND_INVSRCALPHA,
    GX_BLEND_DESTALPHA,
    GX_BLEND_INVDESTALPHA,
    GX_BLEND_DESTCOLOR,
    GX_BLEND_INVDESTCOLOR,
    GX_BLEND_SRCALPHASAT,
};

enum GX_BLEND_OP
{
    GX_BLEND_OP_ADD,
    GX_BLEND_OP_SUBTRACT,
    GX_BLEND_OP_REVSUBTRACT
};

enum GX_CULL_MODE
{
    GX_CULL_MODE_NONE,
    GX_CULL_MODE_FRONT,
    GX_CULL_MODE_BACK
};

struct IGXRenderPipeline
{
    virtual bool Begin() = 0;
    virtual bool End() = 0;
    virtual void Release() = 0;
};

struct GXRenderState
{
    // pipeline state + depth stencil state
    
    GX_BOOL     DepthWriteEnable;
    GX_BOOL     DepthTestEnable;
    GX_CMP_FUNC DepthFunc;
    
    
    // cull & sissor
    GX_BOOL     CullFaceEnable;
    GX_BOOL     SissorEnable;
    GX_CULL_MODE CullMode;
    
    
    // blend
    GX_BOOL     BlendEnable;
    GX_BLEND    BlendSrc;
    GX_BLEND    BlendDst;
    
    GX_BLEND_OP BlendOp;
    
    GXRenderState()
    {
        DepthWriteEnable = GX_TRUE;
        DepthTestEnable = GX_TRUE;
        DepthFunc = GX_CMP_FUNC_LEQUAL;
        
        CullMode = GX_CULL_MODE_NONE;
        CullFaceEnable = GX_FALSE;
        SissorEnable = GX_FALSE;
        
        BlendEnable = GX_FALSE;
        BlendSrc = GX_BLEND_ONE;
        BlendDst = GX_BLEND_ZERO;
        
        BlendOp = GX_BLEND_OP_ADD;
    }
};


struct IGXVB
{
    virtual bool SetData(const GX_VOID * _pData,GX_UINT32 _nSize) = 0;
    virtual void Release() = 0;
};

struct IGXIB
{
    virtual bool SetData(const GX_VOID * _pData,GX_UINT32 _nSize) = 0;
    virtual void Release() = 0;
};

struct IGXTex
{
    virtual void SetData(const GX_VOID * _pData) = 0;
    virtual void SetSubData(const GX_VOID * _pData,GX_RECT * _pRect) = 0;
    virtual void Release() = 0;
};

struct GX_EFFECT_DESC
{
    const char *                szLibrarySource;
    const GXRenderState         renderState;
    const GX_SAMPLER_STATE *    pSamplerState;
    GX_UINT32                   nSamplerStateCount;
};

struct IGXEffect
{
    virtual void SetVertexBuffer( IGXVB * _vbo,GX_UINT32 _index) = 0;
    virtual void SetVertexBuffer( IGXIB * _ibo,GX_UINT32 _index) = 0;
    virtual void SetVertexSamplerState(GX_SAMPLER_STATE * _pSamplerState,GX_UINT32 _index) = 0;
    virtual void SetVertexTexture(IGXTex * _pTexture,GX_UINT32 _index) = 0;
    
    virtual void SetFragmentBuffer(IGXVB * _vbo,GX_UINT32 _index) = 0;
    virtual void SetFragmentSamplerState(GX_SAMPLER_STATE * _pSamplerState,GX_UINT32 _index) = 0;
    virtual void SetFragmentTexture(IGXTex * _pTexture,GX_UINT32 _index) = 0;
    
    virtual GX_BOOL Begin() = 0;
    virtual GX_BOOL End() = 0;
    
    virtual void Release() = 0;
};


// 我们的深度，模板缓冲区一律为 24bit 8bit,所以这里就不写像素类型描述了
struct GX_DEPTH_STENCIL_DESC
{
    IGXTex  * texture;
    
    GX_UINT16 nWidth;
    GX_UINT16 nHeight;
};

// 渲染缓冲区需要指定像素格式
struct GX_RENDERTARGET_DESC
{
    IGXTex *  texture;
    
    GX_UINT16 nWidth;
    GX_UINT16 nHeight;
    
    GX_PIXEL_FORMAT eFormat;
};

struct IGXDepthStencil
{
    virtual const GX_DEPTH_STENCIL_DESC * GetDesc() = 0;
    virtual IGXTex * GetTexture() = 0;
    virtual void Release() = 0;
};

struct IGXRenderTarget
{
    virtual const GX_RENDERTARGET_DESC * GetDesc() = 0;
    virtual IGXTex * GetTexture() = 0;
    virtual void Release() = 0;
};

struct GX_CLEAR
{
    GX_UINT8    clearMask;          //  GX_COLOR_BUFFER_BITS GX_DEPTH_BUFFER_BITS GX_STENCIL_BUFFER_BITS
    float       vColorValues[4];
    float       fDepthValue;
    GX_UINT8    nStencilValue;
    GX_CLEAR()
    {
        clearMask = GX_COLOR_BUFFER_BITS | GX_DEPTH_BUFFER_BITS | GX_STENCIL_BUFFER_BITS;
        vColorValues[0] = 0.8f; vColorValues[1] = 0.8f; vColorValues[2] = 0.8f; vColorValues[3] = 1.0f;
        fDepthValue = 1.0f;
        nStencilValue = 0x0;
    }
};

// 一个 RenderPipeline相当于一个 FrameBufferObject
struct GX_RENDERPIPELINE_DESC
{
    GX_BOOL           bMainPipeline;        // 默认的FBO
    IGXDepthStencil * pDepthStencil;
    IGXRenderTarget * pRenderTargets[GX_RENDERTARGETS_MAX];
    GX_UINT8          nRenderTargets;
    GX_CLEAR          clearOp;
};

enum GX_DRAW
{
    GX_DRAW_TRIANGLE,
    GX_DRAW_LINE
};



struct IGXDevice
{
    virtual IGXVB * CreateVBO(const GX_VOID * _pData,GX_UINT32 _nSize) = 0;
    virtual IGXIB * CreateIBO(const GX_VOID * _pData,GX_UINT32 _nSize) = 0;
    virtual IGXVB * CreateDynVBO(GX_UINT32 _nSize) = 0;
    
    virtual IGXTex * CreateTexture(GX_PIXEL_FORMAT _fmt, GX_VOID * _pData,GX_UINT32 _nWidth,GX_UINT32 _nHeight,GX_BOOL autoMip) = 0;
    virtual IGXTex * CreateTextureDyn(GX_PIXEL_FORMAT _fmt,GX_UINT32 _nWidth,GX_UINT32 _nHeight) = 0;
    virtual IGXTex * CreateChessTexture() = 0;
    
    virtual IGXRenderTarget * CreateRenderTarget(GX_RENDERTARGET_DESC * _pDesc) = 0;
    virtual IGXDepthStencil * CreateDepthStencil(GX_DEPTH_STENCIL_DESC * _pDesc) = 0;
    virtual IGXRenderPipeline * CreateCustomRenderPipeline(GX_RENDERPIPELINE_DESC * _pDesc) = 0;
    virtual IGXRenderPipeline * CreateDefaultRenderPipeline(GX_RENDERPIPELINE_DESC * _pDesc) = 0;
    
    virtual void SetCurrentRenderPipeline(IGXRenderPipeline * pipeline) = 0;
    
    virtual IGXEffect* CreateEffect(GX_EFFECT_DESC * _pDesc) = 0;
    
    virtual GX_BOOL DrawIndexed( GX_DRAW _drawMode, IGXIB * _pIB, GX_UINT32 _NumVertices, GX_UINT32  _NumInstance ) = 0;
    virtual GX_BOOL DrawPrimitives(GX_DRAW _drawMode,GX_UINT32 _NumVertices, GX_UINT32 _NumInstance) = 0;
    
    virtual void SetScissor(const GX_RECT * _pScissor) = 0;
    virtual void SetViewport(const GX_RECT * _pViewport) = 0;
    
    
    virtual IGXRenderPipeline * GetCurrentRenderPipeline() = 0;
    virtual void SetCurrentEffect(IGXEffect * pEffect) = 0;
    virtual IGXEffect* GetCurrentEffect() = 0;
    
    virtual void OnResize(GX_UINT16 nWidth,GX_UINT16 nHeight) = 0;
    
    virtual void BeginDrawing() = 0;
    virtual void FlushDrawing() = 0;
    virtual void EmptyFlush() = 0;
    virtual void Release() = 0;
    
};

IGXDevice * CreateDevice( void * deviceContext );

extern IGXDevice * pGlobalDevice;

#endif
