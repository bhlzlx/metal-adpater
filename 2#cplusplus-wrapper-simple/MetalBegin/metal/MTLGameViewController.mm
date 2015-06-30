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
    CAMetalLayer * metalLayer = [CAMetalLayer layer];
    [metalLayer setFrame:rect];
    [self.view.layer addSublayer:metalLayer];
    self.view.opaque = YES;
    self.view.backgroundColor = [UIColor purpleColor];
    self.view.contentScaleFactor = [[UIScreen mainScreen] scale];
    _pDevice = CreateDevice((__bridge void * )metalLayer);
    
    static GX_RECT viewportRect;
    static GX_RECT scissorRect;
    
    viewportRect.dx = self.view.bounds.size.width;
    viewportRect.dy = self.view.bounds.size.height;
    scissorRect.dx = self.view.bounds.size.width;
    scissorRect.dy = self.view.bounds.size.height;
    
    _pDevice->SetViewport(&viewportRect);
    _pDevice->SetScissor(&scissorRect);
    
    
    
    static GX_RENDERPIPELINE_DESC renderPipelineDesc;
    static GX_RENDERTARGET_DESC renderTargetDesc;
    static GX_DEPTH_STENCIL_DESC depthStencilDesc;
    static GX_TEX_DESC depthTexDesc;
    static GX_EFFECT_DESC effectDesc;
    
    depthStencilDesc.nWidth = rect.size.width;
    depthStencilDesc.nHeight = rect.size.height;
    depthTexDesc.nWidth = rect.size.width;
    depthTexDesc.nHeight = rect.size.height;
    depthTexDesc.eFormat = GX_RAW_DEPTH;
    depthStencilDesc.texture = _pDevice->CreateTextureDyn(GX_RAW_DEPTH, rect.size.width, rect.size.height);
    _pDepthStencil = _pDevice->CreateDepthStencil(&depthStencilDesc);
    
    renderTargetDesc.eFormat = GX_RAW_RGBA8888;
    renderTargetDesc.nWidth = rect.size.width;
    renderTargetDesc.nHeight = rect.size.height;
    renderTargetDesc.texture = nullptr;
    _pRenderTarget = _pDevice->CreateRenderTarget(&renderTargetDesc);
    
    GX_CLEAR clear;
    renderPipelineDesc.pDepthStencil = _pDepthStencil;
    renderPipelineDesc.pRenderTargets[0] = _pRenderTarget;
    renderPipelineDesc.bMainPipeline = GX_TRUE;
    renderPipelineDesc.nRenderTargets = 1;
    renderPipelineDesc.clearOp = clear;
    
    // 初始化pipeline
    _pRenderPipeline = _pDevice->CreateDefaultRenderPipeline(&renderPipelineDesc);
    _pDevice->SetCurrentRenderPipeline(_pRenderPipeline);
    
    const char * szShader =
                #include "../shader.inc"
    effectDesc.nSamplerStateCount = 0;
    effectDesc.szLibrarySource = szShader;
    effectDesc.pSamplerState = nullptr;

    _pEffect = _pDevice->CreateEffect(&effectDesc);
    
    _pVBO = _pDevice->CreateVBO(vertices, sizeof(vertices));


    
    [self _setupMetal];
    [self onUpdate:nil];
    // _gameloop 会在每个runloop循环执行一次
   /* _timer = [CADisplayLink displayLinkWithTarget:self selector:@selector(_gameloop)];
    [_timer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    _inflight_semaphore = dispatch_semaphore_create(3);
    */
    
}

- (void)_setupMetal
{
    /*
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
     */
}

- (void)_render
{
    //dispatch_semaphore_wait(_inflight_semaphore, DISPATCH_TIME_FOREVER);
    // context的texture是不断变化的，取当前有效的texture
    
    if(_pRenderPipeline->Begin() == false || _pEffect->Begin() == false)
    {
        NSTimer * timer = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(onUpdate:) userInfo:nil repeats:NO];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode: NSDefaultRunLoopMode];
        return;
    }
    _pEffect->SetVertexBuffer(_pVBO, 0);
    
    _pDevice->DrawPrimitives(GX_DRAW_TRIANGLE, 3, 1);

    _pEffect->End();
    _pRenderPipeline->End();
    
    _pDevice->FlushDrawing();
    
    NSTimer * timer = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(onUpdate:) userInfo:nil repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode: NSDefaultRunLoopMode];
   
}

-(void)onUpdate:(id)info
{
    [self _render];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
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
/*
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
*/
// Called whenever view changes orientation or layout is changed
/*
- (void)viewDidLayoutSubviews
{
    _layerSizeShouldUpdate = YES;
    [_metalLayer setFrame:self.view.layer.frame];
}
 */

@end

