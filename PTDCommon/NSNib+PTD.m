//
// NSNib+PTD.m
// PaintTheDesktop -- Created on 29/06/2020.
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

#import "NSNib+PTD.h"


@implementation NSNib (PTD)


- (id)ptd_instantiateObjectWithIdentifier:(NSString *)ident withOwner:(nullable id)owner
{
  NSArray *itms;
  BOOL res = [self instantiateWithOwner:owner topLevelObjects:&itms];
  if (!res)
    return nil;
  for (id obj in itms) {
    if ([obj respondsToSelector:@selector(identifier)]) {
      NSString *thisIdent = [obj identifier];
      if ([ident isEqual:thisIdent])
        return obj;
    }
  }
  return nil;
}


@end
