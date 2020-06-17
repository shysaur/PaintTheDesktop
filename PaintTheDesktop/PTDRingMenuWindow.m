//
//  PTDRingMenu.m
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 16/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import <Quartz/Quartz.h>
#import "NSColor+PTD.h"
#import "PTDRingMenuWindow.h"
#import "PTDRingMenu.h"
#import "PTDRingMenuItem.h"
#import "PTDRingMenuSpring.h"


@interface PTDRingMenuWindowItemLayout: PTDRingMenuItem

- (instancetype)initWithRingMenuItem:(PTDRingMenuItem *)item;

@property (nonatomic) CALayer *layer;

@property (nonatomic) CGFloat distanceFromCenter;
@property (nonatomic) CGFloat angleOnRing;

- (CGFloat)maximumExtensionRadius;

- (void)updateLayerWithCenter:(CGPoint)center;

@end


@implementation PTDRingMenuWindowItemLayout


- (instancetype)initWithRingMenuItem:(PTDRingMenuItem *)item
{
  self = [super init];
  self.contents = item.contents;
  self.target = item.target;
  self.action = item.action;
  
  _layer = [[CALayer alloc] init];
  _layer.contents = self.contents;
  _layer.anchorPoint = CGPointMake(0.5, 0.5);
  _layer.zPosition = 1.0;
  _layer.frame = (NSRect){NSZeroPoint, self.contents.size};
  
  return self;
}


- (void)updateLayerWithCenter:(CGPoint)center
{
  if ([[NSUserDefaults standardUserDefaults] boolForKey:@"debug"]) {
    _layer.backgroundColor = [[NSColor redColor] CGColor];
  }
  
  CGFloat sinv = sin(_angleOnRing), cosv = cos(_angleOnRing);
  NSPoint myCenter = NSMakePoint(
      cosv * _distanceFromCenter + center.x,
      sinv * _distanceFromCenter + center.y);
  _layer.position = myCenter;
}


- (CGFloat)maximumExtensionRadius
{
  CGFloat sinv = sin(_angleOnRing), cosv = cos(_angleOnRing);
  NSPoint center = NSMakePoint(
      cosv * _distanceFromCenter,
      sinv * _distanceFromCenter);
      
  NSSize diagonal = self.contents.size;
  diagonal.width /= 2.0;
  diagonal.height /= 2.0;
  if (cosv < 0)
    diagonal.width = -diagonal.width;
  if (sinv < 0)
    diagonal.height = -diagonal.height;
  
  NSPoint outermostPos = NSMakePoint(
      center.x + diagonal.width,
      center.y + diagonal.height);
  return sqrt(outermostPos.x * outermostPos.x + outermostPos.y * outermostPos.y);
}


@end


@interface PTDRingMenuWindowRingInfo : NSObject

@property (nonatomic) CGFloat radius;
@property (nonatomic) CGFloat width;

@end

@implementation PTDRingMenuWindowRingInfo

@end



@implementation PTDRingMenuWindow {
  IBOutlet NSView *_mainView;
  
  NSMutableArray <PTDRingMenuWindowItemLayout *> *_layout;
  NSMutableArray <PTDRingMenuWindowRingInfo *> *_rings;
  CALayer *_selectionLayer;
  
  PTDRingMenuWindowItemLayout *_dragStartItem;
  BOOL _endOfLife;
}


- (instancetype)initWithRingMenu:(PTDRingMenu *)menu
{
  self = [super init];
  [self _layoutMenu:menu];
  return self;
}


- (NSString *)windowNibName
{
  return @"PTDRingMenuWindow";
}


#pragma mark - Event Handling


- (void)_createTrackingAreas
{
  NSTrackingAreaOptions options = NSTrackingActiveAlways |
    NSTrackingInVisibleRect | NSTrackingMouseEnteredAndExited |
    NSTrackingMouseMoved;
  NSTrackingArea *area = [[NSTrackingArea alloc]
    initWithRect:_mainView.frame
    options:options owner:self userInfo:nil];
  [_mainView addTrackingArea:area];
}


- (void)mouseMoved:(NSEvent *)event
{
  PTDRingMenuWindowItemLayout *found = [self _hitTestAtPoint:event.locationInWindow];
  [self _updateSelectionLayerForItem:found clicked:NO];
}


- (void)mouseDown:(NSEvent *)event
{
  _dragStartItem = [self _hitTestAtPoint:event.locationInWindow];
  [self _updateSelectionLayerForItem:_dragStartItem clicked:NO];
}


