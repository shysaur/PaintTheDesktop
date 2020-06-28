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

@interface PTDPaintWindow : NSWindowController <NSWindowDelegate>

- (instancetype)initWithDisplay:(CGDirectDisplayID)display;

@property (nonatomic) CGDirectDisplayID display;
@property (nonatomic) NSString *displayName;

@property (nonatomic) BOOL active;

- (NSBitmapImageRep *)snapshot;
- (void)restoreFromSnapshot:(NSBitmapImageRep *)bitmap;

@end

NS_ASSUME_NONNULL_END
