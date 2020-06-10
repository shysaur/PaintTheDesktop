//
//  PTDResetTool.m
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 10/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import "PTDResetTool.h"
#import "PTDToolManager.h"
#import "PTDPaintView.h"


NSString * const PTDToolIdentifierResetTool = @"PTDToolIdentifierResetTool";


@implementation PTDResetTool


+ (NSString *)toolIdentifier
{
  return PTDToolIdentifierResetTool;
}


- (void)mouseClickedAtPoint:(NSPoint)point
{
  NSRect bounds = [self.currentPaintView paintRect];
  [NSGraphicsContext.currentContext setCompositingOperation:NSCompositingOperationClear];
  [[NSColor colorWithWhite:1.0 alpha:0.0] setFill];
  NSRectFill(bounds);
}


@end
