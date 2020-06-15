//
//  PTDPencilTool.m
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 10/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import "PTDDrawingSurface.h"
#import "PTDPencilTool.h"
#import "PTDTool.h"
#import "PTDCursor.h"


NSString * const PTDToolIdentifierPencilTool = @"PTDToolIdentifierPencilTool";


@interface PTDPencilTool ()

@property (nonatomic) CGFloat size;
@property (nonatomic) NSColor *color;

@end


@implementation PTDPencilTool


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
  return PTDToolIdentifierPencilTool;
}


- (void)dragDidContinueFromPoint:(NSPoint)prevPoint toPoint:(NSPoint)nextPoint
{
  [self.currentDrawingSurface beginCanvasDrawing];
  NSBezierPath *path = [NSBezierPath bezierPath];
  [path setLineCapStyle:NSLineCapStyleRound];
  [path setLineWidth:self.size];
  [self.color setStroke];
  [path moveToPoint:prevPoint];
  [path lineToPoint:nextPoint];
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
  CGFloat size = self.size;
  NSColor *color = self.color;
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
