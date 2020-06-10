//
//  PTDPencilTool.m
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 10/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import "PTDPencilTool.h"
#import "PTDTool.h"


@interface PTDPencilTool ()

@property (nonatomic) CGFloat size;
@property (nonatomic) NSColor *color;

@end


@implementation PTDPencilTool


- (instancetype)init
{
  self = [super init];
  _size = 2.0;
  _color = [NSColor blackColor];
  return self;
}


- (void)dragDidStartAtPoint:(NSPoint)point
{
}


- (void)dragDidContinueFromPoint:(NSPoint)prevPoint toPoint:(NSPoint)nextPoint
{
  NSBezierPath *path = [NSBezierPath bezierPath];
  [path setLineCapStyle:NSLineCapStyleRound];
  [path setLineWidth:self.size];
  [self.color setStroke];
  [path moveToPoint:prevPoint];
  [path lineToPoint:nextPoint];
  [path stroke];
}


- (void)dragDidEndAtPoint:(NSPoint)point
{
}


- (void)deactivate
{
}


- (nullable NSMenu *)optionMenu
{
  return nil;
}


@end
