//
//  MTLTexture.h
//  MetalBegin
//
//  Created by mengxin on 15/6/24.
//  Copyright (c) 2015年 phantom. All rights reserved.
//

#ifndef __MetalBegin__MTLTexture__
#define __MetalBegin__MTLTexture__

#import <metal/metal.h>
#include "Graphics.h"

struct TextureMTL:public IGXTex
{
    id<MTLTexture>          m_mtlTexture;
    
    GX_BOOL                 m_bDynamic;
    GX_UINT8                m_nMipmapLevel;
    
    GX_TEX_DESC             m_desc;
    
    void SetData(const GX_VOID * _pData);
    void SetSubData(const GX_VOID * _pData,GX_RECT * _pRect);
    void Release();
};




#endif /* defined(__MetalBegin__MTLTexture__) */
