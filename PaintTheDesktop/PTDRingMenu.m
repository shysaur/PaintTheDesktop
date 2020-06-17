//
//  PTDRingMenu.m
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 17/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import "PTDRingMenuWindow.h"
#import "PTDRingMenu.h"


typedef struct {
  CGFloat angle;
  NSRange itemRange;
} PTDRingMenuGravityData;


@implementation PTDRingMenu {
  NSMutableArray <NSMutableArray *> *_rings;
  NSMutableArray *_gravities;
}


- (instancetype)init
{
  self = [super init];
  _rings = [[NSMutableArray alloc] init];
  _gravities = [[NSMutableArray alloc] init];
  return self;
}


- (NSMutableArray *)_ringAtIndex:(NSInteger)i
{
  while (_rings.count <= i) {
    [self willChangeValueForKey:@"ringCount"];
    [_rings addObject:[[NSMutableArray alloc] init]];
    [_gravities addObject:[NSNull null]];
    [self didChangeValueForKey:@"ringCount"];
  }
  return [_rings objectAtIndex:i];
}


- (void)addItem:(id)item inRing:(NSInteger)ring
{
  [[self _ringAtIndex:ring] addObject:item];
}


- (void)addItem:(id)item inPosition:(NSInteger)i ring:(NSInteger)ring
{
  [[self _ringAtIndex:ring] insertObject:item atIndex:i];
}


- (void)removeItemInPosition:(NSInteger)i ring:(NSInteger)ring
{
  NSMutableArray *ringObj = [self _ringAtIndex:ring];
  [ringObj removeObjectAtIndex:i];
  
  if (ring == _rings.count - 1 && ringObj.count == 0) {
    [self willChangeValueForKey:@"ringCount"];
    [_rings removeObjectAtIndex:ring];
    [_gravities removeObjectAtIndex:ring];
    [self didChangeValueForKey:@"ringCount"];
  }
}


- (void)setGravityAngle:(CGFloat)rad forRing:(NSInteger)ring
{
  NSRange itmRange = NSMakeRange(0, _rings[ring].count);
  [self setGravityAngle:rad forRing:ring itemRange:itmRange];
}


- (void)setGravityAngle:(CGFloat)radians forRing:(NSInteger)ring itemRange:(NSRange)range
{
  PTDRingMenuGravityData gdata;
  gdata.angle = radians;
  gdata.itemRange = range;
  _gravities[ring] = [NSValue valueWithBytes:&gdata objCType:@encode(PTDRingMenuGravityData)];
}


- (void)ring:(NSInteger)ring gravityAngle:(CGFloat *)angle itemRange:(NSRange *)range
{
  PTDRingMenuGravityData gdata;
  if ((NSNull *)_gravities[ring] != [NSNull null]) {
    [_gravities[ring] getValue:&gdata size:sizeof(PTDRingMenuGravityData)];
  } else {
    gdata.angle = 0.0;
    gdata.itemRange = NSMakeRange(0, _rings[ring].count);
  }
  *angle = gdata.angle;
  *range = gdata.itemRange;
}


- (NSInteger)ringCount
{
  return _rings.count;
}


- (NSArray *)itemArray
{
  NSMutableArray *res = [NSMutableArray array];
  for (NSMutableArray *ring in _rings) {
    [res addObjectsFromArray:ring];
  }
  return [res copy];
}


- (NSArray *)itemArrayForRing:(NSInteger)ring
{
  return [[_rings objectAtIndex:ring] copy];
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
