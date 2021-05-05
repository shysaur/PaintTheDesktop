//
// PTDPaintWindowController.m
// PaintTheDesktop -- Created on 08/06/2020.
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

#import "PTDSimpleCanvasPaintWindowController.h"
#import "PTDPaintViewController.h"
#import "PTDPaintView.h"
#import "PTDAppDelegate.h"


@implementation PTDSimpleCanvasPaintWindowController {
  BOOL _windowLoaded;
}


- (BOOL)isWindowLoaded
{
  return _windowLoaded;
}


- (void)loadWindow
{
  NSRect screenRect = NSScreen.mainScreen.frame;
  CGFloat offset = screenRect.size.height / 3.0;
  CGFloat defaultWidth = 768;
  NSRect contentRect = NSMakeRect(screenRect.origin.x + offset, screenRect.origin.y + offset, defaultWidth, defaultWidth * 10.0 / 16.0);
  NSWindow *window = [[NSWindow alloc]
      initWithContentRect:contentRect
      styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable
      backing:NSBackingStoreBuffered
      defer:YES];
  
  window.backgroundColor = [NSColor colorWithWhite:1.0 alpha:1.0];
  
  self.paintViewController = [[PTDPaintViewController alloc] init];
  self.paintViewController.view = [[PTDPaintView alloc] init];
  window.contentView = self.paintViewController.view;
  [self.paintViewController viewDidLoad];
  
  _windowLoaded = YES;
  self.window = window;
}


- (void)windowDidLoad
{
  [super windowDidLoad];
  [PTDAppDelegate.appDelegate pushAppShouldShowInDock];
}


- (NSMenu *)windowMenu
{
  NSMenu *submenu = [[NSMenu alloc] init];
  NSMenuItem *tmp;
  tmp = [submenu addItemWithTitle:NSLocalizedString(@"Save As...", @"Menu item for saving a drawing to file") action:@selector(saveImageAs:) keyEquivalent:@""];
  tmp.target = self;
  tmp = [submenu addItemWithTitle:NSLocalizedString(@"Restore...", @"Menu item for loading a drawing from file") action:@selector(openImage:) keyEquivalent:@""];
  tmp.target = self;
  return submenu;
}


- (void)windowWillClose:(NSNotification *)notification
{
  [super windowWillClose:notification];
  [PTDAppDelegate.appDelegate popAppShouldShowInDock];
}


@end
