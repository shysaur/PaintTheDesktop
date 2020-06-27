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
#import "PTDRingMenuRing.h"
#import "PTDRingMenuItem.h"
#import "PTDRingMenuSpring.h"
#import "NSGeometry+PTD.h"


static NSMutableSet <PTDRingMenuWindow *> *currentlyOpenMenus;


@interface PTDRingMenuWindowItemLayout: NSObject

- (instancetype)initWithRingMenuItem:(PTDRingMenuItem *)item;
@property (readonly) PTDRingMenuItem *item;

@property (nonatomic, readonly) NSView *view;

@property (nonatomic, readonly) NSSize size;

@property (nonatomic, readonly) NSBezierPath *selectionShape;
@property (nonatomic, readonly) NSSize selectionShapeSize;

@property (nonatomic) CGFloat distanceFromCenter;
@property (nonatomic) CGFloat angleOnRing;

- (CGFloat)maximumExtensionRadius;
- (CGFloat)maximumSide;

- (void)moveToCenter:(NSPoint)center;

- (void)select;
- (void)deselect;

@end


@implementation PTDRingMenuWindowItemLayout {
  NSImageView *_contentsView;
}


- (instancetype)initWithRingMenuItem:(PTDRingMenuItem *)item
{
  self = [super init];
  _item = item;
  _size = self.item.image.size;
  [self _computeSelectionShape];
  [self _setupView];
  return self;
}


- (void)_computeSelectionShape
{
  NSSize thisSize = _size;
  CGFloat r1 = thisSize.height * (M_SQRT1_2 - 0.5);
  CGFloat r2 = thisSize.width * (M_SQRT1_2 - 0.5);
  
  if (fabs(r1 - r2) < FLT_EPSILON) {
    thisSize.height += r1 * 2.0;
    thisSize.width += r2 * 2.0;
    _selectionShape = [NSBezierPath bezierPathWithOvalInRect:(NSRect){NSZeroPoint, thisSize}];
  } else {
    CGFloat r = MIN(r1, r2);
    thisSize.height += r * 1.5;
    thisSize.width += r * 1.5;
    CGFloat rr = MIN(thisSize.height / 4.0, thisSize.width / 4.0);
    _selectionShape = [NSBezierPath bezierPathWithRoundedRect:(NSRect){NSZeroPoint, thisSize} xRadius:rr yRadius:rr];
  }
  
  _selectionShapeSize = thisSize;
}


- (void)_setupView
{
  if (self.item.state == NSControlStateValueOff) {
    NSImageView *view = [NSImageView imageViewWithImage:self.item.image];
    [view setFrameSize:_size];
    _view = view;
    _contentsView = view;
  } else {
    NSSize origSize = self.selectionShapeSize;
    
    CGFloat compx = (CGFloat)((int)(_size.width) % 2);
    CGFloat compy = (CGFloat)((int)(_size.height) % 2);
    NSRect rect = NSMakeRect(0, 0, floor(origSize.width/2.0)*2.0+compx, floor(origSize.height/2.0)*2.0+compy);
    
    NSColor *lineColor = [NSColor ptd_controlAccentColor];
    if (self.item.state == NSControlStateValueMixed) {
      lineColor = [NSColor systemGrayColor];
    }
    
    NSBezierPath *bp = [self.selectionShape copy];
    NSAffineTransform *transf = [NSAffineTransform transform];
    [transf scaleXBy:(rect.size.width-2)/origSize.width yBy:(rect.size.height-2)/origSize.height];
    [transf translateXBy:1.0 yBy:1.0];
    
    [bp transformUsingAffineTransform:transf];
    [bp setLineWidth:2.0];
    
    NSImage *bgImg = [NSImage imageWithSize:rect.size flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
      [lineColor setStroke];
      [bp stroke];
      return YES;
    }];
    NSImageView *mainView = [NSImageView imageViewWithImage:bgImg];
    [mainView setFrameSize:rect.size];
    _view = mainView;
    
    _contentsView = [NSImageView imageViewWithImage:self.item.image];
    [_contentsView setFrameSize:_size];
    
    [mainView addSubview:_contentsView];
    [_contentsView setFrameOrigin:NSMakePoint((rect.size.width - _size.width) / 2.0, (rect.size.height - _size.height) / 2.0)];
  }
}


