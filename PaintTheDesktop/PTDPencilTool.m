//
//  PTDPencilTool.m
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 10/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import "PTDPencilTool.h"
#import "PTDTool.h"


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
  return self;
}


- (void)dragDidStartAtPoint:(NSPoint)point
{
}


- (void)dragDidContinueFromPoint:(NSPoint)prevPoint toPoint:(NSPoint)nextPoint
{
  NSBezierPath *path = [NSBezierPath bezierPath];
  [path setLineCapStyle:NSLineCapStyleRound];
  [path setLineWidth:self.size];
  [self.color setStroke];
  [path moveToPoint:prevPoint];
  [path lineToPoint:nextPoint];
  [path stroke];
}


- (void)dragDidEndAtPoint:(NSPoint)point
{
}


- (void)deactivate
{
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
}


- (void)changeColor:(id)sender
{
  NSArray *colors = @[
    [NSColor blackColor], [NSColor systemRedColor], [NSColor systemGreenColor],
    [NSColor systemBlueColor], [NSColor systemYellowColor], [NSColor whiteColor]
  ];
  self.color = colors[[(NSMenuItem *)sender tag]];
}


@end
