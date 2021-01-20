//
// PTDPaintWindow.m
// PaintTheDesktop -- Created on 08/06/2020.
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

#import "PTDPaintWindow.h"
#import "PTDPaintView.h"
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


@interface PTDPaintWindow ()

@property IBOutlet PTDPaintView *paintView;

@property (nonatomic) PTDToolManager *toolManager;

@property (nonatomic) BOOL mouseInWindow;
@property (nonatomic) BOOL mouseIsDragging;
@property (nonatomic) NSPoint lastMousePosition;

@property (nonatomic) BOOL systemCursorVisibility;

@property (nonatomic, nullable, readonly) PTDCursor *currentCursor;

@end


@implementation PTDPaintWindow


- (instancetype)initWithDisplay:(CGDirectDisplayID)display;
{
  self = [super init];
  
  _toolManager = [[PTDToolManager alloc] init];
  
  _display = display;
  #pragma clang diagnostic push
  #pragma clang diagnostic ignored "-Wdeprecated-declarations"
  io_service_t dispSvc = CGDisplayIOServicePort(display);
  #pragma clang diagnostic pop
  NSDictionary *properties = CFBridgingRelease(IODisplayCreateInfoDictionary(dispSvc, kIODisplayOnlyPreferredName));
  _displayName = [[properties[@kDisplayProductName] allValues] firstObject];
  
  [_toolManager addObserver:self forKeyPath:@"currentTool.cursor" options:0 context:NULL];
  [_toolManager addObserver:self forKeyPath:@"currentTool" options:NSKeyValueObservingOptionPrior context:NULL];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(screenConfigurationDidChange:) name:NSApplicationDidChangeScreenParametersNotification object:nil];
  
  /* If we don't do this, Cocoa will muck around with our window positioning */
  self.shouldCascadeWindows = NO;
  
  _systemCursorVisibility = YES;
  
  return self;
}


