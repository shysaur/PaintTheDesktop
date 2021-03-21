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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class PTDTool;

extern NSString * const PTDToolOptionsChangedNotification;

extern NSString * const PTDToolOptionsChangedNotificationUserInfoOptionKey;
extern NSString * const PTDToolOptionsChangedNotificationUserInfoToolKey;
extern NSString * const PTDToolOptionsChangedNotificationUserInfoObjectKey;

@interface PTDToolOptions : NSObject

+ (PTDToolOptions *)sharedOptions;

- (void)registerGlobalDefaults:(NSDictionary *)defaults;
- (void)registerDefaultsOfToolClass:(nullable Class)toolClass;
- (void)registerDefaults:(NSDictionary *)defaults ofToolClass:(nullable Class)toolClass;

- (void)setObject:(id)object forOption:(NSString *)optionId ofTool:(nullable PTDTool *)tool;
- (void)setString:(NSString *)object forOption:(NSString *)optionId ofTool:(nullable PTDTool *)tool;
- (void)setInteger:(NSInteger)value forOption:(NSString *)optionId ofTool:(nullable PTDTool *)tool;
- (void)setDouble:(double)value forOption:(NSString *)optionId ofTool:(nullable PTDTool *)tool;
- (void)setBool:(BOOL)value forOption:(NSString *)optionId ofTool:(nullable PTDTool *)tool;

- (id)objectForOption:(NSString *)optionId ofTool:(nullable PTDTool *)tool;
- (NSString *)stringForOption:(NSString *)optionId ofTool:(nullable PTDTool *)tool;
- (NSInteger)integerForOption:(NSString *)optionId ofTool:(nullable PTDTool *)tool;
- (double)doubleForOption:(NSString *)optionId ofTool:(nullable PTDTool *)tool;
- (BOOL)boolForOption:(NSString *)optionId ofTool:(nullable PTDTool *)tool;

@end

NS_ASSUME_NONNULL_END
