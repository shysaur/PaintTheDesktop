//
//  PTDRingMenuItem.m
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 17/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import "PTDRingMenuItem.h"

@implementation PTDRingMenuItem


+ (PTDRingMenuItem *)itemWithImage:(NSImage *)image target:(nullable id)target action:(nullable SEL)action
{
  PTDRingMenuItem *res = [[[self class] alloc] init];
  res.image = image;
  res.target = target;
  res.action = action;
  return res;
}


+ (PTDRingMenuItem *)itemWithText:(NSString *)text target:(nullable id)target action:(nullable SEL)action
{
  PTDRingMenuItem *res = [[[self class] alloc] init];
  [res setText:text];
  res.target = target;
  res.action = action;
  return res;
}


- (void)setText:(NSString *)text
{
  NSFont *font = [NSFont systemFontOfSize:NSFont.systemFontSize];
  NSDictionary *attrib = @{
    NSFontAttributeName: font,
    NSForegroundColorAttributeName: [NSColor blackColor]
  };
  NSSize textSize = [text sizeWithAttributes:attrib];
  textSize.width = ceil(textSize.width);
  textSize.height = ceil(textSize.height);
  self.image = [NSImage imageWithSize:textSize flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
    [text drawAtPoint:NSZeroPoint withAttributes:attrib];
    return YES;
  }];
  self.image.template = YES;
}


@end
