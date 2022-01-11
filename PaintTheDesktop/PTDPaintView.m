//
// PTDPaintView.m
// PaintTheDesktop -- Created on 08/06/2020.
//
// Copyright (c) 2020 Daniele Cattaneo
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

#include <OpenGL/gl.h>
#import <Quartz/Quartz.h>
#import "NSView+PTD.h"
#import "PTDPaintView.h"
#import "PTDOpenGLBufferedTexture.h"
#import "PTDNoAnimeCALayer.h"


@implementation PTDPaintView {
  PTDOpenGLBufferedTexture *_mainBuffer;
  PTDNoAnimeCALayer *_overlayLayer;
  CALayer *_cursorLayer;
  BOOL _liveResize;
}


- (instancetype)initWithFrame:(NSRect)frameRect
{
  self = [super initWithFrame:frameRect];
  _liveResize = NO;
  _backingScaleFactor = NSMakeSize(1.0, 1.0);
  [self updateBackingImages];
  return self;
}


- (instancetype)initWithCoder:(NSCoder *)coder
{
  self = [super initWithCoder:coder];
  _liveResize = NO;
  _backingScaleFactor = NSMakeSize(1.0, 1.0);
  [self updateBackingImages];
  return self;
}


- (BOOL)acceptsFirstMouse:(NSEvent *)event
{
  return YES;
}


- (BOOL)isOpaque
{
  return NO;
}


- (BOOL)wantsBestResolutionOpenGLSurface
{
  return YES;
}


- (BOOL)wantsLayer
{
  return YES;
}


- (void)setLayer:(CALayer *)layer
{
  [super setLayer:layer];
  [self initializeCursorLayer];
}


- (void)setFrame:(NSRect)frame
{
  if (self.paintViewDelegate && [self.paintViewDelegate respondsToSelector:@selector(viewWillResize:)])
    [self.paintViewDelegate viewWillResize:self];
  
  [super setFrame:frame];
  if (!self.inLiveResize)
    [self updateBackingImages];
  
  if (self.paintViewDelegate && [self.paintViewDelegate respondsToSelector:@selector(viewDidResize:)])
    [self.paintViewDelegate viewDidResize:self];
}


- (void)setFrameSize:(NSSize)newSize
{
  if (self.paintViewDelegate && [self.paintViewDelegate respondsToSelector:@selector(viewWillResize:)])
    [self.paintViewDelegate viewWillResize:self];
  
  [super setFrameSize:newSize];
  if (!self.inLiveResize)
    [self updateBackingImages];
  
  if (self.paintViewDelegate && [self.paintViewDelegate respondsToSelector:@selector(viewDidResize:)])
    [self.paintViewDelegate viewDidResize:self];
}


- (void)setBounds:(NSRect)frame
{
  if (self.paintViewDelegate && [self.paintViewDelegate respondsToSelector:@selector(viewWillResize:)])
    [self.paintViewDelegate viewWillResize:self];
  
  [super setBounds:frame];
  if (!self.inLiveResize)
    [self updateBackingImages];
  
  if (self.paintViewDelegate && [self.paintViewDelegate respondsToSelector:@selector(viewDidResize:)])
    [self.paintViewDelegate viewDidResize:self];
}


- (void)viewWillStartLiveResize
{
  [super viewWillStartLiveResize];
  _liveResize = YES;
  if (self.paintViewDelegate && [self.paintViewDelegate respondsToSelector:@selector(viewWillStartLiveResize:)])
    [self.paintViewDelegate viewWillStartLiveResize:self];
}


- (BOOL)inLiveResize
{
  return _liveResize ? YES : [super inLiveResize];
}


- (void)viewDidEndLiveResize
{
  [super viewDidEndLiveResize];
  _liveResize = NO;
  if (self.paintViewDelegate && [self.paintViewDelegate respondsToSelector:@selector(viewDidEndLiveResize:)])
    [self.paintViewDelegate viewDidEndLiveResize:self];
  [self updateBackingImages];
}


