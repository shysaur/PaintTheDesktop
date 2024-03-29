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


@interface PTDToolOptionData: NSObject

@property (nonatomic) id defaultValue;
@property (nonatomic) NSSet <Class> *unarchivingClasses;
@property (nonatomic, nullable) PTDValidationBlock validationBlock;

@property (nonatomic, readonly) BOOL requiresArchiving;

@end


@implementation PTDToolOptionData


- (BOOL)requiresArchiving
{
  static NSSet <Class> *plistClasses;
  if (plistClasses == nil) {
    plistClasses = [NSSet setWithArray:@[
      NSString.class, NSNumber.class, NSDictionary.class, NSArray.class, NSDate.class
    ]];
  }
  return ![self.unarchivingClasses isSubsetOfSet:plistClasses];
}


@end


@interface PTDToolOptions ()

@property (nonatomic, readonly) NSMutableDictionary <NSString *, PTDToolOptionData *> *optionData;
@property (nonatomic, readonly) NSMutableDictionary *values;

@end


@implementation PTDToolOptions


- (instancetype)init
{
  self = [super init];
  _values = [[NSMutableDictionary alloc] init];
  _optionData = [[NSMutableDictionary alloc] init];
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


- (NSString *)dictionaryKeyForOption:(NSString *)optionId ofToolClass:(nullable Class)toolClass
{
  if (!toolClass) {
    return [NSString stringWithFormat:@"global.%@", optionId];
  }
  return [NSString stringWithFormat:@"tool.%@.%@", [toolClass toolIdentifier], optionId];
}


- (void)registerGlobalOption:(NSString *)optionId types:(NSArray <Class> *)clss defaultValue:(id)value validationBlock:(nullable PTDValidationBlock)valid
{
  [self registerOption:optionId ofToolClass:nil types:clss defaultValue:value validationBlock:valid];
}


- (void)registerOption:(NSString *)optionId ofToolClass:(nullable Class)toolClass types:(NSArray <Class> *)clss defaultValue:(id)value validationBlock:(nullable PTDValidationBlock)valid
{
  NSString *optionKey = [self dictionaryKeyForOption:optionId ofToolClass:toolClass];
  PTDToolOptionData *data = [[PTDToolOptionData alloc] init];
  NSAssert(value, @"Value cannot be nil");
  data.defaultValue = value;
  data.validationBlock = valid;
  data.unarchivingClasses = [NSSet setWithArray:clss];
  [_optionData setObject:data forKey:optionKey];
}


- (void)setObject:(id)object forOption:(NSString *)optionId ofToolClass:(nullable Class)tool
{
  NSString *dictKey = [self dictionaryKeyForOption:optionId ofToolClass:tool];
  PTDToolOptionData *optionData = [_optionData objectForKey:dictKey];
  NSAssert(optionData, @"Option dictKey %@ not properly registered", dictKey);
  
  NSMutableDictionary *userInfo = [@{
      PTDToolOptionsChangedNotificationUserInfoOptionKey: optionId,
      PTDToolOptionsChangedNotificationUserInfoObjectKey: object
    } mutableCopy];
  if (tool) {
    [userInfo setObject:tool forKey:PTDToolOptionsChangedNotificationUserInfoToolKey];
  }
  
  [_values setObject:object forKey:dictKey];
  
  NSUserDefaults *prefs = NSUserDefaults.standardUserDefaults;
  id plistObject;
  if (!optionData.requiresArchiving)
    plistObject = object;
  else
    plistObject = [NSKeyedArchiver archivedDataWithRootObject:object requiringSecureCoding:YES error:nil];
  
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


- (void)restoreDefaultForOption:(NSString *)optionId ofToolClass:(nullable Class)tool
{
  NSString *dictKey = [self dictionaryKeyForOption:optionId ofToolClass:tool];
  PTDToolOptionData *optionData = [_optionData objectForKey:dictKey];
  [self setObject:optionData.defaultValue forOption:optionId ofToolClass:tool];
}


- (id)objectForOption:(NSString *)optionId ofToolClass:(nullable Class)tool
{
  NSString *dictKey = [self dictionaryKeyForOption:optionId ofToolClass:tool];
  PTDToolOptionData *optionData = [_optionData objectForKey:dictKey];
  NSAssert(optionData, @"Option dictKey %@ not properly registered", dictKey);
  
  id res = [_values objectForKey:dictKey];
  if (res)
    return res;
  
  NSUserDefaults *prefs = NSUserDefaults.standardUserDefaults;
  NSString *key = [NSString stringWithFormat:@"PTDToolOptions.%@", dictKey];
  id objFromDefaults = [prefs objectForKey:key];
  if (objFromDefaults) {
    if ([objFromDefaults isKindOfClass:[NSData class]]) {
      NSError *error;
      res = [NSKeyedUnarchiver unarchivedObjectOfClasses:optionData.unarchivingClasses fromData:objFromDefaults error:&error];
      if (!res)
        NSLog(@"warning: option %@ is corrupt (unarchiving failed %@), using default", error, dictKey);
    } else {
      res = objFromDefaults;
      if (optionData.unarchivingClasses.count == 1)
        if (![res isKindOfClass:optionData.unarchivingClasses.anyObject]) {
          NSLog(@"warning: option %@ is corrupt (type validation failed), using default", dictKey);
          res = nil;
        }
    }
    
    if (res && optionData.validationBlock && !optionData.validationBlock(res)) {
      NSLog(@"warning: option %@ is corrupt (validation failed), using default", dictKey);
      res = nil;
    }
  }
  
  if (!res)
    res = optionData.defaultValue;
    
  [_values setObject:res forKey:dictKey];
  return res;
}


@end
