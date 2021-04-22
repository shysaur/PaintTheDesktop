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

@end


@implementation PTDToolOptionData

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


- (void)setObject:(id)object forOption:(NSString *)optionId ofTool:(nullable PTDTool *)tool
{
  NSString *dictKey = [self dictionaryKeyForOption:optionId ofToolClass:tool.class];
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
  id plistObject = object;
  
  Class singleClass;
  if (optionData.unarchivingClasses.count == 1)
    singleClass = optionData.unarchivingClasses.anyObject;
  if (!singleClass || ![singleClass isSubclassOfClass:[NSString class]] || ![singleClass isSubclassOfClass:[NSNumber class]]) {
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


- (void)restoreDefaultForOption:(NSString *)optionId ofTool:(nullable PTDTool *)tool
{
  NSString *dictKey = [self dictionaryKeyForOption:optionId ofToolClass:tool.class];
  PTDToolOptionData *optionData = [_optionData objectForKey:dictKey];
  [self setObject:optionData.defaultValue forOption:optionId ofTool:tool];
}


- (id)objectForOption:(NSString *)optionId ofTool:(nullable PTDTool *)tool
{
  NSString *dictKey = [self dictionaryKeyForOption:optionId ofToolClass:tool.class];
  PTDToolOptionData *optionData = [_optionData objectForKey:dictKey];
  NSAssert(optionData, @"Option dictKey %@ not properly registered", dictKey);
  
  id res = [_values objectForKey:dictKey];
  if (res)
    return res;
  
  NSUserDefaults *prefs = NSUserDefaults.standardUserDefaults;
  NSString *key = [NSString stringWithFormat:@"PTDToolOptions.%@", dictKey];
  id objFromDefaults = [prefs objectForKey:key];
  if (objFromDefaults) {
    Class singleClass;
    if (optionData.unarchivingClasses.count == 1)
      singleClass = optionData.unarchivingClasses.anyObject;
      
    if (singleClass && [objFromDefaults isKindOfClass:singleClass]) {
      if (optionData.validationBlock && !optionData.validationBlock(objFromDefaults))
        NSLog(@"warning: option %@ is corrupt (validation failed), using default", dictKey);
      else
        res = objFromDefaults;
        
    } else if ([objFromDefaults isKindOfClass:[NSData class]]) {
      NSError *error;
      id decodedObj = [NSKeyedUnarchiver unarchivedObjectOfClasses:optionData.unarchivingClasses fromData:objFromDefaults error:&error];
      if (!decodedObj)
        NSLog(@"warning: option %@ is corrupt (unarchiving failed %@), using default", error, dictKey);
      else if (optionData.validationBlock && !optionData.validationBlock(decodedObj))
        NSLog(@"warning: option %@ is corrupt (validation failed), using default", dictKey);
      else
        res = decodedObj;
    }
  }
  
  if (!res)
    res = optionData.defaultValue;
    
  [_values setObject:res forKey:dictKey];
  return res;
}


@end
