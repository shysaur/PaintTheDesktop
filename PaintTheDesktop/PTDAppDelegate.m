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

@property (nonatomic) PTDPaintWindow *paintWindow;

@end


@implementation PTDAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
  self.paintWindow = [[PTDPaintWindow alloc] init];
  [self.paintWindow.window makeKeyAndOrderFront:nil];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification
{
  // Insert code here to tear down your application
}


@end
