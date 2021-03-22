//
// PTDToolOptions.m
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

#import "PTDToolOptions.h"
#import "PTDTool.h"


NSString * const PTDToolOptionsChangedNotification = @"PTDToolOptionsChangedNotification";

NSString * const PTDToolOptionsChangedNotificationUserInfoOptionKey = @"option";
NSString * const PTDToolOptionsChangedNotificationUserInfoToolKey = @"tool";
NSString * const PTDToolOptionsChangedNotificationUserInfoObjectKey = @"object";


@interface PTDToolOptions ()

@property (nonatomic, readonly) NSMutableDictionary *defaults;
@property (nonatomic, readonly) NSMutableDictionary *values;

@end


@implementation PTDToolOptions


- (instancetype)init
{
  self = [super init];
  _values = [[NSMutableDictionary alloc] init];
  _defaults = [[NSMutableDictionary alloc] init];
  return self;
}


+ (PTDToolOptions *)sharedOptions
{
  static PTDToolOptions *singleton;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    singleton = [[PTDToolOptions alloc] init];
  });
  return singleton;
}


- (void)registerDefaults:(NSDictionary *)defaults ofToolClass:(nullable Class)tool
{
  for (NSString *key in defaults) {
    NSString *dictKey = [self dictionaryKeyForOption:key ofToolClass:tool.class];
    [_defaults setObject:defaults[key] forKey:dictKey];
  }
}


- (void)registerGlobalDefaults:(NSDictionary *)defaults
{
  [self registerDefaults:defaults ofToolClass:nil];
}


- (void)registerDefaultsOfToolClass:(Class)toolClass
{
  [self registerDefaults:[toolClass defaultOptions] ofToolClass:toolClass];
}


- (NSString *)dictionaryKeyForOption:(NSString *)optionId ofToolClass:(nullable Class)toolClass
{
  if (!toolClass) {
    return [NSString stringWithFormat:@"global.%@", optionId];
  }
  return [NSString stringWithFormat:@"tool.%@.%@", [toolClass toolIdentifier], optionId];
}


- (void)setObject:(id)object forOption:(NSString *)optionId ofTool:(nullable PTDTool *)tool
{
  NSString *dictKey = [self dictionaryKeyForOption:optionId ofToolClass:tool.class];
  
  NSMutableDictionary *userInfo = [@{
      PTDToolOptionsChangedNotificationUserInfoOptionKey: optionId,
      PTDToolOptionsChangedNotificationUserInfoObjectKey: object
    } mutableCopy];
  if (tool) {
    [userInfo setObject:tool forKey:PTDToolOptionsChangedNotificationUserInfoToolKey];
  }
  
  [_values setObject:object forKey:dictKey];
  
  NSUserDefaults *prefs = NSUserDefaults.standardUserDefaults;
  id plistObject = object;
  if (![plistObject isKindOfClass:[NSString class]] && ![plistObject isKindOfClass:[NSNumber class]]) {
    plistObject = [NSKeyedArchiver archivedDataWithRootObject:object requiringSecureCoding:YES error:nil];
  }
  if (plistObject) {
    NSString *key = [NSString stringWithFormat:@"PTDToolOptions.%@", dictKey];
    [prefs setObject:plistObject forKey:key];
  } else {
    NSLog(@"warning: cannot store %@ to user defaults, archiving failed", object);
  }
  
  [[NSNotificationCenter defaultCenter]
      postNotificationName:PTDToolOptionsChangedNotification
      object:self
      userInfo:userInfo];
}


- (void)setString:(NSString *)object forOption:(NSString *)optionId ofTool:(nullable PTDTool *)tool
{
  [self setObject:object forOption:optionId ofTool:tool];
}


- (void)setColor:(NSColor *)object forOption:(NSString *)optionId ofTool:(nullable PTDTool *)tool
{
  [self setObject:object forOption:optionId ofTool:tool];
}


- (void)setInteger:(NSInteger)value forOption:(NSString *)optionId ofTool:(nullable PTDTool *)tool
{
  [self setObject:@(value) forOption:optionId ofTool:tool];
}


- (void)setDouble:(double)value forOption:(NSString *)optionId ofTool:(nullable PTDTool *)tool
{
  [self setObject:@(value) forOption:optionId ofTool:tool];
}


- (void)setBool:(BOOL)value forOption:(NSString *)optionId ofTool:(nullable PTDTool *)tool
{
  [self setObject:@(value) forOption:optionId ofTool:tool];
}


- (id)objectForOption:(NSString *)optionId ofTool:(nullable PTDTool *)tool
{
  NSString *dictKey = [self dictionaryKeyForOption:optionId ofToolClass:tool.class];
  
  id res = [_values objectForKey:dictKey];
  if (res)
    return res;
  
  NSUserDefaults *prefs = NSUserDefaults.standardUserDefaults;
  NSString *key = [NSString stringWithFormat:@"PTDToolOptions.%@", dictKey];
  res = [prefs objectForKey:key];
  if (res)
    return res;
  
  return [_defaults objectForKey:dictKey];
}


- (NSString *)stringForOption:(NSString *)optionId ofTool:(nullable PTDTool *)tool
{
  id obj = [self objectForOption:optionId ofTool:tool];
  if (obj && [obj isKindOfClass:[NSString class]])
    return (NSString *)obj;
  return nil;
}


- (NSColor *)colorForOption:(NSString *)optionId ofTool:(nullable PTDTool *)tool
{
  id obj = [self objectForOption:optionId ofTool:tool];
  if (obj && [obj isKindOfClass:[NSColor class]])
    return (NSColor *)obj;
  if (obj && [obj isKindOfClass:[NSData class]]) {
    NSColor *res = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSColor class] fromData:obj error:nil];
    return res;
  }
  return nil;
}


- (NSNumber *)numberForOption:(NSString *)optionId ofTool:(nullable PTDTool *)tool
{
  id obj = [self objectForOption:optionId ofTool:tool];
  if (obj && [obj isKindOfClass:[NSNumber class]])
    return (NSNumber *)obj;
  return @(0);
}


- (NSInteger)integerForOption:(NSString *)optionId ofTool:(nullable PTDTool *)tool
{
  NSNumber *obj = [self numberForOption:optionId ofTool:tool];
  return obj.integerValue;
}


- (double)doubleForOption:(NSString *)optionId ofTool:(nullable PTDTool *)tool
{
  NSNumber *obj = [self numberForOption:optionId ofTool:tool];
  return obj.doubleValue;
}


- (BOOL)boolForOption:(NSString *)optionId ofTool:(nullable PTDTool *)tool
{
  NSNumber *obj = [self numberForOption:optionId ofTool:tool];
  return obj.boolValue;
}


@end
