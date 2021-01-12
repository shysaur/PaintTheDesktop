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

typedef NS_ENUM(NSUInteger, PTDSelectionToolMode) {
  PTDSelectionToolModeMakeSelection,
  PTDSelectionToolModeEditSelection
};

typedef NS_ENUM(NSInteger, PTDSelectionToolHandleID) {
  PTDSelectionToolFirstResizeHandle = 0,
  PTDSelectionToolSWResizeHandle = PTDSelectionToolFirstResizeHandle,
  PTDSelectionToolSResizeHandle,
  PTDSelectionToolSEResizeHandle,
  PTDSelectionToolEResizeHandle,
  PTDSelectionToolNEResizeHandle,
  PTDSelectionToolNResizeHandle,
  PTDSelectionToolNWResizeHandle,
  PTDSelectionToolWResizeHandle,
  PTDSelectionToolLastResizeHandle = PTDSelectionToolWResizeHandle,
  PTDSelectionToolDragHandle,
  PTDSelectionToolNumHandles
};


@implementation PTDSelectionTool {
  NSRect _currentSelection;
  NSPoint _dragPivot;
  NSRect _uneditedCurrentSelection;
  PTDSelectionToolHandleID _activeSelectionHandle;
  NSImageRep *_selectedArea;
  PTDSelectionToolMode _mode;
  
  CAShapeLayer *_selectionIndicator;
  NSMutableArray <CALayer *> *_selectionHandleIndicators;
}


