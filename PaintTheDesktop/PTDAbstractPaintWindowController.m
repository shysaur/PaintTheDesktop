//
// PTDAbstractPaintWindowController.m
// PaintTheDesktop -- Created on 05/05/2021.
//
// Copyright (c) 2021 Daniele Cattaneo
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

#import "PTDAbstractPaintWindowController.h"
#import "PTDUtils.h"


@implementation PTDAbstractPaintWindowController


- (instancetype)initWithCoder:(NSCoder *)coder
{
  self = [super initWithCoder:coder];
  _displayName = NSLocalizedString(@"untitled", @"");
  return self;
}


- (instancetype)initWithWindow:(NSWindow *)window
{
  self = [super initWithWindow:window];
  _displayName = NSLocalizedString(@"untitled", @"");
  return self;
}


- (void)windowDidLoad
{
  [super windowDidLoad];
  self.displayName = _displayName;
  self.window.delegate = self;
}


- (void)setDisplayName:(NSString *)displayName
{
  _displayName = displayName;
  if (self.windowLoaded)
    self.window.title = _displayName;
}


- (void)windowWillClose:(NSNotification *)notification
{
  [self.delegate paintWindowWillClose:self];
}


- (NSMenu *)windowMenu
{
  return nil;
}


- (NSImage *)thumbnail
{
  PTDAbstract();
}


- (void)applicationDidEnableDrawing
{
}


- (void)applicationDidDisableDrawing
{
}


@end
