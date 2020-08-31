//
// PTDRingMenuRing.h
// PaintTheDesktop -- Created on 19/06/2020.
//
// Copyright (c) 2020 Daniele Cattaneo
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
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
