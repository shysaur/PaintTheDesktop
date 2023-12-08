//
// PDFPage+PTD.m
// PaintTheDesktop -- Created on 08/12/23.
//
// Copyright (c) 2023 Daniele Cattaneo
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

#import "PDFPage+PTD.h"

@implementation PDFPage (PTD)


- (NSRect)ptd_rotatedBoundsForBox:(PDFDisplayBox)box
{
  NSRect rect = [self boundsForBox:box];
  NSInteger angle = -self.rotation;
  CGAffineTransform xfm = CGAffineTransformMakeRotation((CGFloat)angle / 180.0 * M_PI);
  rect = CGRectApplyAffineTransform(rect, xfm);
  return rect;
}


- (NSRect)ptd_rotatedCropBox
{
  return [self ptd_rotatedBoundsForBox:kPDFDisplayBoxCropBox];
}


@end
