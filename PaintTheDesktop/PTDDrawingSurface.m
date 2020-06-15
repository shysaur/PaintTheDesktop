//
//  PTDDrawingSurface.m
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 15/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import "PTDDrawingSurface.h"
#import "PTDPaintView.h"


@implementation PTDDrawingSurface {
  PTDPaintView *_paintView;
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
  [NSGraphicsContext setCurrentContext:_paintView.graphicsContext];
}


- (void)beginOverlayDrawing
{
  _touchedPaintView = YES;
  [NSGraphicsContext setCurrentContext:_paintView.overlayGraphicsContext];
}


- (NSRect)bounds
{
  return _paintView.paintRect;
}


- (void)dealloc
{
  [self endDrawing];
}


- (void)endDrawing
{
  [NSGraphicsContext setCurrentContext:nil];
  if (_touchedPaintView) {
    [_paintView setNeedsDisplay:YES];
  }
}


@end
