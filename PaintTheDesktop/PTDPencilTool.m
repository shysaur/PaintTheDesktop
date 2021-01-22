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
  CGFloat size = self.currentBrush.size;
  NSColor *color = self.currentBrush.color;
  NSColor *borderColor = [color ptd_contrastingCursorBorderColor];
  PTDCursor *cursor = [[PTDCursor alloc] init];
  
  cursor.image = [NSImage
      imageWithSize:NSMakeSize(size+2.0, size+2.0)
      flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
    NSRect circleRect = NSMakeRect(1.5, 1.5, size-1.0, size-1.0);
    NSBezierPath *circle = [NSBezierPath bezierPathWithOvalInRect:circleRect];
    
    circle.lineWidth = 3.0;
    [borderColor setStroke];
    [circle stroke];
    
    circle.lineWidth = 1.0;
    [color setStroke];
    [circle stroke];
    return YES;
  }];
  cursor.hotspot = NSMakePoint(size/2+1.0, size/2+1.0);
  
  self.cursor = cursor;
}


@end
