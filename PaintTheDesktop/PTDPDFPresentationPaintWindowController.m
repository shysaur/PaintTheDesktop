//
// PTDPDFPresentationPaintWindowController.m
// PaintTheDesktop -- Created on 05/05/2021.
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

#import <Carbon/Carbon.h>
#import "PTDPDFPresentationPaintWindowController.h"
#import "PTDPDFPageView.h"
#import "PTDAppDelegate.h"


@interface PTDPDFPresentationPaintWindowController ()

@property (nonatomic) IBOutlet PTDPDFPageView *pageView;

@property (nonatomic) PDFDocument *theDocument;
@property (nonatomic) NSInteger pageIndex;

@end


@implementation PTDPDFPresentationPaintWindowController {
  BOOL _openingFile;
  NSMutableArray<NSData *> *_annotationPages;
}


- (NSString *)windowNibName
{
  return @"PTDPDFPresentationPaintWindowController";
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
    if (result != NSModalResponseOK)
      [self close];
    self.theDocument = [[PDFDocument alloc] initWithURL:openPanel.URL];
  }];
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


- (void)windowWillClose:(NSNotification *)notification
{
  [super windowWillClose:notification];
  [PTDAppDelegate.appDelegate popAppShouldShowInDock];
}


@end
