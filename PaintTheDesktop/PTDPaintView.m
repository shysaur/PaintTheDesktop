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


@interface PTDPaintView ()

@property (nonatomic) NSBitmapImageRep *backingImage;

@end


@implementation PTDPaintView {
  CGFloat _scaleFactor;
  NSBitmapImageRep *_previousBackingImage;
  NSBitmapImageRep *_cursorBackingImage;
}


- (instancetype)initWithFrame:(NSRect)frameRect
{
  self = [super initWithFrame:frameRect];
  _scaleFactor = 1.0;
  [self updateBackingImage];
  [self updateCursor];
  return self;
}


- (instancetype)initWithCoder:(NSCoder *)coder
{
  self = [super initWithCoder:coder];
  _scaleFactor = 1.0;
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


- (void)setBackingImage:(NSBitmapImageRep *)backingImage
{
  _backingImage = backingImage;
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
  _scaleFactor = [[[self window] screen] backingScaleFactor];
  [self updateBackingImage];
}


- (NSRect)paintRect
{
  return self.bounds;
}


- (NSGraphicsContext *)graphicsContext
{
  NSGraphicsContext *ctxt = [NSGraphicsContext graphicsContextWithBitmapImageRep:_backingImage];
  CGContextScaleCTM(ctxt.CGContext, _scaleFactor, _scaleFactor);
  return ctxt;
}


- (void)updateBackingImage
{
  NSBitmapImageRep *oldImage = self.backingImage;
  
  NSSize newSize = self.bounds.size;
  NSSize newPxSize = [self convertSizeToBacking:newSize];
  
  NSInteger bytePerRow = ALIGN_OFFS(4 * newPxSize.width, 4);
  self.backingImage = [[NSBitmapImageRep alloc]
      initWithBitmapDataPlanes:NULL
      pixelsWide:newPxSize.width pixelsHigh:newPxSize.height
      bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO
      colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:bytePerRow bitsPerPixel:0];
  
  [NSGraphicsContext setCurrentContext:self.graphicsContext];
  if (oldImage) {
    [oldImage
        drawInRect:(NSRect){NSMakePoint(0, 0), newSize}
        fromRect:(NSRect){NSMakePoint(0, 0), oldImage.size}
        operation:NSCompositingOperationCopy fraction:1.0 respectFlipped:YES
        hints:@{NSImageHintInterpolation: @(NSImageInterpolationHigh)}];
  } else {
    [[NSColor colorWithDeviceWhite:1.0 alpha:0.0] setFill];
    NSRectFill((NSRect){NSMakePoint(0, 0), self.backingImage.size});
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
  NSRect r = [self convertRectToBacking:self.bounds];

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

  glViewport(0, 0, r.size.width, r.size.height);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  //glOrtho(0, r.size.width, 0, r.size.height, -1, 1);
  
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();
  
  glClearColor(0, 0, 0, 0);
  glClear(GL_COLOR_BUFFER_BIT);
  
  
  GLuint texId;
  glGenTextures(1, &texId);
  glBindTexture(GL_TEXTURE_2D, texId);
  
  NSSize imgSize = _backingImage.size;
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, imgSize.width, imgSize.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, _backingImage.bitmapData);

  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  
  
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
  
  glBindTexture(GL_TEXTURE_2D, texId);
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
  
  glDeleteTextures(1, &texId);
  if (_cursorBackingImage) {
    glDeleteTextures(1, &cursorTexId);
  }
  
  glFlush();
}


@end
