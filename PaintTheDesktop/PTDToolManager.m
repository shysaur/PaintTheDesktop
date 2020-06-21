//
//  PTDToolManager.m
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 10/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import "PTDToolManager.h"
#import "PTDTool.h"
#import "PTDBrush.h"
#import "PTDPencilTool.h"
#import "PTDEraserTool.h"
#import "PTDResetTool.h"
#import "PTDRectangleTool.h"
#import "PTDOvalTool.h"


@interface PTDToolManager ()

@property (nonatomic, nullable) NSString *previousToolIdentifier;

@end


@implementation PTDToolManager {
  NSDictionary *_toolClasses;
  NSMutableDictionary *_lastToolForIdentifier;
}


- (instancetype)init
{
  return [[self class] sharedManager];
}


- (instancetype)_init
{
  self = [super init];
  _currentBrush = [[PTDBrush alloc] init];
  _currentTool = [[PTDPencilTool alloc] init];
  
  _availableToolIdentifiers = @[
      PTDToolIdentifierPencilTool,
      PTDToolIdentifierEraserTool,
      PTDToolIdentifierRectangleTool,
      PTDToolIdentifierOvalTool,
      PTDToolIdentifierResetTool
    ];
  _toolClasses = @{
      PTDToolIdentifierPencilTool: [PTDPencilTool class],
      PTDToolIdentifierEraserTool: [PTDEraserTool class],
      PTDToolIdentifierRectangleTool: [PTDRectangleTool class],
      PTDToolIdentifierOvalTool: [PTDOvalTool class],
      PTDToolIdentifierResetTool: [PTDResetTool class]
    };
  _lastToolForIdentifier = [@{} mutableCopy];
    
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


- (PTDRingMenuItem *)ringMenuItemForSelectingToolIdentifier:(NSString *)ti
{
  Class toolClass = [_toolClasses objectForKey:ti];
  PTDRingMenuItem *res = [toolClass menuItem];
  res.representedObject = ti;
  res.target = self;
  res.action = @selector(changeToolAction:);
  return res;
}


- (void)changeToolAction:(id)sender
{
  [PTDToolManager.sharedManager changeTool:sender];
}


- (void)changeTool:(NSString *)newIdentifier
{
  NSString *prevId = [[_currentTool class] toolIdentifier];
  self.previousToolIdentifier = prevId;
  [_lastToolForIdentifier setObject:_currentTool forKey:prevId];
  
  PTDTool *newTool = [_lastToolForIdentifier objectForKey:newIdentifier];
  if (!newTool) {
    Class toolClass = [_toolClasses objectForKey:newIdentifier];
    newTool = [[toolClass alloc] init];
  }
  
  if (_currentTool != newTool) {
    [_currentTool deactivate];
    _currentTool = newTool;
    [newTool activate];
    
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:PTDToolCursorDidChangeNotification object:newTool]];
  }
}


- (void)setCurrentBrush:(PTDBrush *)currentBrush
{
  _currentBrush = currentBrush;
  [self.currentTool brushDidChange];
}


@end
