//
//  NSWindow+PTD.m
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 21/07/20.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import "NSWindow+PTD.h"
#import <objc/runtime.h>


void PTDSwizzleInstanceMethod(id self, SEL originalSelector, SEL swizzledSelector)
{
  Class class = [self class];
  
  Method originalMethod = class_getInstanceMethod(class, originalSelector);
  Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
  
  BOOL didAddMethod = class_addMethod(class,
      originalSelector,
      method_getImplementation(swizzledMethod),
      method_getTypeEncoding(swizzledMethod));
  
  if (didAddMethod) {
    class_replaceMethod(class,
        swizzledSelector,
        method_getImplementation(originalMethod),
        method_getTypeEncoding(originalMethod));
  } else {
    method_exchangeImplementations(originalMethod, swizzledMethod);
  }
}


@implementation NSWindow (PTD)


+ (void)load
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    PTDSwizzleInstanceMethod(self, @selector(setLevel:), @selector(ptd_sw_setLevel:));
  });
}


- (void)ptd_sw_setLevel:(NSWindowLevel)windowLevel
{
  if (windowLevel < kCGMaximumWindowLevelKey) {
    NSLog(@"elevated window %ld (%@) level from %ld to %d",
        (long)self.windowNumber, self, (long)windowLevel, kCGMaximumWindowLevelKey);
    [self ptd_sw_setLevel:kCGMaximumWindowLevelKey];
  } else {
    NSLog(@"not elevated window %ld (%@) level from %ld",
        (long)self.windowNumber, self, (long)windowLevel);
    [self ptd_sw_setLevel:windowLevel];
  }
}


@end
