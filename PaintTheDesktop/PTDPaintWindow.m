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
#import "PTDPencilTool.h"


@interface PTDPaintWindow ()

@property IBOutlet PTDPaintView *paintView;

@property (nonatomic) BOOL mouseIsDragging;
@property (nonatomic) NSPoint lastMousePosition;

@end


@implementation PTDPaintWindow


- (instancetype)initWithScreen:(NSScreen *)screen
{
  self = [super init];
  _screen = screen;
  _currentTool = [[PTDPencilTool alloc] init];
  return self;
}


- (NSString *)windowNibName
{
  return @"PTDPaintWindow";
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


@end
