//
//  NSColor+PTD.m
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 17/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import "NSColor+PTD.h"


@implementation NSColor (PTD)


+ (NSColor *)ptd_selectedRingMenuItemColor
{
  if (@available(macOS 10.14, *)) {
      return [NSColor controlAccentColor];
  } else {
      return [NSColor selectedMenuItemColor];
  }
}


@end
