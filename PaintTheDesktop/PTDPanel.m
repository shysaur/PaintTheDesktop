//
//  PTDPanel.m
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 18/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import <objc/runtime.h>
#import "PTDPanel.h"


@implementation PTDPanel


- (void)rightMouseDown:(NSEvent *)event
{
  /* NSWindow passes right mouse down events straight to NSApp... */
  NSResponder *nextResp = self.nextResponder;
  while (nextResp) {
    if ([self validateProposedFirstResponder:nextResp forEvent:event]) {
      [nextResp rightMouseDown:event];
      break;
    }
    nextResp = self.nextResponder;
  }
}


@end
