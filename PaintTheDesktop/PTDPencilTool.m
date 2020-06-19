//
//  PTDPencilTool.m
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 10/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import "PTDToolManager.h"
#import "PTDBrush.h"
#import "PTDPencilTool.h"
#import "PTDDrawingSurface.h"
#import "PTDTool.h"
#import "PTDCursor.h"


NSString * const PTDToolIdentifierPencilTool = @"PTDToolIdentifierPencilTool";


@implementation PTDPencilTool


+ (NSString *)toolIdentifier
{
  return PTDToolIdentifierPencilTool;
}


- (void)activate
{
  [self updateCursor];
}


- (void)dragDidContinueFromPoint:(NSPoint)prevPoint toPoint:(NSPoint)nextPoint
{
  [self.currentDrawingSurface beginCanvasDrawing];
  NSBezierPath *path = [NSBezierPath bezierPath];
  [path setLineCapStyle:NSLineCapStyleRound];
  [path setLineWidth:PTDToolManager.sharedManager.currentBrush.size];
  [PTDToolManager.sharedManager.currentBrush.color setStroke];
  [path moveToPoint:prevPoint];
  [path lineToPoint:nextPoint];
  [path stroke];
}


- (PTDRingMenuRing *)optionMenu
{
  return [PTDToolManager.sharedManager.currentBrush menuOptions];
}


- (void)brushDidChange
{
  [self updateCursor];
}


- (void)updateCursor
{
  CGFloat size = PTDToolManager.sharedManager.currentBrush.size;
  NSColor *color = PTDToolManager.sharedManager.currentBrush.color;
  PTDCursor *cursor = [[PTDCursor alloc] init];
  
  cursor.image = [NSImage
      imageWithSize:NSMakeSize(size, size)
      flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
    NSRect circleRect = NSMakeRect(0.5, 0.5, size-1.0, size-1.0);
    [color setStroke];
    NSBezierPath *circle = [NSBezierPath bezierPathWithOvalInRect:circleRect];
    [circle stroke];
    return YES;
  }];
  cursor.hotspot = NSMakePoint(size/2, size/2);
  
  self.cursor = cursor;
}


@end
