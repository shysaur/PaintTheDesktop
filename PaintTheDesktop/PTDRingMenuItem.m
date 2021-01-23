//
// PTDRingMenuItem.m
// PaintTheDesktop -- Created on 17/06/2020.
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

#import "PTDRingMenuItem.h"

@implementation PTDRingMenuItem


- (instancetype)init
{
  self = [super init];
  _enabled = YES;
  return self;
}


+ (PTDRingMenuItem *)itemWithImage:(NSImage *)image target:(nullable id)target action:(nullable SEL)action
{
  PTDRingMenuItem *res = [[[self class] alloc] init];
  res.image = image;
  res.target = target;
  res.action = action;
  return res;
}


+ (PTDRingMenuItem *)itemWithText:(NSString *)text target:(nullable id)target action:(nullable SEL)action
{
  PTDRingMenuItem *res = [[[self class] alloc] init];
  [res setText:text];
  res.target = target;
  res.action = action;
  return res;
}


- (void)setText:(NSString *)text
{
  NSFont *font = [NSFont systemFontOfSize:NSFont.systemFontSize];
  NSDictionary *attrib = @{
    NSFontAttributeName: font,
    NSForegroundColorAttributeName: [NSColor blackColor]
  };
  NSSize textSize = [text sizeWithAttributes:attrib];
  textSize.width = ceil(textSize.width);
  textSize.height = ceil(textSize.height);
  self.image = [NSImage imageWithSize:textSize flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
    [text drawAtPoint:NSZeroPoint withAttributes:attrib];
    return YES;
  }];
  self.image.template = YES;
}


@end
