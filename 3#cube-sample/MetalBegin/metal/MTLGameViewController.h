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
    
    IGXVB     *             _pVBO;
    IGXVB*                  _pMatricesVBO;
    IGXVB*                  _pSceneDataVBO;
    
    BOOL                    _layerSizeShouldUpdate;
    
    // 时间调度相关数据结构
    CADisplayLink *         _timer;
    BOOL                    _gameLoopPaused;
    dispatch_semaphore_t    _inflight_semaphore;
    
    //
    glm::mat4               _cubeModel;
    glm::mat4               _cubeView;
    glm::mat4               _projection;
    float                   _rad;
}

-(void)onInit;

@end
