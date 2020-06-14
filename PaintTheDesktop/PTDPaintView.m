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


#define ALIGN_OFFS(n, a) ((((int64_t)(n) + ((a)-1)) / (a)) * (a))


@implementation PTDPaintView {
  PTDOpenGLBufferedTexture *_mainBuffer;
  NSBitmapImageRep *_cursorBackingImage;
}


- (instancetype)initWithFrame:(NSRect)frameRect
{
  self = [super initWithFrame:frameRect];
  _backingScaleFactor = NSMakeSize(1.0, 1.0);
  [self updateBackingImage];
  [self updateCursor];
  return self;
}


- (instancetype)initWithCoder:(NSCoder *)coder
{
  self = [super initWithCoder:coder];
  _backingScaleFactor = NSMakeSize(1.0, 1.0);
  [self updateBackingImage];
  [self updateCursor];
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
  [self updateCursor];
}


- (void)setCursorPosition:(NSPoint)cursorPosition
{
  _cursorPosition = cursorPosition;
  [self setNeedsDisplay:YES];
}


- (void)updateCursor
{
  if (!_cursorImage) {
    _cursorBackingImage = nil;
    [self setNeedsDisplay:YES];
    return;
  }
  
  NSRect cursorRect = NSZeroRect;
  cursorRect.size = self.cursorImage.size;
  NSRect backingRect = [self convertRectToBacking:cursorRect];
  
  NSImageRep *rep = [self.cursorImage bestRepresentationForRect:cursorRect context:self.graphicsContext hints:nil];
  NSInteger bytePerRow = ALIGN_OFFS(4 * backingRect.size.width, 4);
  _cursorBackingImage = [[NSBitmapImageRep alloc]
      initWithBitmapDataPlanes:NULL
      pixelsWide:backingRect.size.width pixelsHigh:backingRect.size.height
      bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO
      colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:bytePerRow bitsPerPixel:0];
  
  [NSGraphicsContext saveGraphicsState];
  NSGraphicsContext *tmpGc = [NSGraphicsContext graphicsContextWithBitmapImageRep:_cursorBackingImage];
  [NSGraphicsContext setCurrentContext:tmpGc];
  [rep drawInRect:backingRect];
  [NSGraphicsContext restoreGraphicsState];
  
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


- (void)drawRect:(NSRect)dirtyRect
{
  GLint zero = 0;
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
  //glOrtho(0, r.size.width, 0, r.size.height, -1, 1);
  
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();
  
  glClearColor(0, 0, 0, 0);
  glClear(GL_COLOR_BUFFER_BIT);
  
  
  GLuint cursorTexId = -1;
  NSSize curSize;
  if (_cursorBackingImage) {
    glGenTextures(1, &cursorTexId);
    glBindTexture(GL_TEXTURE_2D, cursorTexId);
    
    curSize = _cursorBackingImage.size;
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, curSize.width, curSize.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, _cursorBackingImage.bitmapData);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  }
  
  
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  glPushAttrib(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  
  [_mainBuffer bindTextureAndBuffer];
  
  glEnable(_mainBuffer.texUnit);
  glBegin(GL_QUADS);
  glNormal3f(0.0, 0.0, 1.0);
  glTexCoord2d(0, 1); glVertex3f(-1.0, -1.0, 0.0);
  glTexCoord2d(0, 0); glVertex3f(-1.0, 1.0, 0.0);
  glTexCoord2d(1, 0); glVertex3f(1.0, 1.0, 0.0);
  glTexCoord2d(1, 1); glVertex3f(1.0, -1.0, 0.0);
  glEnd();
  
  glBindTexture(_mainBuffer.texUnit, 0);
  glBindBuffer(_mainBuffer.bufferUnit, 0);
  
  
  if (_cursorBackingImage) {
    NSPoint cursorPos = [self convertPointToBacking:self.cursorPosition];
    NSRect r = [self convertRectToBacking:self.bounds];
    GLfloat scrCurLeft = cursorPos.x / r.size.width * 2 - 1;
    GLfloat scrCurBtm = cursorPos.y / r.size.height * 2 - 1;
    GLfloat scrCurRight = curSize.width / r.size.width * 2 + scrCurLeft;
    GLfloat scrCurTop = curSize.height / r.size.height * 2 + scrCurBtm;

    glBindTexture(GL_TEXTURE_2D, cursorTexId);
    glEnable(GL_TEXTURE_2D);
    glBegin(GL_QUADS);
    glNormal3f(0.0, 0.0, 1.0);
    glTexCoord2d(0, 1); glVertex3f(scrCurLeft, scrCurBtm, 0.0);
    glTexCoord2d(0, 0); glVertex3f(scrCurLeft, scrCurTop, 0.0);
    glTexCoord2d(1, 0); glVertex3f(scrCurRight, scrCurTop, 0.0);
    glTexCoord2d(1, 1); glVertex3f(scrCurRight, scrCurBtm, 0.0);
    glEnd();
  }
  
  glDisable(GL_TEXTURE_2D);
  glPopAttrib();
  
  if (_cursorBackingImage) {
    glDeleteTextures(1, &cursorTexId);
  }
  
  glFlush();
}


@end
