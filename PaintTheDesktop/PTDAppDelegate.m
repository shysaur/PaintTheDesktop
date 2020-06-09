//
//  AppDelegate.m
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 08/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import "PTDAppDelegate.h"
#import "PTDPaintWindow.h"


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
  return self;
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
  [self _setupMenu];

  for (NSScreen *screen in NSScreen.screens) {
    PTDPaintWindow *thisWindow = [[PTDPaintWindow alloc] initWithScreen:screen];
    [self.paintWindowControllers addObject:thisWindow];
    [thisWindow.window makeKeyAndOrderFront:nil];
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
    self.statusItem.button.image = [NSImage imageNamed:@"PTDMenuIconOn"];
  } else {
    self.statusItem.button.image = [NSImage imageNamed:@"PTDMenuIconOff"];
  }
}


- (void)applicationWillTerminate:(NSNotification *)aNotification
{
}


@end
