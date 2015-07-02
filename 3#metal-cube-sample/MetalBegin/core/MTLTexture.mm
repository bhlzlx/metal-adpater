//
//  MTLTexture.cpp
//  MetalBegin
//
//  Created by mengxin on 15/6/24.
//  Copyright (c) 2015年 phantom. All rights reserved.
//

#include "MTLTexture.h"

void TextureMTL::SetData(const GX_VOID *_pData)
{
    if (!this->m_bDynamic)
    {
        return;
    }
    GX_UINT64 bytesPerRow = BytesForPixelFormat(this->m_desc.eFormat) * m_mtlTexture.width;
    // 动态纹理mipmap设为0
    [m_mtlTexture replaceRegion:MTLRegionMake2D(0, 0, m_mtlTexture.width, m_mtlTexture.height)
                    mipmapLevel:0
                      withBytes:_pData
                    bytesPerRow:(NSUInteger)bytesPerRow];
}

void TextureMTL::SetSubData(const GX_VOID * _pData,GX_RECT * _pRect)
{
    if (!this->m_bDynamic)
    {
        return;
    }
    
    assert(_pRect->dx < m_mtlTexture.width && _pRect->dy < m_mtlTexture.height);
    
    GX_UINT64 bytesPerRow = BytesForPixelFormat(this->m_desc.eFormat) * _pRect->dx;
    
    [m_mtlTexture replaceRegion:MTLRegionMake2D(0, 0, m_mtlTexture.width, m_mtlTexture.height)
                    mipmapLevel:m_nMipmapLevel
                      withBytes:_pData
                    bytesPerRow:(NSUInteger)bytesPerRow];
}

void TextureMTL::Release()
{
    m_mtlTexture = nil;
    delete this;
}