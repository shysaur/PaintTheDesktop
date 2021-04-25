//
// PTDEraserTool.m
// PaintTheDesktop -- Created on 10/06/2020.
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

#import "PTDDrawingSurface.h"
#import "PTDEraserTool.h"
#import "PTDTool.h"
#import "PTDCursor.h"
#import "PTDToolOptions.h"


NSString * const PTDToolIdentifierEraserTool = @"PTDToolIdentifierEraserTool";

NSString * const PTDEraserToolOptionSize = @"size";
NSString * const PTDEraserToolOptionSizeOptions = @"sizes";


@interface PTDEraserTool ()

@property (nonatomic) CGFloat size;

@end


@implementation PTDEraserTool


+ (void)initialize
{
  PTDToolOptions *o = PTDToolOptions.sharedOptions;
  [o registerOption:PTDEraserToolOptionSize ofToolClass:self types:@[[NSNumber class]] defaultValue:@(20) validationBlock:nil];
  
  [o registerOption:PTDEraserToolOptionSizeOptions ofToolClass:self types:@[[NSArray class], [NSNumber class]] defaultValue:@[
      @(20), @(70), @(120), @(170)
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


- (void)reloadOptions
{
  self.size = [[[PTDToolOptions sharedOptions] objectForOption:PTDEraserToolOptionSize ofToolClass:self.class] integerValue];
  [self updateCursor];
}


+ (NSString *)toolIdentifier
{
  return PTDToolIdentifierEraserTool;
}


- (void)activate
{
  [self updateCursor];
}


- (void)dragDidContinueFromPoint:(NSPoint)prevPoint toPoint:(NSPoint)nextPoint
{
  [self.currentDrawingSurface beginCanvasDrawing];
  [[NSGraphicsContext currentContext] setCompositingOperation:NSCompositingOperationClear];

  [[NSColor colorWithWhite:1.0 alpha:0.0] setFill];
  
  NSRect origRect = NSMakeRect(prevPoint.x-_size/2, prevPoint.y-_size/2, _size, _size);
  NSRect destRect = NSMakeRect(nextPoint.x-_size/2, nextPoint.y-_size/2, _size, _size);
  NSPoint joinP1, joinP2, joinP3, joinP4;
  if ((nextPoint.x - prevPoint.x) * (nextPoint.y - prevPoint.y) > 0) {
    joinP1 = NSMakePoint(NSMinX(origRect), NSMaxY(origRect));
    joinP2 = NSMakePoint(NSMinX(destRect), NSMaxY(destRect));
    joinP3 = NSMakePoint(NSMaxX(destRect), NSMinY(destRect));
    joinP4 = NSMakePoint(NSMaxX(origRect), NSMinY(origRect));
  } else {
    joinP1 = NSMakePoint(NSMinX(origRect), NSMinY(origRect));
    joinP2 = NSMakePoint(NSMinX(destRect), NSMinY(destRect));
    joinP3 = NSMakePoint(NSMaxX(destRect), NSMaxY(destRect));
    joinP4 = NSMakePoint(NSMaxX(origRect), NSMaxY(origRect));
  }
  
  NSRectFill(origRect);
  NSRectFill(destRect);
  NSBezierPath *path = [NSBezierPath bezierPath];
  [path moveToPoint:joinP1];
  [path lineToPoint:joinP2];
  [path lineToPoint:joinP3];
  [path lineToPoint:joinP4];
  [path closePath];
  [path fill];
}


+ (PTDRingMenuItem *)menuItem
{
  return [PTDRingMenuItem itemWithImage:[NSImage imageNamed:@"PTDToolIconEraser"] target:nil action:nil];
}


- (PTDRingMenuRing *)optionMenu
{
  PTDRingMenuRing *res = [PTDRingMenuRing ring];
  
  [res beginGravityMassGroupWithAngle:M_PI_2];
  NSArray <NSNumber *> *sizes = [[PTDToolOptions sharedOptions] objectForOption:PTDEraserToolOptionSizeOptions ofToolClass:self.class];
  for (NSNumber *size in sizes) {
    PTDRingMenuItem *itm = [self menuItemForEraserSize:size.doubleValue];
    if (size.doubleValue == self.size)
      itm.state = NSControlStateValueOn;
    [res addItem:itm];
  }
  [res endGravityMassGroup];
  [res addSpringWithElasticity:1.0];
  
  return res;
}


- (PTDRingMenuItem *)menuItemForEraserSize:(CGFloat)size
{
  NSImage *img;
  const CGFloat threshold = 24;
  const CGFloat minBorder = 4.0;
  const CGFloat maxBorder = 8.0;
  
  if (size < threshold) {
    CGFloat imageSize = round(minBorder + (maxBorder - minBorder) * (threshold-size)/threshold) + size;
    img = [NSImage imageWithSize:NSMakeSize(imageSize, imageSize) flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
      [[NSColor blackColor] setStroke];
      NSBezierPath *bp = [NSBezierPath bezierPathWithRect:NSMakeRect((imageSize - size) / 2.0, (imageSize - size) / 2.0, size, size)];
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
      NSBezierPath *bp = [NSBezierPath bezierPathWithRect:NSMakeRect(minBorder/2.0-0.5, minBorder/2.0-0.5, threshold+1, threshold+1)];
      [bp stroke];
      [sizeStr drawInRect:NSMakeRect(0, (imageSize-realSizeRect.size.height)/2.0, imageSize, realSizeRect.size.height) withAttributes:attrib];
      return YES;
    }];
  }
  img.template = YES;
  
  PTDRingMenuItem *itm = [PTDRingMenuItem itemWithImage:img target:self action:@selector(changeSize:)];
  itm.tag = size;
  return itm;
}


- (void)changeSize:(id)sender
{
  [[PTDToolOptions sharedOptions] setObject:@([(NSMenuItem *)sender tag]) forOption:PTDEraserToolOptionSize ofToolClass:self.class];
}


- (void)updateCursor
{
  CGFloat size = self.size;
  PTDCursor *cursor = [[PTDCursor alloc] init];
  
  cursor.image = [NSImage
      imageWithSize:NSMakeSize(size, size)
      flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
    NSRect squareRect = NSMakeRect(0.5, 0.5, size-1.0, size-1.0);
    NSBezierPath *bp = [NSBezierPath bezierPathWithRect:squareRect];
    [[NSColor whiteColor] setFill];
    [bp fill];
    [[NSColor blackColor] setStroke];
    [bp stroke];
    return YES;
  }];
  cursor.hotspot = NSMakePoint(size/2, size/2);
  
  self.cursor = cursor;
}


@end

