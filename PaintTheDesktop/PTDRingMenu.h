//
// PTDRingMenu.h
// PaintTheDesktop -- Created on 17/06/2020.
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
