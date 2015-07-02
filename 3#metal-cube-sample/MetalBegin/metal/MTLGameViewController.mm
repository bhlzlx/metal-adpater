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
#include <glm/gtc/matrix_transform.hpp>

float screenScale = 0.0f;

struct ShaderMatrices
{
    glm::mat4 model;
    glm::mat4 view;
    glm::mat4 projection;
};

struct ShaderSceneData
{
    glm::vec4 light_pos;
};

const float __cube[8 * 36] =
{
    // 1 …œ
    -1,1,-1,	0,1,0, 0,0,
    -1,1,1,		0,1,0, 0,1,
    1,1,1,		0,1,0, 1,1,
    
    -1,1,-1,	0,1,0, 0,0,
    1,1,1,		0,1,0, 1,1,
    1,1,-1,		0,1,0, 1,0,
    // 2 «∞
    -1,1,1,		0,0,1, 0,0,
    -1,-1,1,	0,0,1, 0,1,
    1,-1,1,		0,0,1, 1,1,
    
    -1,1,1,		0,0,1, 0,0,
    1,-1,1,		0,0,1, 1,1,
    1,1,1,		0,0,1, 1,0,
    // 3 œ¬
    -1,-1,1,	0,-1,0, 0,0,
    -1,-1,-1,	0,-1,0, 0,1,
    1,-1,-1,	0,-1,0, 1,1,
    
    -1,-1,1,	0,-1,0, 0,0,
    1,-1,-1,	0,-1,0, 1,1,
    1,-1,1,     0,-1,0, 1,0,
    // 4 ∫Û
    1,1,-1,     0,0,-1, 0,0,
    1,-1,-1,	0,0,-1, 0,1,
    -1,-1,-1,	0,0,-1, 1,1,
    
    1,1,-1,     0,0,-1, 0,0,
    -1,-1,-1,	0,0,-1, 1,1,
    -1,1,-1,	0,0,-1, 1,0,
    // 5 ”“
    1,1,1,		1,0,0,	0,0,
    1,-1,1,		1,0,0,	0,1,
    1,-1,-1,	1,0,0,	1,1,
    
    1,1,1,		1,0,0,	0,0,
    1,-1,-1,	1,0,0,	1,1,
    1,1,-1,		1,0,0,	1,0,
    // 6 ◊Û
    -1,1,-1,	-1,0,0,	0,0,
    -1,-1,-1,	-1,0,0,	0,1,
    -1,-1,1,	-1,0,0,	1,1,
    
    -1,1,-1,	-1,0,0,	0,0,
    -1,-1,1,	-1,0,0,	1,1,
    -1,1,1,		-1,0,0,	1,0
};

@implementation MTLGameViewController
{
    
}