- (void)moveToCenter:(NSPoint)center
{
  CGFloat sinv = sin(_angleOnRing), cosv = cos(_angleOnRing);
  NSPoint myCenter = NSMakePoint(
    round(cosv * _distanceFromCenter + center.x - 0.5 * _view.frame.size.width),
    round(sinv * _distanceFromCenter + center.y - 0.5 * _view.frame.size.height));
  [_view setFrameOrigin:myCenter];
}


- (void)select
{
  if (self.item.selectedImage) {
    CATransaction.disableActions = YES;
    _contentsView.image = self.item.selectedImage;
  }
}


- (void)deselect
{
  if (self.item.selectedImage) {
    CATransaction.disableActions = YES;
    _contentsView.image = self.item.image;
  }
}


- (CGFloat)maximumExtensionRadius
{
  CGFloat sinv = sin(_angleOnRing), cosv = cos(_angleOnRing);
  NSPoint center = NSMakePoint(
      cosv * _distanceFromCenter,
      sinv * _distanceFromCenter);
      
  NSSize diagonal = self.item.image.size;
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


- (CGFloat)maximumSide
{
  return MAX(self.item.image.size.width, self.item.image.size.height);
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
  NSSize _windowSize;
  
  NSMutableArray <PTDRingMenuWindowItemLayout *> *_layout;
  NSMutableArray <PTDRingMenuWindowRingInfo *> *_rings;
  CALayer *_selectionLayer;
  
  PTDRingMenuWindowItemLayout *_dragStartItem;
  BOOL _endOfLife, _lifeEnded, _draggingMode;
}


- (instancetype)initWithRingMenu:(PTDRingMenu *)menu
{
  self = [super init];
  
  [self _layoutMenu:menu];
  [PTDRingMenuWindow addMenuWindow:self];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationStatusDidChange:) name:NSApplicationDidResignActiveNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationStatusDidChange:) name:NSApplicationDidHideNotification object:nil];
  
  return self;
}


- (NSString *)windowNibName
{
  return @"PTDRingMenuWindow";
}


- (void)close
{
  [super close];
  [PTDRingMenuWindow removeMenuWindow:self];
}


- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)positionCenter:(NSPoint)center
{
  NSRect frame = self.window.frame;
  center.x -= frame.size.width / 2;
  center.y -= frame.size.height / 2;
  [self.window setFrameOrigin:center];
}


- (void)openMenuWithInitialEvent:(NSEvent *)evt
{
  [self.window makeKeyAndOrderFront:nil];
  [self _trackModallyWithInitialEvent:evt];
}


#pragma mark - Global Menu List


+ (NSMutableSet *)currentlyOpenMenus
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    currentlyOpenMenus = [NSMutableSet set];
  });
  return currentlyOpenMenus;
}


+ (void)addMenuWindow:(PTDRingMenuWindow *)menu
{
  [PTDRingMenuWindow.currentlyOpenMenus addObject:menu];
}


