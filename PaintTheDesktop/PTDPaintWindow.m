//
//  PTDPaintWindow.m
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 08/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import "PTDPaintWindow.h"
#import "PTDPaintView.h"
#import "PTDTool.h"
#import "PTDToolManager.h"
#import "PTDCursor.h"
#import "NSScreen+PTD.h"


@interface PTDPaintWindow ()

@property IBOutlet PTDPaintView *paintView;

@property (nonatomic) BOOL mouseInWindow;
@property (nonatomic) BOOL mouseIsDragging;
@property (nonatomic) NSPoint lastMousePosition;

@property (nonatomic) BOOL systemCursorVisibility;

@property (nonatomic, nullable, readonly) PTDTool *currentTool;
@property (nonatomic, nullable, readonly) PTDCursor *currentCursor;

@end


@implementation PTDPaintWindow


- (instancetype)initWithDisplay:(CGDirectDisplayID)display;
{
  self = [super init];
  _display = display;
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cursorDidChange:) name:PTDToolCursorDidChangeNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(screenConfigurationDidChange:) name:NSApplicationDidChangeScreenParametersNotification object:nil];
  
  /* If we don't do this, Cocoa will muck around with our window positioning */
  self.shouldCascadeWindows = NO;
  
  _systemCursorVisibility = YES;
  
  return self;
}


- (void)dealloc
{
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
  
  self.currentCursor = self.currentTool.cursor;
  
  self.active = NO;
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
  } else {
    self.window.isVisible = NO;
  }
  
  _display = display;
}


- (void)screenConfigurationDidChange:(NSNotification *)notification
{
  self.display = _display;
}


- (PTDTool *)currentTool
{
  PTDTool *tool = PTDToolManager.sharedManager.currentTool;
  tool.currentPaintView = self.paintView;
  return tool;
}


- (void)mouseDown:(NSEvent *)event
{
  self.mouseInWindow = YES;
  self.mouseIsDragging = YES;
  self.lastMousePosition = event.locationInWindow;
  
  @autoreleasepool {
    [NSGraphicsContext setCurrentContext:self.paintView.graphicsContext];
    [self.currentTool dragDidStartAtPoint:self.lastMousePosition];
    [NSGraphicsContext setCurrentContext:nil];
  }
  [self updateCursorAtPoint:event.locationInWindow];
  [self.paintView setNeedsDisplay:YES];
}


- (void)mouseUp:(NSEvent *)event
{
  self.mouseInWindow = YES;
  
  if (self.mouseIsDragging) {
    @autoreleasepool {
      [NSGraphicsContext setCurrentContext:self.paintView.graphicsContext];
      [self.currentTool dragDidContinueFromPoint:self.lastMousePosition toPoint:event.locationInWindow];
      [self.currentTool dragDidEndAtPoint:event.locationInWindow];
      [NSGraphicsContext setCurrentContext:nil];
    }
  }
  
  if (event.clickCount == 1) {
    @autoreleasepool {
      [NSGraphicsContext setCurrentContext:self.paintView.graphicsContext];
      [self.currentTool mouseClickedAtPoint:event.locationInWindow];
      [NSGraphicsContext setCurrentContext:nil];
    }
  }
  
  [self updateCursorAtPoint:event.locationInWindow];
  [self.paintView setNeedsDisplay:YES];
  
  self.mouseIsDragging = NO;
}


- (void)rightMouseUp:(NSEvent *)event
{
  self.mouseInWindow = YES;
  
  if (event.clickCount != 1)
    return;
  [self openContextMenuWithEvent:event];
}


- (void)mouseDragged:(NSEvent *)event
{
  self.mouseInWindow = YES;
  
  @autoreleasepool {
    [NSGraphicsContext setCurrentContext:self.paintView.graphicsContext];
    [self.currentTool dragDidContinueFromPoint:self.lastMousePosition toPoint:event.locationInWindow];
    [NSGraphicsContext setCurrentContext:nil];
  }
  [self updateCursorAtPoint:event.locationInWindow];
  [self.paintView setNeedsDisplay:YES];
  
  self.lastMousePosition = event.locationInWindow;
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
  NSMenu *menu = [[NSMenu alloc] init];
  
  NSInteger i = 0;
  for (NSString *toolid in PTDToolManager.sharedManager.availableToolIdentifiers) {
    NSString *label = [PTDToolManager.sharedManager toolNameForIdentifier:toolid];
    NSMenuItem *item = [menu addItemWithTitle:label action:@selector(changeTool:) keyEquivalent:@""];
    item.tag = i;
    if ([toolid isEqual:[[self.currentTool class] toolIdentifier]]) {
      item.state = NSControlStateValueOn;
    }
    i++;
  }
  
  NSMenu *toolMenu = [self.currentTool optionMenu];
  if (toolMenu) {
    [menu addItem:[NSMenuItem separatorItem]];
    NSArray *itemArray = toolMenu.itemArray;
    [toolMenu removeAllItems];
    for (NSMenuItem *item in itemArray) {
      [menu addItem:item];
    }
  }
  
  [menu addItem:[NSMenuItem separatorItem]];
  NSMenuItem *exitItm = [menu addItemWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@""];
  exitItm.target = NSApp;
  
  self.systemCursorVisibility = YES;
  [NSMenu popUpContextMenu:menu withEvent:event forView:self.paintView];
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
    self.window.ignoresMouseEvents = NO;
    [self.window makeKeyAndOrderFront:nil];
  } else {
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


- (void)changeTool:(id)sender
{
  NSArray *tools = PTDToolManager.sharedManager.availableToolIdentifiers;
  NSString *tool = [tools objectAtIndex:[(NSMenuItem *)sender tag]];
  [PTDToolManager.sharedManager changeTool:tool];
}


- (void)cursorDidChange:(NSNotification *)notification
{
  PTDTool *newTool = notification.object;
  self.currentCursor = newTool.cursor;
}


@end
