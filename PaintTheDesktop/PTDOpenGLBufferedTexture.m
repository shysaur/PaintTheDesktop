//
//  PTDOpenGLBufferedTexture.m
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 14/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import "PTDOpenGLBufferedTexture.h"
#include <OpenGL/gl.h>


#define ALIGN_OFFS(n, a) ((((int64_t)(n) + ((a)-1)) / (a)) * (a))


@interface PTDOpenGLBufferedTextureWrapperImageRep: NSBitmapImageRep

- (instancetype)initWithOpenGLContext:(NSOpenGLContext *)glcontext
    buffer:(GLuint)buffer
    pixelsWide:(NSInteger)width
    pixelsHigh:(NSInteger)height
    bitsPerSample:(NSInteger)bps
    samplesPerPixel:(NSInteger)spp
    hasAlpha:(BOOL)alpha
    colorSpaceName:(NSColorSpaceName)colorSpaceName
    bytesPerRow:(NSInteger)rBytes
    bitsPerPixel:(NSInteger)pBits;

@end


@implementation PTDOpenGLBufferedTextureWrapperImageRep {
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
  return self;
}


- (void)dealloc
{
  [_glContext makeCurrentContext];
  glBindBuffer(GL_PIXEL_UNPACK_BUFFER, _glBuffer);
  glUnmapBuffer(GL_PIXEL_UNPACK_BUFFER);
  glBindBuffer(GL_PIXEL_UNPACK_BUFFER, 0);
}


@end



@interface PTDOpenGLBufferedTexture ()

@property (nonatomic) GLint pixelWidth;
@property (nonatomic) GLint pixelHeight;

@end


@implementation PTDOpenGLBufferedTexture {
  GLuint _bufferId;
  GLuint _textureId;
  __weak PTDOpenGLBufferedTextureWrapperImageRep *_lastWrappedImage;
  BOOL _editedSinceLastBind;
}


- (instancetype)initWithOpenGLContext:(NSOpenGLContext *)context
    width:(GLint)width height:(GLint)height usage:(GLenum)bufferUsage
{
  self = [super init];
  
  _openGLContext = context;
  [context makeCurrentContext];
  
  _pixelWidth = width;
  _pixelHeight = height;
  
  NSInteger bytePerRow = ALIGN_OFFS(4 * _pixelWidth, 4);
  glGenBuffers(1, &_bufferId);
  glBindBuffer(GL_PIXEL_UNPACK_BUFFER, _bufferId);
  glBufferData(GL_PIXEL_UNPACK_BUFFER, bytePerRow * _pixelHeight, NULL, bufferUsage);
  glBindBuffer(GL_PIXEL_UNPACK_BUFFER, 0);
  
  return self;
}


- (instancetype)initWithOpenGLContext:(NSOpenGLContext *)context
    width:(GLint)width height:(GLint)height
{
  return [self initWithOpenGLContext:context width:width height:height usage:GL_DYNAMIC_DRAW];
}


- (instancetype)initWithOpenGLContext:(NSOpenGLContext *)context
    image:(NSImage *)image backingScaleFactor:(NSSize)scale
{
  NSSize size = image.size;
  size.width *= scale.width;
  size.height *= scale.height;
  self = [self initWithOpenGLContext:context width:size.width height:size.height usage:GL_STATIC_DRAW];
  
  @autoreleasepool {
    NSBitmapImageRep *buffer = [self bufferAsImageRep];
    NSGraphicsContext *tmpgc = [NSGraphicsContext graphicsContextWithBitmapImageRep:buffer];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:tmpgc];
    
    NSRect drawRect = (NSRect){NSZeroPoint, size};
    [[NSColor colorWithWhite:1.0 alpha:0.0] setFill];
    NSRectFill(drawRect);
    NSImageRep *rep = [image bestRepresentationForRect:drawRect context:nil hints:nil];
    [rep drawInRect:drawRect];
    
    [NSGraphicsContext restoreGraphicsState];
  }
  
  return self;
}


- (NSBitmapImageRep *)bufferAsImageRep
{
  _editedSinceLastBind = YES;
  
  PTDOpenGLBufferedTextureWrapperImageRep *imageRep = _lastWrappedImage;
  if (imageRep)
    return imageRep;
    
  NSInteger bytePerRow = ALIGN_OFFS(4 * _pixelWidth, 4);
  imageRep = [[PTDOpenGLBufferedTextureWrapperImageRep alloc]
      initWithOpenGLContext:self.openGLContext
      buffer:_bufferId
      pixelsWide:_pixelWidth pixelsHigh:_pixelHeight
      bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES
      colorSpaceName:NSCalibratedRGBColorSpace
      bytesPerRow:bytePerRow bitsPerPixel:0];
  _lastWrappedImage = imageRep;
  return imageRep;
}


- (NSSize)pixelSize
{
  return NSMakeSize(_pixelWidth, _pixelHeight);
}


- (void)bindBuffer
{
  [_openGLContext makeCurrentContext];
  glBindBuffer(GL_PIXEL_UNPACK_BUFFER, _bufferId);
}


- (void)bindTextureAndBuffer
{
  [_openGLContext makeCurrentContext];
  
  [self bindBuffer];
  
  if (!_textureId) {
    glGenTextures(1, &_textureId);
    glBindTexture(GL_TEXTURE_2D, _textureId);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, _pixelWidth, _pixelHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  } else {
    glBindTexture(GL_TEXTURE_2D, _textureId);
  }
  
  if (!_editedSinceLastBind)
    return;
    
  glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, _pixelWidth, _pixelHeight, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
  _editedSinceLastBind = NO;
  
  return;
}


- (GLenum)texUnit
{
  return GL_TEXTURE_2D;
}


- (GLenum)bufferUnit
{
  return GL_PIXEL_UNPACK_BUFFER;
}


- (void)dealloc
{
  if (_textureId)
    glDeleteTextures(1, &_textureId);
  glDeleteBuffers(1, &_bufferId);
}


@end
