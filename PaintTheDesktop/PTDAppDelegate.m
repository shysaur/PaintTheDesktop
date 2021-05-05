//
// AppDelegate.m
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

#import <Sparkle/Sparkle.h>
#import "PTDToolManager.h"
#import "PTDTool.h"
#import "PTDAppDelegate.h"
#import "PTDAbstractPaintWindowController.h"
#import "PTDScreenPaintWindowController.h"
#import "PTDSimpleCanvasPaintWindowController.h"
#import "NSScreen+PTD.h"
#import "PTDScreenMenuItemView.h"
#import "NSNib+PTD.h"
#import "PTDPreferencesWindowController.h"


@interface NSMenuItem ()

- (BOOL)_viewHandlesEvents;
- (void)_setViewHandlesEvents:(BOOL)arg1;

@end


@interface PTDAppDelegate ()

@property (nonatomic) NSMutableArray<PTDAbstractPaintWindowController *> *paintWindowControllers;
@property (nonatomic) NSStatusItem *statusItem;
@property (nonatomic) BOOL active;

@property (nonatomic) IBOutlet NSWindow *aboutWindow;
@property (nonatomic) IBOutlet NSTextField *aboutWindowVersionLabel;

@property (nonatomic) PTDPreferencesWindowController *preferencesWindowController;

@end


@implementation PTDAppDelegate {
  NSInteger _dockRefCount;
}


+ (PTDAppDelegate *)appDelegate
{
  return (PTDAppDelegate *)NSApp.delegate;
}


- (instancetype)init
{
  self = [super init];
  _paintWindowControllers = [@[] mutableCopy];
  _active = NO;
  _dockRefCount = 0;
  return self;
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
  [SUUpdater sharedUpdater];
  
  [self _setupMenu];
  [self updateScreenPaintWindows];
  
  NSUserDefaults *ud = NSUserDefaults.standardUserDefaults;
  NSNumber *showAboutScreen = [ud objectForKey:@"PTDAboutPanelDisplayOnLaunch"];
  if (showAboutScreen == nil)
    [ud setBool:NO forKey:@"PTDAboutPanelDisplayOnLaunch"];
  if (showAboutScreen == nil || showAboutScreen.boolValue == YES) {
    [self orderFrontAboutWindow:self];
  }
}


- (IBAction)orderFrontAboutWindow:(id)sender
{
  NSString *version = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
  NSString *buildNum = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"];
  self.aboutWindowVersionLabel.stringValue = [NSString stringWithFormat:NSLocalizedString(@"Version %@ (%@)", @""), version, buildNum];
  
  self.active = NO;
  [NSApp activateIgnoringOtherApps:YES];
  self.aboutWindow.canHide = NO;
  [self.aboutWindow makeKeyAndOrderFront:sender];
}


- (void)_setupMenu
{
  NSStatusBar *menuBar = [NSStatusBar systemStatusBar];
  self.statusItem = [menuBar statusItemWithLength:20.0];
  
  self.statusItem.button.image = [NSImage imageNamed:@"PTDMenuIconOff"];
  self.statusItem.button.target = self;
  self.statusItem.button.action = @selector(toggleDrawing:);
  self.statusItem.behavior = NSStatusItemBehaviorTerminationOnRemoval;
}


- (void)toggleDrawing:(id)sender
{
  if ([NSEvent modifierFlags] == NSEventModifierFlagOption) {
    [self.statusItem popUpStatusItemMenu:[self globalMenu]];
    return;
  }
  self.active = !self.active;
}


- (void)setActive:(BOOL)active
{
  if (active != _active) {
    _active = active;
    
    if (active) {
      self.statusItem.button.image = [NSImage imageNamed:@"PTDMenuIconOn"];
    } else {
      self.statusItem.button.image = [NSImage imageNamed:@"PTDMenuIconOff"];
    }
    
    for (PTDAbstractPaintWindowController *wc in self.paintWindowControllers) {
      if (active)
        [wc applicationDidEnableDrawing];
      else
        [wc applicationDidDisableDrawing];
    }
  }
}


