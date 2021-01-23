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

typedef NS_OPTIONS(NSUInteger, PTDSelectionToolEditFlags) {
    PTDSelectionToolEditFlagsProportional = 1 << 0,
    PTDSelectionToolEditFlagsCentered = 1 << 1,
};


@implementation PTDSelectionTool {
  PTDSelectionToolMode _mode;
  BOOL _isDragging;
  NSPoint _lastMenuPosition;
  
  NSRect _currentSelection;
  
  NSImageRep *_selectedArea;
  
  NSPoint _dragPivot;
  NSPoint _lastMousePosition;
  NSRect _uneditedCurrentSelection;
  PTDSelectionToolHandleID _activeSelectionHandle;
  
  CAShapeLayer *_selectionIndicator;
  CALayer *_selectionPreview;
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


- (void)willOpenOptionMenuAtPoint:(NSPoint)point
{
  _lastMenuPosition = point;
}


- (nullable PTDRingMenuRing *)optionMenu
{
  PTDRingMenuRing *res = [PTDRingMenuRing ring];
  PTDRingMenuItem *itm;
  
  [res beginGravityMassGroupWithAngle:M_PI_2];
  
  itm = [res addItemWithText:NSLocalizedString(@"Cut", @"Menu item for cutting current selection") target:self action:@selector(cut:)];
  itm.enabled = _mode == PTDSelectionToolModeEditSelection;
  itm = [res addItemWithText:NSLocalizedString(@"Copy", @"Menu item for copying current selection") target:self action:@selector(copy:)];
  itm.enabled = _mode == PTDSelectionToolModeEditSelection;
  
  itm = [res addItemWithText:NSLocalizedString(@"Paste", @"Menu item for pasting current selection") target:self action:@selector(paste:)];
  NSPasteboard *pb = [NSPasteboard generalPasteboard];
  itm.enabled = [NSBitmapImageRep canInitWithPasteboard:pb];
  
  [res endGravityMassGroup];
  
  [res addSpringWithElasticity:1.0];
  
  itm = [res addItemWithText:NSLocalizedString(@"Delete", @"Menu item for deleting current selection") target:self action:@selector(delete:)];
  itm.enabled = _mode == PTDSelectionToolModeEditSelection;
  
  [res addSpringWithElasticity:1.0];
  
  return res;
}


- (void)delete:(id)sender
{
  [self deleteAndTerminateEditSelection];
}


- (void)cut:(id)sender
{
  [self copy:sender];
  [self deleteAndTerminateEditSelection];
}


- (void)copy:(id)sender
{
  if (![_selectedArea isKindOfClass:NSBitmapImageRep.class]) {
    NSBeep();
    return;
  }
  
  NSBitmapImageRep *area = (NSBitmapImageRep *)_selectedArea;
  NSPasteboard *pb = [NSPasteboard generalPasteboard];
  [pb declareTypes:@[NSPasteboardTypePNG] owner:nil];
  NSData *png = [area representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
  [pb setData:png forType:NSPasteboardTypePNG];
}


- (void)paste:(id)sender
{
  NSPasteboard *pb = [NSPasteboard generalPasteboard];
  NSImageRep *tmp = [NSImageRep imageRepWithPasteboard:pb];
  if (!tmp) {
    NSBeep();
    return;
  }
  
  [self terminateEditSelection];
  _selectedArea = tmp;
  _currentSelection = NSMakeRect(
      _lastMenuPosition.x - _selectedArea.size.height / 2.0,
      _lastMenuPosition.y - _selectedArea.size.height / 2.0,
      _selectedArea.size.width,
      _selectedArea.size.height);
  _currentSelection.origin = [self.currentDrawingSurface alignPointToBacking:_currentSelection.origin];
  _mode = PTDSelectionToolModeEditSelection;
  [self createSelectionIndicator];
}


- (void)dragDidStartAtPoint:(NSPoint)point
{
  _isDragging = YES;
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
  _isDragging = NO;
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


- (void)modifierFlagsChanged
{
  if (_mode == PTDSelectionToolModeEditSelection && _isDragging) {
    [self continueEditingSelection];
  }
}


- (void)deactivate
{
  [self terminateEditSelection];
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
  
  [self.currentDrawingSurface beginCanvasDrawing];
  [NSGraphicsContext.currentContext setCompositingOperation:NSCompositingOperationClear];
  [NSColor.clearColor setFill];
  NSRectFill(_currentSelection);
  
  _mode = PTDSelectionToolModeEditSelection;
  [self updateSelectionIndicator];
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
  
  _lastMousePosition = point = [self.currentDrawingSurface alignPointToBacking:point];
  _dragPivot = point;
  _uneditedCurrentSelection = _currentSelection;
}


- (void)editSelection_dragDidContinueFromPoint:(NSPoint)prevPoint toPoint:(NSPoint)nextPoint
{
  _lastMousePosition = [self.currentDrawingSurface alignPointToBacking:nextPoint];
  
  [self continueEditingSelection];
}


- (void)editSelection_dragDidEndAtPoint:(NSPoint)point
{
  [self updateSelectionIndicator];
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


- (void)continueEditingSelection
{
  PTDSelectionToolEditFlags flags = 0;
  if (_activeSelectionHandle != PTDSelectionToolDragHandle) {
    if (NSEvent.modifierFlags & NSEventModifierFlagShift)
      flags |= PTDSelectionToolEditFlagsProportional;
    if (NSEvent.modifierFlags & NSEventModifierFlagOption)
      flags |= PTDSelectionToolEditFlagsCentered;
  }
  
  NSRect coeffs = [self transformCoefficientsForSelectionHandle:_activeSelectionHandle editFlags:flags];
  
  CGFloat dx = (_lastMousePosition.x - _dragPivot.x) * coeffs.origin.x;
  CGFloat dy = (_lastMousePosition.y - _dragPivot.y) * coeffs.origin.y;
  CGFloat dw = (_lastMousePosition.x - _dragPivot.x) * coeffs.size.width;
  CGFloat dh = (_lastMousePosition.y - _dragPivot.y) * coeffs.size.height;
  
  if (flags & PTDSelectionToolEditFlagsProportional) {
    CGFloat ratio = _uneditedCurrentSelection.size.width / _uneditedCurrentSelection.size.height;
    if (_activeSelectionHandle == PTDSelectionToolEResizeHandle
        || _activeSelectionHandle == PTDSelectionToolWResizeHandle)
      dh = dw / ratio;
    else if (_activeSelectionHandle == PTDSelectionToolNResizeHandle
        || _activeSelectionHandle == PTDSelectionToolSResizeHandle)
      dw = dh * ratio;
    if (dw > dh * ratio)
      dh = dw / ratio;
    else
      dw = dh * ratio;
    dx = dw / coeffs.size.width * coeffs.origin.x;
    dy = dh / coeffs.size.height * coeffs.origin.y;
  }
  
  if (flags & PTDSelectionToolEditFlagsCentered) {
    dx *= 2.0;
    dy *= 2.0;
    dw *= 2.0;
    dh *= 2.0;
  }
  
  _currentSelection.origin.x = _uneditedCurrentSelection.origin.x + round(dx);
  _currentSelection.origin.y = _uneditedCurrentSelection.origin.y + round(dy);
  _currentSelection.size.width = _uneditedCurrentSelection.size.width + round(dw);
  _currentSelection.size.height = _uneditedCurrentSelection.size.height + round(dh);
  _currentSelection = PTD_NSNormalizedRect(_currentSelection);
  
  if (flags & PTDSelectionToolEditFlagsCentered) {
    NSPoint center = PTD_NSRectCenter(_uneditedCurrentSelection);
    _currentSelection.origin.x = center.x - _currentSelection.size.width / 2.0;
    _currentSelection.origin.y = center.y - _currentSelection.size.height / 2.0;
  }
  
  [self updateSelectionIndicator];
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


- (NSRect)transformCoefficientsForSelectionHandle:(PTDSelectionToolHandleID)handle editFlags:(PTDSelectionToolEditFlags)flags
{
  if (handle == PTDSelectionToolDragHandle) {
    return NSMakeRect(1.0, 1.0, 0.0, 0.0);
  }
  
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
  NSRect coeff = coeffs[handle];
  
  if (flags & PTDSelectionToolEditFlagsProportional) {
    if (coeff.size.width == 0.0) {
      coeff.size.width = 1.0;
      coeff.origin.x = -0.5;
    } else if (coeff.size.height == 0.0) {
      coeff.size.height = 1.0;
      coeff.origin.y = -0.5;
    }
  }
  
  return coeff;
}


- (void)deleteAndTerminateEditSelection
{
  _selectedArea = nil;
  [self terminateEditSelection];
}


- (void)terminateEditSelection
{
  if (_selectedArea) {
    [self.currentDrawingSurface beginCanvasDrawing];
    [_selectedArea drawInRect:_currentSelection fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0 respectFlipped:YES hints:@{NSImageHintInterpolation: @(NSImageInterpolationHigh)}];
    _selectedArea = nil;
    [self.currentDrawingSurface endCanvasDrawing];
  }
  [self removeSelectionIndicator];
  _mode = PTDSelectionToolModeMakeSelection;
}


#pragma mark - Selection Indicator


- (void)createSelectionIndicator
{
  _selectionPreview = [[CALayer alloc] init];
  [self.currentDrawingSurface.overlayLayer addSublayer:_selectionPreview];
  _selectionPreview.borderWidth = 1.0;
  _selectionPreview.borderColor = NSColor.whiteColor.CGColor;
  
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
  
  if (_mode == PTDSelectionToolModeEditSelection) {
    BOOL regenContents = _selectionPreview.contents == nil;
    /* regenerate the preview after each drag has ended for vector images */
    regenContents |= ![_selectedArea isKindOfClass:NSBitmapImageRep.class] && !_isDragging;
    if (regenContents) {
      NSRect proposedRect = (NSRect){NSZeroPoint, _currentSelection.size};
      _selectionPreview.contents = (id)[_selectedArea CGImageForProposedRect:&proposedRect context:nil hints:nil];
    }
  }
  _selectionPreview.frame = _currentSelection;
  
  for (PTDSelectionToolHandleID i=PTDSelectionToolFirstResizeHandle; i<=PTDSelectionToolLastResizeHandle; i++) {
    CALayer *shi = _selectionHandleIndicators[i];
    if (_mode == PTDSelectionToolModeMakeSelection) {
      shi.hidden = YES;
    } else {
      shi.hidden = NO;
      shi.position = [self centerOfSelectionHandle:i];
    }
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
  
  [_selectionPreview removeFromSuperlayer];
  _selectionPreview = nil;
  
  [CATransaction commit];
}


@end
