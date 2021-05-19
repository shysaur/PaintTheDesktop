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

#import <Quartz/Quartz.h>
#import "PTDToolManager.h"
#import "PTDPencilTool.h"
#import "PTDDrawingSurface.h"
#import "PTDTool.h"
#import "PTDCursor.h"
#import "PTDGraphics.h"


NSString * const PTDToolIdentifierPencilTool = @"PTDToolIdentifierPencilTool";


@implementation PTDPencilTool {
  CGMutablePathRef _currentPath;
  CAShapeLayer *_overlayShape;
}


+ (NSString *)toolIdentifier
{
  return PTDToolIdentifierPencilTool;
}


- (void)activate
{
  [self updateCursor];
}


- (void)dragDidStartAtPoint:(NSPoint)point
{
  _currentPath = CGPathCreateMutable();
  CGPathMoveToPoint(_currentPath, NULL, point.x, point.y);
  [self createDragIndicator];
}


- (void)dragDidContinueFromPoint:(NSPoint)prevPoint toPoint:(NSPoint)nextPoint
{
  CGPathAddLineToPoint(_currentPath, NULL, nextPoint.x, nextPoint.y);
  [self updateDragIndicator];
}


- (void)dragDidEndAtPoint:(NSPoint)point
{
  [self.currentDrawingSurface beginCanvasDrawing];
  CGContextRef ctxt = NSGraphicsContext.currentContext.CGContext;
  CGContextBeginPath(ctxt);
  CGContextSetLineCap(ctxt, kCGLineCapRound);
  CGContextSetLineJoin(ctxt, kCGLineJoinRound);
  CGContextSetLineWidth(ctxt, self.size);
  CGContextSetStrokeColorWithColor(ctxt, self.color.CGColor);
  CGContextAddPath(ctxt, _currentPath);
  CGContextStrokePath(ctxt);
  CGPathRelease(_currentPath);
  [self removeDragIndicator];
}


+ (PTDRingMenuItem *)menuItem
{
  return [PTDRingMenuItem itemWithImage:[NSImage imageNamed:@"PTDToolIconPencil"] target:nil action:nil];
}


- (void)reloadOptions
{
  [super reloadOptions];
  [self updateCursor];
}


- (void)updateCursor
{
  PTDCursor *cursor = [[PTDCursor alloc] init];
  cursor.image = PTDCrosshairWithBrushOutlineImage(self.size, self.color);
  cursor.hotspot = NSMakePoint(cursor.image.size.width / 2.0, cursor.image.size.height / 2.0);
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
  _overlayShape.lineJoin = kCALineJoinRound;
  _overlayShape.frame = self.currentDrawingSurface.overlayLayer.bounds;
  [self updateDragIndicator];
}


- (void)updateDragIndicator
{
  [CATransaction begin];
  CATransaction.disableActions = YES;
  _overlayShape.path = _currentPath;
  [CATransaction commit];
}


- (void)removeDragIndicator
{
  [_overlayShape removeFromSuperlayer];
  _overlayShape = nil;
}


@end
