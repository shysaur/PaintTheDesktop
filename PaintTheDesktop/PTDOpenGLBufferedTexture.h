//
// PTDOpenGLBufferedTexture.h
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

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTDOpenGLBufferedTexture : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithOpenGLContext:(NSOpenGLContext *)context
    width:(GLint)width height:(GLint)height
    usage:(GLenum)bufferUsage NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithOpenGLContext:(NSOpenGLContext *)context
    width:(GLint)width height:(GLint)height;
- (instancetype)initWithOpenGLContext:(NSOpenGLContext *)context
    image:(NSImage *)image backingScaleFactor:(NSSize)scale;
    
@property (readonly, nonatomic) NSSize pixelSize;
@property (readonly, nonatomic) GLint pixelWidth;
@property (readonly, nonatomic) GLint pixelHeight;

@property (readonly, nonatomic) NSOpenGLContext *openGLContext;

- (NSBitmapImageRep *)bufferAsImageRep;

- (void)bindBuffer;
- (void)bindTextureAndBuffer;
@property (readonly) GLenum bufferUnit;
@property (readonly) GLenum texUnit;

@end

NS_ASSUME_NONNULL_END
