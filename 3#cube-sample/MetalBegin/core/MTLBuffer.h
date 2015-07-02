//
//  bufferobject.h
//  MetalBegin
//
//  Created by mengxin on 15/6/24.
//  Copyright (c) 2015年 phantom. All rights reserved.
//

#ifndef MetalBegin_bufferobject_h
#define MetalBegin_bufferobject_h

#include "DeviceMTL.h"
#import <metal/metal.h>

struct MTLVBO:public IGXVB
{
    GX_BOOL                     m_bDynamic;
    id<MTLBuffer>               m_mtlBuffer;
    
    GX_UINT32                   m_nLength;
    
    bool SetData(const GX_VOID * _pData,GX_UINT32 _nSize);
    void Release();
};

struct MTLIBO:public IGXIB
{
    GX_BOOL     m_bDynamic;
    id<MTLBuffer>               m_mtlBuffer;
    GX_UINT32                   m_nLength;
    bool SetData(const GX_VOID * _pData,GX_UINT32 _nSize);
    void Release();
};

#endif
