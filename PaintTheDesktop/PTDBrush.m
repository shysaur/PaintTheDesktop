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


- (PTDRingMenuRing *)menuOptions
{
  PTDRingMenuRing *res = [PTDRingMenuRing ring];
  
  [res beginGravityMassGroupWithAngle:M_PI_2];
  for (int i=2; i<10; i += 2) {
    NSString *title = [NSString stringWithFormat:@"Size %d", i];
    PTDRingMenuItem *item = [res addItemWithText:title target:self action:@selector(changeSize:)];
    item.tag = i;
  }
  for (int i=10; i<25; i += 5) {
    NSString *title = [NSString stringWithFormat:@"Size %d", i];
    PTDRingMenuItem *item = [res addItemWithText:title target:self action:@selector(changeSize:)];
    item.tag = i;
  }
  [res endGravityMassGroup];
  
  [res addSpringWithElasticity:0.5];
  
  NSArray *colors = @[
    @"Black", @"Red", @"Green", @"Blue", @"Yellow", @"White"
  ];
  int i = 0;
  for (NSString *color in colors) {
    PTDRingMenuItem *item = [res addItemWithText:color target:self action:@selector(changeColor:)];
    item.tag = i;
    i++;
  }
  
  [res addSpringWithElasticity:0.5];
  return res;
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
