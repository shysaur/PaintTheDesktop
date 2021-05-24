//
// PTDPreferencesWindowController.m
// PaintTheDesktop -- Created on 24/03/2021.
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

#import "PTDPreferencesWindowController.h"
#import "PTDBrushColorPrefsCollectionViewDelegate.h"
#import "PTDAppDelegate.h"
#import "PTDPencilTool.h"


@interface PTDPreferencesWindowController ()

@property (nonatomic, weak) IBOutlet NSTabView *preferencesTabView;
@property (nonatomic, weak) IBOutlet NSToolbar *toolbar;

@property (nonatomic, weak) IBOutlet NSButton *liveSmoothingBtn;
@property (nonatomic, weak) IBOutlet NSSlider *smoothingCoeffSlider;

@end


@implementation PTDPreferencesWindowController


+ (void)initialize
{
  NSUserDefaults *ud = NSUserDefaults.standardUserDefaults;
  [ud registerDefaults:@{
    @"PTDPreferencesTab": @(0)
  }];
}


- (NSString *)windowNibName
{
  return @"PTDPreferencesWindow";
}


- (void)windowDidLoad
{
  self.window.canHide = NO;
  
  [self initializePencilPreferences];
  
  NSUserDefaults *ud = NSUserDefaults.standardUserDefaults;
  int tab = (int)[ud integerForKey:@"PTDPreferencesTab"];
  int maxTabs = (int)self.preferencesTabView.numberOfTabViewItems;
  tab = MAX(0, MIN(tab, maxTabs - 1));
  [self showTabAtIndex:tab withAnimation:NO keepXCenter:YES];
}


- (void)showWindow:(id)sender
{
  [PTDAppDelegate.appDelegate pushAppShouldShowInDock];
  [super showWindow:sender];
}


- (IBAction)changeTab:(id)sender
{
  const char *ident = [sender itemIdentifier].UTF8String;
  int tabId = -1;
  sscanf(ident, "%d", &tabId);
  
  if (tabId < 0 && tabId >= self.preferencesTabView.numberOfTabViewItems) {
    NSBeep();
    return;
  }
  
  [self showTabAtIndex:tabId withAnimation:YES keepXCenter:NO];
  
  NSUserDefaults *ud = NSUserDefaults.standardUserDefaults;
  [ud setInteger:tabId forKey:@"PTDPreferencesTab"];
}


- (void)showTabAtIndex:(int)tabId withAnimation:(BOOL)anim keepXCenter:(BOOL)kxc
{
  NSTabViewItem *tvi = [self.preferencesTabView tabViewItemAtIndex:tabId];
  
  NSSize fittingSize = [tvi.view fittingSize];
  NSRect currentFrame = self.window.frame;
  NSRect newFrame = [self.window frameRectForContentRect:(NSRect){NSZeroPoint, fittingSize}];
  newFrame.origin.x = currentFrame.origin.x;
  if (kxc)
    newFrame.origin.x -= (newFrame.size.width - currentFrame.size.width) / 2;
  newFrame.origin.y = NSMaxY(currentFrame) - newFrame.size.height;
  
  self.preferencesTabView.hidden = YES;
  [self.preferencesTabView selectTabViewItem:tvi];
  [self.window setFrame:newFrame display:YES animate:anim];
  self.preferencesTabView.hidden = NO;
  
  NSString *ident = [NSString stringWithFormat:@"%d", tabId];
  self.toolbar.selectedItemIdentifier = ident;
}


- (void)windowWillClose:(NSNotification *)notification
{
  [PTDAppDelegate.appDelegate popAppShouldShowInDock];
}


#pragma mark - Pencil preferences


- (void)initializePencilPreferences
{
  self.liveSmoothingBtn.state = PTDPencilTool.liveSmoothing ? NSControlStateValueOn : NSControlStateValueOff;
  self.smoothingCoeffSlider.doubleValue = PTDPencilTool.smoothingCoefficient;
}


- (IBAction)changeLiveSmoothing:(id)sender
{
  PTDPencilTool.liveSmoothing = self.liveSmoothingBtn.state == NSControlStateValueOn ? YES : NO;
}


- (IBAction)changeSmoothingCoefficient:(id)sender
{
  PTDPencilTool.smoothingCoefficient = self.smoothingCoeffSlider.doubleValue;
}


@end
