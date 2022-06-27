//
// NSMenu+PTD.m
// PaintTheDesktop -- Created on 29/10/21.
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

#import "NSMenu+PTD.h"
#import <objc/runtime.h>


@interface PTDNSMenuIndentationInfoCache: NSObject

@property (nonatomic) BOOL hasLargeIndent;

@end


@implementation PTDNSMenuIndentationInfoCache

@end


@implementation NSMenu (PTD)


- (BOOL)ptd_itemsHaveLargeIndentation
{
  if (@available(macOS 11.0, *)) {
    PTDNSMenuIndentationInfoCache *cache = objc_getAssociatedObject(self, @selector(ptd_itemsHaveLargeIndentation));
    if (cache) {
      return cache.hasLargeIndent;
    }
    
    cache = [[PTDNSMenuIndentationInfoCache alloc] init];
    for (NSMenuItem *itm in self.itemArray) {
      if (itm.state != NSControlStateValueOff) {
        cache.hasLargeIndent = YES;
        break;
      }
    }
    
    objc_setAssociatedObject(self, @selector(ptd_itemsHaveLargeIndentation), cache, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return cache.hasLargeIndent;
  } else {
    return NO;
  }
}


@end
