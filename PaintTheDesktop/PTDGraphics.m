//
// PTDGraphics.m
// PaintTheDesktop -- Created on 12/04/2021.
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

#import "PTDGraphics.h"
#import "NSColor+PTD.h"


void PTDDrawCircularColorSwatch(NSRect rect, NSColor *color)
{
  [color setFill];
  NSBezierPath *bp = [NSBezierPath bezierPathWithOvalInRect:rect];
  [bp fill];
  
  NSRect borderRect = NSInsetRect(rect, 0.5, 0.5);
  NSColor *borderColor = [NSColor blackColor];
  if (@available(macOS 10.14, *)) {
    if ([[NSAppearance.currentAppearance
        bestMatchFromAppearancesWithNames:
          @[NSAppearanceNameDarkAqua, NSAppearanceNameAqua]]
        isEqual:NSAppearanceNameDarkAqua]) {
      borderColor = [NSColor whiteColor];
    }
  }
  borderColor = [borderColor colorWithAlphaComponent:0.5];
  NSBezierPath *border = [NSBezierPath bezierPathWithOvalInRect:borderRect];
  [borderColor setStroke];
  [border stroke];
}


NSImage *PTDBrushSizeIndicatorImage(CGFloat size)
{
  NSImage *img;
  const CGFloat threshold = 16.0;
  const CGFloat minBorder = 4.0;
  const CGFloat maxBorder = 8.0;
  
  if (size < threshold) {
    CGFloat imageSize = round(minBorder + (maxBorder - minBorder) * (threshold-size)/threshold) + size;
    img = [NSImage imageWithSize:NSMakeSize(imageSize, imageSize) flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
      [[NSColor blackColor] setStroke];
      NSBezierPath *bp = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect((imageSize - size) / 2.0, (imageSize - size) / 2.0, size, size)];
      [bp stroke];
      return YES;
    }];
  } else {
    CGFloat imageSize = threshold+minBorder;
    NSMutableParagraphStyle *parastyle = [[NSMutableParagraphStyle alloc] init];
    parastyle.alignment = NSTextAlignmentCenter;
    NSDictionary *attrib = @{
        NSParagraphStyleAttributeName: parastyle,
        NSFontAttributeName: [NSFont systemFontOfSize:12.0]};
    NSString *sizeStr = [NSString stringWithFormat:@"%d", (int)size];
    NSRect realSizeRect = [sizeStr boundingRectWithSize:NSMakeSize(imageSize, imageSize) options:0 attributes:attrib context:nil];
    
    img = [NSImage imageWithSize:NSMakeSize(imageSize, imageSize) flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
      [[NSColor blackColor] setStroke];
      NSBezierPath *bp = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(minBorder/2.0-0.5, minBorder/2.0-0.5, threshold+1, threshold+1)];
      [bp stroke];
      [sizeStr drawInRect:NSMakeRect(0, (imageSize-realSizeRect.size.height)/2.0, imageSize, realSizeRect.size.height) withAttributes:attrib];
      return YES;
    }];
  }
  
  return img;
}


NSImage *PTDEraserSizeIndicatorImage(CGFloat size)
{
  NSImage *img;
  const CGFloat threshold = 24;
  const CGFloat minBorder = 4.0;
  const CGFloat maxBorder = 8.0;
  
  if (size < threshold) {
    CGFloat imageSize = round(minBorder + (maxBorder - minBorder) * (threshold-size)/threshold) + size;
    img = [NSImage imageWithSize:NSMakeSize(imageSize, imageSize) flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
      [[NSColor blackColor] setStroke];
      NSBezierPath *bp = [NSBezierPath bezierPathWithRect:NSMakeRect((imageSize - size) / 2.0, (imageSize - size) / 2.0, size, size)];
      [bp stroke];
      return YES;
    }];
  } else {
    CGFloat imageSize = threshold+minBorder;
    NSMutableParagraphStyle *parastyle = [[NSMutableParagraphStyle alloc] init];
    parastyle.alignment = NSTextAlignmentCenter;
    NSDictionary *attrib = @{
        NSParagraphStyleAttributeName: parastyle,
        NSFontAttributeName: [NSFont systemFontOfSize:12.0]};
    NSString *sizeStr = [NSString stringWithFormat:@"%d", (int)size];
    NSRect realSizeRect = [sizeStr boundingRectWithSize:NSMakeSize(imageSize, imageSize) options:0 attributes:attrib context:nil];
    
    img = [NSImage imageWithSize:NSMakeSize(imageSize, imageSize) flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
      [[NSColor blackColor] setStroke];
      NSBezierPath *bp = [NSBezierPath bezierPathWithRect:NSMakeRect(minBorder/2.0-0.5, minBorder/2.0-0.5, threshold+1, threshold+1)];
      [bp stroke];
      [sizeStr drawInRect:NSMakeRect(0, (imageSize-realSizeRect.size.height)/2.0, imageSize, realSizeRect.size.height) withAttributes:attrib];
      return YES;
    }];
  }
  
  return img;
}


