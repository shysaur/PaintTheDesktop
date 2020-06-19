//
//  PTDRingMenu.m
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 17/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import "PTDRingMenuWindow.h"
#import "PTDRingMenu.h"
#import "PTDRingMenuRing.h"


@implementation PTDRingMenu {
  NSMutableArray <PTDRingMenuRing *> *_rings;
}


- (instancetype)init
{
  self = [super init];
  _rings = [[NSMutableArray alloc] init];
  return self;
}


+ (PTDRingMenu *)ringMenu
{
  return [[PTDRingMenu alloc] init];
}


- (void)addRing:(PTDRingMenuRing *)ring
{
  [_rings addObject:ring];
}


- (void)addRing:(PTDRingMenuRing *)ring inPosition:(NSInteger)pos
{
  [_rings insertObject:ring atIndex:pos];
}


- (PTDRingMenuRing *)newRing
{
  PTDRingMenuRing *ring = [PTDRingMenuRing ring];
  [self addRing:ring];
  return ring;
}


- (NSInteger)ringCount
{
  return _rings.count;
}


- (NSArray <PTDRingMenuRing *> *)rings
{
  return [_rings copy];
}


- (void)removeRingInPosition:(NSInteger)i
{
  [_rings removeObjectAtIndex:i];
}


- (void)popUpMenuWithEvent:(NSEvent *)event forView:(NSView *)view
{
  [self popUpMenuAtLocation:event.locationInWindow inWindow:view.window event:event];
}


- (void)popUpMenuAtLocation:(NSPoint)location inWindow:(NSWindow *)window event:(NSEvent *)event
{
  NSPoint scrPos = location;
  if (window)
    scrPos = [window convertPointToScreen:location];
    
  PTDRingMenuWindow *wc = [[PTDRingMenuWindow alloc] initWithRingMenu:self];
  [window addChildWindow:wc.window ordered:NSWindowAbove];
  [wc positionCenter:scrPos];
  [wc openMenuWithInitialEvent:event];
}


@end
