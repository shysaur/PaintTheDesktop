//
//  PTDRectangleTool.m
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 15/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import "PTDRectangleTool.h"


NSString * const PTDToolIdentifierRectangleTool = @"PTDToolIdentifierRectangleTool";


@implementation PTDRectangleTool


+ (NSString *)toolIdentifier
{
  return PTDToolIdentifierRectangleTool;
}


+ (PTDRingMenuItem *)menuItem
{
  return [PTDRingMenuItem itemWithImage:[NSImage imageNamed:@"PTDToolIconRectangle"] target:nil action:nil];
}


- (NSBezierPath *)shapeBezierPathInRect:(NSRect)rect
{
  return [NSBezierPath bezierPathWithRect:rect];
}


@end
