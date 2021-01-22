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
#import "PTDBrush.h"
#import "PTDShapeTool.h"
#import "PTDDrawingSurface.h"
#import "PTDTool.h"
#import "PTDCursor.h"
#import "NSGeometry+PTD.h"
#import "NSBezierPath+PTD.h"
#import "NSColor+PTD.h"


@implementation PTDShapeTool {
  NSRect _currentRect;
  CAShapeLayer *_overlayShape;
}


- (void)activate
{
  [self updateCursor];
}


- (NSRect)normalizedCurrentRect
{
  return PTD_NSNormalizedRect(_currentRect);
}


- (void)dragDidStartAtPoint:(NSPoint)point
{
  _currentRect = (NSRect){point, NSZeroSize};
  [self createDragIndicator];
}


- (NSBezierPath *)shapeBezierPathInRect:(NSRect)rect
{
  [NSException raise:NSInternalInconsistencyException format:@"ABSTRACT METHOD: %s", __FUNCTION__];
  return nil;
}


- (void)dragDidContinueFromPoint:(NSPoint)prevPoint toPoint:(NSPoint)nextPoint
{
  _currentRect.size = NSMakeSize(
      nextPoint.x - _currentRect.origin.x,
      nextPoint.y - _currentRect.origin.y);
  [self updateDragIndicator];
}


- (void)dragDidEndAtPoint:(NSPoint)point
{
  _currentRect.size = NSMakeSize(
      point.x - _currentRect.origin.x,
      point.y - _currentRect.origin.y);
  [self removeDragIndicator];
  
  [self.currentDrawingSurface beginCanvasDrawing];
  [NSGraphicsContext.currentContext setShouldAntialias:YES];
  
  NSBezierPath *path = [self shapeBezierPathInRect:[self normalizedCurrentRect]];
  [path setLineWidth:self.currentBrush.size];
  [self.currentBrush.color setStroke];
  [path stroke];
}


- (PTDRingMenuRing *)optionMenu
{
  return self.currentBrush.menuOptions;
}


- (void)setCurrentBrush:(PTDBrush *)currentBrush
{
  [super setCurrentBrush:currentBrush];
  [self updateCursor];
}


- (void)updateCursor
{
  CGFloat size = floor((self.currentBrush.size + 8.0) / 2.0) * 2.0 + 1.0;
  NSColor *color = self.currentBrush.color;
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
  _overlayShape.lineWidth = self.currentBrush.size;
  _overlayShape.strokeColor = self.currentBrush.color.CGColor;
  _overlayShape.fillColor = NSColor.clearColor.CGColor;
  _overlayShape.frame = self.currentDrawingSurface.overlayLayer.bounds;
  [self updateDragIndicator];
}


- (void)updateDragIndicator
{
  [CATransaction begin];
  CATransaction.disableActions = YES;
  
  _overlayShape.path = [self shapeBezierPathInRect:self.normalizedCurrentRect].ptd_CGPath;
  
  [CATransaction commit];
}


- (void)removeDragIndicator
{
  [_overlayShape removeFromSuperlayer];
  _overlayShape = nil;
}


@end
