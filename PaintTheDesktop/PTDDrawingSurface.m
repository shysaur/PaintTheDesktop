//
// PTDDrawingSurface.m
// PaintTheDesktop -- Created on 15/06/2020.
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
#import "PTDPaintView.h"
#import "NSView+PTD.h"


@implementation PTDDrawingSurface {
  PTDPaintView *_paintView;
  NSGraphicsContext *_canvasContext;
  BOOL _touchedPaintView;
}


- (instancetype)initWithPaintView:(PTDPaintView *)paintView
{
  self = [super init];
  _paintView = paintView;
  return self;
}


- (void)beginCanvasDrawing
{
  _touchedPaintView = YES;
  if (!_canvasContext)
    _canvasContext = _paintView.graphicsContext;
  [NSGraphicsContext setCurrentContext:_canvasContext];
}


- (CALayer *)overlayLayer
{
  return _paintView.overlayLayer;
}


- (NSImageRep *)captureRect:(NSRect)rect
{
  return [_paintView snapshotOfRect:rect];
}


- (NSRect)bounds
{
  return _paintView.paintRect;
}


- (NSPoint)alignPointToBacking:(NSPoint)point
{
  return [_paintView ptd_backingAlignedPoint:point];
}


- (void)dealloc
{
  [self endDrawing];
}


- (void)endDrawing
{
  [NSGraphicsContext setCurrentContext:nil];
  _canvasContext = nil;
  if (_touchedPaintView) {
    [_paintView setNeedsDisplay:YES];
  }
}


@end
