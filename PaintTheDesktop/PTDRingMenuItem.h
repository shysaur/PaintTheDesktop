//
//  PTDRingMenuItem.h
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 17/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTDRingMenuItem : NSObject

@property (nonatomic) NSImage *contents;

@property (nonatomic) id target;
@property (nonatomic) SEL action;

@end

NS_ASSUME_NONNULL_END
