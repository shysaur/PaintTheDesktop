//
//  PTDRingMenu.h
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 17/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PTDRingMenuRing.h"
#import "PTDRingMenuItem.h"
#import "PTDRingMenuSpring.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTDRingMenu : NSObject

+ (PTDRingMenu *)ringMenu;

- (void)addRing:(PTDRingMenuRing *)ring;
- (void)addRing:(PTDRingMenuRing *)ring inPosition:(NSInteger)pos;
- (PTDRingMenuRing *)newRing;

@property (nonatomic, readonly) NSInteger ringCount;
@property (nonatomic, readonly) NSArray <PTDRingMenuRing *> *rings;

- (void)removeRingInPosition:(NSInteger)i;

- (void)popUpMenuWithEvent:(NSEvent *)event forView:(nullable NSView *)view;
- (void)popUpMenuAtLocation:(NSPoint)location inWindow:(nullable NSWindow *)window event:(nullable NSEvent *)event;

@end

NS_ASSUME_NONNULL_END
