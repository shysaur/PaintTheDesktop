//
// PTDToolOptions.h
// PaintTheDesktop -- Created on 21/03/2021.
//
// Copyright (c) 2021 Daniele Cattaneo
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

@class PTDTool;

extern NSString * const PTDToolOptionsChangedNotification;

extern NSString * const PTDToolOptionsChangedNotificationUserInfoOptionKey;
extern NSString * const PTDToolOptionsChangedNotificationUserInfoToolKey;
extern NSString * const PTDToolOptionsChangedNotificationUserInfoObjectKey;

typedef BOOL (^PTDValidationBlock)(id value);

@interface PTDToolOptions : NSObject

+ (PTDToolOptions *)sharedOptions;

- (void)registerGlobalOption:(NSString *)optionId types:(NSArray <Class> *)clss defaultValue:(id)value validationBlock:(nullable PTDValidationBlock)valid;
- (void)registerOption:(NSString *)optionId ofToolClass:(nullable Class)toolClass types:(NSArray <Class> *)clss defaultValue:(id)value validationBlock:(nullable PTDValidationBlock)valid;

- (void)setObject:(id)object forOption:(NSString *)optionId ofToolClass:(nullable Class)tool;
- (void)restoreDefaultForOption:(NSString *)optionId ofToolClass:(nullable Class)tool;

- (id)objectForOption:(NSString *)optionId ofToolClass:(nullable Class)tool;

@end

NS_ASSUME_NONNULL_END
