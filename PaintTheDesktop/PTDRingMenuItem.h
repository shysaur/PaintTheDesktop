//
// PTDRingMenuItem.h
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

NS_ASSUME_NONNULL_BEGIN

@interface PTDRingMenuItem : NSObject

+ (PTDRingMenuItem *)itemWithImage:(NSImage *)image target:(nullable id)target action:(nullable SEL)action;
+ (PTDRingMenuItem *)itemWithText:(NSString *)text target:(nullable id)target action:(nullable SEL)action;

@property (nonatomic) NSImage *image;
@property (nonatomic, nullable) NSImage *selectedImage;

- (void)setText:(NSString *)text;

@property (nonatomic) NSControlStateValue state;

@property (nonatomic, weak) id target;
@property (nonatomic) SEL action;

@property (nonatomic) NSInteger tag;
@property (nonatomic, nullable) id representedObject;

@end

NS_ASSUME_NONNULL_END
