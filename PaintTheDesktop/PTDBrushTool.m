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
#import "PTDGraphics.h"


NSString * const PTDBrushToolOptionSize = @"brushSize";
NSString * const PTDBrushToolOptionColor = @"brushColor";
NSString * const PTDBrushToolOptionColorOptions = @"brushColorOptions";
NSString * const PTDBrushToolOptionSizeOptions = @"brushSizeOptions";


@implementation PTDBrushTool


+ (void)initialize
{
  PTDToolOptions *o = PTDToolOptions.sharedOptions;
  
  [o registerGlobalOption:PTDBrushToolOptionSize types:@[[NSNumber class]] defaultValue:@(2.0) validationBlock:nil];
  [o registerGlobalOption:PTDBrushToolOptionColor types:@[[NSColor class]] defaultValue:[NSColor blackColor] validationBlock:nil];
  
  [o registerGlobalOption:PTDBrushToolOptionColorOptions types:@[[NSArray class], [NSColor class]] defaultValue:@[
      [NSColor blackColor], [NSColor systemRedColor], [NSColor systemGreenColor],
      [NSColor systemBlueColor], [NSColor systemYellowColor], [NSColor whiteColor]
    ] validationBlock:^BOOL(id  _Nonnull value) {
      if (![value isKindOfClass:[NSArray class]])
        return NO;
      NSArray *a = (NSArray *)value;
      for (id v in a) {
        if (![v isKindOfClass:[NSColor class]])
          return NO;
      }
      return YES;
    }];
  [o registerGlobalOption:PTDBrushToolOptionSizeOptions types:@[[NSArray class], [NSColor class]] defaultValue:@[
      @(2), @(4), @(6), @(8), @(10), @(15), @(20)
    ] validationBlock:^BOOL(id  _Nonnull value) {
      if (![value isKindOfClass:[NSArray class]])
        return NO;
      NSArray *a = (NSArray *)value;
      for (id v in a) {
        if (![v isKindOfClass:[NSNumber class]])
          return NO;
      }
      return YES;
    }];
}


+ (NSArray <NSColor *> *)defaultColors
{
  return [PTDToolOptions.sharedOptions objectForOption:PTDBrushToolOptionColorOptions ofTool:nil];
}


+ (void)setDefaultColors:(NSArray<NSColor *> *)defaultColors
{
  if (!defaultColors)
    [PTDToolOptions.sharedOptions restoreDefaultForOption:PTDBrushToolOptionColorOptions ofTool:nil];
  else
    [PTDToolOptions.sharedOptions setObject:defaultColors forOption:PTDBrushToolOptionColorOptions ofTool:nil];
}


+ (NSArray <NSNumber *> *)defaultSizes
{
  return [PTDToolOptions.sharedOptions objectForOption:PTDBrushToolOptionSizeOptions ofTool:nil];
}


+ (void)setDefaultSizes:(NSArray<NSNumber *> *)defaultSizes
{
  if (!defaultSizes)
    [PTDToolOptions.sharedOptions restoreDefaultForOption:PTDBrushToolOptionSizeOptions ofTool:nil];
  else
    [PTDToolOptions.sharedOptions setObject:defaultSizes forOption:PTDBrushToolOptionSizeOptions ofTool:nil];
}


- (void)reloadOptions
{
  self.size = [[[PTDToolOptions sharedOptions] objectForOption:PTDBrushToolOptionSize ofTool:nil] integerValue];
  self.color = [[PTDToolOptions sharedOptions] objectForOption:PTDBrushToolOptionColor ofTool:nil];
}


- (nullable PTDRingMenuRing *)optionMenu
{
  PTDRingMenuRing *res = [PTDRingMenuRing ring];
  
  [res beginGravityMassGroupWithAngle:M_PI_2];
  NSArray <NSNumber *> *sizes = [[PTDToolOptions sharedOptions] objectForOption:PTDBrushToolOptionSizeOptions ofTool:nil];
  for (NSNumber *size in sizes) {
    PTDRingMenuItem *item = [self menuItemForBrushSize:size.integerValue];
    [res addItem:item];
  }
  [res endGravityMassGroup];
  
  [res addSpringWithElasticity:0.5];
  
  NSArray <NSColor *> *colors = [[PTDToolOptions sharedOptions] objectForOption:PTDBrushToolOptionColorOptions ofTool:nil];
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
    PTDDrawCircularColorSwatch(NSMakeRect(3, 3, 16-6, 16-6), color);
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
  [[PTDToolOptions sharedOptions] setObject:@([(NSMenuItem *)sender tag]) forOption:PTDBrushToolOptionSize ofTool:nil];
}


- (void)changeColor:(id)sender
{
  [[PTDToolOptions sharedOptions] setObject:sender forOption:PTDBrushToolOptionColor ofTool:nil];
}


@end
