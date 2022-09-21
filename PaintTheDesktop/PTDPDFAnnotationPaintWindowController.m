//
// PTDPDFAnnotationPaintWindowController.m
// PaintTheDesktop -- Created on 09/01/22.
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

#import "PTDPDFAnnotationPaintWindowController.h"
#import "NSGeometry+PTD.h"


@interface PTDPDFAnnotationPaintWindowController ()

@property (nonatomic, weak) IBOutlet NSScrollView *scrollView;

@end


@implementation PTDPDFAnnotationPaintWindowController


- (NSString *)windowNibName
{
  return @"PTDPDFAnnotationPaintWindowController";
}


- (void)windowDidLoad
{
  [super windowDidLoad];
  self.window.backgroundColor = NSColor.whiteColor;
  self.pageView.borderColor = [NSColor colorWithWhite:0.0 alpha:0.2];
  [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(scrollViewWillStartLiveScroll:) name:NSScrollViewWillStartLiveScrollNotification object:self.scrollView];
  [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(scrollViewDidEndLiveScroll:) name:NSScrollViewDidEndLiveScrollNotification object:self.scrollView];
  [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(scrollViewWillStartLiveMagnify:) name:NSScrollViewWillStartLiveMagnifyNotification object:self.scrollView];
  [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(scrollViewDidEndLiveMagnify:) name:NSScrollViewDidEndLiveMagnifyNotification object:self.scrollView];
}


- (void)setTheDocument:(PDFDocument *)theDocument
{
  [super setTheDocument:theDocument];
  [self updateContentViewSize];
  [self scrollToTop];
}


- (void)setPageIndex:(NSInteger)pageIndex
{
  [super setPageIndex:pageIndex];
  [self updateContentViewSize];
  [self scrollToTop];
}


- (void)windowDidResize:(NSNotification *)notification
{
  NSRect visRect = self.scrollView.contentView.bounds;
  NSPoint top = NSMakePoint(NSMinX(self.pageView.frame), NSMaxY(self.pageView.frame));
  visRect.origin.x -= top.x;
  visRect.origin.y -= top.y;
  
  [self updateContentViewSize];
  
  top = NSMakePoint(NSMinX(self.pageView.frame), NSMaxY(self.pageView.frame));
  visRect.origin.x += top.x;
  visRect.origin.y += top.y;
  visRect.size = self.scrollView.contentView.bounds.size;
  [self.scrollView.contentView scrollToPoint:visRect.origin];
  [self.scrollView reflectScrolledClipView:self.scrollView.contentView];
}


- (void)scrollViewWillStartLiveScroll:(NSNotification *)notification
{
  self.paintViewController.active = NO;
}


- (void)scrollViewDidEndLiveScroll:(NSNotification *)notification
{
  self.paintViewController.active = YES;
}


- (void)scrollViewWillStartLiveMagnify:(NSNotification *)notification
{
  self.paintViewController.active = NO;
  [self.paintViewController.view viewWillStartLiveResize];
}


- (void)scrollViewDidEndLiveMagnify:(NSNotification *)notification
{
  NSRect visRect = self.scrollView.contentView.bounds;
  visRect.origin.x -= self.pageView.frame.origin.x;
  visRect.origin.y -= self.pageView.frame.origin.y;
  
  [self updateContentViewSize];
  
  visRect.origin.x += self.pageView.frame.origin.x;
  visRect.origin.y += self.pageView.frame.origin.y;
  [self.scrollView.contentView scrollToPoint:visRect.origin];
  [self.scrollView reflectScrolledClipView:self.scrollView.contentView];
  
  self.paintViewController.active = YES;
  [self.paintViewController.view viewDidEndLiveResize];
}


- (void)updateContentViewSize
{
  if (!self.pageView.pdfPage)
    return;
  
  NSRect pageRect = [self.pageView.pdfPage boundsForBox:kPDFDisplayBoxCropBox];
  NSView *contentView = self.scrollView.documentView;
  
  CGFloat width = self.scrollView.frame.size.width;
  CGFloat height = ceil(pageRect.size.height / pageRect.size.width * width);
  
  CGFloat xPad = floor(self.scrollView.frame.size.width / 2.0) / self.scrollView.magnification;
  CGFloat yPad = floor(self.scrollView.frame.size.height / 2.0) / self.scrollView.magnification;
  
  [contentView setFrameSize:NSMakeSize(width + 2*xPad, height + 2*yPad)];
  [self.pageView setFrameOrigin:NSMakePoint(xPad, yPad)];
  [self.pageView setFrameSize:NSMakeSize(width, height)];
}


- (void)scrollToTop
{
  NSPoint pageTopLeft = NSMakePoint(NSMinX(self.pageView.frame), NSMaxY(self.pageView.frame));
  NSRect visRect = self.scrollView.contentView.bounds;
  NSPoint newBoundsOrigin = NSMakePoint(pageTopLeft.x, pageTopLeft.y - visRect.size.height);
  [self.scrollView.contentView scrollToPoint:newBoundsOrigin];
  [self.scrollView reflectScrolledClipView:self.scrollView.contentView];
}


@end
