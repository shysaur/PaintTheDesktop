//
//  PTDRingMenuRing.m
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 19/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import "PTDRingMenuRing.h"
#import "PTDRingMenuItem.h"
#import "PTDRingMenuSpring.h"


@implementation PTDRingMenuRing {
  NSMutableArray *_items;
}


- (instancetype)init
{
  self = [super init];
  _items = [[NSMutableArray alloc] init];
  return self;
}


+ (PTDRingMenuRing *)ring
{
  return [[PTDRingMenuRing alloc] init];
}


- (void)addItem:(id)item
{
  [_items addObject:item];
}


- (void)addItem:(id)item inPosition:(NSInteger)i
{
  [_items insertObject:item atIndex:i];
}


- (PTDRingMenuItem *)addItemWithImage:(NSImage *)image target:(id)target action:(SEL)action
{
  PTDRingMenuItem *itm = [[PTDRingMenuItem alloc] init];
  itm.image = image;
  itm.target = target;
  itm.action = action;
  [self addItem:itm];
  return itm;
}


- (PTDRingMenuItem *)addItemWithText:(NSString *)text target:(id)target action:(SEL)action
{
  PTDRingMenuItem *itm = [[PTDRingMenuItem alloc] init];
  [itm setText:text];
  itm.target = target;
  itm.action = action;
  [self addItem:itm];
  return itm;
}


- (PTDRingMenuSpring *)addSpringWithElasticity:(CGFloat)k
{
  PTDRingMenuSpring *itm = [[PTDRingMenuSpring alloc] init];
  itm.elasticConstant = k;
  [self addItem:itm];
  return itm;
}


- (void)removeItemInPosition:(NSInteger)i
{
  [_items removeObjectAtIndex:i];
}


- (void)beginGravityMassGroupWithAngle:(CGFloat)angle
{
  self.gravityAngle = angle;
  _gravityMass.location = _items.count;
}


- (void)endGravityMassGroup
{
  NSInteger length = _items.count - _gravityMass.location;
  self.gravityMass = NSMakeRange(_gravityMass.location, length);
}


- (NSInteger)itemCount
{
  return _items.count;
}


- (NSArray *)itemArray
{
  return [_items copy];
}


@end
