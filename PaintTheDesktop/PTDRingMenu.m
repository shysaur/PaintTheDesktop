//
// PTDRingMenu.m
// PaintTheDesktop -- Created on 17/06/2020.
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
