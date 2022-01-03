//
// PTDOpenGLBufferedTexture.m
// PaintTheDesktop -- Created on 14/06/2020.
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

#import "PTDOpenGLBufferedTexture.h"
#include <OpenGL/gl.h>


#define ALIGN_OFFS(n, a) ((((int64_t)(n) + ((a)-1)) / (a)) * (a))


@interface NSBitmapImageRep ()

- (void)_retagBackingWithColorSpace:(NSColorSpace *)colorSpace;

@end


@interface PTDOpenGLBufferedTextureWrapperImageRep: NSBitmapImageRep

- (instancetype)initWithOpenGLContext:(NSOpenGLContext *)glcontext
    buffer:(GLuint)buffer
    pixelsWide:(NSInteger)width
    pixelsHigh:(NSInteger)height
    bitsPerSample:(NSInteger)bps
    samplesPerPixel:(NSInteger)spp
    hasAlpha:(BOOL)alpha
    colorSpace:(NSColorSpace *)colorSpace
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
    colorSpace:(NSColorSpace *)colorSpace
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
      colorSpaceName:NSCalibratedRGBColorSpace
      bytesPerRow:rBytes bitsPerPixel:pBits];
  [self setProperty:@"NSColorSpace" withValue:colorSpace];
  if ([self respondsToSelector:@selector(_retagBackingWithColorSpace:)])
    [self _retagBackingWithColorSpace:colorSpace];
  else
    NSLog(@"PTDOpenGLBufferedTextureWrapperImageRep: couldn't -_retagBackingWithColorSpace:");
      
  _glBuffer = buffer;
  _glContext = glcontext;
  return self;
}


- (instancetype)copyWithZone:(NSZone *)zone
{
  PTDOpenGLBufferedTextureWrapperImageRep *new = [super copyWithZone:zone];
  new->_glContext = nil;
  new->_glBuffer = 0;
  return new;
}


- (void)dealloc
{
  if (!_glContext)
    return;
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
    colorSpace:(NSColorSpace *)colorSpace
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
  
  _colorSpace = colorSpace;
  
  return self;
}


- (instancetype)initWithOpenGLContext:(NSOpenGLContext *)context
    width:(GLint)width height:(GLint)height
    colorSpace:(NSColorSpace *)colorSpace
{
  return [self initWithOpenGLContext:context width:width height:height usage:GL_DYNAMIC_DRAW colorSpace:colorSpace];
}


- (instancetype)initWithOpenGLContext:(NSOpenGLContext *)context
    image:(NSImage *)image backingScaleFactor:(NSSize)scale
    colorSpace:(NSColorSpace *)colorSpace
{
  NSSize size = image.size;
  size.width *= scale.width;
  size.height *= scale.height;
  self = [self initWithOpenGLContext:context width:size.width height:size.height usage:GL_STATIC_DRAW colorSpace:colorSpace];
  
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
      colorSpace:_colorSpace
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


- (void)setColorSpace:(NSColorSpace *)colorSpace
{
  _lastWrappedImage = nil;
  _colorSpace = colorSpace;
}


- (void)convertToColorSpace:(NSColorSpace *)colorSpace renderingIntent:(NSColorRenderingIntent)renderingIntent
{
  if (_colorSpace == nil || colorSpace == nil) {
    self.colorSpace = colorSpace;
    return;
  }
  if ([_colorSpace isEqual:colorSpace])
    return;
  
  @autoreleasepool {
    NSBitmapImageRep *tempImageRep = self.bufferAsImageRep;
    tempImageRep = [tempImageRep bitmapImageRepByConvertingToColorSpace:colorSpace renderingIntent:renderingIntent];
    
    self.colorSpace = colorSpace;
    NSBitmapImageRep *newImageRep = self.bufferAsImageRep;
    NSGraphicsContext *tmpgc = [NSGraphicsContext graphicsContextWithBitmapImageRep:newImageRep];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:tmpgc];
    [tempImageRep drawAtPoint:NSZeroPoint];
    [NSGraphicsContext restoreGraphicsState];
  }
}


- (void)dealloc
{
  if (_textureId)
    glDeleteTextures(1, &_textureId);
  glDeleteBuffers(1, &_bufferId);
}


@end