- (instancetype)init
{
  self = [super init];
  _mode = PTDSelectionToolModeMakeSelection;
  _selectionHandleIndicators = [NSMutableArray array];
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
  _activeSelectionHandle = [self hitTestSelectionHandleAtPoint:point];
  if (_activeSelectionHandle == NSNotFound) {
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
  NSRect coeffs = [self transformCoefficientsForSelectionHandle:_activeSelectionHandle];
  
  CGFloat dx = nextPoint.x - _dragPivot.x;
  CGFloat dy = nextPoint.y - _dragPivot.y;
  
  _currentSelection.origin.x = _uneditedCurrentSelection.origin.x + dx * coeffs.origin.x;
  _currentSelection.origin.y = _uneditedCurrentSelection.origin.y + dy * coeffs.origin.y;
  _currentSelection.size.width = _uneditedCurrentSelection.size.width + dx * coeffs.size.width;
  _currentSelection.size.height = _uneditedCurrentSelection.size.height + dy * coeffs.size.height;
  _currentSelection = PTD_NSNormalizedRect(_currentSelection);
  
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


- (NSPoint)centerOfSelectionHandle:(PTDSelectionToolHandleID)handle
{
  switch (handle) {
    case PTDSelectionToolSWResizeHandle:
      return NSMakePoint(NSMinX(_currentSelection)+.5         , NSMinY(_currentSelection)+.5         ); break;
    case PTDSelectionToolSResizeHandle:
      return NSMakePoint(PTD_NSRectCenter(_currentSelection).x, NSMinY(_currentSelection)+.5         ); break;
    case PTDSelectionToolSEResizeHandle:
      return NSMakePoint(NSMaxX(_currentSelection)-.5         , NSMinY(_currentSelection)+.5         ); break;
    case PTDSelectionToolEResizeHandle:
      return NSMakePoint(NSMaxX(_currentSelection)-.5         , PTD_NSRectCenter(_currentSelection).y); break;
    case PTDSelectionToolNEResizeHandle:
      return NSMakePoint(NSMaxX(_currentSelection)-.5         , NSMaxY(_currentSelection)-.5         ); break;
    case PTDSelectionToolNResizeHandle:
      return NSMakePoint(PTD_NSRectCenter(_currentSelection).x, NSMaxY(_currentSelection)-.5         ); break;
    case PTDSelectionToolNWResizeHandle:
      return NSMakePoint(NSMinX(_currentSelection)+.5         , NSMaxY(_currentSelection)-.5         ); break;
    case PTDSelectionToolWResizeHandle:
      return NSMakePoint(NSMinX(_currentSelection)+.5         , PTD_NSRectCenter(_currentSelection).y); break;
    default:
      break;
  }
  return PTD_NSRectCenter(_currentSelection);
}


- (PTDSelectionToolHandleID)hitTestSelectionHandleAtPoint:(NSPoint)loc
{
  #define HANDLE_WIDTH (9.0)
  #define HANDLE_RECT(p) PTD_NSMakeRectFromPoints( \
    (NSPoint){(p).x - HANDLE_WIDTH/2.0, (p).y - HANDLE_WIDTH/2.0}, \
    (NSPoint){(p).x + HANDLE_WIDTH/2.0, (p).y + HANDLE_WIDTH/2.0})
  
  for (NSInteger i=PTDSelectionToolFirstResizeHandle; i<=PTDSelectionToolLastResizeHandle; i++) {
    if (NSPointInRect(loc, HANDLE_RECT([self centerOfSelectionHandle:i])))
      return i;
  }
  if (NSPointInRect(loc, _currentSelection))
    return PTDSelectionToolDragHandle;
  return NSNotFound;
  
  #undef HANDLE_WIDTH
  #undef HANDLE_RECT
}


- (NSRect)transformCoefficientsForSelectionHandle:(PTDSelectionToolHandleID)handle
{
  static const NSRect coeffs[] = {
           /*   x     y     w     h */
    (NSRect){ 1.0,  1.0, -1.0, -1.0}, /* PTDSelectionToolSWResizeHandle */
    (NSRect){ 0.0,  1.0,  0.0, -1.0}, /* PTDSelectionToolSResizeHandle */
    (NSRect){ 0.0,  1.0,  1.0, -1.0}, /* PTDSelectionToolSEResizeHandle */
    (NSRect){ 0.0,  0.0,  1.0,  0.0}, /* PTDSelectionToolEResizeHandle */
    (NSRect){ 0.0,  0.0,  1.0,  1.0}, /* PTDSelectionToolNEResizeHandle */
    (NSRect){ 0.0,  0.0,  0.0,  1.0}, /* PTDSelectionToolNResizeHandle */
    (NSRect){ 1.0,  0.0, -1.0,  1.0}, /* PTDSelectionToolNWResizeHandle */
    (NSRect){ 1.0,  0.0, -1.0,  0.0}, /* PTDSelectionToolWResizeHandle */
  };
  if (handle == PTDSelectionToolDragHandle) {
    return NSMakeRect(1.0, 1.0, 0.0, 0.0);
  }
  return coeffs[handle];
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
  
  for (PTDSelectionToolHandleID i=PTDSelectionToolFirstResizeHandle; i<=PTDSelectionToolLastResizeHandle; i++) {
    CALayer *shi = [[CALayer alloc] init];
    [_selectionIndicator addSublayer:shi];
    shi.backgroundColor = NSColor.whiteColor.CGColor;
    shi.borderColor = NSColor.blackColor.CGColor;
    shi.borderWidth = 1.0;
    shi.bounds = NSMakeRect(0, 0, 5, 5);
    [_selectionHandleIndicators addObject:shi];
  }
  
  [self updateSelectionIndicator];
}


- (void)updateSelectionIndicator
{
  [CATransaction begin];
  CATransaction.disableActions = YES;
  
  CGPathRef path = CGPathCreateWithRect(NSInsetRect(_currentSelection, .5, .5), NULL);
  _selectionIndicator.path = path;
  CGPathRelease(path);
  
  for (PTDSelectionToolHandleID i=PTDSelectionToolFirstResizeHandle; i<=PTDSelectionToolLastResizeHandle; i++) {
    CALayer *shi = _selectionHandleIndicators[i];
    shi.position = [self centerOfSelectionHandle:i];
  }
  
  [CATransaction commit];
}


- (void)removeSelectionIndicator
{
  [CATransaction begin];
  CATransaction.disableActions = YES;
  
  for (CAShapeLayer *shi in _selectionHandleIndicators) {
    [shi removeFromSuperlayer];
  }
  [_selectionHandleIndicators removeAllObjects];
  
  [_selectionIndicator removeFromSuperlayer];
  _selectionIndicator = nil;
  
  [CATransaction commit];
}


@end
