//
//  PTDPaintWindow.m
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 08/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import "PTDPaintWindow.h"
#import "PTDPaintView.h"


@interface PTDPaintWindow ()

@property IBOutlet PTDPaintView *paintView;

@property (nonatomic) BOOL mouseIsDragging;
@property (nonatomic) NSPoint lastMousePosition;

@end


@implementation PTDPaintWindow


- (NSString *)windowNibName
{
  return @"PTDPaintWindow";
}


- (void)mouseDown:(NSEvent *)event
{
  self.mouseIsDragging = YES;
  self.lastMousePosition = NSEvent.mouseLocation;
}


- (void)mouseUp:(NSEvent *)event
{
  if (self.mouseIsDragging) {
    [self mouseDraggedFromPoint:self.lastMousePosition toPoint:NSEvent.mouseLocation];
  }
  self.mouseIsDragging = NO;
}


- (void)mouseDragged:(NSEvent *)event
{
  [self mouseDraggedFromPoint:self.lastMousePosition toPoint:NSEvent.mouseLocation];
  self.lastMousePosition = NSEvent.mouseLocation;
}


- (void)mouseDraggedFromPoint:(NSPoint)absP1 toPoint:(NSPoint)absP2
{
  NSPoint p1 = [self.window convertPointFromScreen:absP1];
  NSPoint p2 = [self.window convertPointFromScreen:absP2];
  [NSGraphicsContext setCurrentContext:self.paintView.graphicsContext];
  NSBezierPath *path = [NSBezierPath bezierPath];
  [[NSColor blackColor] setStroke];
  [path moveToPoint:p1];
  [path lineToPoint:p2];
  [path stroke];
  

  [self.paintView setNeedsDisplay:YES];
}


- (void)windowDidLoad
{
  [super windowDidLoad];
  
  //self.window.backgroundColor = [NSColor colorWithWhite:1.0 alpha:0.0];
  //self.window.opaque = NO;
  //self.window.hasShadow = NO;
  //self.window.ignoresMouseEvents = YES;
  //self.window.level = NSStatusWindowLevel;
  
  [NSGraphicsContext setCurrentContext:self.paintView.graphicsContext];
  NSBezierPath *path = [NSBezierPath bezierPath];
  NSRect rect = self.paintView.paintRect;
  [path moveToPoint:NSMakePoint(rect.origin.x, rect.origin.y)];
  [path lineToPoint:NSMakePoint(NSMaxX(rect), NSMaxY(rect))];
  [path moveToPoint:NSMakePoint(NSMaxX(rect), rect.origin.y)];
  [path lineToPoint:NSMakePoint(rect.origin.x, NSMaxY(rect))];
  [[NSColor blackColor] setStroke];
  [path stroke];
  [self.paintView setNeedsDisplay:YES];
}


@end
