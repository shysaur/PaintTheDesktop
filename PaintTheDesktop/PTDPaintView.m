//
//  PTDPaintView.m
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 08/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import "PTDPaintView.h"
#include <OpenGL/gl.h>


#define ALIGN_OFFS(n, a) ((((int64_t)(n) + ((a)-1)) / (a)) * (a))


@interface PTDOpenGLBufferWrapperImageRep: NSBitmapImageRep

@end


@implementation PTDOpenGLBufferWrapperImageRep {
  GLuint _glBuffer;
  NSOpenGLContext *_glContext;
}


- (instancetype)initWithOpenGLContext:(NSOpenGLContext *)glcontext
    buffer:(GLuint)buffer
    pixelsWide:(NSInteger)width
    pixelsHigh:(NSInteger)height
    bitsPerSample:(NSInteger)bps
    samplesPerPixel:(NSInteger)spp
    hasAlpha:(BOOL)alpha
    colorSpaceName:(NSColorSpaceName)colorSpaceName
    bytesPerRow:(NSInteger)rBytes
    bitsPerPixel:(NSInteger)pBits
{
  [glcontext makeCurrentContext];
  glBindBuffer(GL_PIXEL_UNPACK_BUFFER, buffer);
  void *bufptr = glMapBuffer(GL_PIXEL_UNPACK_BUFFER, GL_READ_WRITE);
  glBindBuffer(GL_PIXEL_UNPACK_BUFFER, 0);
  
  self = [super
      initWithBitmapDataPlanes:(unsigned char**)&bufptr
      pixelsWide:width pixelsHigh:height
      bitsPerSample:bps samplesPerPixel:spp hasAlpha:alpha isPlanar:NO
      colorSpaceName:colorSpaceName
      bytesPerRow:rBytes bitsPerPixel:pBits];
      
  _glBuffer = buffer;
  _glContext = glcontext;
  NSLog(@"new ptd image %p gl ctxt %p glbuf %d bufptr %p imgbufptr %p", self, glcontext, buffer, bufptr, self.bitmapData);
  return self;
}


- (void)dealloc
{
  [_glContext makeCurrentContext];
  glBindBuffer(GL_PIXEL_UNPACK_BUFFER, _glBuffer);
  glUnmapBuffer(GL_PIXEL_UNPACK_BUFFER);
  glBindBuffer(GL_PIXEL_UNPACK_BUFFER, 0);
  NSLog(@"free ptd image %p", self);
}


@end



@implementation PTDPaintView {
  GLuint _mainTexBufId;
  GLuint _width, _height;
  __weak PTDOpenGLBufferWrapperImageRep *_lastImageRepWrapper;
  GLuint _mainTexId;
  
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


- (NSBitmapImageRep *)bufferAsImageRep
{
  if (_lastImageRepWrapper)
    return _lastImageRepWrapper;
  if (_mainTexBufId == 0)
    return nil;
  NSInteger bytePerRow = ALIGN_OFFS(4 * _width, 4);
  PTDOpenGLBufferWrapperImageRep *imageRep = [[PTDOpenGLBufferWrapperImageRep alloc]
      initWithOpenGLContext:self.openGLContext
      buffer:_mainTexBufId
      pixelsWide:_width pixelsHigh:_height
      bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES
      colorSpaceName:NSCalibratedRGBColorSpace
      bytesPerRow:bytePerRow bitsPerPixel:0];
  _lastImageRepWrapper = imageRep;
  return imageRep;
}


- (NSGraphicsContext *)graphicsContext
{
  NSBitmapImageRep *imageRep = [self bufferAsImageRep];
  NSGraphicsContext *ctxt = [NSGraphicsContext graphicsContextWithBitmapImageRep:imageRep];
  CGContextScaleCTM(ctxt.CGContext, _backingScaleFactor.width, _backingScaleFactor.height);
  return ctxt;
}


- (void)updateBackingImage
{
  NSSize newSize = self.bounds.size;
  NSSize newPxSize = NSMakeSize(newSize.width * _backingScaleFactor.width, newSize.height * _backingScaleFactor.height);
  if (newPxSize.width == _width && newPxSize.height == _height)
    return;

  @autoreleasepool {
    NSBitmapImageRep *oldImage = [self bufferAsImageRep];
    GLuint oldBuffer = _mainTexBufId;
    
    [self.openGLContext makeCurrentContext];
    GLuint newBuffer;
    GLuint newWidth = newPxSize.width, newHeight = newPxSize.height;
    NSInteger newBytePerRow = ALIGN_OFFS(4 * newWidth, 4);
    glGenBuffers(1, &newBuffer);
    glBindBuffer(GL_PIXEL_UNPACK_BUFFER, newBuffer);
    glBufferData(GL_PIXEL_UNPACK_BUFFER, newBytePerRow * newHeight, NULL, GL_DYNAMIC_DRAW);
    
    _lastImageRepWrapper = nil;
    _mainTexBufId = newBuffer;
    _width = newWidth;
    _height = newHeight;
  
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
    
    oldImage = nil;
    if (oldBuffer)
      glDeleteBuffers(1, &oldBuffer);
    [NSGraphicsContext setCurrentContext:nil];
  }
  
  glBindBuffer(GL_PIXEL_UNPACK_BUFFER, 0);
  
  if (_mainTexId)
    glDeleteTextures(1, &_mainTexId);
  glGenTextures(1, &_mainTexId);
  glBindTexture(GL_TEXTURE_2D, _mainTexId);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, _width, _height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glBindTexture(GL_TEXTURE_2D, 0);
  
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
  
  glBindBuffer(GL_PIXEL_UNPACK_BUFFER, _mainTexBufId);
  glBindTexture(GL_TEXTURE_2D, _mainTexId);
  
  glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, _width, _height, GL_RGBA, GL_UNSIGNED_BYTE, NULL);

  glBindBuffer(GL_PIXEL_UNPACK_BUFFER, 0);
  
  
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
  
  glBindTexture(GL_TEXTURE_2D, _mainTexId);
  glEnable(GL_TEXTURE_2D);
  glBegin(GL_QUADS);
  glNormal3f(0.0, 0.0, 1.0);
  glTexCoord2d(0, 1); glVertex3f(-1.0, -1.0, 0.0);
  glTexCoord2d(0, 0); glVertex3f(-1.0, 1.0, 0.0);
  glTexCoord2d(1, 0); glVertex3f(1.0, 1.0, 0.0);
  glTexCoord2d(1, 1); glVertex3f(1.0, -1.0, 0.0);
  glEnd();
  
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
