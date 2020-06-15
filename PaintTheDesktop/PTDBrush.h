//
//  PTDBrush.h
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 15/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTDBrush : NSObject

@property (nonatomic) NSColor *color;
@property (nonatomic) CGFloat size;

- (NSArray <NSMenuItem *> *)menuOptions;

@end

NS_ASSUME_NONNULL_END
