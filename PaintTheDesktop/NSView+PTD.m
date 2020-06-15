//
//  NSView+PTD.m
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 15/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import "NSView+PTD.h"


@implementation NSView (PTD)


- (NSPoint)ptd_backingAlignedPoint:(NSPoint)point
{
  CGFloat scale = self.window.screen.backingScaleFactor;
  return NSMakePoint(
      round(point.x * scale) / scale,
      round(point.y * scale) / scale);
}


@end
