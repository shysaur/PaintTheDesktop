//
// PTDPDFPaintWindowController.m
// PaintTheDesktop -- Created on 10/01/22.
//
// Copyright (c) 2022 Daniele Cattaneo
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

#import <Carbon/Carbon.h>
#import "PTDPDFPaintWindowController.h"
#import "PTDPDFPageView.h"
#import "PTDAppDelegate.h"
#import "PTDAnnotationOverlayPDFPage.h"
#import "NSGeometry+PTD.h"
#import "PTDThumbnailMenuItemView.h"
#import "PDFPage+PTD.h"


@interface PTDPDFPaintWindowController ()

@end


@implementation PTDPDFPaintWindowController {
  BOOL _openingFile;
  NSMutableArray<NSData *> *_annotationPages;
}


- (void)windowDidLoad
{
  [super windowDidLoad];
  _pageIndex = -1;
  self.paintViewController.active = NO;
  self.window.backgroundColor = [NSColor blackColor];
  [PTDAppDelegate.appDelegate pushAppShouldShowInDock];
}


- (void)showWindow:(id)sender
{
  [super showWindow:sender];
  
  if (self.theDocument || _openingFile)
    return;
  
  _openingFile = YES;
  NSOpenPanel *openPanel = [[NSOpenPanel alloc] init];
  openPanel.allowedFileTypes = @[
    (__bridge NSString *)kUTTypePDF];
  [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse result) {
    if (result != NSModalResponseOK) {
      [self close];
    } else {
      self.displayName = openPanel.URL.lastPathComponent;
      self.window.representedURL = openPanel.URL;
      self.theDocument = [[PDFDocument alloc] initWithURL:openPanel.URL];
    }
  }];
}


- (void)updateWindowTitle
{
  NSString *title;
  
  if (self.theDocument) {
    if (self.pageIndex < 0) {
      title = [NSString stringWithFormat:NSLocalizedString(@"%@ (start / %ld)", @"Presentation window title bar format, on blank initial slide"), self.displayName, self.theDocument.pageCount];
    } else if (self.pageIndex >= self.theDocument.pageCount) {
      title = [NSString stringWithFormat:NSLocalizedString(@"%@ (end / %ld)", @"Presentation window title bar format, on blank final slide"), self.displayName, self.theDocument.pageCount];
    } else {
      title = [NSString stringWithFormat:NSLocalizedString(@"%@ (%ld / %ld)", @"Presentation window title bar format"), self.displayName, self.pageIndex + 1, self.theDocument.pageCount];
    }
  } else {
    title = self.displayName;
  }
  
  self.window.title = title;
}


- (void)setTheDocument:(PDFDocument *)theDocument
{
  _theDocument = theDocument;
  [self resetAnnotations];
  self.pageIndex = 0;
}


- (void)resetAnnotations
{
  NSInteger pc = self.theDocument.pageCount;
  _annotationPages = [NSMutableArray arrayWithCapacity:pc];
  for (NSInteger i = 0; i < pc; i++) {
    [_annotationPages addObject:[NSData data]];
  }
}


- (void)setPageIndex:(NSInteger)pageIndex
{
  if (pageIndex == _pageIndex)
    return;
  
  [self stashCanvas];
  
  _pageIndex = pageIndex;
  
  if (pageIndex >= 0 && pageIndex < self.theDocument.pageCount) {
    self.pageView.pdfPage = [self.theDocument pageAtIndex:_pageIndex];
    self.paintViewController.active = YES;
  } else {
    self.pageView.pdfPage = nil;
    self.paintViewController.active = NO;
  }
  
  if (![self restoreCanvas])
    [self clearCanvas];
  
  [self updateWindowTitle];
}


- (void)clearCanvas
{
  @autoreleasepool {
    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext.currentContext = self.paintViewController.view.graphicsContext;
    
    NSRect bounds = self.paintViewController.view.paintRect;
    [NSGraphicsContext.currentContext setCompositingOperation:NSCompositingOperationClear];
    [[NSColor colorWithWhite:1.0 alpha:0.0] setFill];
    NSRectFill(bounds);
    
    [NSGraphicsContext restoreGraphicsState];
    [self.paintViewController.view setNeedsDisplay:YES];
  }
}


