#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>
#import <simd/simd.h>

#import "Graphics.h"

@interface MTLGameViewController : UIViewController
{
    // 设备
    IGXDevice *             _pDevice;
    IGXEffect *             _pEffect;
    
    IGXRenderTarget*        _pRenderTarget;
    IGXDepthStencil*        _pDepthStencil;
    
    IGXRenderPipeline*      _pRenderPipeline;
    
    IGXVB     *             _pVBO;
    
    BOOL                    _layerSizeShouldUpdate;
    
    // 时间调度相关数据结构
    CADisplayLink *         _timer;
    BOOL                    _gameLoopPaused;
    dispatch_semaphore_t    _inflight_semaphore;
}

-(void)onInit;

@end
