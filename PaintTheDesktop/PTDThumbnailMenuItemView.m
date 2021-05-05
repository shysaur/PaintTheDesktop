//
// PTDThumbnailMenuItemView.m
// PaintTheDesktop -- Created on 29/06/2020.
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

#import "PTDThumbnailMenuItemView.h"
#import "NSGeometry+PTD.h"
#import "NSNib+PTD.h"


@interface PTDThumbnailMenuItemView ()

@property (nonatomic) IBOutlet NSImageView *screenThumbnail;
@property (nonatomic) IBOutlet NSBox *thumbnailBox;
@property (nonatomic) IBOutlet NSLayoutConstraint *widthThumbnailConstraint;
@property (nonatomic) IBOutlet NSLayoutConstraint *heightThumbnailConstraint;

@end


@implementation PTDThumbnailMenuItemView


- (instancetype)initWithCoder:(NSCoder *)coder
{
  self = [super initWithCoder:coder];
  _thumbnailArea = 10000;
  return self;
}


- (instancetype)initWithFrame:(NSRect)frame
{
  self = [super initWithFrame:frame];
  _thumbnailArea = 10000;
  return self;
}


- (void)awakeFromNib
{
  if (@available(macOS 10.16, *)) {
    self.leftBorderConstraint.constant = 10;
  }
  self.label.font = [NSFont menuFontOfSize:0];
}


- (void)drawRect:(NSRect)dirtyRect
{
  if (self.enclosingMenuItem.isHighlighted) {
    self.label.textColor = [NSColor selectedMenuItemTextColor];
    self.thumbnailBox.borderColor = [NSColor selectedMenuItemTextColor];
  } else {
    self.label.textColor = [NSColor labelColor];
    self.thumbnailBox.borderColor = [NSColor labelColor];
  }
  [super drawRect:dirtyRect];
}


- (void)setThumbnailArea:(CGFloat)thumbnailArea
{
  _thumbnailArea = thumbnailArea;
  [self updateThumbnail];
}


- (void)setThumbnail:(NSImage *)img
{
  _thumbnail = img;
  [self updateThumbnail];
}


- (void)updateThumbnail
{
  if (!_thumbnail)
    return;
  
  NSSize size;
  _thumbnail.size = size = PTD_NSSizePreservingAspectWithArea(_thumbnail.size, self.thumbnailArea);
  
  CGFloat wPad = self.widthThumbnailConstraint.constant - self.screenThumbnail.frame.size.width;
  CGFloat hPad = self.heightThumbnailConstraint.constant - self.screenThumbnail.frame.size.height;
  self.widthThumbnailConstraint.constant = size.width + wPad;
  self.heightThumbnailConstraint.constant = size.height + hPad;
  
  self.screenThumbnail.image = _thumbnail;
}


@end


@interface NSMenuItem ()

- (BOOL)_viewHandlesEvents;
- (void)_setViewHandlesEvents:(BOOL)arg1;

@end


@implementation NSMenuItem (PTDScreenMenuItemView)


+ (NSMenuItem *)ptd_menuItemWithLabel:(NSString *)label thumbnail:(NSImage *)thumb thumbnailArea:(CGFloat)area
{
  static NSNib *viewNib;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    viewNib = [[NSNib alloc] initWithNibNamed:@"PTDThumbnailMenuItemView" bundle:[NSBundle mainBundle]];
  });

  PTDThumbnailMenuItemView *view = [viewNib ptd_instantiateObjectWithIdentifier:@"screenMenuItem" withOwner:nil];
  NSMenuItem *mi = [[NSMenuItem alloc] initWithTitle:label action:nil keyEquivalent:@""];
  view.label.stringValue = label;
  if (area >= 1)
    view.thumbnailArea = area;
  [view setThumbnail:thumb];
  mi.view = view;
  [mi _setViewHandlesEvents:NO];
  [view setFrameSize:view.fittingSize];
  return mi;
}


@end
