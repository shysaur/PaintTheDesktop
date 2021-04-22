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


static const CGFloat _BrushSizeThreshold = 16.0;
static const CGFloat _BrushSizeMinBorder = 4.0;
static const CGFloat _BrushSizeMaxBorder = 8.0;


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


NSSize PTDBrushSizeIndicatorMinimumSize(CGFloat size)
{
  CGFloat imageSize;
  if (size < _BrushSizeThreshold) {
    imageSize = round(_BrushSizeMinBorder + (_BrushSizeMaxBorder - _BrushSizeMinBorder) * (_BrushSizeThreshold - size) / _BrushSizeThreshold) + size;
  } else {
    imageSize = _BrushSizeThreshold + _BrushSizeMinBorder;
  }
  return NSMakeSize(imageSize, imageSize);
}


void PTDDrawBrushSizeIndicator(NSRect rect, CGFloat size)
{
  NSSize imageXYSize = PTDBrushSizeIndicatorMinimumSize(size);
  CGFloat imageSize = imageXYSize.width;
  NSPoint offset = rect.origin;
  offset.x += floor((rect.size.width - imageSize) / 2.0);
  offset.y += floor((rect.size.height - imageSize) / 2.0);
  
  if (size < _BrushSizeThreshold) {
    [[NSColor blackColor] setStroke];
    NSBezierPath *bp = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(offset.x + (imageSize - size) / 2.0, offset.y + (imageSize - size) / 2.0, size, size)];
    [bp stroke];
  } else {
    NSMutableParagraphStyle *parastyle = [[NSMutableParagraphStyle alloc] init];
    parastyle.alignment = NSTextAlignmentCenter;
    NSDictionary *attrib = @{
        NSParagraphStyleAttributeName: parastyle,
        NSFontAttributeName: [NSFont systemFontOfSize:12.0]};
    NSString *sizeStr = [NSString stringWithFormat:@"%d", (int)size];
    NSRect realSizeRect = [sizeStr boundingRectWithSize:NSMakeSize(imageSize, imageSize) options:0 attributes:attrib context:nil];
    
    [[NSColor blackColor] setStroke];
    NSBezierPath *bp = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(offset.x + _BrushSizeMinBorder/2.0-0.5, offset.y + _BrushSizeMinBorder/2.0-0.5, _BrushSizeThreshold+1, _BrushSizeThreshold+1)];
    [bp stroke];
    [sizeStr drawInRect:NSMakeRect(offset.x, offset.y + (imageSize-realSizeRect.size.height)/2.0, imageSize, realSizeRect.size.height) withAttributes:attrib];
  }
}

