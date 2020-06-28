//
//  PTDPaintView.m
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 08/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import <Quartz/Quartz.h>
#import "NSView+PTD.h"
#import "PTDPaintView.h"
#import "PTDOpenGLBufferedTexture.h"
#include <OpenGL/gl.h>


@implementation PTDPaintView {
  PTDOpenGLBufferedTexture *_mainBuffer;
  PTDOpenGLBufferedTexture *_overlayBuffer;
  CALayer *_cursorLayer;
}


- (instancetype)initWithFrame:(NSRect)frameRect
{
  self = [super initWithFrame:frameRect];
  _backingScaleFactor = NSMakeSize(1.0, 1.0);
  [self updateBackingImages];
  return self;
}


- (instancetype)initWithCoder:(NSCoder *)coder
{
  self = [super initWithCoder:coder];
  _backingScaleFactor = NSMakeSize(1.0, 1.0);
  [self updateBackingImages];
  return self;
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


- (void)setFrame:(NSRect)frame
{
  [super setFrame:frame];
  [self updateBackingImages];
}


- (void)setBounds:(NSRect)frame
{
  [super setBounds:frame];
  [self updateBackingImages];
}


- (void)viewDidChangeBackingProperties
{
  [self updateBackingImages];
}


- (void)setBackingScaleFactor:(NSSize)backingScaleFactor
{
  _backingScaleFactor = backingScaleFactor;
  [self updateBackingImages];
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
  return copy;
}


- (NSGraphicsContext *)graphicsContext
{
  NSBitmapImageRep *imageRep = _mainBuffer.bufferAsImageRep;
  NSGraphicsContext *ctxt = [NSGraphicsContext graphicsContextWithBitmapImageRep:imageRep];
  CGContextScaleCTM(ctxt.CGContext, _backingScaleFactor.width, _backingScaleFactor.height);
  return ctxt;
}


- (NSGraphicsContext *)overlayGraphicsContext
{
  if (!_overlayBuffer) {
    _overlayBuffer = [[PTDOpenGLBufferedTexture alloc]
        initWithOpenGLContext:self.openGLContext
        width:_mainBuffer.pixelWidth height:_mainBuffer.pixelHeight];
  }
  NSBitmapImageRep *imageRep = _overlayBuffer.bufferAsImageRep;
  NSGraphicsContext *ctxt = [NSGraphicsContext graphicsContextWithBitmapImageRep:imageRep];
  CGContextScaleCTM(ctxt.CGContext, _backingScaleFactor.width, _backingScaleFactor.height);
  return ctxt;
}


- (void)updateBackingImages
{
  NSSize newSize = self.bounds.size;
  NSSize newPxSize = NSMakeSize(newSize.width * _backingScaleFactor.width, newSize.height * _backingScaleFactor.height);
  if (newPxSize.width == _mainBuffer.pixelWidth && newPxSize.height == _mainBuffer.pixelHeight)
    return;

  @autoreleasepool {
    NSBitmapImageRep *oldImage = _mainBuffer.bufferAsImageRep;
    _mainBuffer = [[PTDOpenGLBufferedTexture alloc]
        initWithOpenGLContext:self.openGLContext
        width:newPxSize.width height:newPxSize.height];
  
    [NSGraphicsContext setCurrentContext:self.graphicsContext];
    if (oldImage) {
      [oldImage
          drawInRect:(NSRect){NSMakePoint(0, 0), newSize}
          fromRect:(NSRect){NSMakePoint(0, 0), oldImage.size}
          operation:NSCompositingOperationCopy fraction:1.0 respectFlipped:YES
          hints:@{NSImageHintInterpolation: @(NSImageInterpolationHigh)}];
    } else {
      [[NSColor colorWithDeviceWhite:1.0 alpha:0.0] setFill];
      NSRectFill((NSRect){NSMakePoint(0, 0), newPxSize});
    }
    [NSGraphicsContext setCurrentContext:nil];
    
    _overlayBuffer = nil;
  }
  
  [self setNeedsDisplay:YES];
}


- (void)setCursorImage:(NSImage *)cursorImage
{
  _cursorImage = cursorImage;
  if (_cursorLayer)
    [_cursorLayer removeFromSuperlayer];
    
  _cursorLayer = [CALayer layer];
  [self.layer addSublayer:_cursorLayer];
  _cursorLayer.contents = cursorImage;
  _cursorLayer.anchorPoint = NSZeroPoint;
  
  _cursorLayer.frame = (NSRect){
      [self ptd_backingAlignedPoint:self.cursorPosition],
      cursorImage.size};
}


- (void)setCursorPosition:(NSPoint)cursorPosition
{
  _cursorPosition = cursorPosition;
  [CATransaction begin];
  [CATransaction setDisableActions:YES];
  _cursorLayer.position = [self ptd_backingAlignedPoint:_cursorPosition];
  [CATransaction commit];
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
  [self.openGLContext setValues:&zero forParameter:NSOpenGLCPSurfaceOpacity];
  
  glEnable(GL_ALPHA_TEST);
  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
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
  [self drawOverlay];
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


- (void)drawOverlay
{
  if (!_overlayBuffer)
    return;
    
  [_overlayBuffer bindTextureAndBuffer];
  
  glEnable(_overlayBuffer.texUnit);
  glBegin(GL_QUADS);
  glNormal3f(0.0, 0.0, 1.0);
  glTexCoord2d(0, 1); glVertex3f(-1.0, -1.0, 0.0);
  glTexCoord2d(0, 0); glVertex3f(-1.0, 1.0, 0.0);
  glTexCoord2d(1, 0); glVertex3f(1.0, 1.0, 0.0);
  glTexCoord2d(1, 1); glVertex3f(1.0, -1.0, 0.0);
  glEnd();
  glDisable(_overlayBuffer.texUnit);
  
  glBindTexture(_overlayBuffer.texUnit, 0);
  glBindBuffer(_overlayBuffer.bufferUnit, 0);
}


@end
