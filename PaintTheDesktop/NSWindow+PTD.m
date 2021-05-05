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
#import "PTDUtils.h"


static NSInteger _forceTopLevelRefCount;


@interface NSWindow ()

- (void)_setWindowNumber:(NSInteger)wn;

@end


@implementation NSWindow (PTD)


+ (void)load
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    PTDSwizzleInstanceMethod(self, @selector(setLevel:), @selector(ptd_sw_setLevel:));
    _forceTopLevelRefCount = 0;
  });
}


+ (void)ptd_pushForceTopLevel
{
  _forceTopLevelRefCount++;
}


+ (void)ptd_popForceTopLevel
{
  if (_forceTopLevelRefCount > 0)
    _forceTopLevelRefCount--;
  else
    NSLog(@"calls to -ptd_popForceTopLevel mismatched with -ptd_pushForceTopLevel");
}


- (void)ptd_sw_setLevel:(NSWindowLevel)windowLevel
{
  if (_forceTopLevelRefCount > 0 && windowLevel < kCGMaximumWindowLevelKey) {
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
