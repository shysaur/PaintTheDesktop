//
//  PTDRectangleTool.m
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 15/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import "PTDToolManager.h"
#import "PTDBrush.h"
#import "PTDRectangleTool.h"
#import "PTDDrawingSurface.h"
#import "PTDTool.h"
#import "PTDCursor.h"


NSString * const PTDToolIdentifierRectangleTool = @"PTDToolIdentifierRectangleTool";


@implementation PTDRectangleTool {
  NSRect _currentRect;
}


+ (NSString *)toolIdentifier
{
  return PTDToolIdentifierRectangleTool;
}


- (void)activate
{
  [self updateCursor];
}


- (NSRect)normalizedCurrentRect
{
  NSRect result = _currentRect;
  if (result.size.width < 0) {
    result.origin.x += result.size.width;
    result.size.width = -result.size.width;
  }
  if (result.size.height < 0) {
    result.origin.y += result.size.height;
    result.size.height = -result.size.height;
  }
  return result;
}


- (void)dragDidStartAtPoint:(NSPoint)point
{
  _currentRect = (NSRect){point, NSZeroSize};
  [self dragDidContinueFromPoint:point toPoint:point];
}


- (void)dragDidContinueFromPoint:(NSPoint)prevPoint toPoint:(NSPoint)nextPoint
{
  [self.currentDrawingSurface beginOverlayDrawing];
  [NSGraphicsContext.currentContext setShouldAntialias:NO];
  
  [[NSGraphicsContext currentContext] setCompositingOperation:NSCompositingOperationClear];
  
  NSBezierPath *path = [NSBezierPath bezierPathWithRect:[self normalizedCurrentRect]];
  [path setLineWidth:PTDToolManager.sharedManager.currentBrush.size+2.0];
  [[NSColor colorWithWhite:0.0 alpha:0.0] setStroke];
  [path stroke];
  
  _currentRect.size = NSMakeSize(
      nextPoint.x - _currentRect.origin.x,
      nextPoint.y - _currentRect.origin.y);
  
  [[NSGraphicsContext currentContext] setCompositingOperation:NSCompositingOperationCopy];
  
  path = [NSBezierPath bezierPathWithRect:[self normalizedCurrentRect]];
  [path setLineWidth:PTDToolManager.sharedManager.currentBrush.size];
  [PTDToolManager.sharedManager.currentBrush.color setStroke];
  [path stroke];
}


- (void)dragDidEndAtPoint:(NSPoint)point
{
  [self.currentDrawingSurface beginOverlayDrawing];
  [NSGraphicsContext.currentContext setShouldAntialias:NO];
  
  [[NSGraphicsContext currentContext] setCompositingOperation:NSCompositingOperationClear];
  
  NSBezierPath *path = [NSBezierPath bezierPathWithRect:[self normalizedCurrentRect]];
  [path setLineWidth:PTDToolManager.sharedManager.currentBrush.size+2.0];
  [[NSColor colorWithWhite:0.0 alpha:0.0] setStroke];
  [path stroke];
  
  _currentRect.size = NSMakeSize(
      point.x - _currentRect.origin.x,
      point.y - _currentRect.origin.y);
  
  [self.currentDrawingSurface beginCanvasDrawing];
  [NSGraphicsContext.currentContext setShouldAntialias:YES];
  
  path = [NSBezierPath bezierPathWithRect:[self normalizedCurrentRect]];
  [path setLineWidth:PTDToolManager.sharedManager.currentBrush.size];
  [PTDToolManager.sharedManager.currentBrush.color setStroke];
  [path stroke];
}


- (PTDRingMenuRing *)optionMenu
{
  return PTDToolManager.sharedManager.currentBrush.menuOptions;
}


- (void)brushDidChange
{
  [self updateCursor];
}


- (void)updateCursor
{
  CGFloat size = floor((PTDToolManager.sharedManager.currentBrush.size + 8.0) / 2.0) * 2.0 + 1.0;
  NSColor *color = PTDToolManager.sharedManager.currentBrush.color;
  PTDCursor *cursor = [[PTDCursor alloc] init];
  
  cursor.image = [NSImage
      imageWithSize:NSMakeSize(size, size)
      flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
    [color setStroke];
    NSBezierPath *cross = [NSBezierPath bezierPath];
    [cross moveToPoint:NSMakePoint(0, size/2)];
    [cross lineToPoint:NSMakePoint(size, size/2)];
    [cross moveToPoint:NSMakePoint(size/2, 0)];
    [cross lineToPoint:NSMakePoint(size/2, size)];
    [cross stroke];
    return YES;
  }];
  cursor.hotspot = NSMakePoint(size/2, size/2);
  
  self.cursor = cursor;
}


@end