- (void)mouseDragged:(NSEvent *)event
{
  PTDRingMenuWindowItemLayout *found = [self _hitTestAtPoint:event.locationInWindow];
  [self _updateSelectionLayerForItem:found clicked:NO];
}


- (void)mouseUp:(NSEvent *)event
{
  PTDRingMenuWindowItemLayout *found = [self _hitTestAtPoint:event.locationInWindow];
  if (found == _dragStartItem && _dragStartItem.action && !_endOfLife) {
    [NSApp sendAction:_dragStartItem.action to:_dragStartItem.target from:nil];
  }
  [self _updateSelectionLayerForItem:found clicked:YES];
}


- (PTDRingMenuWindowItemLayout *)_hitTestAtPoint:(NSPoint)point
{
  PTDRingMenuWindowItemLayout *res;
  for (PTDRingMenuWindowItemLayout *item in _layout) {
    if (NSPointInRect(point, item.layer.frame))
      return item;
  }
  return res;
}


#pragma mark - Layout & Setup


- (void)windowDidLoad
{
  [super windowDidLoad];
  
  self.window.backgroundColor = [NSColor clearColor];
  self.window.opaque = NO;
  
  _mainView.wantsLayer = YES;
  CALayer *rootLayer = [[CALayer alloc] init];
  rootLayer.backgroundColor = [[NSColor clearColor] CGColor];
  
  CGPoint center = CGPointMake(
      _mainView.bounds.size.width / 2.0,
      _mainView.bounds.size.height / 2.0);
  for (PTDRingMenuWindowItemLayout *li in _layout) {
    [li updateLayerWithCenter:center];
    [rootLayer addSublayer:li.layer];
  }
  
  CALayer *backdropLyr = [[CALayer alloc] init];
  backdropLyr.contents = [self _backdrop];
  backdropLyr.frame = (CGRect){CGPointZero, _mainView.bounds.size};
  [rootLayer addSublayer:backdropLyr];
    
  rootLayer.frame = _mainView.bounds;
  _mainView.layer = rootLayer;
  
  [self _createTrackingAreas];
  
  if ([[NSUserDefaults standardUserDefaults] boolForKey:@"debug"]) {
    CALayer *dbgCenterLyr = [[CALayer alloc] init];
    dbgCenterLyr.backgroundColor = [[NSColor blueColor] CGColor];
    dbgCenterLyr.frame = CGRectMake(0, 0, 1, 1);
    dbgCenterLyr.position = center;
    [rootLayer addSublayer:dbgCenterLyr];
  }
}


- (NSImage *)_backdrop
{
  NSArray <PTDRingMenuWindowRingInfo *> *rings = [_rings copy];
  CGPoint center = CGPointMake(
      _mainView.bounds.size.width / 2.0,
      _mainView.bounds.size.height / 2.0);

  NSImage *res = [NSImage
      imageWithSize:_mainView.bounds.size
      flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
    [[NSColor windowBackgroundColor] setStroke];
    for (PTDRingMenuWindowRingInfo *ring in rings) {
      CGFloat rad = ring.radius;
      NSRect ovalRect = NSMakeRect(center.x - rad, center.y - rad, rad * 2.0, rad * 2.0);
      NSBezierPath *bp = [NSBezierPath bezierPathWithOvalInRect:ovalRect];
      [bp setLineWidth:ring.width];
      [bp stroke];
    }
    return YES;
  }];
  return res;
}


- (void)_layoutMenu:(PTDRingMenu *)menu
{
  _layout = [[NSMutableArray alloc] init];
  _rings = [[NSMutableArray alloc] init];
  
  CGFloat radius = 24.0;
  for (NSInteger i = 0; i < menu.ringCount; i++) {
    NSArray *ring = [menu itemArrayForRing:i];
    
    CGFloat gravity;
    NSRange range;
    [menu ring:i gravityAngle:&gravity itemRange:&range];
    
    [self _layoutRing:ring withMinimumRadius:radius gravityAngle:gravity range:range nextMinimumRadius:&radius];
    radius += 4.0;
  }
}


