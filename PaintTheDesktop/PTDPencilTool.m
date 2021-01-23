//
// PTDPencilTool.m
// PaintTheDesktop -- Created on 10/06/2020.
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

#import "PTDToolManager.h"
#import "PTDBrush.h"
#import "PTDPencilTool.h"
#import "PTDDrawingSurface.h"
#import "PTDTool.h"
#import "PTDCursor.h"
#import "NSColor+PTD.h"


NSString * const PTDToolIdentifierPencilTool = @"PTDToolIdentifierPencilTool";


@implementation PTDPencilTool


+ (NSString *)toolIdentifier
{
  return PTDToolIdentifierPencilTool;
}


- (void)activate
{
  [self updateCursor];
}


- (void)dragDidContinueFromPoint:(NSPoint)prevPoint toPoint:(NSPoint)nextPoint
{
  [self.currentDrawingSurface beginCanvasDrawing];
  NSBezierPath *path = [NSBezierPath bezierPath];
  [path setLineCapStyle:NSLineCapStyleRound];
  [path setLineWidth:self.currentBrush.size];
  [self.currentBrush.color setStroke];
  [path moveToPoint:prevPoint];
  [path lineToPoint:nextPoint];
  [path stroke];
}


+ (PTDRingMenuItem *)menuItem
{
  return [PTDRingMenuItem itemWithImage:[NSImage imageNamed:@"PTDToolIconPencil"] target:nil action:nil];
}


- (PTDRingMenuRing *)optionMenu
{
  return [self.currentBrush menuOptions];
}


- (void)setCurrentBrush:(PTDBrush *)currentBrush
{
  [super setCurrentBrush:currentBrush];
  [self updateCursor];
}


- (void)updateCursor
{
  NSColor *color = self.currentBrush.color;
  NSColor *borderColor = [color ptd_contrastingCursorBorderColor];
  PTDCursor *cursor = [[PTDCursor alloc] init];
  
  const CGFloat outlineSize = 3.0;
  const CGFloat lineSize = 1.0;
  const CGFloat circleXhairDist = 2.0;
  const CGFloat minXhairLen = 2.0;
  CGFloat circleSize = self.currentBrush.size;
  CGFloat cursorSize = MAX(21.0, circleSize + 2.0 * (circleXhairDist + minXhairLen) + outlineSize);
  CGFloat xhairLen = (cursorSize - circleSize - 2.0 * circleXhairDist - outlineSize) / 2.0;
  
  CGFloat center = cursorSize / 2.0;
  CGFloat circleOrigin = center - circleSize / 2.0;
  CGFloat xhairOriginFromCenter = circleSize / 2.0 + circleXhairDist;
  
  cursor.image = [NSImage
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
  cursor.hotspot = NSMakePoint(center, center);
  
  self.cursor = cursor;
}


@end
