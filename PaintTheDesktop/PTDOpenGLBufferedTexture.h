//
//  PTDOpenGLBufferedTexture.h
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 14/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
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