+ (void)removeMenuWindow:(PTDRingMenuWindow *)menu
{
  [PTDRingMenuWindow.currentlyOpenMenus removeObject:menu];
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


- (NSEvent *)_trackModallyWithInitialEvent:(NSEvent *)initialEvent
{
  NSEvent *postEvent, *event;
  BOOL inInitialSetup = !!initialEvent;
  
  while (!_lifeEnded) {
    @autoreleasepool {
      event = [NSApp
          nextEventMatchingMask:NSEventMaskAny
          untilDate:[NSDate distantFuture]
          inMode:NSDefaultRunLoopMode dequeue:YES];
      
      NSEventType type = [event type];
      switch (type) {
        case NSEventTypeLeftMouseDown:
        case NSEventTypeRightMouseDown:
        case NSEventTypeOtherMouseDown:
          inInitialSetup = NO;
          if (event.window != self.window) {
            [self _fadeOutAndClose];
            _lifeEnded = YES;
          } else
            postEvent = event;
          break;
          
        case NSEventTypeLeftMouseDragged:
        case NSEventTypeRightMouseDragged:
        case NSEventTypeOtherMouseDragged:
        case NSEventTypeMouseMoved:
          if (inInitialSetup) {
            _draggingMode = YES;
            [self absorbInitialEvent:event];
          } else {
            postEvent = event;
          }
          break;
          
        case NSEventTypeLeftMouseUp:
        case NSEventTypeRightMouseUp:
        case NSEventTypeOtherMouseUp:
          if (inInitialSetup && _draggingMode && event.clickCount == 0) {
            [self absorbInitialEvent:event];
          } else {
            postEvent = event;
          }
          inInitialSetup = NO;
          break;
          
        default:
          postEvent = event;
      }
      
      if (postEvent)
        [NSApp sendEvent:postEvent];
    }
  }
  
  [NSApp discardEventsMatchingMask:NSEventMaskAny beforeEvent:event];
  return postEvent;
}


- (void)absorbInitialEvent:(NSEvent *)event
{
  NSPoint absPos = [event.window convertPointToScreen:event.locationInWindow];
  NSPoint myPos = [self.window convertPointFromScreen:absPos];
  NSEvent *newEvent = [NSEvent
      mouseEventWithType:event.type
      location:myPos
      modifierFlags:event.modifierFlags
      timestamp:event.timestamp
      windowNumber:self.window.windowNumber
      context:nil
      eventNumber:event.eventNumber
      clickCount:event.clickCount
      pressure:event.pressure];
      
  switch (newEvent.type) {
    case NSEventTypeLeftMouseDown:
      [self mouseDown:newEvent];
      break;
    case NSEventTypeRightMouseDown:
      [self rightMouseDown:newEvent];
      break;
    case NSEventTypeLeftMouseDragged:
      [self mouseDragged:newEvent];
      break;
    case NSEventTypeRightMouseDragged:
      [self rightMouseDragged:newEvent];
      break;
    case NSEventTypeMouseMoved:
      [self mouseMoved:newEvent];
      break;
    case NSEventTypeLeftMouseUp:
      [self mouseUp:newEvent];
      break;
    case NSEventTypeRightMouseUp:
      [self rightMouseUp:newEvent];
      break;
    default:
      break;
  }
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
  if ((found == _dragStartItem || _draggingMode) && found.item.action && !_endOfLife) {
    id sender = found.item.representedObject ?: found.item;
    [NSApp sendAction:found.item.action to:found.item.target from:sender];
  } else if (!found) {
    [self _fadeOutAndClose];
  }
  [self _updateSelectionLayerForItem:found clicked:YES];
}


- (void)rightMouseDown:(NSEvent *)event
{
  [self mouseDown:event];
}


- (void)rightMouseDragged:(NSEvent *)event
{
  [self mouseDragged:event];
}


- (void)rightMouseUp:(NSEvent *)event
{
  [self mouseUp:event];
}


- (PTDRingMenuWindowItemLayout *)_hitTestAtPoint:(NSPoint)point
{
  PTDRingMenuWindowItemLayout *res;
  for (PTDRingMenuWindowItemLayout *item in _layout) {
    if (NSPointInRect(point, item.view.frame))
      return item;
  }
  return res;
}


- (void)applicationStatusDidChange:(NSNotification *)notification
{
  if (![NSApp isActive] || [NSApp isHidden]) {
    [self close];
    _endOfLife = _lifeEnded = YES;
  }
}


#pragma mark - Layout & Setup


- (void)windowDidLoad
{
  [super windowDidLoad];
  
  [self.window setFrame:(NSRect){NSZeroPoint, _windowSize} display:NO];
  self.window.level = NSSubmenuWindowLevel;
  self.window.backgroundColor = [NSColor clearColor];
  self.window.opaque = NO;
  
  _mainView.wantsLayer = YES;
  CALayer *rootLayer = [[CALayer alloc] init];
  rootLayer.backgroundColor = [[NSColor clearColor] CGColor];
  
  CGPoint center = CGPointMake(
      _mainView.bounds.size.width / 2.0,
      _mainView.bounds.size.height / 2.0);
  for (PTDRingMenuWindowItemLayout *li in _layout) {
    [li moveToCenter:center];
    [_mainView addSubview:li.view];
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
  
  CGFloat radius = 8.0;
  for (NSInteger i = 0; i < menu.ringCount; i++) {
    PTDRingMenuRing *ring = menu.rings[i];
    
    [self _layoutRing:ring withMinimumRadius:radius nextMinimumRadius:&radius];
    radius += 4.0;
  }
  
  _windowSize = NSMakeSize(radius * 2.0 + 1.0, radius * 2.0 + 1.0);
}


- (void)_layoutRing:(PTDRingMenuRing *)ring
  withMinimumRadius:(CGFloat)rad
  nextMinimumRadius:(CGFloat *)nextRad
{
  CGFloat itemLength = 0.0;
  CGFloat radiusExtension = 0.0;
  CGFloat gravityItemLength = 0.0;

  NSMutableArray *ringItems = [@[] mutableCopy];
  NSRange range = ring.gravityMass;
  NSRange gravityMassRange = NSMakeRange(NSNotFound, 0);
  NSInteger i = 0, j = 0;
  for (id obj in ring.itemArray) {
    if (i == range.location)
      gravityMassRange.location = j;
    if (i == NSMaxRange(range)-1)
      gravityMassRange.length = j - gravityMassRange.location;
    if ([obj isKindOfClass:[PTDRingMenuItem class]]) {
      PTDRingMenuWindowItemLayout *layout = [[PTDRingMenuWindowItemLayout alloc] initWithRingMenuItem:obj];
      [ringItems addObject:layout];
      itemLength += layout.maximumSide;
      radiusExtension = MAX(radiusExtension, layout.maximumSide * M_SQRT2 / 2.0);
      if (NSLocationInRange(i, range))
        gravityItemLength += layout.maximumSide;
      j++;
    }
    i++;
  }
  
  rad += radiusExtension;
  rad = MAX(rad, itemLength / (2 * M_PI));
  CGFloat circumference = rad * (2 * M_PI);
  CGFloat springLength = circumference - itemLength;
  
  CGFloat *weights = calloc(ringItems.count, sizeof(CGFloat));
  
  NSInteger currWeight = ringItems.count - 1;
  weights[currWeight] = 0.1;
  CGFloat weightAccum = 0.0;
  for (id obj in ring.itemArray) {
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
  
  CGFloat springForce = springLength / totalWeight;
  
  CGFloat angleSpan = (mainMass * springForce + gravityItemLength) / circumference * 2.0 * M_PI;
  CGFloat currentAngle = angleSpan / 2 + ring.gravityAngle;
  CGFloat padding = 0.0;
  
  j = gravityMassRange.location;
  for (i = 0; i < ringItems.count; i++) {
    PTDRingMenuWindowItemLayout *litem = ringItems[j];
    litem.distanceFromCenter = rad;
    currentAngle -= (0.5 * litem.maximumSide) / circumference * 2.0 * M_PI;
    litem.angleOnRing = currentAngle;
    currentAngle -= (0.5 * litem.maximumSide) / circumference * 2.0 * M_PI;
    currentAngle -= weights[j] * springForce / circumference * (2 * M_PI);
    padding = MAX(padding, litem.maximumExtensionRadius);
    j = (j + 1) % ringItems.count;
  }
  
  free(weights);
  
  *nextRad = rad + (padding - rad);
  [_layout addObjectsFromArray:ringItems];
  
  PTDRingMenuWindowRingInfo *rinfo = [[PTDRingMenuWindowRingInfo alloc] init];
  rinfo.radius = rad;
  rinfo.width = (padding - rad) * 2.0;
  [_rings addObject:rinfo];
}


- (NSImage *)_selectionBackdropForItem:(PTDRingMenuWindowItemLayout *)item
{
  NSImage *image = [NSImage imageWithSize:item.selectionShapeSize flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
    [[NSColor ptd_controlAccentColor] setFill];
    [item.selectionShape fill];
    return YES;
  }];
  return image;
}


- (void)_updateSelectionLayerForItem:(PTDRingMenuWindowItemLayout *)item clicked:(BOOL)click
{
  if (_endOfLife)
    return;
    
  for (PTDRingMenuWindowItemLayout *itm in _layout) {
    [itm deselect];
  }
    
  if (!item) {
    if (_selectionLayer)
      _selectionLayer.opacity = 0.0;
    return;
  }
  
  if (!_selectionLayer) {
    _selectionLayer = [[CALayer alloc] init];
    [_mainView.layer insertSublayer:_selectionLayer atIndex:1];
    CATransaction.disableActions = YES;
  }
  
  CATransaction.disableActions = YES;
  
  NSImage *backdrop = [self _selectionBackdropForItem:item];
  _selectionLayer.contents = backdrop;
  _selectionLayer.frame = (NSRect){NSZeroPoint, backdrop.size};
  _selectionLayer.position = PTD_NSRectCenter(item.view.frame);
  _selectionLayer.frame = [self.window backingAlignedRect:_selectionLayer.frame options:NSAlignAllEdgesInward];
  [item select];
  
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
    _selectionLayer.opacity = 1.0;
  }
}


- (void)_fadeOutAndClose
{
  _endOfLife = YES;
  _lifeEnded = YES;
  [CATransaction begin];
  [CATransaction setCompletionBlock:^{
    [self close];
  }];
  CATransaction.animationDuration = 0.4;
  [self.window.animator setAlphaValue:0.0];
  [CATransaction commit];
}


@end
