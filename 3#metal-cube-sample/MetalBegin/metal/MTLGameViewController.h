#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>
#import <simd/simd.h>

#include <glm/glm.hpp>

#import "Graphics.h"

@interface MTLGameViewController : UIViewController
{
    // 设备
    IGXDevice *             _pDevice;
    IGXEffect *             _pEffect;
    IGXTex    *             _pTexture;
    GX_SAMPLER_STATE        _samplerState;
    
    IGXRenderTarget*        _pRenderTarget;
    IGXDepthStencil*        _pDepthStencil;
    IGXRenderPipeline*      _pRenderPipeline;
    
    IGXRenderTarget*        _pShadowRenderTarget;
    IGXDepthStencil*        _pShadowRenderStencil;
    IGXRenderPipeline*      _pShadowRenderPipeline;
    IGXEffect*              _pShadowEffect;
    
    IGXVB*                  _pCubeVBO;
    IGXVB*                  _pPlaneVBO;
    IGXVB*                  _pPlaneMatricesVBO;
    IGXVB*                  _pCubeMatricesVBO;
    IGXVB*                  _pSceneDataVBO;
    
    BOOL                    _layerSizeShouldUpdate;
    
    // 时间调度相关数据结构
    CADisplayLink *         _timer;
    //
    glm::mat4               _cubeModel;
    glm::mat4               _cubeView;
    glm::mat4               _planeModel;
    
    glm::mat4               _projection;
    glm::mat4               _shadowView;
    float                   _rad;
}

-(void)onInit;

@end
