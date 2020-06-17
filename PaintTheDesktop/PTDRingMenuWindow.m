//
//  PTDRingMenu.m
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 16/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

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
  NSMutableArray <PTDRingMenuWindowItemLayout *> *_layout;
  NSMutableArray <PTDRingMenuWindowRingInfo *> *_rings;
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


- (void)windowDidLoad
{
  [super windowDidLoad];
  NSView *contentView = self.window.contentView;
  contentView.wantsLayer = YES;
  CALayer *rootLayer = contentView.layer;
  
  CGPoint center = CGPointMake(
      contentView.bounds.size.width / 2.0,
      contentView.bounds.size.height / 2.0);
  for (PTDRingMenuWindowItemLayout *li in _layout) {
    [li updateLayerWithCenter:center];
    [rootLayer addSublayer:li.layer];
  }
  
  rootLayer.contents = [self _backdrop];
  rootLayer.frame = contentView.bounds;
  
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
      self.window.contentView.bounds.size.width / 2.0,
      self.window.contentView.bounds.size.height / 2.0);

  NSImage *res = [NSImage
      imageWithSize:self.window.contentView.bounds.size
      flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
    for (PTDRingMenuWindowRingInfo *ring in rings) {
      CGFloat rad = ring.radius;
      NSRect ovalRect = NSMakeRect(center.x - rad, center.y - rad, rad * 2.0, rad * 2.0);
      NSBezierPath *bp = [NSBezierPath bezierPathWithOvalInRect:ovalRect];
      [[NSColor colorWithWhite:0.0 alpha:0.25] setStroke];
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


@end
