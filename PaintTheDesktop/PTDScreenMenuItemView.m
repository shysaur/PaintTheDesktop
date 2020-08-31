//
// PTDScreenMenuItemView.m
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

#import "PTDScreenMenuItemView.h"


@interface PTDScreenMenuItemView ()

@property (nonatomic) IBOutlet NSImageView *screenThumbnail;
@property (nonatomic) IBOutlet NSBox *thumbnailBox;
@property (nonatomic) IBOutlet NSLayoutConstraint *widthThumbnailConstraint;
@property (nonatomic) IBOutlet NSLayoutConstraint *heightThumbnailConstraint;

@end


@implementation PTDScreenMenuItemView


- (void)drawRect:(NSRect)dirtyRect
{
  if (self.enclosingMenuItem.isHighlighted) {
    self.screenName.textColor = [NSColor selectedMenuItemTextColor];
    self.thumbnailBox.borderColor = [NSColor selectedMenuItemTextColor];
  } else {
    self.screenName.textColor = [NSColor labelColor];
    self.thumbnailBox.borderColor = [NSColor labelColor];
  }
  [super drawRect:dirtyRect];
}


- (void)setThumbnail:(NSBitmapImageRep *)imagerep
{
  const CGFloat area = 10000;
  CGFloat scale = sqrt(area / (imagerep.pixelsHigh * imagerep.pixelsWide));
  CGFloat w = imagerep.pixelsWide * scale;
  CGFloat h = imagerep.pixelsHigh * scale;
  
  NSImage *img = [[NSImage alloc] init];
  img.size = NSMakeSize(w, h);
  [img addRepresentation:imagerep];
  
  CGFloat wPad = self.widthThumbnailConstraint.constant - self.screenThumbnail.frame.size.width;
  CGFloat hPad = self.heightThumbnailConstraint.constant - self.screenThumbnail.frame.size.height;
  self.widthThumbnailConstraint.constant = w + wPad;
  self.heightThumbnailConstraint.constant = h + hPad;
  
  self.screenThumbnail.image = img;
}


@end