NSImage *PTDCrosshairWithBrushOutlineImage(CGFloat size, NSColor *color)
{
  NSColor *borderColor = [color ptd_contrastingCursorBorderColor];
  
  const CGFloat outlineSize = 3.0;
  const CGFloat lineSize = 1.0;
  const CGFloat circleXhairDist = 2.0;
  const CGFloat minXhairLen = 2.0;
  CGFloat circleSize = size;
  CGFloat cursorSize = MAX(21.0, circleSize + 2.0 * (circleXhairDist + minXhairLen) + outlineSize);
  CGFloat xhairLen = (cursorSize - circleSize - 2.0 * circleXhairDist - outlineSize) / 2.0;
  
  CGFloat center = cursorSize / 2.0;
  CGFloat circleOrigin = center - circleSize / 2.0;
  CGFloat xhairOriginFromCenter = circleSize / 2.0 + circleXhairDist;
  
  return [NSImage
      imageWithSize:NSMakeSize(cursorSize, cursorSize)
      flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
    NSBezierPath *path = [NSBezierPath bezierPath];
    
    NSRect circleRect = NSMakeRect(circleOrigin, circleOrigin, circleSize, circleSize);
    [path appendBezierPathWithOvalInRect:circleRect];
    
    [path moveToPoint:NSMakePoint(center - xhairOriginFromCenter, center)];
    [path lineToPoint:NSMakePoint(center - xhairOriginFromCenter - xhairLen, center)];
    [path moveToPoint:NSMakePoint(center, center + xhairOriginFromCenter)];
    [path lineToPoint:NSMakePoint(center, center + xhairOriginFromCenter + xhairLen)];
    [path moveToPoint:NSMakePoint(center + xhairOriginFromCenter, center)];
    [path lineToPoint:NSMakePoint(center + xhairOriginFromCenter + xhairLen, center)];
    [path moveToPoint:NSMakePoint(center, center - xhairOriginFromCenter)];
    [path lineToPoint:NSMakePoint(center, center - xhairOriginFromCenter - xhairLen)];
    
    path.lineCapStyle = NSLineCapStyleSquare;
    path.lineWidth = outlineSize;
    [borderColor setStroke];
    [path stroke];
    path.lineCapStyle = NSLineCapStyleSquare;
    path.lineWidth = lineSize+0.001; // Quartz ignores lineCapStyle if lineWidth <= 1.0
    [color setStroke];
    [path stroke];
    return YES;
  }];
}


NSImage *PTDCrosshairImage(CGFloat size, NSColor *color)
{
  size = floor((size + 8.0) / 2.0) * 2.0 + 1.0;
  NSColor *borderColor = [color ptd_contrastingCursorBorderColor];
  
  return [NSImage
      imageWithSize:NSMakeSize(size+2.0, size+2.0)
      flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
    NSBezierPath *cross = [NSBezierPath bezierPath];
    [cross moveToPoint:NSMakePoint(1.0         , 1.0+size/2.0)];
    [cross lineToPoint:NSMakePoint(1.0+size    , 1.0+size/2.0)];
    [cross moveToPoint:NSMakePoint(1.0+size/2.0, 1.0         )];
    [cross lineToPoint:NSMakePoint(1.0+size/2.0, 1.0+size    )];
    
    cross.lineWidth = 3.0;
    cross.lineCapStyle = NSLineCapStyleSquare;
    [borderColor setStroke];
    [cross stroke];
    
    cross.lineWidth = 1.0;
    cross.lineCapStyle = NSLineCapStyleButt;
    [color setStroke];
    [cross stroke];
    
    return YES;
  }];
}

