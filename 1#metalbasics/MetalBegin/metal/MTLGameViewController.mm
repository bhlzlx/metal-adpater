//
//  MTLGameViewController.m
//  GLESxMetal
//
//  Created by mengxin on 15/5/14.
//  Copyright (c) 2015年 mengxin. All rights reserved.
//

#import "MTLGameViewController.h"



#import <Metal/Metal.h>
#import <simd/simd.h>
#import <QuartzCore/QuartzCore.h>

static const float vertices[18] =
{
    1,0,0,       1,0,0,
    0,1,0,       0,1,0,
    0,0,0,       0,0,1
};


@implementation MTLGameViewController
{
}

- (void)dealloc
{
}

-(void)onInit
{
    // 初始化device
    CGRect rect = [self.view bounds];
    _device = MTLCreateSystemDefaultDevice();
    assert(_device);
    _commandQueue = [_device newCommandQueue];
    _library = [_device newDefaultLibrary];
    // 创建渲染上下文
    _metalLayer = [CAMetalLayer layer];
    _metalLayer.device = _device;
    _metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    _metalLayer.framebufferOnly = YES;
    [_metalLayer setFrame:rect];
    [self.view.layer addSublayer:_metalLayer];
    self.view.opaque = YES;
    self.view.backgroundColor = [UIColor purpleColor];
    self.view.contentScaleFactor = [[UIScreen mainScreen] scale];
    
    [self _setupMetal];
    // _gameloop 会在每个runloop循环执行一次
    _timer = [CADisplayLink displayLinkWithTarget:self selector:@selector(_gameloop)];
    [_timer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    _inflight_semaphore = dispatch_semaphore_create(3);
    
}

- (void)_setupMetal
{
    // 初始化shader function
    _vertexFunc = [_library newFunctionWithName:@"vertex_shader"];
    _fragmentFunc = [_library newFunctionWithName:@"fragment_shader"];
    // 模型VBO
    _modelVBO = [_device newBufferWithBytes:vertices length:sizeof(vertices) options:MTLResourceOptionCPUCacheModeDefault];
    // 初始化渲染管线
    MTLRenderPipelineDescriptor * pipelineDesc = [[MTLRenderPipelineDescriptor alloc] init];
    // 设置（多重）采样数，不设置就设为1
    pipelineDesc.sampleCount = 1;
    pipelineDesc.vertexFunction = _vertexFunc;
    pipelineDesc.fragmentFunction = _fragmentFunc;
    pipelineDesc.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    pipelineDesc.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
    NSError * error;
    _renderPipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineDesc error:&error];
    if(_renderPipelineState == nil)
    {
        NSLog(@"failed to create render pipeline state~ error : %@",error.description);
    }
    // 设置深度缓冲区的可读写状态
    MTLDepthStencilDescriptor * depthStencilDesc = [[MTLDepthStencilDescriptor alloc] init];
    [depthStencilDesc setDepthCompareFunction:MTLCompareFunctionLessEqual];
    [depthStencilDesc setDepthWriteEnabled:YES];
    _depthStencilState = [_device newDepthStencilStateWithDescriptor:depthStencilDesc];
}

-(void)_setupRenderPassDescriptorForTexture:(id<MTLTexture>)_texture
{
    // 这里相当于设置FBO的 color 和 depthstencil渲染缓冲区
    if (_renderPassDesc == nil)
    {
        _renderPassDesc = [[MTLRenderPassDescriptor alloc] init];
    }
    
    _renderPassDesc.colorAttachments[0].texture = _texture;
    _renderPassDesc.colorAttachments[0].loadAction = MTLLoadActionClear;
    _renderPassDesc.colorAttachments[0].clearColor = MTLClearColorMake(1, 0, 1, 1);
    _renderPassDesc.colorAttachments[0].storeAction = MTLStoreActionStore;
    
    if(_depthTexture == nil || _depthTexture.width != _texture.width || _depthTexture.height != _texture.height)
    {
        // 创建一个新的深度贴图
        MTLTextureDescriptor * depthTextureDesc = [[MTLTextureDescriptor alloc] init];
        depthTextureDesc.width = _texture.width;
        depthTextureDesc.height = _texture.height;
        depthTextureDesc.pixelFormat = MTLPixelFormatDepth32Float;
        depthTextureDesc.mipmapLevelCount = 1;
        _depthTexture = [_device newTextureWithDescriptor:depthTextureDesc];
        // 把深度贴图给fbo
        _renderPassDesc.depthAttachment.texture = _depthTexture;
        _renderPassDesc.depthAttachment.loadAction = MTLLoadActionClear;
        _renderPassDesc.depthAttachment.clearDepth = 1.0f;
        _renderPassDesc.depthAttachment.storeAction = MTLStoreActionDontCare;
    }
}

- (void)_render
{
    dispatch_semaphore_wait(_inflight_semaphore, DISPATCH_TIME_FOREVER);
    // context的texture是不断变化的，取当前有效的texture
    id<CAMetalDrawable> drawable = _metalLayer.nextDrawable;
    // 若drawable无效，跳过，不渲染
    if (drawable == nil)
    {
        return;
    }
    // 用command queue 对象 生成一个临时 commandbuffer
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"command buffer";
    id<MTLTexture> texture = drawable.texture;
    // 设置当前有效的texture到当前FBO中，如果必要更新深度缓冲区
    [self _setupRenderPassDescriptorForTexture:texture];
    // 一个render encoder,使用render encoder对象向command buffer提交绘图指令
    id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:_renderPassDesc];
    renderEncoder.label = @"render encoder";
    // 设置深度缓冲区的读写控制
    [renderEncoder setDepthStencilState:_depthStencilState];
    // 设置渲染管线（shader,像素格式等等参数）
    [renderEncoder setRenderPipelineState:_renderPipelineState];
    // 设置渲染数据（提交给shader）
    [renderEncoder setVertexBuffer:_modelVBO offset:0 atIndex:0];
    // 绘制图形~
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
    // 操作完毕
    [renderEncoder endEncoding];
    // Call the view's completion handler which is required by the view since it will signal its semaphore and set up the next buffer
    __block dispatch_semaphore_t block_sema = _inflight_semaphore;
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
        dispatch_semaphore_signal(block_sema);
    }];
    // Schedule a present once the framebuffer is complete
    [commandBuffer presentDrawable:drawable];
    // Finalize rendering here & push the command buffer to the GPU
    [commandBuffer commit];
}

- (void)viewDidLoad
{
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}



- (void)_loadAssets
{
    
}

- (void)setupRenderPassDescriptorForTexture:(id <MTLTexture>) texture
{
    
}



- (void)_reshape
{
    // When reshape is called, update the view and projection matricies since this means the view orientation or size changed
    // float aspect = fabs(self.view.bounds.size.width / self.view.bounds.size.height);
}

- (void)_update
{
    
}

// The main game loop called by the CADisplayLine timer
- (void)_gameloop
{
    @autoreleasepool {
        if (_layerSizeShouldUpdate)
        {
            CGFloat nativeScale = self.view.window.screen.nativeScale;
            CGSize drawableSize = self.view.bounds.size;
            drawableSize.width *= nativeScale;
            drawableSize.height *= nativeScale;
            _metalLayer.drawableSize = drawableSize;
            // 这里一般要改变投影矩阵
            [self _reshape];
            _layerSizeShouldUpdate = NO;
        }
        // draw
        [self _render];
    }
}

// Called whenever view changes orientation or layout is changed
- (void)viewDidLayoutSubviews
{
    _layerSizeShouldUpdate = YES;
    [_metalLayer setFrame:self.view.layer.frame];
}

@end

