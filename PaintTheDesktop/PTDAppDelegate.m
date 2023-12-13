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
#import "PTDThumbnailMenuItemView.h"
#import "NSNib+PTD.h"
#import "PTDPreferencesWindowController.h"
#import "PTDPDFPresentationPaintWindowController.h"
#import "NSWindow+PTD.h"
#import "PTDPDFAnnotationPaintWindowController.h"


@interface PTDAppDelegate ()

@property (nonatomic) SPUStandardUpdaterController *updateController;

@property (nonatomic) NSMutableArray<PTDAbstractPaintWindowController *> *paintWindowControllers;
@property (nonatomic) NSStatusItem *statusItem;

@property (nonatomic) IBOutlet NSWindow *aboutWindow;
@property (nonatomic) IBOutlet NSTextField *aboutWindowVersionLabel;

@property (nonatomic) PTDPreferencesWindowController *preferencesWindowController;

@end


@implementation PTDAppDelegate {
  NSInteger _dockRefCount;
}


+ (void)registerDefaults
{
  NSUserDefaults *ud = NSUserDefaults.standardUserDefaults;
  [ud registerDefaults:@{
    @"PTDAlwaysShowsDockIcon": @(NO)
  }];
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
  
  [self.class registerDefaults];
  [PTDToolManager registerDefaults];
  
  NSUserDefaults *ud = NSUserDefaults.standardUserDefaults;
  _alwaysShowsDockIcon = [ud boolForKey:@"PTDAlwaysShowsDockIcon"];
  
  _updateController = [[SPUStandardUpdaterController alloc] initWithStartingUpdater:YES updaterDelegate:nil userDriverDelegate:nil];
  
  return self;
}


#pragma mark - Application Lifecycle


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
  NSEvent.mouseCoalescingEnabled = NO;
  if (!self.alwaysShowsDockIcon)
    [self hideDockIcon];
  
  [self setupMenu];
  [self updateScreenPaintWindows];
  
  NSUserDefaults *ud = NSUserDefaults.standardUserDefaults;
  NSNumber *showAboutScreen = [ud objectForKey:@"PTDAboutPanelDisplayOnLaunch"];
  if (showAboutScreen == nil)
    [ud setBool:NO forKey:@"PTDAboutPanelDisplayOnLaunch"];
  if (showAboutScreen == nil || showAboutScreen.boolValue == YES) {
    [self openAboutWindow:self];
  }
}


- (void)setAlwaysShowsDockIcon:(BOOL)alwaysShowsDockIcon
{
  NSUserDefaults *ud = NSUserDefaults.standardUserDefaults;
  [ud setBool:alwaysShowsDockIcon forKey:@"PTDAlwaysShowsDockIcon"];
  
  if (_alwaysShowsDockIcon != alwaysShowsDockIcon && _dockRefCount == 0) {
    if (alwaysShowsDockIcon)
      [self hideDockIcon];
    else
      [self showDockIcon];
  }
  
  _alwaysShowsDockIcon = alwaysShowsDockIcon;
}


- (void)pushAppShouldShowInDock
{
  if (_dockRefCount == 0 && !self.alwaysShowsDockIcon) {
    [self showDockIcon];
  }
  _dockRefCount++;
}


- (void)popAppShouldShowInDock
{
  if (_dockRefCount > 0) {
    _dockRefCount--;
    if (_dockRefCount == 0 && !self.alwaysShowsDockIcon)
      [self hideDockIcon];
  } else {
    NSLog(@"calls to -popAppShouldShowInDock mismatched with -pushAppShouldShowInDock!");
  }
}


