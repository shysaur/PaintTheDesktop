//
//  PTDRoundRectTool.m
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 22/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import "PTDRoundRectTool.h"


NSString * const PTDToolIdentifierRoundRectTool = @"PTDToolIdentifierRoundRectTool";


@implementation PTDRoundRectTool


+ (NSString *)toolIdentifier
{
  return PTDToolIdentifierRoundRectTool;
}


+ (PTDRingMenuItem *)menuItem
{
  return [PTDRingMenuItem itemWithImage:[NSImage imageNamed:@"PTDToolIconRoundRect"] target:nil action:nil];
}


- (NSBezierPath *)shapeBezierPathInRect:(NSRect)rect
{
  return [NSBezierPath bezierPathWithRoundedRect:rect xRadius:8.0 yRadius:8.0];
}


@end
