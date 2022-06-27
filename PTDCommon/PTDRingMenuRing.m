//
// PTDRingMenuRing.m
// PaintTheDesktop -- Created on 19/06/2020.
//
// Copyright (c) 2020 Daniele Cattaneo
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
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
