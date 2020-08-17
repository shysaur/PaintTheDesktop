//
//  AppDelegate.m
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 08/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import "PTDToolManager.h"
#import "PTDTool.h"
#import "PTDAppDelegate.h"
#import "PTDPaintWindow.h"
#import "NSScreen+PTD.h"
#import "PTDScreenMenuItemView.h"
#import "NSNib+PTD.h"


@interface NSMenuItem ()

- (BOOL)_viewHandlesEvents;
- (void)_setViewHandlesEvents:(BOOL)arg1;

@end


@interface PTDAppDelegate ()

@property (nonatomic) NSMutableArray<PTDPaintWindow *> *paintWindowControllers;
@property (nonatomic) NSStatusItem *statusItem;
@property (nonatomic) BOOL active;

@property (nonatomic) IBOutlet NSWindow *aboutWindow;
@property (nonatomic) IBOutlet NSTextField *aboutWindowVersionLabel;

@end


@implementation PTDAppDelegate


- (instancetype)init
{
  self = [super init];
  _paintWindowControllers = [@[] mutableCopy];
  _active = NO;
  return self;
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
  [self _setupMenu];

  for (NSScreen *screen in NSScreen.screens) {
    PTDPaintWindow *thisWindow = [[PTDPaintWindow alloc] initWithDisplay:[screen ptd_displayID]];
    [self.paintWindowControllers addObject:thisWindow];
    thisWindow.active = self.active;
  }
  
  NSUserDefaults *ud = NSUserDefaults.standardUserDefaults;
  NSNumber *showAboutScreen = [ud objectForKey:@"PTDAboutPanelDisplayOnLaunch"];
  if (!showAboutScreen)
    [ud setBool:NO forKey:@"PTDAboutPanelDisplayOnLaunch"];
  if (!showAboutScreen || showAboutScreen.boolValue == YES) {
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
  [self.aboutWindow makeKeyAndOrderFront:sender];
}


- (void)applicationDidChangeScreenParameters:(NSNotification *)notification
{
  for (NSScreen *screen in NSScreen.screens) {
    CGDirectDisplayID dispId = [screen ptd_displayID];
    
    BOOL alreadyHandled = NO;
    for (PTDPaintWindow *window in self.paintWindowControllers) {
      if (dispId == window.display) {
        alreadyHandled = YES;
        break;
      }
    }
    
    if (!alreadyHandled) {
      PTDPaintWindow *thisWindow = [[PTDPaintWindow alloc] initWithDisplay:dispId];
      [self.paintWindowControllers addObject:thisWindow];
      thisWindow.active = self.active;
    }
  }
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
    for (PTDPaintWindow *wc in self.paintWindowControllers) {
      wc.active = active;
    }
    if (active) {
      [PTDToolManager.sharedManager.currentTool activate];
      self.statusItem.button.image = [NSImage imageNamed:@"PTDMenuIconOn"];
    } else {
      [PTDToolManager.sharedManager.currentTool deactivate];
      self.statusItem.button.image = [NSImage imageNamed:@"PTDMenuIconOff"];
    }
  }
  _active = active;
}


- (NSMenu *)globalMenu
{
  NSMenu *res = [[NSMenu alloc] init];
  NSNib *viewNib = [[NSNib alloc] initWithNibNamed:@"PTDScreenMenuItemView" bundle:[NSBundle mainBundle]];
  
  for (PTDPaintWindow *paintw in _paintWindowControllers) {
    NSString *title = [NSString stringWithFormat:@"%@", paintw.displayName];
    PTDScreenMenuItemView *view = [viewNib ptd_instantiateObjectWithIdentifier:@"screenMenuItem" withOwner:nil];
    NSMenuItem *mi = [res addItemWithTitle:title action:nil keyEquivalent:@""];
    view.screenName.stringValue = title;
    [view setThumbnail:[paintw snapshot]];
    mi.view = view;
    [mi _setViewHandlesEvents:NO];
    [view setFrameSize:view.fittingSize];
    
    NSMenu *submenu = [[NSMenu alloc] init];
    NSMenuItem *tmp;
    tmp = [submenu addItemWithTitle:NSLocalizedString(@"Save As...", @"Menu item for saving a drawing to file") action:@selector(saveWindow:) keyEquivalent:@""];
    tmp.target = self;
    tmp.representedObject = paintw;
    tmp = [submenu addItemWithTitle:NSLocalizedString(@"Restore...", @"Menu item for loading a drawing from file") action:@selector(loadWindow:) keyEquivalent:@""];
    tmp.target = self;
    tmp.representedObject = paintw;
    
    mi.submenu = submenu;
  }
  
  [res addItem:[NSMenuItem separatorItem]];
  [res addItemWithTitle:NSLocalizedString(@"About PaintTheDesktop", @"") action:@selector(orderFrontAboutWindow:) keyEquivalent:@""];
  [res addItemWithTitle:NSLocalizedString(@"Quit", @"") action:@selector(terminate:) keyEquivalent:@""];
  
  return res;
}


- (void)saveWindow:(NSMenuItem *)sender
{
  BOOL oldActive = self.active;
  self.active = NO;
  PTDPaintWindow *window = (PTDPaintWindow *)sender.representedObject;
  
  NSSavePanel *savePanel = [[NSSavePanel alloc] init];
  savePanel.allowedFileTypes = @[@"png"];
  NSModalResponse resp = [savePanel runModal];
  if (resp == NSModalResponseCancel)
    return;
  
  NSBitmapImageRep *snapshot = [window snapshot];
  NSURL *file = savePanel.URL;
  NSData *dataToSave;
  dataToSave = [snapshot representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
  [dataToSave writeToURL:file atomically:NO];
  
  self.active = oldActive;
}


- (void)loadWindow:(NSMenuItem *)sender
{
  BOOL oldActive = self.active;
  self.active = NO;
  PTDPaintWindow *window = (PTDPaintWindow *)sender.representedObject;
  
  NSOpenPanel *openPanel = [[NSOpenPanel alloc] init];
  openPanel.allowedFileTypes = @[
    (__bridge NSString *)kUTTypePNG,
    (__bridge NSString *)kUTTypeTIFF,
    (__bridge NSString *)kUTTypeBMP,
    (__bridge NSString *)kUTTypeJPEG,
    (__bridge NSString *)kUTTypeGIF];
  NSModalResponse resp = [openPanel runModal];
  if (resp == NSModalResponseCancel)
    return;
    
  NSData *imageData = [NSData dataWithContentsOfURL:openPanel.URL];
  NSBitmapImageRep *image = [[NSBitmapImageRep alloc] initWithData:imageData];
  [window restoreFromSnapshot:image];
  
  self.active = oldActive;
}


- (void)applicationWillTerminate:(NSNotification *)aNotification
{
}


@end
