//
// PTDBrushTool.m
// PaintTheDesktop -- Created on 21/03/2021.
//
// Copyright (c) 2021 Daniele Cattaneo
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

#import "PTDBrushTool.h"
#import "PTDToolOptions.h"


@implementation PTDBrushTool


+ (void)initialize
{
  [PTDToolOptions.sharedOptions registerGlobalDefaults:@{
      @"size": @(2.0),
      @"color": [NSColor blackColor]
    }];
}


- (void)reloadOptions
{
  self.size = [[PTDToolOptions sharedOptions] integerForOption:@"size" ofTool:nil];
  self.color = [[PTDToolOptions sharedOptions] objectForOption:@"color" ofTool:nil];
}


- (nullable PTDRingMenuRing *)optionMenu
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
    NSRect mainRect = NSMakeRect(3, 3, 16-6, 16-6);
    [color setFill];
    NSBezierPath *bp = [NSBezierPath bezierPathWithOvalInRect:mainRect];
    [bp fill];
    
    NSRect borderRect = NSInsetRect(mainRect, 0.5, 0.5);
    NSColor *borderColor = [NSColor blackColor];
    if (@available(macOS 10.14, *)) {
      if ([[NSAppearance.currentAppearance
          bestMatchFromAppearancesWithNames:
            @[NSAppearanceNameDarkAqua, NSAppearanceNameAqua]]
          isEqual:NSAppearanceNameDarkAqua]) {
        borderColor = [NSColor whiteColor];
      }
    }
    borderColor = [borderColor colorWithAlphaComponent:0.5];
    NSBezierPath *border = [NSBezierPath bezierPathWithOvalInRect:borderRect];
    [borderColor setStroke];
    [border stroke];
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
      NSBezierPath *bp = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect((imageSize - size) / 2.0, (imageSize - size) / 2.0, size, size)];
      [bp stroke];
      return YES;
    }];
  } else {
    CGFloat imageSize = threshold+minBorder;
    NSMutableParagraphStyle *parastyle = [[NSMutableParagraphStyle alloc] init];
    parastyle.alignment = NSTextAlignmentCenter;
    NSDictionary *attrib = @{
        NSParagraphStyleAttributeName: parastyle,
        NSFontAttributeName: [NSFont systemFontOfSize:12.0]};
    NSString *sizeStr = [NSString stringWithFormat:@"%d", (int)size];
    NSRect realSizeRect = [sizeStr boundingRectWithSize:NSMakeSize(imageSize, imageSize) options:0 attributes:attrib context:nil];
    
    img = [NSImage imageWithSize:NSMakeSize(imageSize, imageSize) flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
      [[NSColor blackColor] setStroke];
      NSBezierPath *bp = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(minBorder/2.0-0.5, minBorder/2.0-0.5, threshold+1, threshold+1)];
      [bp stroke];
      [sizeStr drawInRect:NSMakeRect(0, (imageSize-realSizeRect.size.height)/2.0, imageSize, realSizeRect.size.height) withAttributes:attrib];
      return YES;
    }];
  }
  img.template = YES;
  
  PTDRingMenuItem *itm = [PTDRingMenuItem itemWithImage:img target:self action:@selector(changeSize:)];
  itm.tag = size;
  if (size == _size)
    itm.state = NSControlStateValueOn;
  return itm;
}


- (void)changeSize:(id)sender
{
  [[PTDToolOptions sharedOptions] setInteger:[(NSMenuItem *)sender tag] forOption:@"size" ofTool:nil];
}


- (void)changeColor:(id)sender
{
  [[PTDToolOptions sharedOptions] setObject:sender forOption:@"color" ofTool:nil];
}


@end