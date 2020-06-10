//
//  PTDToolManager.m
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 10/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import "PTDToolManager.h"
#import "PTDPencilTool.h"
#import "PTDEraserTool.h"


@implementation PTDToolManager
{
  NSDictionary *_toolNames;
  NSDictionary *_toolClasses;
}


- (instancetype)init
{
  return [[self class] sharedManager];
}


- (instancetype)_init
{
  self = [super init];
  _currentTool = [[PTDPencilTool alloc] init];
  
  _availableToolIdentifiers = @[
      PTDToolIdentifierPencilTool,
      PTDToolIdentifierEraserTool
    ];
  _toolNames = @{
      PTDToolIdentifierPencilTool: @"Pencil",
      PTDToolIdentifierEraserTool: @"Eraser"
    };
  _toolClasses = @{
      PTDToolIdentifierPencilTool: [PTDPencilTool class],
      PTDToolIdentifierEraserTool: [PTDEraserTool class],
    };
    
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
  return [_toolNames objectForKey:ti];
}


- (void)changeTool:(NSString *)newIdentifier
{
  Class toolClass = [_toolClasses objectForKey:newIdentifier];
  [_currentTool deactivate];
  _currentTool = [[toolClass alloc] init];
}


@end
