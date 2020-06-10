//
//  PTDTool.m
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 10/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import "PTDTool.h"


@implementation PTDTool


- (instancetype)init
{
  self = [super init];
  return self;
}


+ (NSString *)toolIdentifier
{
  [NSException raise:NSInternalInconsistencyException format:@"ABSTRACT METHOD: %s", __FUNCTION__];
  return nil;
}


- (void)dragDidStartAtPoint:(NSPoint)point
{
}


- (void)dragDidContinueFromPoint:(NSPoint)prevPoint toPoint:(NSPoint)nextPoint
{
}


- (void)dragDidEndAtPoint:(NSPoint)point
{
}


- (void)mouseClickedAtPoint:(NSPoint)point
{
}


- (void)activate
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
