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
  NSSize _dragOffset;
  NSImageRep *_selectedArea;
  PTDSelectionToolMode _mode;
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
  [self terminateEditSelection];
}


#pragma mark - New Selection Mode


- (void)newSelection_dragDidStartAtPoint:(NSPoint)point
{
  _currentSelection.origin = [self.currentDrawingSurface alignPointToBacking:point];
}


- (void)newSelection_dragDidContinueFromPoint:(NSPoint)prevPoint toPoint:(NSPoint)nextPoint
{
  [self.currentDrawingSurface beginOverlayDrawing];
  
  NSRect oldSelection = PTD_NSMakeRectFromPoints(_currentSelection.origin, [self.currentDrawingSurface alignPointToBacking:prevPoint]);
  NSRect newSelection = PTD_NSMakeRectFromPoints(_currentSelection.origin, [self.currentDrawingSurface alignPointToBacking:nextPoint]);
  
  [self.currentDrawingSurface beginOverlayDrawing];
  [NSGraphicsContext.currentContext setCompositingOperation:NSCompositingOperationClear];
  [NSColor.clearColor setFill];
  NSRectFill(oldSelection);
  [NSGraphicsContext.currentContext setCompositingOperation:NSCompositingOperationCopy];
  [NSColor.blackColor setFill];
  NSFrameRect(newSelection);
}


- (void)newSelection_dragDidEndAtPoint:(NSPoint)point
{
  point = [self.currentDrawingSurface alignPointToBacking:point];
  _currentSelection = PTD_NSMakeRectFromPoints(_currentSelection.origin, point);
  if (_currentSelection.size.width < 1 || _currentSelection.size.height < 1)
    return;
  
  _selectedArea = [self.currentDrawingSurface captureRect:_currentSelection];
  
  [self drawSelectionInOverlay];
  
  [self.currentDrawingSurface beginCanvasDrawing];
  [NSGraphicsContext.currentContext setCompositingOperation:NSCompositingOperationClear];
  [NSColor.clearColor setFill];
  NSRectFill(_currentSelection);
  
  _mode = PTDSelectionToolModeEditSelection;
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
  _dragOffset.width = point.x - _currentSelection.origin.x;
  _dragOffset.height = point.y - _currentSelection.origin.y;
}


- (void)editSelection_dragDidContinueFromPoint:(NSPoint)prevPoint toPoint:(NSPoint)nextPoint
{
  [self clearSelectionInOverlay];
  nextPoint = [self.currentDrawingSurface alignPointToBacking:nextPoint];
  _currentSelection.origin.x = nextPoint.x - _dragOffset.width;
  _currentSelection.origin.y = nextPoint.y - _dragOffset.height;
  [self drawSelectionInOverlay];
}


- (void)editSelection_dragDidEndAtPoint:(NSPoint)point
{
  /* noop */
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
  [NSColor.blackColor setFill];
  NSFrameRect(_currentSelection);
}


- (void)terminateEditSelection
{
  if (_selectedArea) {
    [self clearSelectionInOverlay];
    [self.currentDrawingSurface beginCanvasDrawing];
    [_selectedArea drawInRect:_currentSelection fromRect:(NSRect){NSZeroPoint, _selectedArea.size} operation:NSCompositingOperationSourceOver fraction:1.0 respectFlipped:YES hints:@{NSImageHintInterpolation: @(NSImageInterpolationHigh)}];
    _selectedArea = nil;
  }
  _mode = PTDSelectionToolModeMakeSelection;
}


@end