- (void)dealloc
{
  [_toolManager removeObserver:self forKeyPath:@"currentTool.cursor"];
  [_toolManager removeObserver:self forKeyPath:@"currentTool"];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (NSString *)windowNibName
{
  return @"PTDPaintWindow";
}


- (void)windowDidLoad
{
  [super windowDidLoad];
  
  self.window.backgroundColor = [NSColor colorWithWhite:1.0 alpha:0.0];
  self.window.opaque = NO;
  self.window.hasShadow = NO;
  self.window.level = kCGMaximumWindowLevelKey;
  self.window.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorFullScreenAuxiliary;
  
  if ([[NSUserDefaults standardUserDefaults] boolForKey:@"debug"]) {
    self.window.movable = YES;
    self.window.styleMask = self.window.styleMask | NSWindowStyleMaskTitled;
  } else {
    self.window.movable = NO;
  }
  
  self.display = _display;
  [self.window orderFrontRegardless];
  
  NSTrackingAreaOptions options = NSTrackingActiveAlways |
    NSTrackingInVisibleRect | NSTrackingMouseEnteredAndExited |
    NSTrackingMouseMoved;
  NSTrackingArea *area = [[NSTrackingArea alloc]
    initWithRect:self.paintView.frame
    options:options owner:self userInfo:nil];
  [self.paintView addTrackingArea:area];
  
  [self currentToolDidChange];
  self.currentCursor = self.toolManager.currentTool.cursor;
  
  self.active = NO;
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


- (void)setDisplay:(CGDirectDisplayID)display
{
  CGRect dispFrame = CGDisplayBounds(display);
  
  if (CGDisplayIsActive(display) && (dispFrame.size.width > 0) && (dispFrame.size.height > 0)) {
    /* translate from CG reference coords to NS ones */
    dispFrame.origin.y += dispFrame.size.height;
    CGRect zeroScreenRect = CGDisplayBounds(CGMainDisplayID());
    dispFrame.origin.y = -dispFrame.origin.y + zeroScreenRect.size.height;
    
    self.window.isVisible = YES;
    [self.window setFrame:dispFrame display:NO];
    
    CGFloat scale = self.window.screen.backingScaleFactor;
    self.paintView.backingScaleFactor = NSMakeSize(scale, scale);
  } else {
    self.window.isVisible = NO;
  }
  
  _display = display;
}


- (void)screenConfigurationDidChange:(NSNotification *)notification
{
  self.display = _display;
}


- (PTDDrawingSurface *)drawingSurface
{
  return [[PTDDrawingSurface alloc] initWithPaintView:self.paintView];
}


- (PTDTool *)initializeToolWithSurface:(PTDDrawingSurface *)drawingSurface
{
  PTDTool *tool = self.toolManager.currentTool;
  tool.currentDrawingSurface = drawingSurface;
  return tool;
}


- (void)mouseDown:(NSEvent *)event
{
  self.mouseInWindow = YES;
  self.mouseIsDragging = YES;
  self.lastMousePosition = event.locationInWindow;
  
  @autoreleasepool {
    PTDDrawingSurface *surf = [self drawingSurface];
    PTDTool *tool = [self initializeToolWithSurface:surf];
    [tool dragDidStartAtPoint:self.lastMousePosition];
  }
  [self updateCursorAtPoint:event.locationInWindow];
}


- (void)mouseDragged:(NSEvent *)event
{
  self.mouseInWindow = YES;
  
  @autoreleasepool {
    PTDDrawingSurface *surf = [self drawingSurface];
    PTDTool *tool = [self initializeToolWithSurface:surf];
    if (!self.mouseIsDragging) {
      [tool dragDidStartAtPoint:self.lastMousePosition];
      self.mouseIsDragging = YES;
    } else {
      [tool dragDidContinueFromPoint:self.lastMousePosition toPoint:event.locationInWindow];
    }
  }
  
  self.lastMousePosition = event.locationInWindow;
  [self updateCursorAtPoint:event.locationInWindow];
}


- (void)mouseUp:(NSEvent *)event
{
  self.mouseInWindow = YES;
  
  if (self.mouseIsDragging) {
    @autoreleasepool {
      PTDDrawingSurface *surf = [self drawingSurface];
      PTDTool *tool = [self initializeToolWithSurface:surf];
      [tool dragDidContinueFromPoint:self.lastMousePosition toPoint:event.locationInWindow];
      [tool dragDidEndAtPoint:event.locationInWindow];
    }
  }
  
  if (event.clickCount == 1) {
    @autoreleasepool {
      PTDDrawingSurface *surf = [self drawingSurface];
      PTDTool *tool = [self initializeToolWithSurface:surf];
      [tool mouseClickedAtPoint:event.locationInWindow];
    }
  }
  
  [self updateCursorAtPoint:event.locationInWindow];
  
  self.mouseIsDragging = NO;
}


- (void)rightMouseDown:(NSEvent *)event
{
  self.mouseInWindow = YES;
  [self openContextMenuWithEvent:event];
}


- (void)mouseMoved:(NSEvent *)event
{
  self.mouseInWindow = YES;
  [self updateCursorAtPoint:event.locationInWindow];
}


- (void)mouseEntered:(NSEvent *)event
{
  self.mouseInWindow = YES;
  [self updateCursorAtPoint:event.locationInWindow];
}


- (void)mouseExited:(NSEvent *)event
{
  self.mouseInWindow = NO;
  [self updateCursorAtPoint:event.locationInWindow];
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
  
  PTDRingMenuRing *optMenu = [self.toolManager.currentTool optionMenu];
  if (optMenu)
    [ringMenu addRing:optMenu];
  
  self.systemCursorVisibility = YES;
  [ringMenu popUpMenuWithEvent:event forView:self.paintView];
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
  self.paintView.cursorImage = currentCursor.image;
  _currentCursor = currentCursor;
  [self updateCursorAtPoint:self.lastMousePosition];
}


- (void)updateCursorAtPoint:(NSPoint)point
{
  if (self.active && self.mouseInWindow) {
    NSPoint hotspot = self.currentCursor.hotspot;
    self.paintView.cursorPosition = NSMakePoint(point.x - hotspot.x, point.y - hotspot.y);
  } else {
    if (self.paintView.cursorImage) {
      CGFloat outX = NSMaxX(self.paintView.paintRect) + self.paintView.cursorImage.size.width + 1;
      CGFloat outY = NSMaxX(self.paintView.paintRect) + self.paintView.cursorImage.size.height + 1;
      self.paintView.cursorPosition = NSMakePoint(outX, outY);
    }
  }
  self.systemCursorVisibility = [self computeNextCursorVisibility];
}


- (void)setMouseInWindow:(BOOL)mouseInWindow
{
  self.systemCursorVisibility = [self computeNextCursorVisibility];
  _mouseInWindow = mouseInWindow;
}


- (void)setActive:(BOOL)active
{
  if (active) {
    [self.toolManager.currentTool activate];
    self.window.ignoresMouseEvents = NO;
    [self.window makeKeyAndOrderFront:nil];
  } else {
    [self.toolManager.currentTool deactivate];
    self.window.ignoresMouseEvents = YES;
  }
  _active = active;
  [self updateCursorAtPoint:self.lastMousePosition];
}


- (BOOL)computeNextCursorVisibility
{
  if (!self.active)
    return YES;
  if (!self.currentCursor)
    return YES;
  return !self.mouseInWindow;
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


- (NSBitmapImageRep *)snapshot
{
  return self.paintView.snapshot;
}


- (void)restoreFromSnapshot:(NSBitmapImageRep *)bitmap
{
  @autoreleasepool {
    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext.currentContext = self.paintView.graphicsContext;
    [bitmap drawInRect:self.paintView.paintRect];
    [NSGraphicsContext restoreGraphicsState];
    [self.paintView setNeedsDisplay:YES];
  }
}


@end
