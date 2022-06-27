//
// NSBezierPath+PTD.m
// PaintTheDesktop -- Created on 22/01/2021.
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

#import "NSBezierPath+PTD.h"


@implementation NSBezierPath (PTD)


- (CGPathRef)ptd_CGPath
{
  CGMutablePathRef path = CGPathCreateMutable();
  
  BOOL didClosePath = YES;
  NSInteger numElements = self.elementCount;

  for (NSInteger i = 0; i < numElements; i++) {
    NSPoint points[3];
  
    switch ([self elementAtIndex:i associatedPoints:points]) {
      case NSMoveToBezierPathElement:
        CGPathMoveToPoint(path, NULL, points[0].x, points[0].y);
        break;
        
      case NSLineToBezierPathElement:
        CGPathAddLineToPoint(path, NULL, points[0].x, points[0].y);
        didClosePath = NO;
        break;
        
      case NSCurveToBezierPathElement:
        CGPathAddCurveToPoint(path, NULL, points[0].x, points[0].y,
                              points[1].x, points[1].y,
                              points[2].x, points[2].y);
        didClosePath = NO;
        break;
        
      case NSClosePathBezierPathElement:
        CGPathCloseSubpath(path);
        didClosePath = YES;
        break;
    }
  }
  
  if (!didClosePath)
    CGPathCloseSubpath(path);
  
  CFAutorelease(path);
  return path;
}


@end
