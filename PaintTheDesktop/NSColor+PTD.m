//
// NSColor+PTD.m
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

#import "NSColor+PTD.h"


@implementation NSColor (PTD)


+ (NSColor *)ptd_ringMenuHighlightColor
{
  if (@available(macOS 10.14, *)) {
      return [NSColor controlAccentColor];
  } else {
      return [NSColor selectedMenuItemColor];
  }
}


+ (NSColor *)ptd_ringMenuItemTextColor
{
  return NSColor.labelColor;
}


+ (NSColor *)ptd_ringMenuItemSelectedTextColor
{
  return NSColor.selectedMenuItemTextColor;
}


+ (NSColor *)ptd_ringMenuDisabledItemTextColor
{
  return NSColor.disabledControlTextColor;
}


- (NSColor *)ptd_contrastingCursorBorderColor
{
  NSColor *grayscaleColor = [self colorUsingColorSpaceName:NSCalibratedWhiteColorSpace];
  CGFloat white, alpha;
  if (grayscaleColor.whiteComponent > sqrt(2.0) / 2.0) {
    white = 0.0;
    alpha = 1.0 - sqrt(2.0) / 2.0;
  } else {
    white = 1.0;
    alpha = sqrt(2.0) / 2.0;
  }
  return [NSColor colorWithCalibratedWhite:white alpha:alpha];
}


@end
