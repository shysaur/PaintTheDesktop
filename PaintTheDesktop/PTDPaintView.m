//
//  PTDPaintView.m
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 08/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import "PTDPaintView.h"


@interface PTDPaintView ()

@property (nonatomic) NSBitmapImageRep *backingImage;

@end


@implementation PTDPaintView {
  CGFloat _scaleFactor;
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


- (void)updateLayer
{
  NSImage *tmpImage = [[NSImage alloc] initWithSize:_backingImage.size];
  [tmpImage addRepresentation:_backingImage];
  self.layer.contents = tmpImage;
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
  
  self.backingImage = [[NSBitmapImageRep alloc]
      initWithBitmapDataPlanes:NULL
      pixelsWide:newPxSize.width pixelsHigh:newPxSize.height
      bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO
      colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0];
  
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


@end
