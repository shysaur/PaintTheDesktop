//
// NSWindow+PTD.m
// PaintTheDesktop -- Created on 21/07/20.
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
