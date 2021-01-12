//
// NSGeometry+PTD.h
// PaintTheDesktop -- Created on 27/06/2020.
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

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

NS_INLINE NSPoint PTD_NSRectCenter(NSRect rect)
{
  return NSMakePoint(
      rect.origin.x + rect.size.width / 2.0,
      rect.origin.y + rect.size.height / 2.0);
}

NS_INLINE NSRect PTD_NSMakeRectFromPoints(NSPoint p0, NSPoint p1)
{
  if (p0.x > p1.x) {
    CGFloat temp = p0.x;
    p0.x = p1.x;
    p1.x = temp;
  }
  if (p0.y > p1.y) {
    CGFloat temp = p0.y;
    p0.y = p1.y;
    p1.y = temp;
  }
  return (NSRect){p0, NSMakeSize(p1.x - p0.x, p1.y - p0.y)};
}

NS_INLINE NSRect PTD_NSNormalizedRect(NSRect rect)
{
  if (rect.size.width < 0) {
    rect.origin.x += rect.size.width;
    rect.size.width = -rect.size.width;
  }
  if (rect.size.height < 0) {
    rect.origin.y += rect.size.height;
    rect.size.height = -rect.size.height;
  }
  return rect;
}

NS_ASSUME_NONNULL_END
