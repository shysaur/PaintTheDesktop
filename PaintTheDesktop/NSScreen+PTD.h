//
//  NSScreen+PTD.h
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 12/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSScreen (PTD)

@property (nonatomic, readonly) CGDirectDisplayID ptd_displayID;

@end

NS_ASSUME_NONNULL_END
