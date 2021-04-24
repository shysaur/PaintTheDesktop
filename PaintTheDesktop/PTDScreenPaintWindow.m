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


@implementation PTDScreenPaintWindow


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
  
  return self;
}


- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)windowDidLoad
{
  /* If we don't do this, Cocoa will muck around with our window positioning */
  self.shouldCascadeWindows = NO;
  
  [super windowDidLoad];
  
  self.window.styleMask = NSWindowStyleMaskBorderless | NSWindowStyleMaskNonactivatingPanel;
  self.window.backgroundColor = [NSColor colorWithWhite:1.0 alpha:0.0];
  self.window.opaque = NO;
  self.window.hasShadow = NO;
  self.window.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorFullScreenAuxiliary | NSWindowCollectionBehaviorIgnoresCycle;
  self.window.level = kCGMaximumWindowLevelKey;
  
  if ([[NSUserDefaults standardUserDefaults] boolForKey:@"debug"]) {
    self.window.movable = YES;
    self.window.styleMask = self.window.styleMask | NSWindowStyleMaskTitled;
  } else {
    self.window.movable = NO;
  }
  
  self.display = _display;
  [self.window orderFrontRegardless];
  
  self.active = NO;
}


- (void)setDisplay:(CGDirectDisplayID)display
{
  CGRect dispFrame = CGDisplayBounds(display);
  
  if (CGDisplayIsActive(display) && (dispFrame.size.width > 0) && (dispFrame.size.height > 0)) {
    /* translate from CG reference coords to NS ones */
    dispFrame.origin.y += dispFrame.size.height;
    CGRect zeroScreenRect = CGDisplayBounds(CGMainDisplayID());
    dispFrame.origin.y = -dispFrame.origin.y + zeroScreenRect.size.height;
    
    self.window.isVisible = YES;
    [self.window setFrame:dispFrame display:NO];
  } else {
    self.window.isVisible = NO;
  }
  
  _display = display;
}


- (void)screenConfigurationDidChange:(NSNotification *)notification
{
  self.display = _display;
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


@end