- (void)viewDidChangeBackingProperties
{
  if (!self.window || self.inLiveResize)
    return;
  [_mainBuffer convertToColorSpace:self.window.screen.colorSpace renderingIntent:NSColorRenderingIntentRelativeColorimetric];
  CGFloat scale = self.window.screen.backingScaleFactor;
  NSSize oldScaleFactor = self.backingScaleFactor;
  self.backingScaleFactor = NSMakeSize(MAX(oldScaleFactor.width, scale), MAX(oldScaleFactor.height, scale));
}


- (void)setBackingScaleFactor:(NSSize)backingScaleFactor
{
  _backingScaleFactor = backingScaleFactor;
  [self updateBackingImages];
  [self update];
}


- (CALayer *)overlayLayer
{
  if (!_overlayLayer) {
    _overlayLayer = [[PTDNoAnimeCALayer alloc] init];
    [self.layer addSublayer:_overlayLayer];
    _overlayLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
    _overlayLayer.frame = self.bounds;
    _overlayLayer.zPosition = 50;
  }
  return _overlayLayer;
}


- (NSRect)paintRect
{
  return self.bounds;
}


- (NSBitmapImageRep *)snapshot
{
  NSBitmapImageRep *copy;
  @autoreleasepool {
    NSBitmapImageRep *imageRep = _mainBuffer.bufferAsImageRep;
    copy = [imageRep copy];
  }
  
  copy.size = NSMakeSize(
      (CGFloat)copy.pixelsWide / _backingScaleFactor.width,
      (CGFloat)copy.pixelsHigh / _backingScaleFactor.height);
  return copy;
}


- (NSBitmapImageRep *)snapshotOfRect:(NSRect)rect
{
  NSRect backingRect = rect;
  backingRect.origin.x *= _backingScaleFactor.width;
  backingRect.size.width *= _backingScaleFactor.width;
  backingRect.origin.y *= _backingScaleFactor.height;
  backingRect.size.height *= _backingScaleFactor.height;
  
  NSInteger backingWidth = ceil(backingRect.size.width);
  NSInteger backingHeight = ceil(backingRect.size.height);
  
  NSBitmapImageRep *copy;
  @autoreleasepool {
    NSBitmapImageRep *imageRep = _mainBuffer.bufferAsImageRep;
    
    copy = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:backingWidth pixelsHigh:backingHeight bitsPerSample:imageRep.bitsPerSample samplesPerPixel:imageRep.samplesPerPixel hasAlpha:imageRep.hasAlpha isPlanar:NO colorSpaceName:imageRep.colorSpaceName bytesPerRow:0 bitsPerPixel:0];
    copy = [copy bitmapImageRepByRetaggingWithColorSpace:imageRep.colorSpace];
    
    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext.currentContext = [NSGraphicsContext graphicsContextWithBitmapImageRep:copy];
    [imageRep drawInRect:(NSRect){NSZeroPoint, backingRect.size} fromRect:backingRect operation:NSCompositingOperationCopy fraction:1.0 respectFlipped:YES hints:nil];
    [NSGraphicsContext restoreGraphicsState];
  }
  
  copy.size = NSMakeSize(
      (CGFloat)copy.pixelsWide / _backingScaleFactor.width,
      (CGFloat)copy.pixelsHigh / _backingScaleFactor.height);
  return copy;
}


- (NSGraphicsContext *)graphicsContext
{
  NSBitmapImageRep *imageRep = _mainBuffer.bufferAsImageRep;
  NSGraphicsContext *ctxt = [NSGraphicsContext graphicsContextWithBitmapImageRep:imageRep];
  CGContextScaleCTM(ctxt.CGContext, _backingScaleFactor.width, _backingScaleFactor.height);
  return ctxt;
}


