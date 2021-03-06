//
// PTDAnnotationOverlayPDFPage.m
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

#import "PTDAnnotationOverlayPDFPage.h"
#import "NSAffineTransform+PTD.h"


@implementation PTDAnnotationOverlayPDFPage {
  PDFPage *_origPage;
  NSData *_imageData;
}


- (instancetype)initWithPDFPage:(PDFPage *)origPage overlay:(NSData *)imageData
{
  self = [super init];
  
  _origPage = origPage;
  self.rotation = _origPage.rotation;
  
  _imageData = imageData;
  
  return self;
}


- (NSString *)label
{
  return _origPage.label;
}


- (NSRect)boundsForBox:(PDFDisplayBox)box
{
  return [_origPage boundsForBox:box];
}


- (void)drawWithBox:(PDFDisplayBox)box toContext:(CGContextRef)context
{
  [NSGraphicsContext saveGraphicsState];
  NSGraphicsContext.currentContext = [NSGraphicsContext graphicsContextWithCGContext:context flipped:NO];
  
  [NSGraphicsContext.currentContext saveGraphicsState];
  [_origPage drawWithBox:box toContext:context];
  [NSGraphicsContext.currentContext restoreGraphicsState];
  
  NSBezierPath *clip = [NSBezierPath bezierPathWithRect:[self boundsForBox:box]];
  [clip addClip];
  
  @autoreleasepool {
    NSRect cropBox = [self boundsForBox:kPDFDisplayBoxCropBox];
    NSBitmapImageRep *image = [[NSBitmapImageRep alloc] initWithData:_imageData];
    [image drawInRect:cropBox];
  }
  
  [NSGraphicsContext restoreGraphicsState];
}


@end
