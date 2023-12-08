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


@implementation PTDPDFPageView


- (void)setFrameSize:(NSSize)newSize
{
  [super setFrameSize:newSize];
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
  [at concat];
  
  [page drawWithBox:kPDFDisplayBoxCropBox toContext:NSGraphicsContext.currentContext.CGContext];
  
  if (self.borderColor) {
    [self.borderColor set];
    NSFrameRect(sourceRect);
  }
  
  [NSGraphicsContext.currentContext restoreGraphicsState];
}


- (void)setPdfPage:(PDFPage *)pdfPage
{
  _pdfPage = pdfPage;
  [self setNeedsLayout:YES];
  [self setNeedsDisplay:YES];
}


@end
