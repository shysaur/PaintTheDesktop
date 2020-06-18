//
//  PTDRingMenuItem.m
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 17/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import "PTDRingMenuItem.h"

@implementation PTDRingMenuItem


- (void)setText:(NSString *)text
{
  NSFont *font = [NSFont systemFontOfSize:NSFont.systemFontSize];
  NSDictionary *attrib = @{
    NSFontAttributeName: font,
    NSForegroundColorAttributeName: [NSColor labelColor]
  };
  NSSize textSize = [text sizeWithAttributes:attrib];
  textSize.width = ceil(textSize.width);
  textSize.height = ceil(textSize.height);
  self.image = [NSImage imageWithSize:textSize flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
    [text drawAtPoint:NSZeroPoint withAttributes:attrib];
    return YES;
  }];
  NSDictionary *attrib2 = @{
    NSFontAttributeName: font,
    NSForegroundColorAttributeName: [NSColor selectedMenuItemTextColor]
  };
  self.selectedImage = [NSImage imageWithSize:textSize flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
    [text drawAtPoint:NSMakePoint(0, 0) withAttributes:attrib2];
    return YES;
  }];
}


@end
