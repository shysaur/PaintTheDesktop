//
// PTDPaintViewController.m
// PaintTheDesktop -- Created on 24/04/2021.
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

#import "PTDPaintViewController.h"
#import "PTDDrawingSurface.h"
#import "PTDTool.h"
#import "PTDToolManager.h"
#import "PTDCursor.h"
#import "NSScreen+PTD.h"
#import "PTDRingMenu.h"
#import "PTDRingMenuRing.h"
#import "PTDRingMenuItem.h"
#import "PTDRingMenuSpring.h"
#import "PTDRingMenuWindow.h"


@interface PTDPaintViewController ()

@property (nonatomic) PTDToolManager *toolManager;

@property (nonatomic) BOOL mouseInView;
@property (nonatomic) BOOL mouseIsDragging;
@property (nonatomic) NSPoint lastMousePosition;

@property (nonatomic) BOOL systemCursorVisibility;

@property (nonatomic, nullable, readonly) PTDCursor *currentCursor;

@end


@implementation PTDPaintViewController {
  __weak PTDDrawingSurface *_lastDrawingSurface;
}

@dynamic view;


- (void)viewDidLoad
{
  [super viewDidLoad];
  
  _toolManager = [[PTDToolManager alloc] init];
  
  [_toolManager addObserver:self forKeyPath:@"currentTool.cursor" options:0 context:NULL];
  [_toolManager addObserver:self forKeyPath:@"currentTool" options:NSKeyValueObservingOptionPrior context:NULL];
  
  _systemCursorVisibility = YES;
  
  NSTrackingAreaOptions options = NSTrackingActiveAlways |
    NSTrackingInVisibleRect | NSTrackingMouseEnteredAndExited |
    NSTrackingMouseMoved;
  NSTrackingArea *area = [[NSTrackingArea alloc]
    initWithRect:self.view.bounds
    options:options owner:self userInfo:nil];
  [self.view addTrackingArea:area];
  
  [self currentToolDidChange];
  self.currentCursor = self.toolManager.currentTool.cursor;
  
  self.active = YES;
}


