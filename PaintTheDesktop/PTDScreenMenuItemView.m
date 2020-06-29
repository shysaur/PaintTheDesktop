//
//  PTDScreenMenuItemView.m
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 29/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
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
