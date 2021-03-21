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
#import "PTDPencilTool.h"
#import "PTDEraserTool.h"
#import "PTDResetTool.h"
#import "PTDRectangleTool.h"
#import "PTDOvalTool.h"
#import "PTDRoundRectTool.h"
#import "PTDSelectionTool.h"
#import "PTDToolOptions.h"


@interface PTDToolManager ()

@property (nonatomic) PTDTool *currentTool;

@end


@implementation PTDToolManager {
  NSDictionary *_toolClasses;
}


- (instancetype)init
{
  self = [super init];
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
    
  return self;
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
  [self changeTool:sender];
}


- (void)changeTool:(NSString *)newIdentifier
{
  NSString *prevId = [[_currentTool class] toolIdentifier];
  if ([prevId isEqual:newIdentifier])
    return;
  
  Class toolClass = [_toolClasses objectForKey:newIdentifier];
  self.currentTool = [[toolClass alloc] init];
}


@end
