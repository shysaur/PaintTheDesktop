//
//  PTDRingMenuRing.h
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 19/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PTDRingMenuItem;
@class PTDRingMenuSpring;

NS_ASSUME_NONNULL_BEGIN

@interface PTDRingMenuRing : NSObject

+ (PTDRingMenuRing *)ring;

- (void)addItem:(id)item;
- (void)addItem:(id)item inPosition:(NSInteger)i;
- (PTDRingMenuItem *)addItemWithImage:(NSImage *)image target:(nullable id)target action:(nullable SEL)action;
- (PTDRingMenuItem *)addItemWithText:(NSString *)text target:(nullable id)target action:(nullable SEL)action;
- (PTDRingMenuSpring *)addSpringWithElasticity:(CGFloat)k;

- (void)removeItemInPosition:(NSInteger)i;

@property (nonatomic) CGFloat gravityAngle;
@property (nonatomic) NSRange gravityMass;

- (void)beginGravityMassGroupWithAngle:(CGFloat)angle;
- (void)endGravityMassGroup;

@property (nonatomic, readonly) NSInteger itemCount;
@property (nonatomic, readonly) NSArray *itemArray;

@end

NS_ASSUME_NONNULL_END