- (NSMenu *)globalMenu
{
  NSMenu *res = [[NSMenu alloc] init];
  NSNib *viewNib = [[NSNib alloc] initWithNibNamed:@"PTDScreenMenuItemView" bundle:[NSBundle mainBundle]];
  
  for (PTDAbstractPaintWindowController *paintw in _paintWindowControllers) {
    NSString *title = [NSString stringWithFormat:@"%@", paintw.displayName];
    PTDScreenMenuItemView *view = [viewNib ptd_instantiateObjectWithIdentifier:@"screenMenuItem" withOwner:nil];
    NSMenuItem *mi = [res addItemWithTitle:title action:nil keyEquivalent:@""];
    view.screenName.stringValue = title;
    [view setThumbnail:[paintw snapshot]];
    mi.view = view;
    [mi _setViewHandlesEvents:NO];
    [view setFrameSize:view.fittingSize];
    
    NSMenu *submenu = [paintw windowMenu];
    if (submenu)
      mi.submenu = submenu;
  }
  
  [res addItemWithTitle:NSLocalizedString(@"New Blank Canvas", @"") action:@selector(newCanvasWindow:) keyEquivalent:@""];
  
  [res addItem:[NSMenuItem separatorItem]];
  
  [res addItemWithTitle:NSLocalizedString(@"About PaintTheDesktop", @"") action:@selector(orderFrontAboutWindow:) keyEquivalent:@""];
  
  [res addItem:[NSMenuItem separatorItem]];
  
  NSMenuItem *prefsMi = [res addItemWithTitle:NSLocalizedString(@"Preferences...", @"") action:@selector(openPreferences:) keyEquivalent:@""];
  [prefsMi setTarget:self];
  
  NSMenuItem *sparkleMi = [res addItemWithTitle:NSLocalizedString(@"Check for Updates...", @"") action:@selector(checkForUpdates:) keyEquivalent:@""];
  [sparkleMi setTarget:[SUUpdater sharedUpdater]];
  
  [res addItem:[NSMenuItem separatorItem]];
  
  [res addItemWithTitle:NSLocalizedString(@"Quit", @"") action:@selector(terminate:) keyEquivalent:@""];
  
  return res;
}


- (void)newCanvasWindow:(id)sender
{
  PTDAbstractPaintWindowController *thisWindow = [[PTDSimpleCanvasPaintWindowController alloc] init];
  [self.paintWindowControllers addObject:thisWindow];
  thisWindow.delegate = self;
  [thisWindow showWindow:self];
}


- (void)paintWindowWillClose:(PTDAbstractPaintWindowController *)windowCtl
{
  [self.paintWindowControllers removeObject:windowCtl];
}


- (void)openPreferences:(id)sender
{
  if (self.preferencesWindowController == nil) {
    self.preferencesWindowController = [[PTDPreferencesWindowController alloc] init];
  }
  [NSApp activateIgnoringOtherApps:YES];
  [self.preferencesWindowController showWindow:self];
}


- (void)pushAppShouldShowInDock
{
  if (_dockRefCount == 0) {
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
  }
  _dockRefCount++;
}


- (void)popAppShouldShowInDock
{
  if (_dockRefCount > 0) {
    _dockRefCount--;
    if (_dockRefCount == 0)
      [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
  } else {
    NSLog(@"calls to -popAppShouldShowInDock mismatched with -pushAppShouldShowInDock!");
  }
}


- (void)applicationWillTerminate:(NSNotification *)aNotification
{
}


#pragma mark - Screen Paint Windows


- (void)updateScreenPaintWindows
{
  for (NSScreen *screen in NSScreen.screens) {
    CGDirectDisplayID dispId = [screen ptd_displayID];
    
    BOOL alreadyHandled = NO;
    for (PTDAbstractPaintWindowController *window in self.paintWindowControllers) {
      if ([window isKindOfClass:[PTDScreenPaintWindowController class]] && dispId == ((PTDScreenPaintWindowController *)window).display) {
        alreadyHandled = YES;
        break;
      }
    }
    
    if (!alreadyHandled) {
      PTDScreenPaintWindowController *thisWindow = [[PTDScreenPaintWindowController alloc] initWithDisplay:dispId];
      [self.paintWindowControllers addObject:thisWindow];
      if (self.active)
        [thisWindow applicationDidEnableDrawing];
      else
        [thisWindow applicationDidDisableDrawing];
    }
  }
}


- (void)applicationDidChangeScreenParameters:(NSNotification *)notification
{
  [self updateScreenPaintWindows];
}


@end
