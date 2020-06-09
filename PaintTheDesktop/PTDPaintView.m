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
}


- (instancetype)initWithFrame:(NSRect)frameRect
{
  self = [super initWithFrame:frameRect];
  _scaleFactor = 1.0;
  [self updateBackingImage];
  return self;
}


- (instancetype)initWithCoder:(NSCoder *)coder
{
  self = [super initWithCoder:coder];
  _scaleFactor = 1.0;
  [self updateBackingImage];
  return self;
}


- (BOOL)isOpaque
{
  return NO;
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


- (void)drawRect:(NSRect)dirtyRect
{
  NSRect r = self.bounds;
  NSSize imgSize = _backingImage.size;

  GLint zero = 0;
  [self.openGLContext setValues:&zero forParameter:NSOpenGLCPSurfaceOpacity];
  
  glDisable(GL_ALPHA_TEST);
  glDisable(GL_DEPTH_TEST);
  glDisable(GL_SCISSOR_TEST);
  glDisable(GL_BLEND);
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
  
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, imgSize.width, imgSize.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, _backingImage.bitmapData);

  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  glPushAttrib(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  glEnable(GL_TEXTURE_2D);
  glBegin(GL_QUADS);
  glNormal3f(0.0, 0.0, 1.0);
  glTexCoord2d(0, 1); glVertex3f(-1.0, -1.0, 0.0);
  glTexCoord2d(0, 0); glVertex3f(-1.0, 1.0, 0.0);
  glTexCoord2d(1, 0); glVertex3f(1.0, 1.0, 0.0);
  glTexCoord2d(1, 1); glVertex3f(1.0, -1.0, 0.0);
  glEnd();
  glDisable(GL_TEXTURE_2D);
  glPopAttrib();
  
  glDeleteTextures(1, &texId);
  
  glFlush();
}


@end
