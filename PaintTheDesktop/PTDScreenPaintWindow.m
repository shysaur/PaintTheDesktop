//
// PTDScreenPaintWindow.m
// PaintTheDesktop -- Created on 23/04/2021.
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

#import "PTDScreenPaintWindow.h"
#import "PTDToolManager.h"
#import "PTDPaintView.h"


@interface PTDScreenPaintWindow ()

@property (nonatomic) BOOL active;

@end


@implementation PTDScreenPaintWindow {
  BOOL _windowLoaded;
}


- (instancetype)initWithDisplay:(CGDirectDisplayID)display;
{
  self = [super init];
  
  _display = display;
  #pragma clang diagnostic push
  #pragma clang diagnostic ignored "-Wdeprecated-declarations"
  io_service_t dispSvc = CGDisplayIOServicePort(display);
  #pragma clang diagnostic pop
  NSDictionary *properties = CFBridgingRelease(IODisplayCreateInfoDictionary(dispSvc, kIODisplayOnlyPreferredName));
  self.displayName = [[properties[@kDisplayProductName] allValues] firstObject];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(screenConfigurationDidChange:) name:NSApplicationDidChangeScreenParametersNotification object:nil];
  
  /* If we don't do this, Cocoa will muck around with our window positioning */
  self.shouldCascadeWindows = NO;
  
  return self;
}


- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (BOOL)isWindowLoaded
{
  return _windowLoaded;
}


- (void)loadWindow
{
  NSRect contentRect = [self displayRect];
  NSWindow *window = [[NSWindow alloc]
      initWithContentRect:contentRect
      styleMask:NSWindowStyleMaskBorderless
      backing:NSBackingStoreBuffered
      defer:YES];
  
  window.backgroundColor = [NSColor colorWithWhite:1.0 alpha:0.0];
  window.canHide = NO;
  window.opaque = NO;
  window.hasShadow = NO;
  window.collectionBehavior =
      NSWindowCollectionBehaviorCanJoinAllSpaces |
      NSWindowCollectionBehaviorFullScreenAuxiliary |
      NSWindowCollectionBehaviorIgnoresCycle;
  window.level = kCGMaximumWindowLevelKey;
  
  if ([[NSUserDefaults standardUserDefaults] boolForKey:@"debug"]) {
    window.movable = YES;
    window.styleMask = window.styleMask | NSWindowStyleMaskTitled;
  } else {
    window.movable = NO;
  }
  
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
  [self.window orderFrontRegardless];
}


- (void)setDisplay:(CGDirectDisplayID)display
{
  _display = display;

  NSRect dispFrame = [self displayRect];
  if (!NSIsEmptyRect(dispFrame)) {
    self.window.isVisible = YES;
    [self.window setFrame:dispFrame display:NO];
  } else {
    self.window.isVisible = NO;
  }
}


- (NSRect)displayRect
{
  if (!CGDisplayIsActive(self.display))
    return NSZeroRect;
    
  CGRect dispFrame = CGDisplayBounds(self.display);
  
  if (dispFrame.size.width <= 0 || dispFrame.size.height <= 0)
    return NSZeroRect;
  
  /* translate from CG reference coords to NS ones */
  dispFrame.origin.y += dispFrame.size.height;
  CGRect zeroScreenRect = CGDisplayBounds(CGMainDisplayID());
  dispFrame.origin.y = -dispFrame.origin.y + zeroScreenRect.size.height;
  return dispFrame;
}


- (void)screenConfigurationDidChange:(NSNotification *)notification
{
  self.display = _display;
}


- (void)applicationDidEnableDrawing
{
  self.active = YES;
}


- (void)applicationDidDisableDrawing
{
  self.active = NO;
}


- (void)setActive:(BOOL)active
{
  if (active) {
    self.window.ignoresMouseEvents = NO;
    [self.window makeKeyAndOrderFront:nil];
  } else {
    self.window.ignoresMouseEvents = YES;
  }
  _active = active;
  self.paintViewController.active = active;
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


- (void)saveImageAs:(id)sender
{
  BOOL oldActive = self.active;
  self.active = NO;
  [super saveImageAs:sender];
  self.active = oldActive;
}


- (void)openImage:(id)sender
{
  BOOL oldActive = self.active;
  self.active = NO;
  [super openImage:sender];
  self.active = oldActive;
}


@end
