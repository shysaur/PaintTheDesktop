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
#import "PTDNoAnimeCALayer.h"


@interface PTDPDFPageRendererRequest: NSObject

@property (nonatomic) NSRect src; // in page coordinates
@property (nonatomic) NSRect dest; // in view coordinates
@property (nonatomic) NSSize backingSize; // in backing coordinates
@property (nonatomic) NSColorSpace *colorSpace;
@property (nonatomic) CGImageRef bitmap;

@end

@implementation PTDPDFPageRendererRequest

- (void)setBitmap:(CGImageRef)bitmap
{
  if (_bitmap)
    CFRelease(_bitmap);
  CFRetain(bitmap);
  _bitmap = bitmap;
}

- (void)dealloc
{
  if (_bitmap)
    CFRelease(_bitmap);
}

@end


@interface PTDPDFPageRenderer: NSObject

- (instancetype)initWithPage:(PDFPage *)page;
- (void)requestRenderPageArea:(NSRect)src toRect:(NSRect)dest backingSize:(NSSize)backing colorSpace:(NSColorSpace *)colorSpace;

@property (nonatomic, copy) void (^readyCallback)(CGImageRef bmp, NSRect src, NSRect dest);

@end


@implementation PTDPDFPageRenderer {
  PDFPage *_page;
  BOOL _working;
  PTDPDFPageRendererRequest *_lastRequest;
  PTDPDFPageRendererRequest *_nextRequest;
}


- (instancetype)initWithPage:(PDFPage *)page
{
  self = [super init];
  _page = page;
  return self;
}


- (void)requestRenderPageArea:(NSRect)src toRect:(NSRect)dest backingSize:(NSSize)backing colorSpace:(NSColorSpace *)colorSpace
{
  PTDPDFPageRendererRequest *next = [[PTDPDFPageRendererRequest alloc] init];
  next.src = src;
  next.dest = dest;
  next.backingSize = NSMakeSize(round(backing.width), round(backing.height));
  next.colorSpace = colorSpace;
  _nextRequest = next;
  [self startWorkingIfIdle];
}


- (void)startWorkingIfIdle
{
  if (_working)
    return;
  if (!_nextRequest)
    return;
  _working = YES;
  PTDPDFPageRendererRequest *curRequest = _nextRequest;
  _nextRequest = nil;
  
  if (NSEqualRects(_lastRequest.src, curRequest.src) &&
      NSEqualSizes(_lastRequest.backingSize, curRequest.backingSize) &&
      [_lastRequest.colorSpace isEqual:curRequest.colorSpace]) {
    curRequest.bitmap = _lastRequest.bitmap;
    [self workEndedWithResult:curRequest];
  } else {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
      [self workRenderingWithRequest:curRequest];
      dispatch_async(dispatch_get_main_queue(), ^{
        [self workEndedWithResult:curRequest];
      });
    });
  }
}


- (void)workEndedWithResult:(PTDPDFPageRendererRequest *)result
{
  _lastRequest = result;
  _working = NO;
  if (_readyCallback) {
    _readyCallback(result.bitmap, result.src, result.dest);
  }
  [self startWorkingIfIdle];
}


- (void)workRenderingWithRequest:(PTDPDFPageRendererRequest *)request
{
  NSInteger width = round(request.backingSize.width);
  NSInteger height = round(request.backingSize.height);
  CGContextRef bmpCtx = CGBitmapContextCreate(NULL,
                                              width, height, 8, 0, 
                                              request.colorSpace.CGColorSpace,
                                              kCGImageAlphaNoneSkipLast | kCGImageByteOrderDefault);
  
  @autoreleasepool {
    NSGraphicsContext *ctx = [NSGraphicsContext graphicsContextWithCGContext:bmpCtx flipped:NO];
    NSGraphicsContext.currentContext = ctx;
    
    NSRect sourceRect = request.src;
    NSRect destRect = NSMakeRect(0, 0, width, height);
    [[NSColor whiteColor] setFill];
    NSRectFill(destRect);
    
    NSAffineTransform *at = [NSAffineTransform ptd_transformMappingRect:sourceRect toRect:destRect];
    [at rotateByDegrees:-_page.rotation];
    [at concat];
    
    CGContextDrawPDFPage(NSGraphicsContext.currentContext.CGContext, _page.pageRef);
    [ctx flushGraphics];
    NSGraphicsContext.currentContext = nil;
  }
  CGImageRef img = CGBitmapContextCreateImage(bmpCtx);
  request.bitmap = img;
  CFRelease(img);
  CGContextRelease(bmpCtx);
  sleep(1);
}


@end


