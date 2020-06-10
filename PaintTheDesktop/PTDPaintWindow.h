//
//  PTDPaintWindow.h
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 08/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PTDToolInterface;

@interface PTDPaintWindow : NSWindowController

- (instancetype)initWithScreen:(NSScreen *)screen;

@property (readonly, nonatomic) NSScreen *screen;

@property (nonatomic) BOOL active;

@end

NS_ASSUME_NONNULL_END
