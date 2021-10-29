//
// PTDScreenPaintWindowController.m
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

#import "PTDScreenPaintWindowController.h"
#import "PTDToolManager.h"
#import "PTDPaintView.h"
#import "NSWindow+PTD.h"
#import "PTDAppDelegate.h"


@interface PTDScreenPaintWindowController ()

@property (nonatomic) BOOL active;

@end


@implementation PTDScreenPaintWindowController {
  BOOL _windowLoaded;
  NSString *_displayProductName;
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
  _displayProductName = [[properties[@kDisplayProductName] allValues] firstObject];
  
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
  [self updateAfterScreenConfigurationChange];
  [self.window orderFrontRegardless];
}


- (void)setDisplay:(CGDirectDisplayID)display
{
  _display = display;
  [self updateAfterScreenConfigurationChange];
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
  [self updateAfterScreenConfigurationChange];
}


- (void)updateAfterScreenConfigurationChange
{
  NSRect dispFrame = [self displayRect];
  if (!NSIsEmptyRect(dispFrame)) {
    self.displayName = _displayProductName;
    self.window.isVisible = YES;
    [self.window setFrame:dispFrame display:NO];
  } else {
    self.displayName = [NSString stringWithFormat:
        NSLocalizedString(@"%@ (disconnected)",
          @"Format string for menu items corresponding to disconnected screens"),
        _displayProductName];
    self.window.isVisible = NO;
  }
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
  NSMenuItem *tmp, *tmp2;
  tmp = [submenu addItemWithTitle:NSLocalizedString(@"Save As...", @"Menu item for saving a drawing to file") action:@selector(saveImageAs:) keyEquivalent:@""];
  tmp.target = self;
  tmp = [submenu addItemWithTitle:NSLocalizedString(@"Restore...", @"Menu item for loading a drawing from file") action:@selector(openImage:) keyEquivalent:@""];
  tmp.target = self;
  
  if (!CGDisplayIsActive(self.display)) {
    [submenu addItem:[NSMenuItem separatorItem]];
    tmp = [submenu addItemWithTitle:NSLocalizedString(@"Delete...", @"Menu item for deleting a screen painting") action:@selector(performClose:) keyEquivalent:@""];
    tmp.target = self;
  }
  
  [submenu addItem:[NSMenuItem separatorItem]];
  tmp = [submenu addItemWithTitle:NSLocalizedString(@"Main Display...", @"Menu item for making a display main") action:@selector(makeDisplayMain:) keyEquivalent:@""];
  tmp.target = self;
  tmp2 = [submenu addItemWithTitle:NSLocalizedString(@"Main Display", @"Menu item for making a display main without asking") action:@selector(makeDisplayMain:) keyEquivalent:@""];
  tmp2.target = self;
  tmp2.alternate = YES;
  tmp2.keyEquivalentModifierMask = NSEventModifierFlagOption;
  if (CGDisplayIsMain(self.display)) {
    tmp.state = NSControlStateValueOn;
    tmp2.state = NSControlStateValueOn;
  }
  if (!CGDisplayIsActive(self.display)) {
    tmp.enabled = NO;
    tmp2.enabled = NO;
  }
  
  return submenu;
}


- (void)saveImageAs:(id)sender
{
  BOOL oldActive = PTDAppDelegate.appDelegate.active;
  PTDAppDelegate.appDelegate.active = NO;
  [NSWindow ptd_pushForceTopLevel];
  [super saveImageAs:sender];
  [NSWindow ptd_popForceTopLevel];
  PTDAppDelegate.appDelegate.active = oldActive;
}


- (void)openImage:(id)sender
{
  BOOL oldActive = PTDAppDelegate.appDelegate.active;
  PTDAppDelegate.appDelegate.active = NO;
  [NSWindow ptd_pushForceTopLevel];
  [super openImage:sender];
  [NSWindow ptd_popForceTopLevel];
  PTDAppDelegate.appDelegate.active = oldActive;
}