- (BOOL)stashCanvas
{
  if (_pageIndex < 0 || _pageIndex >= self.theDocument.pageCount)
    return NO;
    
  NSBitmapImageRep *painting = [self snapshot];
  NSData *pngPainting = [painting representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
  _annotationPages[_pageIndex] = pngPainting;
  return YES;
}


- (BOOL)restoreCanvas
{
  if (_pageIndex < 0 || _pageIndex >= self.theDocument.pageCount)
    return NO;
  
  NSData *pngPainting = _annotationPages[_pageIndex];
  if (pngPainting.length == 0)
    return NO;
    
  NSBitmapImageRep *painting = [NSBitmapImageRep imageRepWithData:pngPainting];
  [self restoreFromSnapshot:painting];
  return YES;
}


- (void)keyDown:(NSEvent *)event
{
  if (!self.theDocument)
    return;
    
  NSInteger dPage = 0;
  if (event.keyCode == kVK_LeftArrow) {
    dPage = -1;
  } else if (event.keyCode == kVK_RightArrow || event.keyCode == kVK_Space || event.keyCode == kVK_Return) {
    dPage = +1;
  }
  
  if (dPage != 0) {
    NSInteger numPages = self.theDocument.pageCount;
    NSInteger page = self.pageIndex + dPage;
    if (page < -1) {
      NSBeep();
      page = -1;
    } else if (page > numPages) {
      NSBeep();
      page = numPages;
    }
    self.pageIndex = page;
  }
}


- (NSImage *)thumbnail
{
  [self stashCanvas];
  return [self thumbnailOfPageIndex:self.pageIndex withArea:10000];
}


- (NSImage *)thumbnailOfPageIndex:(NSInteger)pageIndex withArea:(CGFloat)area
{
  if (pageIndex < 0 || pageIndex >= self.theDocument.pageCount) {
    NSSize size = self.pageView.bounds.size;
    return [NSImage imageWithSize:size flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
      [[NSColor blackColor] setFill];
      NSRectFill(dstRect);
      return YES;
    }];
  }
  
  PDFPage *page = [self.theDocument pageAtIndex:pageIndex];
  NSRect box = [page ptd_rotatedCropBox];
  NSSize destSize = PTD_NSSizePreservingAspectWithArea(box.size, area);
  NSImage *baseThumb = [page thumbnailOfSize:destSize forBox:kPDFDisplayBoxCropBox];
  NSData *snapshotData =_annotationPages[pageIndex];
  NSBitmapImageRep *snapshot;
  if (snapshotData.length > 0)
    snapshot = [[NSBitmapImageRep alloc] initWithData:snapshotData];
  NSRect destRect = (NSRect){NSZeroPoint, destSize};
  
  return [NSImage imageWithSize:destSize flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
    [[NSColor whiteColor] setFill];
    NSRectFill(destRect);
    [baseThumb drawInRect:destRect fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0];
    if (snapshot)
      [snapshot drawInRect:destRect fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0 respectFlipped:NO hints:nil];
    return YES;
  }];
}


- (NSMenu *)windowMenu
{
  NSMenu *submenu = [[NSMenu alloc] init];
  NSMenuItem *tmp;
  
  tmp = [submenu addItemWithTitle:NSLocalizedString(@"Save Page Annotations As...", @"Menu item for saving single page annotations to file") action:@selector(saveImageAs:) keyEquivalent:@""];
  tmp.target = self;
  tmp = [submenu addItemWithTitle:NSLocalizedString(@"Restore Page Annotations...", @"Menu item for loading single page annotations from file") action:@selector(openImage:) keyEquivalent:@""];
  tmp.target = self;
  
  [submenu addItem:[NSMenuItem separatorItem]];
  
  tmp = [submenu addItemWithTitle:NSLocalizedString(@"Save Annotated PDF...", @"Menu item for saving annotated PDFs to file") action:@selector(saveAnnotatedDocumentAs:) keyEquivalent:@""];
  tmp.target = self;
  
  [submenu addItem:[NSMenuItem separatorItem]];
  
  [submenu addItemWithTitle:NSLocalizedString(@"Skip to page", @"Menu item label for PDF page selection") action:nil keyEquivalent:@""];
  NSInteger pageCount = self.theDocument.pageCount;
  for (NSInteger i=0; i<pageCount; i++) {
    PDFPage *page = [self.theDocument pageAtIndex:i];
    NSString *label = [NSString stringWithFormat:NSLocalizedString(@"%@ (%ld / %ld)", @"Menu item format for PDF page selection"), page.label, i+1, pageCount];
    NSImage *thumb = [self thumbnailOfPageIndex:i withArea:2500];
    
    tmp = [NSMenuItem ptd_menuItemWithLabel:label thumbnail:thumb thumbnailArea:5000];
    tmp.tag = i;
    tmp.action = @selector(skipToPage:);
    tmp.target = self;
    tmp.state = i == self.pageIndex ? NSOnState : NSOffState;
    
    [submenu addItem:tmp];
  }
  
  return submenu;
}


- (PDFDocument *)annotatedPDFDocument
{
  [self stashCanvas];
  
  PDFDocument *newDocument = [[PDFDocument alloc] init];
  NSInteger pageCount = self.theDocument.pageCount;
  for (NSInteger i=0; i<pageCount; i++) {
    PDFPage *origPage = [self.theDocument pageAtIndex:i];
    NSData *image = _annotationPages[i];
    if (image.length > 0) {
      PTDAnnotationOverlayPDFPage *page = [[PTDAnnotationOverlayPDFPage alloc] initWithPDFPage:origPage overlay:image];
      [newDocument insertPage:page atIndex:i];
    } else {
      [newDocument insertPage:origPage atIndex:i];
    }
  }
  return newDocument;
}


- (void)saveAnnotatedDocumentAs:(id)sender
{
  NSSavePanel *savePanel = [[NSSavePanel alloc] init];
  savePanel.allowedFileTypes = @[@"pdf"];
  [savePanel beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse result) {
    if (result == NSModalResponseCancel)
      return;
    dispatch_async(dispatch_get_main_queue(), ^{
      PDFDocument *doc = [self annotatedPDFDocument];
      [doc writeToURL:savePanel.URL];
    });
  }];
}


- (void)skipToPage:(id)sender
{
  NSInteger pageIndex = [sender tag];
  if (pageIndex >= 0 && pageIndex < self.theDocument.pageCount)
    self.pageIndex = pageIndex;
}


- (void)windowWillClose:(NSNotification *)notification
{
  [super windowWillClose:notification];
  [PTDAppDelegate.appDelegate popAppShouldShowInDock];
}


@end
