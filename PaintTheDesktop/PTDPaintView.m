//
//  PTDPaintView.m
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 08/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import "PTDPaintView.h"
#import "PTDOpenGLBufferedTexture.h"
#include <OpenGL/gl.h>


@implementation PTDPaintView {
  PTDOpenGLBufferedTexture *_mainBuffer;
  PTDOpenGLBufferedTexture *_cursorBuffer;
}


- (instancetype)initWithFrame:(NSRect)frameRect
{
  self = [super initWithFrame:frameRect];
  _backingScaleFactor = NSMakeSize(1.0, 1.0);
  [self updateBackingImage];
  return self;
}


- (instancetype)initWithCoder:(NSCoder *)coder
{
  self = [super initWithCoder:coder];
  _backingScaleFactor = NSMakeSize(1.0, 1.0);
  [self updateBackingImage];
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
  [self updateBackingImage];
}


- (void)setBounds:(NSRect)frame
{
  [super setBounds:frame];
  [self updateBackingImage];
}


- (void)viewDidChangeBackingProperties
{
  [self updateBackingImage];
}


- (void)setBackingScaleFactor:(NSSize)backingScaleFactor
{
  _backingScaleFactor = backingScaleFactor;
  [self updateBackingImage];
}


- (NSRect)paintRect
{
  return self.bounds;
}


- (NSGraphicsContext *)graphicsContext
{
  NSBitmapImageRep *imageRep = _mainBuffer.bufferAsImageRep;
  NSGraphicsContext *ctxt = [NSGraphicsContext graphicsContextWithBitmapImageRep:imageRep];
  CGContextScaleCTM(ctxt.CGContext, _backingScaleFactor.width, _backingScaleFactor.height);
  return ctxt;
}


- (void)updateBackingImage
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
  }
  
  [self setNeedsDisplay:YES];
}


- (void)setCursorImage:(NSImage *)cursorImage
{
  _cursorImage = cursorImage;
  
  if (!_cursorImage) {
    _cursorBuffer = nil;
  } else {
    _cursorBuffer = [[PTDOpenGLBufferedTexture alloc]
        initWithOpenGLContext:self.openGLContext
        image:_cursorImage backingScaleFactor:self.backingScaleFactor];
  }
  
  [self setNeedsDisplay:YES];
}


- (void)setCursorPosition:(NSPoint)cursorPosition
{
  _cursorPosition = cursorPosition;
  [self setNeedsDisplay:YES];
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
  [self drawCursor];
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


- (void)drawCursor
{
  if (!_cursorBuffer)
    return;
    
  NSPoint cursorPos = NSMakePoint(
      self.cursorPosition.x * self.backingScaleFactor.width,
      self.cursorPosition.y * self.backingScaleFactor.height);
  NSRect r = (NSRect){NSZeroPoint, _mainBuffer.pixelSize};
  GLfloat scrCurLeft = cursorPos.x / r.size.width * 2 - 1;
  GLfloat scrCurBtm = cursorPos.y / r.size.height * 2 - 1;
  GLfloat scrCurRight = _cursorBuffer.pixelWidth / r.size.width * 2 + scrCurLeft;
  GLfloat scrCurTop = _cursorBuffer.pixelHeight / r.size.height * 2 + scrCurBtm;

  [_cursorBuffer bindTextureAndBuffer];
  
  glEnable(_cursorBuffer.texUnit);
  glBegin(GL_QUADS);
  glNormal3f(0.0, 0.0, 1.0);
  glTexCoord2d(0, 1); glVertex3f(scrCurLeft, scrCurBtm, 0.0);
  glTexCoord2d(0, 0); glVertex3f(scrCurLeft, scrCurTop, 0.0);
  glTexCoord2d(1, 0); glVertex3f(scrCurRight, scrCurTop, 0.0);
  glTexCoord2d(1, 1); glVertex3f(scrCurRight, scrCurBtm, 0.0);
  glEnd();
  glDisable(_cursorBuffer.texUnit);
  
  glBindTexture(_cursorBuffer.texUnit, 0);
  glBindBuffer(_cursorBuffer.bufferUnit, 0);
}


@end
