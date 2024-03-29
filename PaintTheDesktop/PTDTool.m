//
// PTDTool.m
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

#import "PTDTool.h"
#import "PTDCursor.h"
#import "PTDToolOptions.h"
#import "PTDUtils.h"


@implementation PTDTool {
  id _optionsChangedObserver;
}


+ (void)registerDefaults
{
}


- (instancetype)init
{
  self = [super init];
  
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  _optionsChangedObserver= [nc addObserverForName:PTDToolOptionsChangedNotification
      object:PTDToolOptions.sharedOptions
      queue:nil usingBlock:^(NSNotification * _Nonnull note) {
    PTDTool *otherTool = [note.userInfo objectForKey:PTDToolOptionsChangedNotificationUserInfoToolKey];
    if (!otherTool || [self isKindOfClass:[otherTool class]])
      [self reloadOptions];
  }];
  
  [self reloadOptions];
  
  return self;
}


- (void)dealloc
{
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc removeObserver:_optionsChangedObserver];
}


+ (NSString *)toolIdentifier
{
  PTDAbstract();
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


- (void)modifierFlagsChanged
{
}


- (void)activate
{
}


- (void)deactivate
{
}


+ (PTDRingMenuItem *)menuItem
{
  return [PTDRingMenuItem itemWithText:self.toolIdentifier target:nil action:nil];
}


- (void)willOpenOptionMenuAtPoint:(NSPoint)point
{
}


- (nullable PTDRingMenuRing *)optionMenu
{
  return nil;
}


- (void)reloadOptions
{
}


+ (NSDictionary *)defaultOptions
{
  return @{};
}


@end
