//
// PTDRectangleTool.m
// PaintTheDesktop -- Created on 15/06/2020.
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

#import <QuartzCore/QuartzCore.h>
#import "PTDToolManager.h"
#import "PTDShapeTool.h"
#import "PTDDrawingSurface.h"
#import "PTDTool.h"
#import "PTDCursor.h"
#import "NSGeometry+PTD.h"
#import "NSBezierPath+PTD.h"
#import "NSColor+PTD.h"


#define SIGN(x) ((x) < 0.0 ? -1.0 : 1.0)


@implementation PTDShapeTool {
  NSRect _currentRect;
  NSPoint _point0, _point1;
  CAShapeLayer *_overlayShape;
}


- (void)activate
{
  [self updateCursor];
}


- (NSBezierPath *)shapeBezierPathInRect:(NSRect)rect
{
  [NSException raise:NSInternalInconsistencyException format:@"ABSTRACT METHOD: %s", __FUNCTION__];
  return nil;
}


- (void)dragDidStartAtPoint:(NSPoint)point
{
  _point0 = point;
  _currentRect = (NSRect){point, NSZeroSize};
  [self createDragIndicator];
}


- (void)recomputeCurrentRect
{
  CGFloat x = _point0.x;
  CGFloat y = _point0.y;
  CGFloat w = _point1.x - _point0.x;
  CGFloat h = _point1.y - _point0.y;
  
  if (NSEvent.modifierFlags & NSEventModifierFlagShift) {
    CGFloat side = MAX(fabs(w), fabs(h));
    w = side * SIGN(w);
    h = side * SIGN(h);
  }
  
  if (NSEvent.modifierFlags & NSEventModifierFlagOption) {
    x -= w;
    y -= h;
    w *= 2.0;
    h *= 2.0;
  }
  
  _currentRect = PTD_NSNormalizedRect(NSMakeRect(x, y, w, h));
}


- (void)dragDidContinueFromPoint:(NSPoint)prevPoint toPoint:(NSPoint)nextPoint
{
  _point1 = nextPoint;
  [self recomputeCurrentRect];
  [self updateDragIndicator];
}


- (void)modifierFlagsChanged
{
  [self recomputeCurrentRect];
  [self updateDragIndicator];
}


- (void)dragDidEndAtPoint:(NSPoint)point
{
  [self removeDragIndicator];
  
  [self.currentDrawingSurface beginCanvasDrawing];
  [NSGraphicsContext.currentContext setShouldAntialias:YES];
  
  NSBezierPath *path = [self shapeBezierPathInRect:_currentRect];
  [path setLineWidth:self.size];
  [self.color setStroke];
  [path stroke];
}


- (void)reloadOptions
{
  [super reloadOptions];
  [self updateCursor];
}


- (void)updateCursor
{
  CGFloat size = floor((self.size + 8.0) / 2.0) * 2.0 + 1.0;
  NSColor *color = self.color;
  NSColor *borderColor = [color ptd_contrastingCursorBorderColor];
  PTDCursor *cursor = [[PTDCursor alloc] init];
  
  cursor.image = [NSImage
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
  cursor.hotspot = NSMakePoint(size/2.0+1.0, size/2.0+1.0);
  
  self.cursor = cursor;
}


- (void)createDragIndicator
{
  _overlayShape = [[CAShapeLayer alloc] init];
  [self.currentDrawingSurface.overlayLayer addSublayer:_overlayShape];
  _overlayShape.lineWidth = self.size;
  _overlayShape.strokeColor = self.color.CGColor;
  _overlayShape.fillColor = NSColor.clearColor.CGColor;
  _overlayShape.frame = self.currentDrawingSurface.overlayLayer.bounds;
  [self updateDragIndicator];
}


- (void)updateDragIndicator
{
  [CATransaction begin];
  CATransaction.disableActions = YES;
  
  _overlayShape.path = [self shapeBezierPathInRect:_currentRect].ptd_CGPath;
  
  [CATransaction commit];
}


- (void)removeDragIndicator
{
  [_overlayShape removeFromSuperlayer];
  _overlayShape = nil;
}


@end
