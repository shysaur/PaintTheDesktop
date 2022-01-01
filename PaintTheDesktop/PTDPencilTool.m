//
// PTDPencilTool.m
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

#import <Quartz/Quartz.h>
#import "PTDToolManager.h"
#import "PTDPencilTool.h"
#import "PTDDrawingSurface.h"
#import "PTDTool.h"
#import "PTDCursor.h"
#import "PTDGraphics.h"
#import "PTDToolOptions.h"


NSString * const PTDToolIdentifierPencilTool = @"PTDToolIdentifierPencilTool";

NSString * const PTDPencilToolOptionSmoothingCoefficient = @"smoothingCoefficient";
NSString * const PTDPencilToolOptionLiveSmoothing = @"liveSmoothing";


@implementation PTDPencilTool {
  CGMutablePathRef _currentPath;
  CAShapeLayer *_overlayShape;
}


+ (void)registerDefaults
{
  PTDToolOptions *o = PTDToolOptions.sharedOptions;
  [o registerOption:PTDPencilToolOptionSmoothingCoefficient ofToolClass:self types:@[[NSNumber class]] defaultValue:@(0.5) validationBlock:nil];
  [o registerOption:PTDPencilToolOptionLiveSmoothing ofToolClass:self types:@[[NSNumber class]] defaultValue:@(NO) validationBlock:nil];
}


+ (void)setSmoothingCoefficient:(double)smoothingCoefficient
{
  [PTDToolOptions.sharedOptions setObject:@(smoothingCoefficient) forOption:PTDPencilToolOptionSmoothingCoefficient ofToolClass:self.class];
}


+ (double)smoothingCoefficient
{
  return [[PTDToolOptions.sharedOptions objectForOption:PTDPencilToolOptionSmoothingCoefficient ofToolClass:self.class] doubleValue];
}


+ (void)setLiveSmoothing:(BOOL)liveSmoothing
{
  [PTDToolOptions.sharedOptions setObject:@(liveSmoothing) forOption:PTDPencilToolOptionLiveSmoothing ofToolClass:self.class];
}


+ (BOOL)liveSmoothing
{
  return [[PTDToolOptions.sharedOptions objectForOption:PTDPencilToolOptionLiveSmoothing ofToolClass:self.class] boolValue];
}


+ (NSString *)toolIdentifier
{
  return PTDToolIdentifierPencilTool;
}


- (void)activate
{
  [self updateCursor];
}


- (void)dragDidStartAtPoint:(NSPoint)point
{
  _currentPath = CGPathCreateMutable();
  CGPathMoveToPoint(_currentPath, NULL, point.x, point.y);
  [self createDragIndicator];
}


- (void)dragDidContinueFromPoint:(NSPoint)prevPoint toPoint:(NSPoint)nextPoint
{
  CGPathAddLineToPoint(_currentPath, NULL, nextPoint.x, nextPoint.y);
  [self updateDragIndicator];
}


- (void)dragDidEndAtPoint:(NSPoint)point
{
  [self.currentDrawingSurface beginCanvasDrawing];
  
  CGContextRef ctxt = NSGraphicsContext.currentContext.CGContext;
  CGContextBeginPath(ctxt);
  CGContextSetLineCap(ctxt, kCGLineCapRound);
  CGContextSetLineJoin(ctxt, kCGLineJoinRound);
  CGContextSetLineWidth(ctxt, self.size);
  CGContextSetStrokeColorWithColor(ctxt, self.color.CGColor);
  
  if ([self.class smoothingCoefficient] > 0.001) {
    CGContextAddPath(ctxt, [self smoothedPath]);
  } else {
    CGContextAddPath(ctxt, _currentPath);
  }
  
  CGContextStrokePath(ctxt);
  CGPathRelease(_currentPath);
  [self removeDragIndicator];
}


#define WRAP(n, p) (((n) % (p) + (p)) % (p))
#define ST_MAX(a, b) ((a) > (b) ? (a) : (b))

static const int smoothHistSize = 8;
static const unsigned int smoothHistBufSize = ST_MAX(smoothHistSize*2+1, 0x20);
static const double smoothBellMaxWidth = 5.0;

typedef struct PTDSmoothedPathContext {
  CGMutablePathRef smoothedPath;
  NSPoint history[smoothHistBufSize];
  double smoothingCoeff;
  unsigned int historyIdx;
  BOOL pathStarted;
} PTDSmoothedPathContext;

static void _PTDPencilToolSmoothedPathCallback(void *info, const CGPathElement *element)
{
  PTDSmoothedPathContext *spc = (PTDSmoothedPathContext *)info;
  if (element->type == kCGPathElementMoveToPoint) {
    for (int i=0; i<smoothHistBufSize; i++)
      spc->history[i] = element->points[0];
  }
  _PTDPencilToolSmoothedPathCalcNextPoint(spc, element->points[0]);
}