- (void)showDockIcon
{
  [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
  [NSRunningApplication.currentApplication activateWithOptions:NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps];
}


- (void)hideDockIcon
{
  [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification
{
}


#pragma mark - Menu


- (void)setupMenu
{
  NSStatusBar *menuBar = [NSStatusBar systemStatusBar];
  self.statusItem = [menuBar statusItemWithLength:20.0];
  
  self.statusItem.button.image = [NSImage imageNamed:@"PTDMenuIconOff"];
  self.statusItem.button.target = self;
  self.statusItem.button.action = @selector(statusItemAction:);
  [self.statusItem.button sendActionOn:NSEventMaskLeftMouseUp | NSEventMaskRightMouseUp];
  self.statusItem.behavior = NSStatusItemBehaviorTerminationOnRemoval;
}


- (void)statusItemAction:(id)sender
{
  if (NSEvent.modifierFlags == NSEventModifierFlagOption ||
        NSEvent.modifierFlags == NSEventModifierFlagControl ||
        NSApp.currentEvent.type == NSEventTypeRightMouseUp) {
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
  
  [self appendPaintingListToMenu:res];
  
  [res addItemWithTitle:NSLocalizedString(@"New Blank Canvas", @"") action:@selector(newCanvasWindow:) keyEquivalent:@""];
  [res addItemWithTitle:NSLocalizedString(@"New Presentation...", @"") action:@selector(newPresentationWindow:) keyEquivalent:@""];
  [res addItemWithTitle:NSLocalizedString(@"New PDF Viewer...", @"") action:@selector(newPDFAnnotationWindow:) keyEquivalent:@""];
  
  [res addItem:[NSMenuItem separatorItem]];
  
  [res addItemWithTitle:NSLocalizedString(@"About PaintTheDesktop", @"") action:@selector(openAboutWindow:) keyEquivalent:@""];
  
  [res addItem:[NSMenuItem separatorItem]];
  
  NSMenuItem *prefsMi = [res addItemWithTitle:NSLocalizedString(@"Preferences...", @"") action:@selector(openPreferences:) keyEquivalent:@""];
  [prefsMi setTarget:self];
  
  NSMenuItem *sparkleMi = [res addItemWithTitle:NSLocalizedString(@"Check for Updates...", @"") action:@selector(checkForUpdates:) keyEquivalent:@""];
  [sparkleMi setTarget:self.updateController];
  
  [res addItem:[NSMenuItem separatorItem]];
  
  [res addItemWithTitle:NSLocalizedString(@"Quit", @"") action:@selector(terminate:) keyEquivalent:@""];
  
  return res;
}


- (BOOL)menuHasKeyEquivalent:(NSMenu *)menu forEvent:(NSEvent *)event target:(id _Nullable __autoreleasing *)target action:(SEL _Nullable *)action
{
  assert(menu == self.paintingsMenu);
  return NO;
}


- (void)menuNeedsUpdate:(NSMenu *)menu
{
  assert(menu == self.paintingsMenu);
  [menu removeAllItems];
  [self appendPaintingListToMenu:menu];
}


- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
  if (self.active) {
    if (menuItem.action == @selector(newCanvasWindow:) ||
        menuItem.action == @selector(newPresentationWindow:) ||
        menuItem.action == @selector(newPDFAnnotationWindow:))
      return NO;
  }
  return YES;
}


- (void)appendPaintingListToMenu:(NSMenu *)res
{
  for (PTDAbstractPaintWindowController *paintw in _paintWindowControllers) {
    NSMenuItem *mi = [self menuItemForPainting:paintw];
    [res addItem:mi];
  }
}


- (NSMenuItem *)menuItemForPainting:(PTDAbstractPaintWindowController *)paintw
{
  NSString *title = [NSString stringWithFormat:@"%@", paintw.displayName];
  NSMenuItem *mi = [NSMenuItem ptd_menuItemWithLabel:title thumbnail:paintw.thumbnail thumbnailArea:0];
  NSMenu *submenu = [paintw windowMenu];
  if (submenu)
    mi.submenu = submenu;
  return mi;
}


- (void)newCanvasWindow:(id)sender
{
  PTDAbstractPaintWindowController *thisWindow = [[PTDSimpleCanvasPaintWindowController alloc] init];
  [self.paintWindowControllers addObject:thisWindow];
  thisWindow.delegate = self;
  [thisWindow showWindow:self];
}


- (void)newPresentationWindow:(id)sender
{
  PTDPDFPresentationPaintWindowController *thisWindow = [[PTDPDFPresentationPaintWindowController alloc] init];
  [self.paintWindowControllers addObject:thisWindow];
  thisWindow.delegate = self;
  [thisWindow showWindow:self];
}


- (void)newPDFAnnotationWindow:(id)sender
{
  PTDPDFAnnotationPaintWindowController *thisWindow = [[PTDPDFAnnotationPaintWindowController alloc] init];
  [self.paintWindowControllers addObject:thisWindow];
  thisWindow.delegate = self;
  [thisWindow showWindow:self];
}


- (void)paintWindowWillClose:(PTDAbstractPaintWindowController *)windowCtl
{
  [self.paintWindowControllers removeObject:windowCtl];
}


- (void)openAboutWindow:(id)sender
{
  NSString *version = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
  NSString *buildNum = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"];
  self.aboutWindowVersionLabel.stringValue = [NSString stringWithFormat:NSLocalizedString(@"Version %@ (%@)", @""), version, buildNum];
  
  self.active = NO;
  [NSApp activateIgnoringOtherApps:YES];
  self.aboutWindow.canHide = NO;
  self.aboutWindow.level = kCGMaximumWindowLevelKey;
  [self.aboutWindow makeKeyAndOrderFront:sender];
}


- (void)openPreferences:(id)sender
{
  if (self.preferencesWindowController == nil) {
    self.preferencesWindowController = [[PTDPreferencesWindowController alloc] init];
  }
  
  self.active = NO;
  [NSApp activateIgnoringOtherApps:YES];
  [self.preferencesWindowController showWindow:self];
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
      NSString *name = screen.ptd_name;
      PTDScreenPaintWindowController *thisWindow = [[PTDScreenPaintWindowController alloc] initWithDisplay:dispId localizedName:name];
      [self.paintWindowControllers addObject:thisWindow];
      thisWindow.delegate = self;
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
