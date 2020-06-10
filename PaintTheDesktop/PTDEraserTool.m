//
//  PTDEraserTool.m
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 10/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import "PTDEraserTool.h"
#import "PTDTool.h"


NSString * const PTDToolIdentifierEraserTool = @"PTDToolIdentifierEraserTool";


@interface PTDEraserTool ()

@property (nonatomic) CGFloat size;

@end


@implementation PTDEraserTool


- (instancetype)init
{
  self = [super init];
  _size = 20.0;
  return self;
}


+ (NSString *)toolIdentifier
{
  return PTDToolIdentifierEraserTool;
}


- (void)dragDidContinueFromPoint:(NSPoint)prevPoint toPoint:(NSPoint)nextPoint
{
  [[NSGraphicsContext currentContext] setCompositingOperation:NSCompositingOperationClear];

  NSBezierPath *path = [NSBezierPath bezierPath];
  [path setLineCapStyle:NSLineCapStyleSquare];
  [path setLineWidth:self.size];
  [[NSColor colorWithWhite:1.0 alpha:0.0] setStroke];
  [path moveToPoint:prevPoint];
  [path lineToPoint:nextPoint];
  [path stroke];
}


- (nullable NSMenu *)optionMenu
{
  NSMenu *res = [[NSMenu alloc] init];
  
  for (int i=20; i<200; i += 50) {
    NSString *title = [NSString stringWithFormat:@"Size %d", i];
    NSMenuItem *mi = [res addItemWithTitle:title action:@selector(changeSize:) keyEquivalent:@""];
    mi.target = self;
    mi.tag = i;
  }
  
  return res;
}


- (void)changeSize:(id)sender
{
  self.size = [(NSMenuItem *)sender tag];
}


@end