- (void)dealloc
{
  [_toolManager removeObserver:self forKeyPath:@"currentTool.cursor"];
  [_toolManager removeObserver:self forKeyPath:@"currentTool"];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
  if (object == _toolManager) {
    if ([keyPath isEqual:@"currentTool.cursor"]) {
      self.currentCursor = self.toolManager.currentTool.cursor;
    } else if ([keyPath isEqual:@"currentTool"]) {
      if ([change[NSKeyValueChangeNotificationIsPriorKey] isEqual:@YES]) {
        [self currentToolWillChange];
      } else {
        [self currentToolDidChange];
      }
    }
  } else {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}


- (PTDDrawingSurface *)drawingSurface
{
  PTDDrawingSurface *lastDrawingSurface = _lastDrawingSurface;
  if (!lastDrawingSurface)
    lastDrawingSurface = [[PTDDrawingSurface alloc] initWithPaintView:self.view];
  return lastDrawingSurface;
}


- (PTDTool *)initializeToolWithSurface:(PTDDrawingSurface *)drawingSurface
{
  PTDTool *tool = self.toolManager.currentTool;
  tool.currentDrawingSurface = drawingSurface;
  return tool;
}


- (NSPoint)locationForEvent:(NSEvent *)event
{
  return [self.view convertPoint:event.locationInWindow fromView:nil];
}


- (void)mouseDown:(NSEvent *)event
{
  self.mouseInView = YES;
  if (!self.active)
    return;
  
  self.mouseIsDragging = YES;
  self.lastMousePosition = [self locationForEvent:event];
  
  @autoreleasepool {
    PTDDrawingSurface *surf = [self drawingSurface];
    PTDTool *tool = [self initializeToolWithSurface:surf];
    [tool dragDidStartAtPoint:self.lastMousePosition];
  }
  [self updateCursorAtPoint:[self locationForEvent:event]];
}


- (void)mouseDragged:(NSEvent *)event
{
  self.mouseInView = YES;
  if (!self.active)
    return;
  
  @autoreleasepool {
    PTDDrawingSurface *surf = [self drawingSurface];
    PTDTool *tool = [self initializeToolWithSurface:surf];
    if (!self.mouseIsDragging) {
      [tool dragDidStartAtPoint:self.lastMousePosition];
      self.mouseIsDragging = YES;
    } else {
      [tool dragDidContinueFromPoint:self.lastMousePosition toPoint:[self locationForEvent:event]];
    }
  }
  
  self.lastMousePosition = [self locationForEvent:event];
  [self updateCursorAtPoint:[self locationForEvent:event]];
}


- (void)mouseUp:(NSEvent *)event
{
  self.mouseInView = YES;
  if (!self.active)
    return;
  
  if (self.mouseIsDragging) {
    @autoreleasepool {
      PTDDrawingSurface *surf = [self drawingSurface];
      PTDTool *tool = [self initializeToolWithSurface:surf];
      [tool dragDidContinueFromPoint:self.lastMousePosition toPoint:[self locationForEvent:event]];
      [tool dragDidEndAtPoint:[self locationForEvent:event]];
    }
  }
  
  if (event.clickCount == 1) {
    @autoreleasepool {
      PTDDrawingSurface *surf = [self drawingSurface];
      PTDTool *tool = [self initializeToolWithSurface:surf];
      [tool mouseClickedAtPoint:[self locationForEvent:event]];
    }
  }
  
  [self updateCursorAtPoint:[self locationForEvent:event]];
  
  self.mouseIsDragging = NO;
}


- (void)rightMouseDown:(NSEvent *)event
{
  self.mouseInView = YES;
  if (!self.active)
    return;
  [self openContextMenuWithEvent:event];
}


- (void)mouseMoved:(NSEvent *)event
{
  self.mouseInView = YES;
  [self updateCursorAtPoint:[self locationForEvent:event]];
}


- (void)mouseEntered:(NSEvent *)event
{
  self.mouseInView = YES;
  [self updateCursorAtPoint:[self locationForEvent:event]];
}


- (void)mouseExited:(NSEvent *)event
{
  self.mouseInView = NO;
  [self updateCursorAtPoint:[self locationForEvent:event]];
}


- (void)flagsChanged:(NSEvent *)event
{
  if (self.mouseInView && self.mouseIsDragging) {
    @autoreleasepool {
      PTDDrawingSurface *surf = [self drawingSurface];
      PTDTool *tool = [self initializeToolWithSurface:surf];
      [tool modifierFlagsChanged];
    }
  }
}


- (void)openContextMenuWithEvent:(NSEvent *)event
{
  PTDRingMenu *ringMenu = [[PTDRingMenu alloc] init];
  PTDRingMenuRing *itemsRing = [ringMenu newRing];
  
  for (NSString *toolid in self.toolManager.availableToolIdentifiers) {
    PTDRingMenuItem *item = [self.toolManager ringMenuItemForSelectingToolIdentifier:toolid];
    if ([toolid isEqual:[[self.toolManager.currentTool class] toolIdentifier]])
      item.state = NSControlStateValueOn;
    [itemsRing addItem:item];
  }
  [itemsRing beginGravityMassGroupWithAngle:-M_PI_2];
  [itemsRing addItemWithText:NSLocalizedString(@"Quit", @"") target:NSApp action:@selector(terminate:)];
  [itemsRing endGravityMassGroup];
  
  @autoreleasepool {
    PTDDrawingSurface *surf = [self drawingSurface];
    PTDTool *tool = [self initializeToolWithSurface:surf];
    
    PTDRingMenuRing *optMenu = [tool optionMenu];
    if (optMenu)
      [ringMenu addRing:optMenu];
    
    [tool willOpenOptionMenuAtPoint:[self locationForEvent:event]];
    self.systemCursorVisibility = YES;
    [ringMenu popUpMenuWithEvent:event forView:self.view];
  }
}


- (void)currentToolWillChange
{
  @autoreleasepool {
    PTDDrawingSurface *surf = [self drawingSurface];
    PTDTool *tool = [self initializeToolWithSurface:surf];
    [tool deactivate];
  }
}


- (void)currentToolDidChange
{
  @autoreleasepool {
    PTDDrawingSurface *surf = [self drawingSurface];
    PTDTool *tool = [self initializeToolWithSurface:surf];
    [tool activate];
  }
}


- (void)setCurrentCursor:(PTDCursor * _Nullable)currentCursor
{
  self.view.cursorImage = currentCursor.image;
  _currentCursor = currentCursor;
  [self updateCursorAtPoint:self.lastMousePosition];
}


- (void)updateCursorAtPoint:(NSPoint)point
{
  if (self.active && self.mouseInView) {
    NSPoint hotspot = self.currentCursor.hotspot;
    self.view.cursorPosition = NSMakePoint(point.x - hotspot.x, point.y - hotspot.y);
  } else {
    if (self.view.cursorImage) {
      CGFloat outX = NSMaxX(self.view.paintRect) + self.view.cursorImage.size.width + 1;
      CGFloat outY = NSMaxX(self.view.paintRect) + self.view.cursorImage.size.height + 1;
      self.view.cursorPosition = NSMakePoint(outX, outY);
    }
  }
  self.systemCursorVisibility = [self computeNextCursorVisibility];
}


- (void)setMouseInView:(BOOL)mouseInView
{
  _mouseInView = mouseInView;
  self.systemCursorVisibility = [self computeNextCursorVisibility];
}


- (void)setActive:(BOOL)active
{
  if (_active != active) {
    if (active) {
      [self.toolManager.currentTool activate];
    } else {
      [self.toolManager.currentTool deactivate];
    }
  }
  _active = active;
  NSPoint mousePositionInWindow = [self.view.window mouseLocationOutsideOfEventStream];
  [self updateCursorAtPoint:[self.view convertPoint:mousePositionInWindow fromView:nil]];
}


- (BOOL)computeNextCursorVisibility
{
  if (!self.active)
    return YES;
  if (!self.currentCursor)
    return YES;
  return !self.mouseInView;
}


- (void)setSystemCursorVisibility:(BOOL)systemCursorVisibility
{
  if (_systemCursorVisibility != systemCursorVisibility) {
    if (systemCursorVisibility) {
      [NSCursor unhide];
    } else {
      [NSCursor hide];
    }
  }
  _systemCursorVisibility = systemCursorVisibility;
}


@end
