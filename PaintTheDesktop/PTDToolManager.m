//
// PTDToolManager.m
// PaintTheDesktop -- Created on 10/06/2020.
//
// Copyright (c) 2020 Daniele Cattaneo
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

#import "PTDToolManager.h"
#import "PTDTool.h"
#import "PTDBrush.h"
#import "PTDPencilTool.h"
#import "PTDEraserTool.h"
#import "PTDResetTool.h"
#import "PTDRectangleTool.h"
#import "PTDOvalTool.h"
#import "PTDRoundRectTool.h"
#import "PTDSelectionTool.h"


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
      PTDToolIdentifierRoundRectTool,
      PTDToolIdentifierSelectionTool,
      PTDToolIdentifierResetTool
    ];
  _toolClasses = @{
      PTDToolIdentifierPencilTool: [PTDPencilTool class],
      PTDToolIdentifierEraserTool: [PTDEraserTool class],
      PTDToolIdentifierRectangleTool: [PTDRectangleTool class],
      PTDToolIdentifierOvalTool: [PTDOvalTool class],
      PTDToolIdentifierRoundRectTool: [PTDRoundRectTool class],
      PTDToolIdentifierSelectionTool: [PTDSelectionTool class],
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
