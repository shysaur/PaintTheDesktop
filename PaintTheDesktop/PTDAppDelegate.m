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


@interface PTDAppDelegate ()

@property (nonatomic) NSMutableArray<PTDPaintWindow *> *paintWindowControllers;
@property (nonatomic) NSStatusItem *statusItem;
@property (nonatomic) BOOL active;

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


- (IBAction)toggleDrawing:(id)sender
{
  self.active = !self.active;
  for (PTDPaintWindow *wc in self.paintWindowControllers) {
    wc.active = self.active;
  }
  if (self.active) {
    [PTDToolManager.sharedManager.currentTool activate];
    self.statusItem.button.image = [NSImage imageNamed:@"PTDMenuIconOn"];
  } else {
    [PTDToolManager.sharedManager.currentTool deactivate];
    self.statusItem.button.image = [NSImage imageNamed:@"PTDMenuIconOff"];
  }
}


- (void)applicationWillTerminate:(NSNotification *)aNotification
{
}


@end
