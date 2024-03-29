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


- (void)endCanvasDrawing
{
  if (_canvasContext) {
    [_canvasContext flushGraphics];
  }
  [NSGraphicsContext setCurrentContext:nil];
  _canvasContext = nil;
  if (_touchedPaintView) {
    [_paintView setNeedsDisplay:YES];
  }
}


- (CALayer *)overlayLayer
{
  return _paintView.overlayLayer;
}


- (void)beginTextEditingWithTextView:(NSTextView *)textView;
{
  [_paintView addSubview:textView];
  [_paintView.window makeKeyAndOrderFront:nil];
  [_paintView.window makeFirstResponder:textView];
}


- (void)endTextEditing:(NSTextView *)textView
{
  [textView removeFromSuperview];
}


- (NSBitmapImageRep *)captureRect:(NSRect)rect
{
  return [_paintView snapshotOfRect:rect];
}


- (NSRect)bounds
{
  return _paintView.paintRect;
}


- (NSPoint)convertPointFromScreen:(NSPoint)point
{
  NSPoint p2 = [_paintView.window convertPointFromScreen:point];
  return [_paintView convertPoint:p2 fromView:nil];
}


- (NSPoint)alignPointToBacking:(NSPoint)point
{
  return [_paintView ptd_backingAlignedPoint:point];
}


- (void)dealloc
{
  if (_canvasContext) {
    [self endCanvasDrawing];
  }
}


@end
