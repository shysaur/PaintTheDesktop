//
// PTDResetTool.m
// PaintTheDesktop -- Created on 10/06/2020.
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

#import "PTDDrawingSurface.h"
#import "PTDResetTool.h"
#import "PTDToolManager.h"
#import "PTDPaintView.h"


NSString * const PTDToolIdentifierResetTool = @"PTDToolIdentifierResetTool";


@implementation PTDResetTool


+ (NSString *)toolIdentifier
{
  return PTDToolIdentifierResetTool;
}


+ (PTDRingMenuItem *)menuItem
{
  NSImage *image = [[NSBundle bundleForClass:[self class]] imageForResource:@"PTDToolIconReset"];
  return [PTDRingMenuItem itemWithImage:image target:nil action:nil];
}


- (void)mouseClickedAtPoint:(NSPoint)point
{
  [self.currentDrawingSurface beginCanvasDrawing];
  NSRect bounds = [self.currentDrawingSurface bounds];
  [NSGraphicsContext.currentContext setCompositingOperation:NSCompositingOperationClear];
  [[NSColor colorWithWhite:1.0 alpha:0.0] setFill];
  NSRectFill(bounds);
  
  NSShowAnimationEffect(NSAnimationEffectPoof, NSEvent.mouseLocation, NSZeroSize, nil, nil, NULL);
}


@end
