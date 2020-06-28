//
//  NSImage+PTD.h
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 27/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSImage (PTD)

- (instancetype)ptd_imageByTintingWithColor:(NSColor *)color;

@end

NS_ASSUME_NONNULL_END
