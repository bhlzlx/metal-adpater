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
    glm::mat4 shadowView;
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

const float __plane[8 * 6] =
{
    -1,0,-1,	0,1,0, 0,1,
    -1,0,1,		0,1,0, 0,0,
    1,0,1,		0,1,0, 1,0,
    
    -1,0,-1,	0,1,0, 0,1,
    1,0,1,		0,1,0, 1,0,
    1,0,-1,		0,1,0, 1,1
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
    _pCubeVBO->Release();
    _pPlaneVBO->Release();
    _pPlaneMatricesVBO->Release();
    _pCubeMatricesVBO->Release();
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
    
    static GX_EFFECT_DESC               effectDesc;
    
    // 初始化 depthstencil 和  rendertarget
    depthStencilDesc.nWidth = rect.size.width * [[UIScreen mainScreen] scale];
    depthStencilDesc.nHeight = rect.size.height * [[UIScreen mainScreen] scale];
    _pDepthStencil = _pDevice->CreateDepthStencil(&depthStencilDesc);
    
    renderTargetDesc.eFormat = GX_RAW_RGBA8888;
    renderTargetDesc.nWidth = rect.size.width;
    renderTargetDesc.nHeight = rect.size.height;
    _pRenderTarget = _pDevice->CreateRenderTarget(&renderTargetDesc);
    
    GX_CLEAR clear;
    renderPipelineDesc.pDepthStencil = _pDepthStencil;
    renderPipelineDesc.pRenderTargets[0] = _pRenderTarget;
    renderPipelineDesc.bMainPipeline = GX_TRUE;
    renderPipelineDesc.nRenderTargets = 1;
    renderPipelineDesc.clearOp = clear;
    
    // 初始化pipeline
    _pRenderPipeline = _pDevice->CreateRenderPipeline(&renderPipelineDesc);

    const char * szNoramlRenderShader =
                #include "../sceneRenderer.h"
    
    effectDesc.nSamplerStateCount = 0;
    effectDesc.szLibrarySource = szNoramlRenderShader;
    effectDesc.pSamplerState = nullptr;

    _pDevice->SetCurrentRenderPipeline(_pRenderPipeline);
    _pEffect = _pDevice->CreateEffect(&effectDesc);
    
    // 初始化shadow渲染需要的pipeline
    const char * szDepthRenderShader =
                #include "../shadowRenderer.h"
    depthStencilDesc.nWidth = 1024;
    depthStencilDesc.nHeight = 1024;
    _pShadowRenderStencil = _pDevice->CreateDepthStencil(&depthStencilDesc);
    renderPipelineDesc.pDepthStencil = _pShadowRenderStencil;
    renderPipelineDesc.nRenderTargets = 0;
    renderPipelineDesc.bMainPipeline = GX_FALSE;
    
    _pShadowRenderPipeline = _pDevice->CreateRenderPipeline(&renderPipelineDesc);
    
    effectDesc.szLibrarySource = szDepthRenderShader;
    _pDevice->SetCurrentRenderPipeline(_pShadowRenderPipeline);
    _pShadowEffect = _pDevice->CreateEffect(&effectDesc);
    
    
    // 初始化 模型所 需要的 VBO
    _pCubeVBO = _pDevice->CreateVBO(__cube, sizeof(__cube));
    _pPlaneVBO = _pDevice->CreateVBO(__plane, sizeof(__plane));
    _pPlaneMatricesVBO = _pDevice->CreateDynVBO(sizeof(ShaderMatrices));
    _pCubeMatricesVBO = _pDevice->CreateDynVBO(sizeof(ShaderMatrices));
    _pSceneDataVBO = _pDevice->CreateDynVBO(sizeof(ShaderSceneData));
    // 生成默认贴图
    _pTexture = _pDevice->CreateChessTexture();
    // 处理纹理采样
    _samplerState.AddressU = GX_TEX_ADDRESS_REPEAT;
    _samplerState.AddressV = GX_TEX_ADDRESS_REPEAT;
    _samplerState.MagFilter = GX_TEX_FILTER_MIP_LINEAR;
    _samplerState.MinFilter = GX_TEX_FILTER_NEAREST;
    
    _rad = 0.0f;
    _cubeView = glm::lookAt(glm::vec3(10,5,10), glm::vec3(0,0,0), glm::vec3(0,1,0));
    _shadowView = glm::lookAt(glm::vec3(0,10,5), glm::vec3(0,0,0), glm::vec3(0,1,0));
    _planeModel = glm::translate( glm::scale(glm::mat4(1.0f), glm::vec3(4.0f,1.0f,4.0f)), glm::vec3(0.0f,-1.2f,0.0f));
    
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
    static ShaderSceneData sceneData;
    static ShaderMatrices matrices;
    static GX_RECT viewport;
    viewport.x = viewport.y = 0;
    
    viewport.dx = 1024;
    viewport.dy = 1024;
    //////// 渲染 深度 /////////
    _pDevice->SetViewport(&viewport);
    if( self->_pShadowRenderPipeline->Begin() == false || _pShadowEffect->Begin() == false)
    {
        _pDevice->EmptyFlush();
        return;
    }
    
    matrices.model = _cubeModel;
    matrices.view =  _shadowView;
    matrices.projection = _projection;
    
    _pCubeMatricesVBO->SetData(&matrices, sizeof(matrices));
    
    sceneData.light_pos = glm::vec4(0,10,5,1);
    _pSceneDataVBO->SetData(&sceneData, sizeof(sceneData));
    
    _pShadowEffect->SetVertexBuffer(_pCubeVBO, 0);
    _pShadowEffect->SetVertexBuffer(_pCubeMatricesVBO, 1);
    _pShadowEffect->SetVertexBuffer(_pSceneDataVBO, 2);
    
    _pDevice->DrawPrimitives(GX_DRAW_TRIANGLE, 36, 1);
    
    
    matrices.model = _planeModel;
    _pPlaneMatricesVBO->SetData(&matrices, sizeof(matrices));
    _pShadowEffect->SetVertexBuffer(_pPlaneVBO, 0);
    _pShadowEffect->SetVertexBuffer(_pPlaneMatricesVBO, 1);
    _pDevice->DrawPrimitives(GX_DRAW_TRIANGLE, 6, 1);
    
    _pShadowEffect->End();
    _pShadowRenderPipeline->End();
    
    
    viewport.dx = self.view.bounds.size.width * screenScale;
    viewport.dy = self.view.bounds.size.height * screenScale;
    _pDevice->SetViewport(&viewport);
    //////// 渲染 场景 /////////
    // 判断当前程序资源的有效性，如果无效则

    if(_pRenderPipeline->Begin() == false || _pEffect->Begin() == false)
    {
        _pDevice->EmptyFlush();
        return;
    }
    
    matrices.model          = _cubeModel;
    matrices.view           = _cubeView;
    matrices.shadowView     = _shadowView;
    matrices.projection     = _projection;
    
    _pCubeMatricesVBO->SetData(&matrices, sizeof(matrices));
    
    sceneData.light_pos = glm::vec4(5,10,0,1);
    _pSceneDataVBO->SetData(&sceneData, sizeof(sceneData));
    
    _pEffect->SetVertexBuffer(_pCubeVBO, 0);
    _pEffect->SetVertexBuffer(_pCubeMatricesVBO, 1);
    _pEffect->SetVertexBuffer(_pSceneDataVBO, 2);
    
    _pEffect->SetFragmentTexture(_pTexture, 0);
    _pEffect->SetFragmentTexture(_pShadowRenderPipeline->GetDepthTexture(), 1);
    _pEffect->SetFragmentSamplerState(&_samplerState, 0);
    
    _pDevice->DrawPrimitives(GX_DRAW_TRIANGLE, 36, 1);
    
    
    matrices.model = _planeModel;
    _pPlaneMatricesVBO->SetData(&matrices, sizeof(matrices));
    _pEffect->SetVertexBuffer(_pPlaneVBO, 0);
    _pEffect->SetVertexBuffer(_pPlaneMatricesVBO, 1);
    _pDevice->DrawPrimitives(GX_DRAW_TRIANGLE, 6, 1);

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
    
    _projection = glm::perspective(45.0f, (float)(rect.size.width)/(float)rect.size.height, 0.1f, 20.0f);
}

@end

