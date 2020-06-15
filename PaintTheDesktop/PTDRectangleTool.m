//
//  PTDRectangleTool.m
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 15/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import "PTDRectangleTool.h"
#import "PTDDrawingSurface.h"
#import "PTDTool.h"
#import "PTDCursor.h"


NSString * const PTDToolIdentifierRectangleTool = @"PTDToolIdentifierRectangleTool";


@interface PTDRectangleTool ()

@property (nonatomic) CGFloat size;
@property (nonatomic) NSColor *color;

@end


@implementation PTDRectangleTool {
  NSRect _currentRect;
}


- (instancetype)init
{
  self = [super init];
  _size = 2.0;
  _color = [NSColor blackColor];
  [self updateCursor];
  return self;
}


+ (NSString *)toolIdentifier
{
  return PTDToolIdentifierRectangleTool;
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
  
  [[NSGraphicsContext currentContext] setCompositingOperation:NSCompositingOperationClear];
  
  NSBezierPath *path = [NSBezierPath bezierPathWithRect:[self normalizedCurrentRect]];
  [path setLineWidth:self.size+1.0];
  [[NSColor colorWithWhite:0.0 alpha:0.0] setStroke];
  [path stroke];
  
  _currentRect.size = NSMakeSize(
      nextPoint.x - _currentRect.origin.x,
      nextPoint.y - _currentRect.origin.y);
  
  [[NSGraphicsContext currentContext] setCompositingOperation:NSCompositingOperationCopy];
  
  path = [NSBezierPath bezierPathWithRect:[self normalizedCurrentRect]];
  [path setLineWidth:self.size];
  [self.color setStroke];
  [path stroke];
}


- (void)dragDidEndAtPoint:(NSPoint)point
{
  [self.currentDrawingSurface beginOverlayDrawing];
  
  [[NSGraphicsContext currentContext] setCompositingOperation:NSCompositingOperationClear];
  
  NSBezierPath *path = [NSBezierPath bezierPathWithRect:[self normalizedCurrentRect]];
  [path setLineWidth:self.size+1.0];
  [[NSColor colorWithWhite:0.0 alpha:0.0] setStroke];
  [path stroke];
  
  _currentRect.size = NSMakeSize(
      point.x - _currentRect.origin.x,
      point.y - _currentRect.origin.y);
  
  [self.currentDrawingSurface beginCanvasDrawing];
  
  path = [NSBezierPath bezierPathWithRect:[self normalizedCurrentRect]];
  [path setLineWidth:self.size];
  [self.color setStroke];
  [path stroke];
}


- (nullable NSMenu *)optionMenu
{
  NSMenu *res = [[NSMenu alloc] init];
  
  for (int i=2; i<10; i += 2) {
    NSString *title = [NSString stringWithFormat:@"Size %d", i];
    NSMenuItem *mi = [res addItemWithTitle:title action:@selector(changeSize:) keyEquivalent:@""];
    mi.target = self;
    mi.tag = i;
  }
  for (int i=10; i<25; i += 5) {
    NSString *title = [NSString stringWithFormat:@"Size %d", i];
    NSMenuItem *mi = [res addItemWithTitle:title action:@selector(changeSize:) keyEquivalent:@""];
    mi.target = self;
    mi.tag = i;
  }
  
  [res addItem:[NSMenuItem separatorItem]];
  
  NSArray *colors = @[
    @"Black", @"Red", @"Green", @"Blue", @"Yellow", @"White"
  ];
  int i = 0;
  for (NSString *color in colors) {
    NSMenuItem *mi = [res addItemWithTitle:color action:@selector(changeColor:) keyEquivalent:@""];
    mi.target = self;
    mi.tag = i;
    i++;
  }
  
  return res;
}


- (void)changeSize:(id)sender
{
  self.size = [(NSMenuItem *)sender tag];
  [self updateCursor];
}


- (void)changeColor:(id)sender
{
  NSArray *colors = @[
    [NSColor blackColor], [NSColor systemRedColor], [NSColor systemGreenColor],
    [NSColor systemBlueColor], [NSColor systemYellowColor], [NSColor whiteColor]
  ];
  self.color = colors[[(NSMenuItem *)sender tag]];
  [self updateCursor];
}


- (void)updateCursor
{
  CGFloat size = floor((self.size + 8.0) / 2.0) * 2.0 + 1.0;
  NSColor *color = self.color;
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
