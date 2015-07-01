//
//  MTLRenderPipeline.cpp
//  MetalBegin
//
//  Created by mengxin on 15/6/25.
//  Copyright (c) 2015年 phantom. All rights reserved.
//

#include "MTLDevice.h"
#include "MTLRenderPipeline.h"
#include "MTLTexture.h"

/*
        RenderTargetMTL Imp
 */

IGXTex * RenderTargetMTL::GetTexture()
{
    return m_pTexture;
}

const GX_RENDERTARGET_DESC * RenderTargetMTL::GetDesc()
{
    return &desc;
}

void RenderTargetMTL::Release()
{
    this->m_pTexture->Release();
    delete this;
}

/************************************
        DepthStencilMTL Imp
 ************************************/

IGXTex * DepthStencilMTL::GetTexture()
{
    return m_pTexture;
}

const GX_DEPTH_STENCIL_DESC * DepthStencilMTL::GetDesc()
{
    return &desc;
}

void DepthStencilMTL::Release()
{
    this->m_pTexture->Release();
    delete this;
}

void RenderPipelineMTL::Init()
{
    if (m_bDefaultPipeline)
    {
        MTLClearColor clearColor = MTLClearColorMake(
                                                     m_desc.clearOp.vColorValues[0],
                                                     m_desc.clearOp.vColorValues[1],
                                                     m_desc.clearOp.vColorValues[2],
                                                     m_desc.clearOp.vColorValues[3]);
        for (int i = 0; i<m_desc.nRenderTargets; ++i)
        {
            const GX_RENDERTARGET_DESC * renderTargetDesc = m_desc.pRenderTargets[i]->GetDesc();
            TextureMTL * pTex = (TextureMTL *)renderTargetDesc->texture;
            if (pTex)
            {
                m_renderPassDesc.colorAttachments[i].texture = pTex->m_mtlTexture;
            }
            else
            {
                m_renderPassDesc.colorAttachments[i].texture = nil;
            }
            
            m_renderPassDesc.colorAttachments[i].loadAction = MTLLoadActionClear;
            m_renderPassDesc.colorAttachments[i].clearColor = clearColor;
            m_renderPassDesc.colorAttachments[i].storeAction = MTLStoreActionStore;
        }
        // 默认的fbo需要看看窗口大小是不是变了需要处理
        
        id<CAMetalDrawable> drawable = internalDevice->currentDrawable();
        if (drawable == nil)
        {
            return;
        }
        id<MTLTexture> texture = drawable.texture;
        //NSLog(@"texture width : %lu height: %lu ",(unsigned long)texture.width,(unsigned long)texture.height);
        m_renderPassDesc.colorAttachments[0].texture = texture;
        
        // 处理深度缓冲区
        DepthStencilMTL * depthStencil = (DepthStencilMTL *)m_desc.pDepthStencil;
        TextureMTL * depthTexRef = ((TextureMTL *)depthStencil->desc.texture);
        id<MTLTexture> depthTexture = depthTexRef->m_mtlTexture;
        if (depthTexture.width != texture.width || depthTexture.height != texture.height)
        {
            // 创建一个新的深度贴图
            MTLTextureDescriptor * depthTextureDesc = [[MTLTextureDescriptor alloc] init];
            depthTextureDesc.width = texture.width; depthTextureDesc.height = texture.height;
            depthTextureDesc.pixelFormat = MTLPixelFormatDepth32Float;
            depthTextureDesc.mipmapLevelCount = 1;
            depthTexture =  [internalDevice->m_mtlDevice newTextureWithDescriptor:depthTextureDesc];
            depthTexRef->m_mtlTexture = depthTexture;
            depthTexRef->m_desc.nWidth = (GX_UINT32)texture.width;
            depthTexRef->m_desc.nHeight = (GX_UINT32)texture.height;
            [depthTextureDesc release];
        }
    }
}

bool RenderPipelineMTL::Begin()
{
    if (m_bDefaultPipeline)
    {
        MTLClearColor clearColor = MTLClearColorMake(
                                                     m_desc.clearOp.vColorValues[0],
                                                     m_desc.clearOp.vColorValues[1],
                                                     m_desc.clearOp.vColorValues[2],
                                                     m_desc.clearOp.vColorValues[3]);
        for (int i = 0; i<m_desc.nRenderTargets; ++i)
        {
            const GX_RENDERTARGET_DESC * renderTargetDesc = m_desc.pRenderTargets[i]->GetDesc();
            TextureMTL * pTex = (TextureMTL *)renderTargetDesc->texture;
            if (pTex)
            {
                m_renderPassDesc.colorAttachments[i].texture = pTex->m_mtlTexture;
            }
            else
            {
                m_renderPassDesc.colorAttachments[i].texture = nil;
            }
            
            m_renderPassDesc.colorAttachments[i].loadAction = MTLLoadActionClear;
            m_renderPassDesc.colorAttachments[i].clearColor = clearColor;
            m_renderPassDesc.colorAttachments[i].storeAction = MTLStoreActionStore;
        }
        // 默认的fbo需要看看窗口大小是不是变了需要处理
        
        id<CAMetalDrawable> drawable = internalDevice->currentDrawable();
        if (drawable == nil)
        {
            return false;
        }
        id<MTLTexture> texture = drawable.texture;
        m_renderPassDesc.colorAttachments[0].texture = texture;
        
        //NSLog(@"texture width : %lu height: %lu ",(unsigned long)texture.width,(unsigned long)texture.height);
        
        // 处理深度缓冲区
        DepthStencilMTL * depthStencil = (DepthStencilMTL *)m_desc.pDepthStencil;
        TextureMTL * depthTexRef = ((TextureMTL *)depthStencil->desc.texture);
        id<MTLTexture> depthTexture = depthTexRef->m_mtlTexture;
        if (depthTexture.width != texture.width || depthTexture.height != texture.height)
        {
            // 创建一个新的深度贴图
            MTLTextureDescriptor * depthTextureDesc = [[MTLTextureDescriptor alloc] init];
            depthTextureDesc.width = texture.width; depthTextureDesc.height = texture.height;
            depthTextureDesc.pixelFormat = MTLPixelFormatDepth32Float;
            depthTextureDesc.mipmapLevelCount = 1;
            depthTexture =  [internalDevice->m_mtlDevice newTextureWithDescriptor:depthTextureDesc];
            depthTexRef->m_mtlTexture = depthTexture;
            depthTexRef->m_desc.nWidth = (GX_UINT32)texture.width;
            depthTexRef->m_desc.nHeight = (GX_UINT32)texture.height;
            [depthTextureDesc release];
        }
        m_renderPassDesc.depthAttachment.texture = depthTexture;
        m_renderPassDesc.depthAttachment.loadAction = MTLLoadActionClear;
        m_renderPassDesc.depthAttachment.clearDepth = 1.0f;
        m_renderPassDesc.depthAttachment.storeAction = MTLStoreActionDontCare;
    }
    
    m_renderCmdEncoder = [internalDevice->m_mtlDefaultCmdBuffer renderCommandEncoderWithDescriptor:m_renderPassDesc];
    
    internalDevice->SetCurrentRenderPipeline(this);
    
    return true;
}

bool RenderPipelineMTL::End()
{
    internalDevice->SetCurrentRenderPipeline(nullptr);
    [m_renderCmdEncoder endEncoding];
    return true;
}

void RenderPipelineMTL::Release()
{
    contexRef = nil;
    m_renderPassDesc = nil;
    m_renderCmdEncoder = nil;
    delete this;
}
