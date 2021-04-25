//
// PTDLineTool.m
// PaintTheDesktop -- Created on 25/04/2021.
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

#import <QuartzCore/QuartzCore.h>
#import "PTDLineTool.h"
#import "PTDPencilTool.h"
#import "PTDDrawingSurface.h"
#import "PTDTool.h"
#import "PTDCursor.h"
#import "PTDGraphics.h"
#import "NSBezierPath+PTD.h"


NSString * const PTDToolIdentifierLineTool = @"PTDToolIdentifierLineTool";


@implementation PTDLineTool {
  NSPoint _point0, _point1;
  CAShapeLayer *_overlayShape;
}


+ (NSString *)toolIdentifier
{
  return PTDToolIdentifierLineTool;
}


+ (PTDRingMenuItem *)menuItem
{
  return [PTDRingMenuItem itemWithImage:[NSImage imageNamed:@"PTDToolIconLine"] target:nil action:nil];
}


- (void)activate
{
  [self updateCursor];
}


- (void)reloadOptions
{
  [super reloadOptions];
  [self updateCursor];
}


- (void)dragDidStartAtPoint:(NSPoint)point
{
  _point0 = _point1 = point;
  [self createDragIndicator];
}


- (void)dragDidContinueFromPoint:(NSPoint)prevPoint toPoint:(NSPoint)nextPoint
{
  _point1 = nextPoint;
  [self updateDragIndicator];
}


- (void)dragDidEndAtPoint:(NSPoint)point
{
  [self removeDragIndicator];
  [self.currentDrawingSurface beginCanvasDrawing];
  NSBezierPath *path = [NSBezierPath bezierPath];
  [path setLineCapStyle:NSLineCapStyleRound];
  [path setLineWidth:self.size];
  [path moveToPoint:_point0];
  [path lineToPoint:_point1];
  [self.color setStroke];
  [path stroke];
}


- (void)updateCursor
{
  PTDCursor *cursor = [[PTDCursor alloc] init];
  cursor.image = PTDCrosshairImage(self.size, self.color);
  cursor.hotspot = NSMakePoint(cursor.image.size.width/2.0, cursor.image.size.height/2.0);
  self.cursor = cursor;
}


- (void)createDragIndicator
{
  _overlayShape = [[CAShapeLayer alloc] init];
  [self.currentDrawingSurface.overlayLayer addSublayer:_overlayShape];
  _overlayShape.lineWidth = self.size;
  _overlayShape.strokeColor = self.color.CGColor;
  _overlayShape.fillColor = NSColor.clearColor.CGColor;
  _overlayShape.lineCap = kCALineCapRound;
  _overlayShape.frame = self.currentDrawingSurface.overlayLayer.bounds;
  [self updateDragIndicator];
}


- (void)updateDragIndicator
{
  [CATransaction begin];
  CATransaction.disableActions = YES;
  
  CGMutablePathRef path = CGPathCreateMutable();
  CGPathMoveToPoint(path, NULL, _point0.x, _point0.y);
  CGPathAddLineToPoint(path, NULL, _point1.x, _point1.y);
  _overlayShape.path = path;
  CGPathRelease(path);
  
  [CATransaction commit];
}


- (void)removeDragIndicator
{
  [_overlayShape removeFromSuperlayer];
  _overlayShape = nil;
}


@end
