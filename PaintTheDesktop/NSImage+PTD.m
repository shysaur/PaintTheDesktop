//
//  NSImage+PTD.m
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 27/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import "NSImage+PTD.h"


@implementation NSImage (PTD)


- (instancetype)ptd_imageByTintingWithColor:(NSColor *)color
{
  NSImage *copy = [self copy];
  if (!self.template)
    return copy;
  
  NSRect rect = (NSRect){NSZeroPoint, copy.size};
  NSImage *newImage = [NSImage imageWithSize:copy.size flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
    [copy drawInRect:rect];
    [color setFill];
    NSRectFillUsingOperation(rect, NSCompositingOperationSourceAtop);
    return YES;
  }];
  return newImage;
}


@end
