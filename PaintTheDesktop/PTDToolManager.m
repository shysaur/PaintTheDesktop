//
//  PTDToolManager.m
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 10/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import "PTDToolManager.h"
#import "PTDPencilTool.h"


@implementation PTDToolManager


- (instancetype)init
{
  return [[self class] sharedManager];
}


- (instancetype)_init
{
  self = [super init];
  _currentTool = [[PTDPencilTool alloc] init];
  _availableToolIdentifiers = @[
      PTDToolIdentifierPencilTool
    ];
  return self;
}


+ (PTDToolManager *)sharedManager
{
  static PTDToolManager *sharedManager;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
      sharedManager = [[PTDToolManager alloc] _init];
  });
  return sharedManager;
}


- (NSString *)toolNameForIdentifier:(NSString *)ti
{
  NSDictionary * const tools = @{
      PTDToolIdentifierPencilTool: @"Pencil"
    };
  return [tools objectForKey:ti];
}


- (void)changeTool:(NSString *)newIdentifier
{
  NSDictionary * const tools = @{
      PTDToolIdentifierPencilTool: [PTDPencilTool class]
    };
  Class toolClass = [tools objectForKey:newIdentifier];
  [_currentTool deactivate];
  _currentTool = [[toolClass alloc] init];
}


@end