@implementation PTDPDFPageView {
  PTDPDFPageRenderer *_renderer;
  CALayer *_bgLayer;
  NSRect _contentLayerVisBox;
  CALayer *_contentLayer;
  CALayer *_borderLayer;
}


- (instancetype)initWithCoder:(NSCoder *)coder
{
  self = [super initWithCoder:coder];
  
  self.layer = [self makeBackingLayer];
  _bgLayer = [[PTDNoAnimeCALayer alloc] init];
  _bgLayer.backgroundColor = CGColorCreateGenericGray(1.0, 1.0);
  [self.layer addSublayer:_bgLayer];
  _contentLayer = [[PTDNoAnimeCALayer alloc] init];
  [self.layer addSublayer:_contentLayer];
  _borderLayer = [[PTDNoAnimeCALayer alloc] init];
  [self.layer addSublayer:_borderLayer];
    
  return self;
}


- (BOOL)wantsLayer
{
  return YES;
}


- (void)setPdfPage:(PDFPage *)pdfPage
{
  NSRect oldPageBox = [_pdfPage ptd_rotatedCropBox];
  _pdfPage = pdfPage;
  
  if (_pdfPage) {
    NSRect newPageBox = [_pdfPage ptd_rotatedCropBox];
    if (!NSEqualRects(oldPageBox, newPageBox)) {
      _contentLayerVisBox = NSMakeRect(0, 0, 0, 0);
      _contentLayer.contents = nil;
    }
    
    _renderer = [[PTDPDFPageRenderer alloc] initWithPage:pdfPage];
    __weak PTDPDFPageView *weakSelf = self;
    [_renderer setReadyCallback:^(CGImageRef bmp, NSRect src, NSRect dest) {
      [weakSelf renderingReadyWithBitmap:bmp source:src destination:dest];
    }];
  } else {
    _renderer = nil;
  }
  
  [self setNeedsLayout:YES];
  [self setNeedsDisplay:YES];
}


- (void)setBorderColor:(NSColor *)borderColor
{
  _borderColor = borderColor;
  if (borderColor) {
    _borderLayer.borderWidth = 1.0;
    _borderLayer.borderColor = borderColor.CGColor;
  } else {
    _borderLayer.borderWidth = 0.0;
  }
}


- (BOOL)clipsToBounds
{
  return YES;
}


- (void)renderingReadyWithBitmap:(CGImageRef)bmp source:(NSRect)src destination:(NSRect)dest
{
  _contentLayer.contents = (__bridge id _Nullable)(bmp);
  _contentLayerVisBox = src;
  _contentLayer.frame = [self recomputeContentLayerFrame];
}


- (NSRect)recomputeContentLayerFrame
{
  NSRect pageFrame = [self pageFrame];
  NSRect box = [self.pdfPage ptd_rotatedCropBox];
  CGAffineTransform xfm = PTDTransformMappingRectToRect(box, pageFrame);
  return CGRectApplyAffineTransform(_contentLayerVisBox, xfm);
}


- (void)requestNewRenderingInRect:(NSRect)visRect
{
  NSRect pageFrame = [self pageFrame];
  NSRect box = [self.pdfPage ptd_rotatedCropBox];
  CGAffineTransform xfm = PTDTransformMappingRectToRect(pageFrame, box);
  
  NSRect visPageFrame = NSIntersectionRect(pageFrame, visRect);
  visPageFrame = [self backingAlignedRect:visPageFrame options:NSAlignAllEdgesNearest];
  NSRect visBox = CGRectApplyAffineTransform(visPageFrame, xfm);
  NSRect backing = [self convertRectToBacking:visPageFrame];
  
  NSColorSpace *cs = self.window.screen.colorSpace;
  
  [_renderer requestRenderPageArea:visBox toRect:visPageFrame backingSize:backing.size colorSpace:cs];
}


- (void)setFrameSize:(NSSize)newSize
{
  [super setFrameSize:newSize];
  [self setNeedsLayout:YES];
  [self setNeedsDisplay:YES];
}


- (void)drawRect:(NSRect)dirtyRect
{
  if (!self.pdfPage) {
    _bgLayer.opacity = 0.0;
    _borderLayer.opacity = 0.0;
    _contentLayer.opacity = 0.0;
    return;
  }
  _bgLayer.opacity = 1.0;
  _borderLayer.opacity = 1.0;
  _contentLayer.opacity = 1.0;
  NSRect pageFrame = [self pageFrame];
  _bgLayer.frame = pageFrame;
  _borderLayer.frame = pageFrame;
  _contentLayer.frame = [self recomputeContentLayerFrame];
  [self requestNewRenderingInRect:self.visibleRect];
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


@end
