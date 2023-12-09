//
// PTDPDFPageView.m
// PaintTheDesktop -- Created on 05/05/2021.
//
// Copyright (c) 2021 Daniele Cattaneo
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

#import "PTDPDFPageView.h"
#import "PDFPage+PTD.h"
#import "NSAffineTransform+PTD.h"


@interface PTDPDFPageRenderer: NSObject

- (instancetype)initWithPage:(PDFPage *)page;
- (void)requestRenderWithBackingSize:(NSSize)size;

@property (nonatomic, readonly) NSBitmapImageRep *lastRender;
@property (nonatomic, copy) void (^readyCallback)(void);

@end


@implementation PTDPDFPageRenderer {
  PDFPage *_page;
  BOOL _working;
  NSSize _size;
  BOOL _pendingWork;
  NSSize _pendingSize;
}


- (instancetype)initWithPage:(PDFPage *)page
{
  self = [super init];
  _page = page;
  return self;
}


- (void)requestRenderWithBackingSize:(NSSize)size
{
  
  _pendingWork = YES;
  _pendingSize = size;
  [self startWorkingIfIdle];
}


- (void)startWorkingIfIdle
{
  if (_working)
    return;
  if (!_pendingWork)
    return;
  _working = YES;
  _pendingWork = NO;
  NSSize workSize = _pendingSize;
  
  if (NSEqualSizes(workSize, _size)) {
    [self workEndedWithResult:_lastRender ofSize:_size];
  } else {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
      NSBitmapImageRep *bmp = [self workRenderingWithSize:workSize];
      dispatch_async(dispatch_get_main_queue(), ^{
        [self workEndedWithResult:bmp ofSize:workSize];
      });
    });
  }
}


- (void)workEndedWithResult:(NSBitmapImageRep *)bmp ofSize:(NSSize)size
{
  self->_lastRender = bmp;
  self->_size = size;
  
  self->_working = NO;
  if (self->_readyCallback)
    self->_readyCallback();
  [self startWorkingIfIdle];
}


- (NSBitmapImageRep *)workRenderingWithSize:(NSSize)size
{
  NSInteger width = round(size.width);
  NSInteger height = round(size.height);
  NSBitmapImageRep *bmp = [[NSBitmapImageRep alloc]
                           initWithBitmapDataPlanes:NULL
                           pixelsWide:width
                           pixelsHigh:height
                           bitsPerSample:8
                           samplesPerPixel:3
                           hasAlpha:NO
                           isPlanar:NO
                           colorSpaceName:NSCalibratedRGBColorSpace
                           bytesPerRow:0
                           bitsPerPixel:32];
  @autoreleasepool {
    NSGraphicsContext *ctx = [NSGraphicsContext graphicsContextWithBitmapImageRep:bmp];
    NSGraphicsContext.currentContext = ctx;
    
    NSRect sourceRect = [_page ptd_rotatedCropBox];
    NSRect destRect = (NSRect){{0, 0}, {width, height}};
    [[NSColor whiteColor] setFill];
    NSRectFill(destRect);
    
    NSAffineTransform *at = [NSAffineTransform ptd_transformMappingRect:sourceRect toRect:destRect];
    [at rotateByDegrees:-_page.rotation];
    [at concat];
    
    CGContextDrawPDFPage(NSGraphicsContext.currentContext.CGContext, _page.pageRef);
    [ctx flushGraphics];
    NSGraphicsContext.currentContext = nil;
  }
  NSLog(@"Finished rendering PDF page %@ at size %@", _page.label, NSStringFromSize(size));
  return bmp;
}


@end


@implementation PTDPDFPageView {
  PTDPDFPageRenderer *_renderer;
}


- (void)setFrameSize:(NSSize)newSize
{
  [super setFrameSize:newSize];
  [self requestNewRendering];
  [self setNeedsLayout:YES];
}


- (void)layout
{
  [super layout];
  
  if (self.pdfPage) {
    NSRect pageFrame = [self pageFrame];
    [self.pageChildView setFrameOrigin:pageFrame.origin];
    [self.pageChildView setFrameSize:pageFrame.size];
  }
}


- (NSRect)pageFrame
{
  NSRect pageRect = [self.pdfPage ptd_rotatedCropBox];
  NSRect frame = self.frame;
  NSRect res = NSZeroRect;
  
  CGFloat scaleX = NSWidth(frame) / NSWidth(pageRect);
  CGFloat scaleY = NSHeight(frame) / NSHeight(pageRect);
  
  if (scaleX < scaleY) {
    res.size.width = frame.size.width;
    res.size.height = round(NSHeight(pageRect) * scaleX);
  } else {
    res.size.width = round(NSWidth(pageRect) * scaleY);
    res.size.height = frame.size.height;
  }
  
  res.origin.x = round((NSWidth(frame) - NSWidth(res)) / 2.0);
  res.origin.y = round((NSHeight(frame) - NSHeight(res)) / 2.0);
  
  return res;
}


- (NSRect)backingAlignedPageFrame
{
  return [self backingAlignedRect:[self pageFrame] options:NSAlignAllEdgesNearest];
}

/*
- (void)drawRect:(NSRect)dirtyRect
{
  [super drawRect:dirtyRect];
  
  PDFPage *page = self.pdfPage;
  if (!page)
    return;
  
  NSRect sourceRect = [page ptd_rotatedCropBox];
  NSRect destRect = [self pageFrame];
  
  [NSGraphicsContext.currentContext saveGraphicsState];
  
  [[NSColor whiteColor] setFill];
  NSRectFill(destRect);
  
  NSAffineTransform *at = [NSAffineTransform ptd_transformMappingRect:sourceRect toRect:destRect];
  [at rotateByDegrees:-page.rotation];
  [at concat];
  
  CGContextDrawPDFPage(NSGraphicsContext.currentContext.CGContext, page.pageRef);
  
  [NSGraphicsContext.currentContext restoreGraphicsState];
  
  if (self.borderColor) {
    [self.borderColor set];
    NSFrameRect(destRect);
  }
}
*/


- (void)drawRect:(NSRect)dirtyRect
{
  [NSBezierPath clipRect:dirtyRect];
  NSBitmapImageRep *bmp = [_renderer lastRender];
  NSRect destRect = [self backingAlignedPageFrame];
  [bmp drawInRect:destRect];
  if (self.borderColor) {
    [self.borderColor set];
    NSFrameRect(destRect);
  }
}


- (void)renderingReady
{
  [self setNeedsDisplay:YES];
}


- (void)requestNewRendering
{
  if (!_renderer) {
    NSLog(@"warning: %@ requested a rendering but renderer is not set", self);
    return;
  }
  NSRect frame = [self backingAlignedPageFrame];
  NSRect backingFrame = [self convertRectToBacking:frame];
  [_renderer requestRenderWithBackingSize:backingFrame.size];
}


- (void)setPdfPage:(PDFPage *)pdfPage
{
  _pdfPage = pdfPage;
  
  _renderer = [[PTDPDFPageRenderer alloc] initWithPage:pdfPage];
  __weak PTDPDFPageView *weakSelf = self;
  [_renderer setReadyCallback:^{
    __strong PTDPDFPageView *strongSelf = weakSelf;
    [strongSelf renderingReady];
  }];
  [self requestNewRendering];
  
  [self setNeedsLayout:YES];
  [self setNeedsDisplay:YES];
}


@end
