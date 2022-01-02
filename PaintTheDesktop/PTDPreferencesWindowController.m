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
#import "PTDTextTool.h"


@interface PTDPreferencesWindowController ()

@property (nonatomic, weak) IBOutlet NSTabView *preferencesTabView;
@property (nonatomic, weak) IBOutlet NSToolbar *toolbar;

@property (nonatomic, weak) IBOutlet NSButton *liveSmoothingBtn;
@property (nonatomic, weak) IBOutlet NSSlider *smoothingCoeffSlider;

@property (nonatomic, weak) IBOutlet NSPopUpButton *fontPopUp;

@end


@implementation PTDPreferencesWindowController {
  __weak NSMenuItem *_selectedFontMenuItem;
}


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
  [self initializeTextPreferences];
  
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


#pragma mark - Text preferences


- (void)initializeTextPreferences
{
  [self populateFontMenu];
}


- (void)populateFontMenu
{
  NSMenu *temporaryMenu = [[NSMenu alloc] init];
  [temporaryMenu addItemWithTitle:@"Loading..." action:nil keyEquivalent:@""];
  self.fontPopUp.menu = temporaryMenu;
  self.fontPopUp.enabled = NO;
  
  NSString *initialFontName = PTDTextTool.baseFontName;
  
  dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0), ^{
    [self populateFontMenuInBackgroundWithInitialSelection:initialFontName];
  });
}


- (void)populateFontMenuInBackgroundWithInitialSelection:(NSString *)initSel
{
  NSFontManager *fm = NSFontManager.sharedFontManager;
  NSMenu *theMenu = [[NSMenu alloc] init];
  
  NSArray *families = fm.availableFontFamilies;
  for (NSString *familyName in families) {
    NSMenuItem *familyItem = [self menuItemForFontFamily:familyName initialSelection:initSel];
    [theMenu addItem:familyItem];
  }
  
  dispatch_async(dispatch_get_main_queue(), ^{
    self.fontPopUp.menu = theMenu;
    self.fontPopUp.enabled = YES;
    [self updatePopUpWithFont];
  });
}


static NSInteger PTDFontFamilyMemberSpecimenEligibilityScore(NSArray *member)
{
  NSInteger weight = [member[2] integerValue];
  NSFontTraitMask mask = [member[3] integerValue];
  
  NSInteger weightScore = (20 - ABS(weight - 5)) * 100;
  
  NSInteger flagsScore = 40;
  if (mask & NSItalicFontMask)
    flagsScore -= 10;
  if (mask & NSBoldFontMask)
    flagsScore -= 10;
  if (mask & NSSmallCapsFontMask)
    flagsScore -= 10;
  if (mask & NSNarrowFontMask || mask & NSExpandedFontMask || mask & NSCondensedFontMask || mask & NSPosterFontMask || mask & NSCompressedFontMask)
    flagsScore -= 10;
  
  return weightScore + flagsScore;
}

- (NSMenuItem *)menuItemForFontFamily:(NSString *)familyName initialSelection:(NSString *)initSel
{
  NSFontManager *fm = NSFontManager.sharedFontManager;
  NSArray *members = [fm availableMembersOfFontFamily:familyName];
  
  if (members.count == 1) {
    NSString *psname = members[0][0];
    NSMenuItem *mi = [self menuItemWithTitle:familyName forFontName:psname initialSelection:initSel];
    return mi;
  }
  
  NSMenu *membersSubmenu = [[NSMenu alloc] init];
  NSArray *specimen = members[0];
  NSInteger specimenScore = PTDFontFamilyMemberSpecimenEligibilityScore(specimen);
  for (NSArray *member in members) {
    NSString *psname = member[0];
    NSString *label = member[1];
    
    NSMenuItem *mi = [self menuItemWithTitle:label forFontName:psname initialSelection:initSel];
    [membersSubmenu addItem:mi];
    
    NSInteger newSpecimenScore = PTDFontFamilyMemberSpecimenEligibilityScore(member);
    if (newSpecimenScore > specimenScore) {
      specimen = member;
      specimenScore = newSpecimenScore;
    }
  }
  
  NSMenuItem *familyMenuItem = [self menuItemWithTitle:familyName forFontName:specimen[0] initialSelection:nil];
  familyMenuItem.submenu = membersSubmenu;
  familyMenuItem.action = nil;
  return familyMenuItem;
}


- (NSMenuItem *)menuItemWithTitle:(NSString *)title forFontName:(NSString *)postscriptName initialSelection:(NSString *)initSel
{
  /* this call is what takes time */
  NSFont *font = [NSFont fontWithName:postscriptName size:14.0];
  
  NSMenuItem *menuItem = [[NSMenuItem alloc] init];
  menuItem.attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:@{
    NSFontAttributeName: font,
    NSForegroundColorAttributeName: NSColor.controlTextColor
  }];
  menuItem.representedObject = postscriptName;
  menuItem.target = self;
  menuItem.action = @selector(changeTextBaseFont:);
  
  if (initSel && [postscriptName isEqual:initSel]) {
    menuItem.state = NSControlStateValueOn;
    _selectedFontMenuItem = menuItem;
  }
  
  return menuItem;
}


- (void)updatePopUpWithFont
{
  NSMenuItem *selectedItem = _selectedFontMenuItem;
  NSMenuItem *parentItem;
  
  if (selectedItem.menu.supermenu) {
    NSMenu *rootMenu = selectedItem.menu.supermenu;
    NSInteger i = [rootMenu indexOfItemWithSubmenu:selectedItem.menu];
    parentItem = [rootMenu itemAtIndex:i];
    [self.fontPopUp selectItemAtIndex:i];
  } else {
    [self.fontPopUp selectItem:selectedItem];
  }
  
  NSMenuItem *displayItem;
  if (parentItem) {
    NSMutableAttributedString *str = [selectedItem.attributedTitle mutableCopy];
    NSString *prefix = [parentItem.title stringByAppendingString:@" — "];
    [str replaceCharactersInRange:NSMakeRange(0, 0) withString:prefix];
    displayItem = [[NSMenuItem alloc] init];
    displayItem.attributedTitle = str;
  } else {
    displayItem = selectedItem;
  }
  NSPopUpButtonCell *cell = self.fontPopUp.cell;
  cell.usesItemFromMenu = NO;
  cell.menuItem = displayItem;
}


- (void)changeTextBaseFont:(NSMenuItem *)sender
{
  if (_selectedFontMenuItem) {
    _selectedFontMenuItem.state = NSControlStateValueOff;
  }
  [sender setState:NSControlStateValueOn];
  _selectedFontMenuItem = sender;
  PTDTextTool.baseFontName = [sender representedObject];
  [self updatePopUpWithFont];
}


@end
