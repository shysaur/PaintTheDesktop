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


@interface PTDPaintWindow ()

@property IBOutlet PTDPaintView *paintView;

@property (nonatomic) BOOL mouseIsDragging;
@property (nonatomic) NSPoint lastMousePosition;

@property (nonatomic, nullable, readonly) id <PTDTool> currentTool;

@end


@implementation PTDPaintWindow


- (instancetype)initWithScreen:(NSScreen *)screen
{
  self = [super init];
  _screen = screen;
  return self;
}


- (NSString *)windowNibName
{
  return @"PTDPaintWindow";
}


- (void)windowDidLoad
{
  [super windowDidLoad];
  
  [self.window setFrame:self.screen.frame display:YES animate:NO];
  
  self.window.backgroundColor = [NSColor colorWithWhite:1.0 alpha:0.0];
  self.window.opaque = NO;
  self.window.hasShadow = NO;
  self.window.level = kCGMaximumWindowLevelKey;
  self.window.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorFullScreenAuxiliary;
  
  self.active = NO;
}


- (id <PTDTool>)currentTool
{
  return PTDToolManager.sharedManager.currentTool;
}


- (void)mouseDown:(NSEvent *)event
{
  self.mouseIsDragging = YES;
  self.lastMousePosition = event.locationInWindow;
  
  [NSGraphicsContext setCurrentContext:self.paintView.graphicsContext];
  [self.currentTool dragDidStartAtPoint:self.lastMousePosition];
  [self.paintView setNeedsDisplay:YES];
}


- (void)mouseUp:(NSEvent *)event
{
  if (self.mouseIsDragging) {
    [NSGraphicsContext setCurrentContext:self.paintView.graphicsContext];
    [self.currentTool dragDidContinueFromPoint:self.lastMousePosition toPoint:event.locationInWindow];
    [self.currentTool dragDidEndAtPoint:event.locationInWindow];
    [self.paintView setNeedsDisplay:YES];
  }
  self.mouseIsDragging = NO;
}


- (void)rightMouseUp:(NSEvent *)event
{
  if (event.clickCount != 1)
    return;
  
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
  
  [NSMenu popUpContextMenu:menu withEvent:event forView:self.paintView];
}


- (void)mouseDragged:(NSEvent *)event
{
  [NSGraphicsContext setCurrentContext:self.paintView.graphicsContext];
  [self.currentTool dragDidContinueFromPoint:self.lastMousePosition toPoint:event.locationInWindow];
  [self.paintView setNeedsDisplay:YES];
  
  self.lastMousePosition = event.locationInWindow;
}


- (void)setActive:(BOOL)active
{
  if (active) {
    self.window.ignoresMouseEvents = NO;
    [self.window makeKeyAndOrderFront:self];
  } else {
    self.window.ignoresMouseEvents = YES;
  }
  _active = active;
}


- (void)changeTool:(id)sender
{
  NSArray *tools = PTDToolManager.sharedManager.availableToolIdentifiers;
  NSString *tool = [tools objectAtIndex:[(NSMenuItem *)sender tag]];
  [PTDToolManager.sharedManager changeTool:tool];
}


@end
