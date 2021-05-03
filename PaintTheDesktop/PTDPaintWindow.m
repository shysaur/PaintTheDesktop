//
// PTDPaintWindow.m
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

#import "PTDPaintWindow.h"
#import "PTDPaintViewController.h"
#import "PTDPaintView.h"
#import "NSScreen+PTD.h"


@interface PTDPaintWindow ()

@end


@implementation PTDPaintWindow 


- (instancetype)init
{
  self = [super init];
  _displayName = NSLocalizedString(@"untitled", @"");
  return self;
}


- (NSString *)windowNibName
{
  return @"PTDPaintWindow";
}


- (void)windowDidLoad
{
  [super windowDidLoad];
  
  self.window.backgroundColor = [NSColor colorWithWhite:1.0 alpha:1.0];
  self.window.title = self.displayName;
}


- (void)setDisplayName:(NSString *)displayName
{
  _displayName = displayName;
  if (self.windowLoaded)
    self.window.title = _displayName;
}


- (void)windowWillClose:(NSNotification *)notification
{
  [self.delegate paintWindowWillClose:self];
}


- (NSBitmapImageRep *)snapshot
{
  return self.paintViewController.view.snapshot;
}


- (void)restoreFromSnapshot:(NSBitmapImageRep *)bitmap
{
  @autoreleasepool {
    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext.currentContext = self.paintViewController.view.graphicsContext;
    [bitmap drawInRect:self.paintViewController.view.paintRect];
    [NSGraphicsContext restoreGraphicsState];
    [self.paintViewController.view setNeedsDisplay:YES];
  }
}


- (NSMenu *)windowMenu
{
  NSMenu *submenu = [[NSMenu alloc] init];
  NSMenuItem *tmp;
  tmp = [submenu addItemWithTitle:NSLocalizedString(@"Save As...", @"Menu item for saving a drawing to file") action:@selector(saveImageAs:) keyEquivalent:@""];
  tmp.target = self;
  tmp = [submenu addItemWithTitle:NSLocalizedString(@"Restore...", @"Menu item for loading a drawing from file") action:@selector(openImage:) keyEquivalent:@""];
  tmp.target = self;
  return submenu;
}


- (void)saveImageAs:(id)sender
{
  NSSavePanel *savePanel = [[NSSavePanel alloc] init];
  savePanel.allowedFileTypes = @[@"png"];
  NSModalResponse resp = [savePanel runModal];
  if (resp == NSModalResponseCancel)
    return;
  
  NSBitmapImageRep *snapshot = [self snapshot];
  NSURL *file = savePanel.URL;
  NSData *dataToSave;
  dataToSave = [snapshot representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
  [dataToSave writeToURL:file atomically:NO];
}


- (void)openImage:(id)sender
{
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
  [self restoreFromSnapshot:image];
}


@end
