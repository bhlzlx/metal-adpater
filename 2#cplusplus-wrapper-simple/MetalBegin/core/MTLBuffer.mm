//
//  bufferobject.cpp
//  MetalBegin
//
//  Created by mengxin on 15/6/24.
//  Copyright (c) 2015年 phantom. All rights reserved.
//

#include "MTLBuffer.h"

bool MTLVBO::SetData(const GX_VOID * _pData,GX_UINT32 _nSize)
{
    if (this->m_bDynamic)
    {
        if (m_mtlBuffer.length > _nSize)
        {
            memcpy(m_mtlBuffer.contents, _pData, _nSize);
            m_nLength = _nSize;
            return true;
        }
        else
        {
            return false;
        }
    }
    return false;
}

void MTLVBO::Release()
{
    this->m_mtlBuffer = nil;
    delete this;
}

bool MTLIBO::SetData(const GX_VOID * _pData,GX_UINT32 _nSize)
{
    if (this->m_bDynamic)
    {
        if (m_mtlBuffer.length > _nSize)
        {
            memcpy(m_mtlBuffer.contents, _pData, _nSize);
            m_nLength = _nSize;
            return true;
        }
        else
        {
            return false;
        }
    }
    return false;
}

void MTLIBO::Release()
{
    this->m_mtlBuffer = nil;
    delete this;
}

