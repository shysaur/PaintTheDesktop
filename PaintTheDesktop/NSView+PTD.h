//
//  NSView+PTD.h
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 15/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSView (PTD)

- (NSPoint)ptd_backingAlignedPoint:(NSPoint)point;

@end

NS_ASSUME_NONNULL_END
