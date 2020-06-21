//
//  PTDOvalTool.m
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 21/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import "PTDOvalTool.h"


NSString * const PTDToolIdentifierOvalTool = @"PTDToolIdentifierOvalTool";


@implementation PTDOvalTool


+ (NSString *)toolIdentifier
{
  return PTDToolIdentifierOvalTool;
}


+ (PTDRingMenuItem *)menuItem
{
  return [PTDRingMenuItem itemWithImage:[NSImage imageNamed:@"PTDToolIconOval"] target:nil action:nil];
}


- (NSBezierPath *)shapeBezierPathInRect:(NSRect)rect
{
  return [NSBezierPath bezierPathWithOvalInRect:rect];
}


@end
