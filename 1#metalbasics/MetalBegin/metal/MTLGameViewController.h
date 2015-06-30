#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>
#import <simd/simd.h>

@interface MTLGameViewController : UIViewController
{
    // 设备
    id<MTLDevice>           _device;
    // 队列
    id<MTLCommandQueue>     _commandQueue;
    // shader库
    id<MTLLibrary>          _library;
    // metal context layer
    CAMetalLayer*           _metalLayer;
    BOOL                    _layerSizeShouldUpdate;
    // shader
    id<MTLFunction>         _vertexFunc;
    id<MTLFunction>         _fragmentFunc;
    // vbo
    id<MTLBuffer>           _modelVBO;
    //创建一个渲染管线，作用类似于一个FBO的状态,但比FBO状态描述要多一些
    id<MTLRenderPipelineState> \
                            _renderPipelineState;
    // 控制深度缓冲区读写的一个状态变量
    id<MTLDepthStencilState>    \
                            _depthStencilState;
    // 时间调度相关数据结构
    CADisplayLink *         _timer;
    BOOL                    _gameLoopPaused;
    dispatch_semaphore_t    _inflight_semaphore;
    // 一个renderpass相当于一个FBO
    MTLRenderPassDescriptor * \
                            _renderPassDesc;
    // FBO的深度纹理
    id<MTLTexture>          _depthTexture;
}

-(void)onInit;

@end