- (void)dealloc
{
    _pDevice->Release();
    _pEffect->Release();
    _pDepthStencil->Release();
    _pRenderTarget->Release();
    _pRenderPipeline->Release();
    _pVBO->Release();
    [_timer release];
    [super dealloc];
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
    screenScale = self.view.contentScaleFactor = [[UIScreen mainScreen] scale];
    _pDevice = CreateDevice((void * )metalLayer);
    
    static GX_RECT viewportRect;
    static GX_RECT scissorRect;
    
    viewportRect.dx = self.view.bounds.size.width * screenScale;
    viewportRect.dy = self.view.bounds.size.height * screenScale;
    scissorRect.dx = self.view.bounds.size.width * screenScale;
    scissorRect.dy = self.view.bounds.size.height * screenScale;
    
    _pDevice->SetViewport(&viewportRect);
    _pDevice->SetScissor(&scissorRect);
    
    static GX_RENDERPIPELINE_DESC       renderPipelineDesc;

    static GX_RENDERTARGET_DESC         renderTargetDesc;
    static GX_DEPTH_STENCIL_DESC        depthStencilDesc;
    static GX_TEX_DESC                  depthTexDesc;
    static GX_EFFECT_DESC               effectDesc;
    
    depthStencilDesc.nWidth = rect.size.width * [[UIScreen mainScreen] scale];
    depthStencilDesc.nHeight = rect.size.height * [[UIScreen mainScreen] scale];
    depthTexDesc.nWidth = rect.size.width * [[UIScreen mainScreen] scale];
    depthTexDesc.nHeight = rect.size.height * [[UIScreen mainScreen] scale];
    depthTexDesc.eFormat = GX_RAW_DEPTH;
    depthStencilDesc.texture = _pDevice->CreateTextureDyn(GX_RAW_DEPTH, rect.size.width * [[UIScreen mainScreen] scale], rect.size.height * [[UIScreen mainScreen] scale]);
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
                #include "../shader.inl"
    
    effectDesc.nSamplerStateCount = 0;
    effectDesc.szLibrarySource = szShader;
    effectDesc.pSamplerState = nullptr;

    _pEffect = _pDevice->CreateEffect(&effectDesc);
    
    _pVBO = _pDevice->CreateVBO(__cube, sizeof(__cube));
    _pMatricesVBO = _pDevice->CreateDynVBO(sizeof(ShaderMatrices));
    _pSceneDataVBO = _pDevice->CreateDynVBO(sizeof(ShaderSceneData));
    
    _pTexture = _pDevice->CreateChessTexture();
    _samplerState.AddressU = GX_TEX_ADDRESS_REPEAT;
    _samplerState.AddressV = GX_TEX_ADDRESS_REPEAT;
    _samplerState.MagFilter = GX_TEX_FILTER_MIP_LINEAR;
    _samplerState.MinFilter = GX_TEX_FILTER_NEAREST;
    
    

    [self _setupMetal];
    
    _rad = 0.0f;
    _cubeView = glm::lookAt(glm::vec3(10,5,10), glm::vec3(0,0,0), glm::vec3(0,1,0));
    
    // _gameloop 会在每个runloop循环执行一次
    _timer = [CADisplayLink displayLinkWithTarget:self selector:@selector(_gameloop)];
    [_timer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];    
}

- (void)_setupMetal
{
}

- (void)_render
{
    // context的texture是不断变化的，取当前有效的texture
    // 准备提交command buffer的互斥工作
    _pDevice->BeginDrawing();
    // 判断当前程序资源的有效性，如果无效则
    if(_pRenderPipeline->Begin() == false || _pEffect->Begin() == false)
    {
        _pDevice->EmptyFlush();
        return;
    }
    
    ShaderMatrices matrices ;
    matrices.model = _cubeModel;
    matrices.view = _cubeView;
    matrices.projection = _projection;
    _pMatricesVBO->SetData(&matrices, sizeof(matrices));
    
    ShaderSceneData sceneData;
    sceneData.light_pos = glm::vec4(10,5,10,1);
    _pSceneDataVBO->SetData(&sceneData, sizeof(sceneData));
    
    _pEffect->SetVertexBuffer(_pVBO, 0);
    _pEffect->SetVertexBuffer(_pMatricesVBO, 1);
    _pEffect->SetVertexBuffer(_pSceneDataVBO, 2);
    
    _pEffect->SetFragmentTexture(_pTexture, 0);
    _pEffect->SetFragmentSamplerState(&_samplerState, 0);
    
    
    _pDevice->DrawPrimitives(GX_DRAW_TRIANGLE, 3, 1);

    _pEffect->End();
    _pRenderPipeline->End();
    _pDevice->FlushDrawing();
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
    _rad += 0.02;
    _cubeModel = glm::rotate(glm::mat4(1.0), _rad, glm::vec3(0,1,0));
}

// The main game loop called by the CADisplayLine timer

- (void)_gameloop
{
    @autoreleasepool
    {
        // 更新数据
        [self _update];
        // 渲染
        [self _render];
    }
}

// Called whenever view changes orientation or layout is changed

- (void)viewDidLayoutSubviews
{
    CGRect rect = [self.view bounds];
    _pDevice->OnResize(rect.size.width, rect.size.height);
    self.view.contentScaleFactor = [[UIScreen mainScreen] scale];
    
    _projection = glm::perspective(45.0f, (float)(rect.size.width)/(float)rect.size.height, 0.1f, 1000.0f);
}

@end