- (void)_layoutRing:(NSArray *)ring
  withMinimumRadius:(CGFloat)rad
  gravityAngle:(CGFloat)grav range:(NSRange)range
  nextMinimumRadius:(CGFloat *)nextRad
{
  NSMutableArray *ringItems = [@[] mutableCopy];
  NSRange gravityMassRange = NSMakeRange(NSNotFound, 0);
  NSInteger i = 0, j = 0;
  for (id obj in ring) {
    if (i == range.location)
      gravityMassRange.location = j;
    if (i == NSMaxRange(range)-1)
      gravityMassRange.length = j - gravityMassRange.location;
    if ([obj isKindOfClass:[PTDRingMenuItem class]]) {
      [ringItems addObject:[[PTDRingMenuWindowItemLayout alloc] initWithRingMenuItem:obj]];
      j++;
    }
    i++;
  }
  
  CGFloat *weights = calloc(ringItems.count, sizeof(CGFloat));
  
  NSInteger currWeight = ringItems.count - 1;
  weights[currWeight] = 0.1;
  CGFloat weightAccum = 0.0;
  for (id obj in ring) {
    if ([obj isKindOfClass:[PTDRingMenuItem class]]) {
      currWeight = (currWeight + 1) % ringItems.count;
      weights[currWeight] = 0.1;
      weightAccum = 0.0;
    } else {
      weightAccum += ((PTDRingMenuSpring *)obj).elasticConstant;
      weights[currWeight] = weightAccum;
    }
  }
  
  CGFloat totalWeight = 0.0;
  CGFloat mainMass = 0.0;
  for (i = 0; i < ringItems.count; i++) {
    totalWeight += weights[i];
    if (NSLocationInRange(i, gravityMassRange))
      mainMass += weights[i];
  }
  
  CGFloat angleSpan = mainMass / totalWeight * (2 * M_PI);
  CGFloat currentAngle = angleSpan / 2 + grav;
  CGFloat padding = 0.0;
  
  j = gravityMassRange.location;
  for (i = 0; i < ringItems.count; i++) {
    PTDRingMenuWindowItemLayout *litem = ringItems[j];
    litem.distanceFromCenter = rad;
    litem.angleOnRing = currentAngle;
    currentAngle -= weights[j] / totalWeight * (2 * M_PI);
    padding = MAX(padding, litem.maximumExtensionRadius);
    j = (j + 1) % ringItems.count;
  }
  
  free(weights);
  
  *nextRad = rad + 2 * (padding - rad);
  [_layout addObjectsFromArray:ringItems];
  
  PTDRingMenuWindowRingInfo *rinfo = [[PTDRingMenuWindowRingInfo alloc] init];
  rinfo.radius = rad;
  rinfo.width = (padding - rad) * 2.0;
  [_rings addObject:rinfo];
}


- (NSImage *)_selectionBackdropForItem:(PTDRingMenuWindowItemLayout *)item
{
  NSSize thisSize = item.contents.size;
  thisSize.height += thisSize.height * 2.0 * (M_SQRT1_2 - 0.5);
  thisSize.width += thisSize.width * 2.0 * (M_SQRT1_2 - 0.5);
  NSImage *image = [NSImage imageWithSize:thisSize flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
    NSBezierPath *bp = [NSBezierPath bezierPathWithOvalInRect:(NSRect){NSZeroPoint, thisSize}];
    [[NSColor ptd_controlAccentColor] setFill];
    [bp fill];
    return YES;
  }];
  return image;
}


- (void)_updateSelectionLayerForItem:(PTDRingMenuWindowItemLayout *)item clicked:(BOOL)click
{
  if (_endOfLife)
    return;
    
  if (!item) {
    if (_selectionLayer)
      _selectionLayer.opacity = 0.0;
    return;
  }
  
  if (!_selectionLayer) {
    _selectionLayer = [[CALayer alloc] init];
    [_mainView.layer addSublayer:_selectionLayer];
    CATransaction.disableActions = YES;
  }
  
  NSImage *backdrop = [self _selectionBackdropForItem:item];
  _selectionLayer.contents = backdrop;
  _selectionLayer.frame = (NSRect){NSZeroPoint, backdrop.size};
  _selectionLayer.position = item.layer.position;
  _selectionLayer.zPosition = 0.5;
  
  if (click) {
    /* Why can't this be done with Core Animation? */
    CATransaction.disableActions = YES;
    _selectionLayer.opacity = 0.0;
    _endOfLife = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.075 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      CATransaction.disableActions = YES;
      self->_selectionLayer.opacity = 1.0;
      CATransaction.disableActions = NO;
      [self _fadeOutAndClose];
    });
    
  } else {
    _selectionLayer.speed = 3.0;
    _selectionLayer.opacity = 1.0;
  }
}


- (void)_fadeOutAndClose
{
  [CATransaction begin];
  [CATransaction setCompletionBlock:^{
    [self close];
  }];
  CATransaction.animationDuration = 0.4;
  [self.window.animator setAlphaValue:0.0];
  [CATransaction commit];
}


@end
