//
//  PTDBrush.m
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 15/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import "PTDBrush.h"
#import "PTDToolManager.h"
#import "PTDTool.h"


@implementation PTDBrush


- (instancetype)init
{
  self = [super init];
  _size = 2.0;
  _color = [NSColor blackColor];
  return self;
}


- (NSArray <NSMenuItem *> *)menuOptions
{
  NSMutableArray *res = [@[] mutableCopy];
  
  for (int i=2; i<10; i += 2) {
    NSString *title = [NSString stringWithFormat:@"Size %d", i];
    NSMenuItem *mi = [[NSMenuItem alloc] initWithTitle:title action:@selector(changeSize:) keyEquivalent:@""];
    mi.target = self;
    mi.tag = i;
    [res addObject:mi];
  }
  for (int i=10; i<25; i += 5) {
    NSString *title = [NSString stringWithFormat:@"Size %d", i];
    NSMenuItem *mi = [[NSMenuItem alloc] initWithTitle:title action:@selector(changeSize:) keyEquivalent:@""];
    mi.target = self;
    mi.tag = i;
    [res addObject:mi];
  }
  
  [res addObject:[NSMenuItem separatorItem]];
  
  NSArray *colors = @[
    @"Black", @"Red", @"Green", @"Blue", @"Yellow", @"White"
  ];
  int i = 0;
  for (NSString *color in colors) {
    NSMenuItem *mi = [[NSMenuItem alloc] initWithTitle:color action:@selector(changeColor:) keyEquivalent:@""];
    mi.target = self;
    mi.tag = i;
    [res addObject:mi];
    i++;
  }
  
  return [res copy];
}


- (void)changeSize:(id)sender
{
  self.size = [(NSMenuItem *)sender tag];
  
  [PTDToolManager.sharedManager.currentTool brushDidChange];
}


- (void)changeColor:(id)sender
{
  NSArray *colors = @[
    [NSColor blackColor], [NSColor systemRedColor], [NSColor systemGreenColor],
    [NSColor systemBlueColor], [NSColor systemYellowColor], [NSColor whiteColor]
  ];
  self.color = colors[[(NSMenuItem *)sender tag]];
  
  [PTDToolManager.sharedManager.currentTool brushDidChange];
}


@end
