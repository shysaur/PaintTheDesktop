//
//  PTDEraserTool.m
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 10/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import "PTDDrawingSurface.h"
#import "PTDEraserTool.h"
#import "PTDTool.h"
#import "PTDCursor.h"


NSString * const PTDToolIdentifierEraserTool = @"PTDToolIdentifierEraserTool";


@interface PTDEraserTool ()

@property (nonatomic) CGFloat size;

@end


@implementation PTDEraserTool


- (instancetype)init
{
  self = [super init];
  _size = 20.0;
  return self;
}


+ (NSString *)toolIdentifier
{
  return PTDToolIdentifierEraserTool;
}


- (void)activate
{
  [self updateCursor];
}


- (void)dragDidContinueFromPoint:(NSPoint)prevPoint toPoint:(NSPoint)nextPoint
{
  [self.currentDrawingSurface beginCanvasDrawing];
  [[NSGraphicsContext currentContext] setCompositingOperation:NSCompositingOperationClear];

  [[NSColor colorWithWhite:1.0 alpha:0.0] setFill];
  
  NSRect origRect = NSMakeRect(prevPoint.x-_size/2, prevPoint.y-_size/2, _size, _size);
  NSRect destRect = NSMakeRect(nextPoint.x-_size/2, nextPoint.y-_size/2, _size, _size);
  NSPoint joinP1, joinP2, joinP3, joinP4;
  if ((nextPoint.x - prevPoint.x) * (nextPoint.y - prevPoint.y) > 0) {
    joinP1 = NSMakePoint(NSMinX(origRect), NSMaxY(origRect));
    joinP2 = NSMakePoint(NSMinX(destRect), NSMaxY(destRect));
    joinP3 = NSMakePoint(NSMaxX(destRect), NSMinY(destRect));
    joinP4 = NSMakePoint(NSMaxX(origRect), NSMinY(origRect));
  } else {
    joinP1 = NSMakePoint(NSMinX(origRect), NSMinY(origRect));
    joinP2 = NSMakePoint(NSMinX(destRect), NSMinY(destRect));
    joinP3 = NSMakePoint(NSMaxX(destRect), NSMaxY(destRect));
    joinP4 = NSMakePoint(NSMaxX(origRect), NSMaxY(origRect));
  }
  
  NSRectFill(origRect);
  NSRectFill(destRect);
  NSBezierPath *path = [NSBezierPath bezierPath];
  [path moveToPoint:joinP1];
  [path lineToPoint:joinP2];
  [path lineToPoint:joinP3];
  [path lineToPoint:joinP4];
  [path closePath];
  [path fill];
}


- (NSArray <NSMenuItem *> *)optionMenu
{
  NSMutableArray *res = [@[] mutableCopy];
  
  for (int i=20; i<200; i += 50) {
    NSString *title = [NSString stringWithFormat:@"Size %d", i];
    NSMenuItem *mi = [[NSMenuItem alloc] initWithTitle:title action:@selector(changeSize:) keyEquivalent:@""];
    mi.target = self;
    mi.tag = i;
    [res addObject:mi];
  }
  
  return res;
}


- (void)changeSize:(id)sender
{
  self.size = [(NSMenuItem *)sender tag];
  [self updateCursor];
}


- (void)updateCursor
{
  CGFloat size = self.size;
  PTDCursor *cursor = [[PTDCursor alloc] init];
  
  cursor.image = [NSImage
      imageWithSize:NSMakeSize(size, size)
      flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
    NSRect squareRect = NSMakeRect(0.5, 0.5, size-1.0, size-1.0);
    NSBezierPath *bp = [NSBezierPath bezierPathWithRect:squareRect];
    [[NSColor whiteColor] setFill];
    [bp fill];
    [[NSColor blackColor] setStroke];
    [bp stroke];
    return YES;
  }];
  cursor.hotspot = NSMakePoint(size/2, size/2);
  
  self.cursor = cursor;
}


@end