static void _PTDPencilToolSmoothedPathCalcNextPoint(PTDSmoothedPathContext *spc, NSPoint point)
{
  spc->history[WRAP((spc->historyIdx++), smoothHistBufSize)] = point;
  if (spc->historyIdx <= smoothHistSize)
    return;
    
  CGPoint accum = {0.0, 0.0};
  CGFloat totalWeight = 0.0;
  
  int centerIdx = WRAP(spc->historyIdx - smoothHistSize - 1, smoothHistBufSize);
  CGFloat distAccum = 0.0;
  
  for (int i=-smoothHistSize; i<=smoothHistSize; i++) {
    int pi, pj;
    if (i < 0) {
      /* points before center, in reverse order */
      pi = WRAP(centerIdx - smoothHistSize - i - 1, smoothHistBufSize);
      pj = WRAP(centerIdx - smoothHistSize - i, smoothHistBufSize);
    } else if (i == 0) {
      pi = pj = centerIdx;
      distAccum = 0;
    } else {
      /* points after center, in direct order */
      pi = WRAP(centerIdx + i, smoothHistBufSize);
      pj = WRAP(pi - 1, smoothHistBufSize);
    }
    
    CGPoint point1 = spc->history[pi];
    CGPoint point2 = spc->history[pj];
    CGFloat dx = point1.x - point2.x;
    CGFloat dy = point1.y - point2.y;
    CGFloat dist = sqrt(dx * dx + dy * dy);
    distAccum += dist;
    
    CGFloat sigma = smoothBellMaxWidth * spc->smoothingCoeff;
    CGFloat weight = exp(-(distAccum * distAccum) / (2 * sigma * sigma));
        
    accum.x += point1.x * weight;
    accum.y += point1.y * weight;
    totalWeight += weight;
  }
  
  accum.x /= totalWeight;
  accum.y /= totalWeight;
  
  if (!spc->pathStarted) {
    spc->pathStarted = YES;
    CGPathMoveToPoint(spc->smoothedPath, NULL, accum.x, accum.y);
  } else {
    CGPathAddLineToPoint(spc->smoothedPath, NULL, accum.x, accum.y);
  }
}

- (CGPathRef)smoothedPath
{
  PTDSmoothedPathContext spc;
  spc.smoothedPath = CGPathCreateMutable();
  spc.historyIdx = 0;
  spc.smoothingCoeff = [self.class smoothingCoefficient];
  spc.pathStarted = NO;
  
  CGPathApply(_currentPath, &spc, _PTDPencilToolSmoothedPathCallback);
  
  NSPoint lastPoint = spc.history[WRAP(spc.historyIdx - 1, smoothHistBufSize)];
  for (int i=0; i<smoothHistSize; i++)
    _PTDPencilToolSmoothedPathCalcNextPoint(&spc, lastPoint);
  
  return CFAutorelease(spc.smoothedPath);
}


+ (PTDRingMenuItem *)menuItem
{
  return [PTDRingMenuItem itemWithImage:[NSImage imageNamed:@"PTDToolIconPencil"] target:nil action:nil];
}


- (void)reloadOptions
{
  [super reloadOptions];
  [self updateCursor];
}


- (void)updateCursor
{
  PTDCursor *cursor = [[PTDCursor alloc] init];
  cursor.image = PTDCrosshairWithBrushOutlineImage(self.size, self.color);
  cursor.hotspot = NSMakePoint(cursor.image.size.width / 2.0, cursor.image.size.height / 2.0);
  self.cursor = cursor;
}


- (void)createDragIndicator
{
  _overlayShape = [[CAShapeLayer alloc] init];
  [self.currentDrawingSurface.overlayLayer addSublayer:_overlayShape];
  _overlayShape.lineWidth = self.size;
  _overlayShape.strokeColor = self.color.CGColor;
  _overlayShape.fillColor = NSColor.clearColor.CGColor;
  _overlayShape.lineCap = kCALineCapRound;
  _overlayShape.lineJoin = kCALineJoinRound;
  _overlayShape.frame = self.currentDrawingSurface.overlayLayer.bounds;
  [self updateDragIndicator];
}


- (void)updateDragIndicator
{
  [CATransaction begin];
  CATransaction.disableActions = YES;
  if (![self.class liveSmoothing] || [self.class smoothingCoefficient] <= 0.001)
    _overlayShape.path = _currentPath;
  else
    _overlayShape.path = [self smoothedPath];
  [CATransaction commit];
}


- (void)removeDragIndicator
{
  [_overlayShape removeFromSuperlayer];
  _overlayShape = nil;
}


@end
