//
// PTDSelectionTool.m
// PaintTheDesktop -- Created on 10/01/2021.
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
#import "PTDSelectionTool.h"
#import "PTDDrawingSurface.h"
#import "NSGeometry+PTD.h"


NSString * const PTDToolIdentifierSelectionTool = @"PTDToolIdentifierSelectionTool";

typedef enum : NSUInteger {
    PTDSelectionToolModeMakeSelection,
    PTDSelectionToolModeEditSelection
} PTDSelectionToolMode;


@implementation PTDSelectionTool {
  NSRect _currentSelection;
  NSPoint _dragPivot;
  NSRect _uneditedCurrentSelection;
  NSImageRep *_selectedArea;
  PTDSelectionToolMode _mode;
  CAShapeLayer *_selectionIndicator;
}


- (instancetype)init
{
  self = [super init];
  _mode = PTDSelectionToolModeMakeSelection;
  return self;
}


+ (NSString *)toolIdentifier
{
  return PTDToolIdentifierSelectionTool;
}


+ (PTDRingMenuItem *)menuItem
{
  return [PTDRingMenuItem itemWithImage:[NSImage imageNamed:@"PTDToolIconSelection"] target:nil action:nil];
}


- (void)dragDidStartAtPoint:(NSPoint)point
{
  switch (_mode) {
    case PTDSelectionToolModeMakeSelection:
      [self newSelection_dragDidStartAtPoint:point];
      break;
    case PTDSelectionToolModeEditSelection:
      [self editSelection_dragDidStartAtPoint:point];
      break;
  }
}


- (void)dragDidContinueFromPoint:(NSPoint)prevPoint toPoint:(NSPoint)nextPoint
{
  switch (_mode) {
    case PTDSelectionToolModeMakeSelection:
      [self newSelection_dragDidContinueFromPoint:prevPoint toPoint:nextPoint];
      break;
    case PTDSelectionToolModeEditSelection:
      [self editSelection_dragDidContinueFromPoint:prevPoint toPoint:nextPoint];
      break;
  }
}


- (void)dragDidEndAtPoint:(NSPoint)point
{
  switch (_mode) {
    case PTDSelectionToolModeMakeSelection:
      [self newSelection_dragDidEndAtPoint:point];
      break;
    case PTDSelectionToolModeEditSelection:
      [self editSelection_dragDidEndAtPoint:point];
      break;
  }
}


- (void)mouseClickedAtPoint:(NSPoint)point
{
  switch (_mode) {
    case PTDSelectionToolModeMakeSelection:
      [self newSelection_mouseClickedAtPoint:point];
      break;
    case PTDSelectionToolModeEditSelection:
      [self editSelection_mouseClickedAtPoint:point];
      break;
  }
}


#pragma mark - New Selection Mode


- (void)newSelection_dragDidStartAtPoint:(NSPoint)point
{
  _dragPivot = [self.currentDrawingSurface alignPointToBacking:point];
  _currentSelection.origin = _dragPivot;
  _currentSelection.size = NSZeroSize;
  [self createSelectionIndicator];
}


- (void)newSelection_dragDidContinueFromPoint:(NSPoint)prevPoint toPoint:(NSPoint)nextPoint
{
  _currentSelection = PTD_NSMakeRectFromPoints(_dragPivot, [self.currentDrawingSurface alignPointToBacking:nextPoint]);
  [self updateSelectionIndicator];
}


- (void)newSelection_dragDidEndAtPoint:(NSPoint)point
{
  point = [self.currentDrawingSurface alignPointToBacking:point];
  _currentSelection = PTD_NSMakeRectFromPoints(_dragPivot, point);
  if (_currentSelection.size.width < 1 || _currentSelection.size.height < 1) {
    [self removeSelectionIndicator];
    return;
  }
  
  _selectedArea = [self.currentDrawingSurface captureRect:_currentSelection];
  
  [self drawSelectionInOverlay];
  [self updateSelectionIndicator];
  
  [self.currentDrawingSurface beginCanvasDrawing];
  [NSGraphicsContext.currentContext setCompositingOperation:NSCompositingOperationClear];
  [NSColor.clearColor setFill];
  NSRectFill(_currentSelection);
  
  _mode = PTDSelectionToolModeEditSelection;
}


- (void)newSelection_mouseClickedAtPoint:(NSPoint)point
{
  [self terminateEditSelection];
}


#pragma mark - Edit Selection Mode


