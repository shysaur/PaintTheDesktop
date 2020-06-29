//
//  PTDScreenMenuItemView.h
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 29/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTDScreenMenuItemView : NSView

@property (nonatomic) IBOutlet NSTextField *screenName;

- (void)setThumbnail:(NSBitmapImageRep *)image;

@end

NS_ASSUME_NONNULL_END