- (void)updateBackingImages
{
  _overlayLayer.frame = self.bounds;
  
  NSSize newSize = self.bounds.size;
  NSSize newPxSize = NSMakeSize(newSize.width * _backingScaleFactor.width, newSize.height * _backingScaleFactor.height);
  if (newPxSize.width == _mainBuffer.pixelWidth && newPxSize.height == _mainBuffer.pixelHeight)
    return;
  if (newPxSize.width == 0 || newPxSize.height == 0) {
    NSLog(@"%s: canceling because area is zero", __PRETTY_FUNCTION__);
    return;
  }

  @autoreleasepool {
    NSBitmapImageRep *oldImage = _mainBuffer.bufferAsImageRep;
    _mainBuffer = [[PTDOpenGLBufferedTexture alloc]
        initWithOpenGLContext:self.openGLContext
        width:newPxSize.width height:newPxSize.height
        colorSpace:self.window.screen.colorSpace];
  
    [NSGraphicsContext setCurrentContext:self.graphicsContext];
    if (oldImage) {
      [oldImage
          drawInRect:(NSRect){NSZeroPoint, newSize}
          fromRect:NSZeroRect
          operation:NSCompositingOperationCopy fraction:1.0 respectFlipped:YES
          hints:@{NSImageHintInterpolation: @(NSImageInterpolationHigh)}];
    } else {
      [[NSColor colorWithDeviceWhite:1.0 alpha:0.0] setFill];
      NSRectFill((NSRect){NSMakePoint(0, 0), newPxSize});
    }
    [NSGraphicsContext setCurrentContext:nil];
  }
  
  [self setNeedsDisplay:YES];
}


- (void)setCursorImage:(NSImage *)cursorImage
{
  _cursorImage = cursorImage;
  if (self.layer)
    [self initializeCursorLayer];
}


- (void)setCursorPosition:(NSPoint)cursorPosition
{
  _cursorPosition = cursorPosition;
  if (_cursorLayer) {
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    _cursorLayer.position = [self ptd_backingAlignedPoint:_cursorPosition];
    [CATransaction commit];
  }
}


- (void)initializeCursorLayer
{
  if (_cursorLayer)
    [_cursorLayer removeFromSuperlayer];
    
  _cursorLayer = [CALayer layer];
  [self.layer addSublayer:_cursorLayer];
  _cursorLayer.zPosition = 100;
  _cursorLayer.contents = self.cursorImage;
  _cursorLayer.anchorPoint = NSZeroPoint;
  _cursorLayer.bounds = (NSRect){NSZeroPoint, self.cursorImage.size};
  _cursorLayer.position = [self ptd_backingAlignedPoint:self.cursorPosition];
}


- (NSOpenGLPixelFormat *)pixelFormat
{
  NSOpenGLPixelFormatAttribute attrs[] = {
    NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersionLegacy,
    0
  };
  return [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
}


- (void)prepareOpenGL
{
  [super prepareOpenGL];
  
  static const GLint zero = 0;
  [self.openGLContext setValues:&zero forParameter:NSOpenGLContextParameterSurfaceOpacity];
  [self.openGLContext setValues:&zero forParameter:NSOpenGLContextParameterSwapInterval];
  
  glEnable(GL_ALPHA_TEST);
  glEnable(GL_BLEND);
  glBlendEquationSeparate(GL_FUNC_ADD, GL_FUNC_ADD);
  glBlendFuncSeparate(GL_ONE, GL_ONE_MINUS_SRC_ALPHA, GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
  glDisable(GL_DEPTH_TEST);
  glDisable(GL_SCISSOR_TEST);
  glDisable(GL_DITHER);
  glDisable(GL_CULL_FACE);
  glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
  glDepthMask(GL_FALSE);
  glStencilMask(0);

  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();
  
  glClearColor(0, 0, 0, 0);
}


- (void)drawRect:(NSRect)dirtyRect
{
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  [self drawBackdrop];
  glFlush();
}


- (void)drawBackdrop
{
  [_mainBuffer bindTextureAndBuffer];
  
  glEnable(_mainBuffer.texUnit);
  glBegin(GL_QUADS);
  glNormal3f(0.0, 0.0, 1.0);
  glTexCoord2d(0, 1); glVertex3f(-1.0, -1.0, 0.0);
  glTexCoord2d(0, 0); glVertex3f(-1.0, 1.0, 0.0);
  glTexCoord2d(1, 0); glVertex3f(1.0, 1.0, 0.0);
  glTexCoord2d(1, 1); glVertex3f(1.0, -1.0, 0.0);
  glEnd();
  glDisable(_mainBuffer.texUnit);
  
  glBindTexture(_mainBuffer.texUnit, 0);
  glBindBuffer(_mainBuffer.bufferUnit, 0);
}


@end