- (void)performClose:(id)sender
{
  BOOL oldActive = PTDAppDelegate.appDelegate.active;
  PTDAppDelegate.appDelegate.active = NO;
  [NSWindow ptd_pushForceTopLevel];
  
  NSAlert *closeAlert = [[NSAlert alloc] init];
  closeAlert.messageText = [NSString stringWithFormat:NSLocalizedString(@"Do you really want to delete the painting associated to the screen named \"%@\"?", @"Message text, screen painting dispose confirmation"), _displayProductName];
  closeAlert.informativeText = NSLocalizedString(@"The painting will be lost, and a new one will be created if the screen is reconnected.", @"Informative text, screen painting dispose confirmation");
  [closeAlert addButtonWithTitle:NSLocalizedString(@"Delete", @"OK button, screen painting dispose confirmation")];
  [closeAlert addButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel button, screen painting dispose confirmation")];
  
  NSModalResponse resp = [closeAlert runModal];
  
  [NSWindow ptd_popForceTopLevel];
  PTDAppDelegate.appDelegate.active = oldActive;
  
  if (resp == NSAlertFirstButtonReturn)
    [self close];
}


- (void)makeDisplayMain:(id)sender
{
  if (CGDisplayIsMain(self.display))
    return;
  if (!CGDisplayIsActive(self.display)) {
    NSBeep();
    return;
  }
  
  if (!(NSEvent.modifierFlags & NSEventModifierFlagOption)) {
    BOOL oldActive = PTDAppDelegate.appDelegate.active;
    PTDAppDelegate.appDelegate.active = NO;
    NSAlert *dispAlert = [[NSAlert alloc] init];
    dispAlert.messageText = [NSString stringWithFormat:NSLocalizedString(@"Do you really want to make \"%@\" the main display?", @"Message text, main display change confirmation"), _displayProductName];
    dispAlert.informativeText = NSLocalizedString(@"Window and dock locations will move around from the old main display to the new one.\n\nAll changes will be reversed when closing the app.", @"Informative text, main display change confirmation");
    [dispAlert addButtonWithTitle:NSLocalizedString(@"Set Main Display", @"OK button, main display change confirmation")];
    [dispAlert addButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel button, main display change confirmation")];
    NSModalResponse resp = [dispAlert runModal];
    if (resp != NSAlertFirstButtonReturn)
      return;
    [NSWindow ptd_popForceTopLevel];
    PTDAppDelegate.appDelegate.active = oldActive;
  }
  
  CGRect origBounds = CGDisplayBounds(self.display);
  CGFloat dx = -origBounds.origin.x;
  CGFloat dy = -origBounds.origin.y;
  
  CGDisplayConfigRef conf = NULL;
  CGDirectDisplayID *displays = NULL;
  CGError err = CGBeginDisplayConfiguration(&conf);
  if (err != kCGErrorSuccess)
    goto cancel;
    
  uint32_t dispCount = 0;
  CGGetActiveDisplayList(0, NULL, &dispCount);
  if (dispCount == 0)
    goto cancel;
  displays = calloc(dispCount, sizeof(CGDirectDisplayID));
  err = CGGetActiveDisplayList(dispCount, displays, &dispCount);
  if (err != kCGErrorSuccess)
    goto cancel;
  
  for (uint32_t i=0; i<dispCount; i++) {
    CGRect dispBounds = CGDisplayBounds(displays[i]);
    int32_t x = dispBounds.origin.x + dx;
    int32_t y = dispBounds.origin.y + dy;
    err = CGConfigureDisplayOrigin(conf, displays[i], x, y);
    if (err != kCGErrorSuccess)
      goto cancel;
  }
  
  err = CGCompleteDisplayConfiguration(conf, kCGConfigureForAppOnly);
  if (err != kCGErrorSuccess)
    goto cancel;
  
  free(displays);
  return;
  
cancel:
  NSLog(@"display configuration failed with code %d", err);
  NSBeep();
  if (conf)
    CGCancelDisplayConfiguration(conf);
  free(displays);
}


@end
