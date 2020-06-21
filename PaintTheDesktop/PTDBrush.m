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
    PTDRingMenuItem *item = [self menuItemForBrushSize:i];
    [res addItem:item];
  }
  for (int i=10; i<25; i += 5) {
    PTDRingMenuItem *item = [self menuItemForBrushSize:i];
    [res addItem:item];
  }
  [res endGravityMassGroup];
  
  [res addSpringWithElasticity:0.5];
  
  NSArray *colors = @[
    [NSColor blackColor], [NSColor systemRedColor], [NSColor systemGreenColor],
    [NSColor systemBlueColor], [NSColor systemYellowColor], [NSColor whiteColor]
  ];
  for (NSColor *color in colors) {
    PTDRingMenuItem *item = [self menuItemForBrushColor:color];
    [res addItem:item];
  }
  
  [res addSpringWithElasticity:0.5];
  return res;
}


- (PTDRingMenuItem *)menuItemForBrushColor:(NSColor *)color
{
  NSImage *img = [NSImage imageWithSize:NSMakeSize(16, 16) flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
    [[color blendedColorWithFraction:0.5 ofColor:[NSColor blackColor]] setStroke];
    [color setFill];
    NSBezierPath *bp = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(3, 3, 16-6, 16-6)];
    [bp fill];
    [bp stroke];
    return YES;
  }];
  PTDRingMenuItem *itm = [PTDRingMenuItem itemWithImage:img target:self action:@selector(changeColor:)];
  itm.representedObject = color;
  if ([color isEqual:_color])
    itm.state = NSControlStateValueOn;
  return itm;
}


- (PTDRingMenuItem *)menuItemForBrushSize:(CGFloat)size
{
  NSImage *img;
  const CGFloat threshold = 16.0;
  const CGFloat minBorder = 4.0;
  const CGFloat maxBorder = 8.0;
  
  if (size < threshold) {
    CGFloat imageSize = round(minBorder + (maxBorder - minBorder) * (threshold-size)/threshold) + size;
    img = [NSImage imageWithSize:NSMakeSize(imageSize, imageSize) flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
      [[NSColor blackColor] setStroke];
      [[NSColor whiteColor] setFill];
      NSBezierPath *bp = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect((imageSize - size) / 2.0, (imageSize - size) / 2.0, size, size)];
      [bp fill];
      [bp stroke];
      return YES;
    }];
  } else {
    CGFloat imageSize = threshold+minBorder;
    NSMutableParagraphStyle *parastyle = [[NSMutableParagraphStyle alloc] init];
    parastyle.alignment = NSTextAlignmentCenter;
    NSDictionary *attrib = @{NSParagraphStyleAttributeName: parastyle};
    NSString *sizeStr = [NSString stringWithFormat:@"%d", (int)size];
    NSRect realSizeRect = [sizeStr boundingRectWithSize:NSMakeSize(imageSize, imageSize) options:0 attributes:attrib context:nil];
    
    img = [NSImage imageWithSize:NSMakeSize(imageSize, imageSize) flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
      [[NSColor blackColor] setStroke];
      [[NSColor whiteColor] setFill];
      NSBezierPath *bp = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(minBorder/2.0-0.5, minBorder/2.0-0.5, threshold+1, threshold+1)];
      [bp fill];
      [bp stroke];
      [sizeStr drawInRect:NSMakeRect(0, (imageSize-realSizeRect.size.height)/2.0, imageSize, realSizeRect.size.height) withAttributes:attrib];
      return YES;
    }];
  }
  
  PTDRingMenuItem *itm = [PTDRingMenuItem itemWithImage:img target:self action:@selector(changeSize:)];
  itm.tag = size;
  if (size == _size)
    itm.state = NSControlStateValueOn;
  return itm;
}


- (void)changeSize:(id)sender
{
  self.size = [(NSMenuItem *)sender tag];
  [PTDToolManager.sharedManager.currentTool brushDidChange];
}


- (void)changeColor:(id)sender
{
  self.color = sender;
  [PTDToolManager.sharedManager.currentTool brushDidChange];
}


@end
