//
//  PTDAlwaysOnTopSavePanel.m
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 29/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import "PTDAlwaysOnTopSavePanel.h"


@implementation PTDAlwaysOnTopSavePanel


- (instancetype)initWithContentRect:(NSRect)contentRect styleMask:(NSWindowStyleMask)style backing:(NSBackingStoreType)backingStoreType defer:(BOOL)flag
{
  self = [super initWithContentRect:contentRect styleMask:style backing:backingStoreType defer:flag];
  self.level = kCGMaximumWindowLevelKey;
  return self;
}


- (void)setLevel:(NSWindowLevel)level
{
  /* When opening a modal window, Cocoa sets its level to kCGMainMenuWindowLevelKey,
   * but that level is under the painting window.
   * So we force the level to be the right one to place our open/save windows
   * above it. */
  [super setLevel:kCGMaximumWindowLevelKey];
}


@end


@implementation PTDAlwaysOnTopOpenPanel


- (instancetype)initWithContentRect:(NSRect)contentRect styleMask:(NSWindowStyleMask)style backing:(NSBackingStoreType)backingStoreType defer:(BOOL)flag
{
  self = [super initWithContentRect:contentRect styleMask:style backing:backingStoreType defer:flag];
  self.level = kCGMaximumWindowLevelKey;
  return self;
}


- (void)setLevel:(NSWindowLevel)level
{
  [super setLevel:kCGMaximumWindowLevelKey];
}


@end