- (void)editSelection_dragDidStartAtPoint:(NSPoint)point
{
  if (!NSPointInRect(point, _currentSelection)) {
    [self terminateEditSelection];
    [self newSelection_dragDidStartAtPoint:point];
    return;
  }
  point = [self.currentDrawingSurface alignPointToBacking:point];
  _dragPivot = point;
  _uneditedCurrentSelection = _currentSelection;
}


- (void)editSelection_dragDidContinueFromPoint:(NSPoint)prevPoint toPoint:(NSPoint)nextPoint
{
  [self clearSelectionInOverlay];
  nextPoint = [self.currentDrawingSurface alignPointToBacking:nextPoint];
  _currentSelection.origin.x = _uneditedCurrentSelection.origin.x + (nextPoint.x - _dragPivot.x);
  _currentSelection.origin.y = _uneditedCurrentSelection.origin.y + (nextPoint.y - _dragPivot.y);
  [self drawSelectionInOverlay];
  [self updateSelectionIndicator];
}


- (void)editSelection_dragDidEndAtPoint:(NSPoint)point
{
  /* noop */
}


- (void)editSelection_mouseClickedAtPoint:(NSPoint)point
{
  if (NSPointInRect(point, _currentSelection)) {
    NSMenu *menu = [[NSMenu alloc] init];
    [menu addItemWithTitle:NSLocalizedString(@"Delete", @"Menu item for deleting current selection") action:@selector(deleteAndTerminateEditSelection) keyEquivalent:@""].target = self;
    [menu popUpMenuPositioningItem:nil atLocation:NSEvent.mouseLocation inView:nil];
  } else {
    [self terminateEditSelection];
  }
}


- (void)clearSelectionInOverlay
{
  [self.currentDrawingSurface beginOverlayDrawing];
  [NSColor.clearColor setFill];
  NSRectFill(_currentSelection);
}


- (void)drawSelectionInOverlay
{
  [self.currentDrawingSurface beginOverlayDrawing];
  [_selectedArea drawInRect:_currentSelection];
}


- (void)deleteAndTerminateEditSelection
{
  [self clearSelectionInOverlay];
  _selectedArea = nil;
  [self terminateEditSelection];
}


- (void)terminateEditSelection
{
  if (_selectedArea) {
    [self clearSelectionInOverlay];
    [self.currentDrawingSurface beginCanvasDrawing];
    [_selectedArea drawInRect:_currentSelection fromRect:(NSRect){NSZeroPoint, _selectedArea.size} operation:NSCompositingOperationSourceOver fraction:1.0 respectFlipped:YES hints:@{NSImageHintInterpolation: @(NSImageInterpolationHigh)}];
    _selectedArea = nil;
  }
  [self removeSelectionIndicator];
  _mode = PTDSelectionToolModeMakeSelection;
}


#pragma mark - Selection Indicator


- (void)createSelectionIndicator
{
  _selectionIndicator = [[CAShapeLayer alloc] init];
  [self.currentDrawingSurface.overlayLayer addSublayer:_selectionIndicator];
  _selectionIndicator.frame = self.currentDrawingSurface.overlayLayer.bounds;
  _selectionIndicator.lineWidth = 1.0;
  _selectionIndicator.lineDashPattern = @[@(4.0), @(4.0)];
  _selectionIndicator.strokeColor = NSColor.blackColor.CGColor;
  _selectionIndicator.fillColor = NSColor.clearColor.CGColor;
  
  CABasicAnimation *dashPhaseAnimation = [CABasicAnimation animation];
  dashPhaseAnimation.duration = 1.0 / 30.0 * 8.0;
  dashPhaseAnimation.repeatCount = INFINITY;
  dashPhaseAnimation.keyPath = @"lineDashPhase";
  dashPhaseAnimation.fromValue = @0.0;
  dashPhaseAnimation.toValue = @8.0;
  dashPhaseAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
  [_selectionIndicator addAnimation:dashPhaseAnimation forKey:@"dashPhaseAnimation"];
  
  [self updateSelectionIndicator];
}


- (void)updateSelectionIndicator
{
  CGPathRef path = CGPathCreateWithRect(NSInsetRect(_currentSelection, .5, .5), NULL);
  _selectionIndicator.path = path;
  CGPathRelease(path);
}


- (void)removeSelectionIndicator
{
  [_selectionIndicator removeFromSuperlayer];
  _selectionIndicator = nil;
}


@end
