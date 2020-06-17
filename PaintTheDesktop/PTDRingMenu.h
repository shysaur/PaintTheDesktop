//
//  PTDRingMenu.h
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 17/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class PTDRingMenuItem;
@class PTDRingMenuSpring;

@interface PTDRingMenu : NSObject

- (void)addItem:(id)item inRing:(NSInteger)ring;
- (void)addItem:(id)item inPosition:(NSInteger)i ring:(NSInteger)ring;

- (void)removeItemInPosition:(NSInteger)i ring:(NSInteger)ring;

- (void)setGravityAngle:(CGFloat)radians forRing:(NSInteger)ring;
- (void)setGravityAngle:(CGFloat)radians forRing:(NSInteger)ring itemRange:(NSRange)range;
- (void)ring:(NSInteger)ring gravityAngle:(CGFloat *)angle itemRange:(NSRange *)range;

@property (nonatomic, readonly) NSInteger ringCount;
- (NSArray *)itemArray;
- (NSArray *)itemArrayForRing:(NSInteger)ring;

- (void)popUpMenuWithEvent:(NSEvent *)event forView:(nullable NSView *)view;
- (void)popUpMenuAtLocation:(NSPoint)location inWindow:(nullable NSWindow *)window;

@end

NS_ASSUME_NONNULL_END
