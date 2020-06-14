//
//  NSScreen+PTD.m
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 12/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import "NSScreen+PTD.h"


@implementation NSScreen (PTD)


- (CGDirectDisplayID)ptd_displayID
{
  return [self.deviceDescription[@"NSScreenNumber"] unsignedIntValue];
}


@end
