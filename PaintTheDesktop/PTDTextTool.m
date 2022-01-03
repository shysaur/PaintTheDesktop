//
// PTDTextTool.m
// PaintTheDesktop -- Created on 30/12/21.
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

#import "PTDTextTool.h"
#import "PTDDrawingSurface.h"
#import "NSView+PTD.h"
#import "NSTextView+PTD.h"
#import "PTDCursor.h"
#import "PTDGraphics.h"
#import "PTDBrushTool.h"
#import "PTDToolOptions.h"


NSString * const PTDToolIdentifierTextTool = @"PTDToolIdentifierTextTool";

NSString * const PTDTextToolOptionDefaultFontSizes = @"defaultFontSizes";
NSString * const PTDTextToolOptionBaseFontName = @"baseFontName";
NSString * const PTDTextToolOptionFontSize = @"fontSize";
NSString * const PTDTextToolOptionTextAlignment = @"textAlignment";


@interface NSLayoutManager ()

- (void)_setDrawsDebugBaselines:(BOOL)arg1;

@end


@interface PTDTextToolView: NSTextView

@end


@implementation PTDTextToolView


- (nullable NSMenu *)menuForEvent:(NSEvent *)event
{
  return nil;
}


@end


@interface PTDTextTool ()

@property (nonatomic) NSColor *color;
@property (nonatomic) CGFloat fontSize;
@property (nonatomic) NSTextAlignment textAlignment;

@property (nonatomic) NSFont *resolvedFont;

@end


@implementation PTDTextTool {
  NSTextView *_textView;
  NSPoint _baselinePivot;
}


+ (void)registerDefaults
{
  [super registerDefaults];
  
  PTDToolOptions *o = PTDToolOptions.sharedOptions;
  
  [o registerOption:PTDTextToolOptionDefaultFontSizes ofToolClass:self types:@[[NSArray class], [NSNumber class]] defaultValue:@[
      @(24), @(48), @(72), @(100)
    ] validationBlock:^BOOL(id  _Nonnull value) {
      if (![value isKindOfClass:[NSArray class]])
        return NO;
      NSArray *a = (NSArray *)value;
      for (id v in a) {
        if (![v isKindOfClass:[NSNumber class]])
          return NO;
      }
      return YES;
    }];
  
  [o registerOption:PTDTextToolOptionBaseFontName ofToolClass:self types:@[[NSString class]] defaultValue:@"Helvetica" validationBlock:nil];
  [o registerOption:PTDTextToolOptionFontSize ofToolClass:self types:@[[NSNumber class]] defaultValue:@(24) validationBlock:nil];
  [o registerOption:PTDTextToolOptionTextAlignment ofToolClass:self types:@[[NSNumber class]] defaultValue:@(NSTextAlignmentLeft) validationBlock:nil];
}


+ (NSString *)baseFontName
{
  return [PTDToolOptions.sharedOptions objectForOption:PTDTextToolOptionBaseFontName ofToolClass:self];
}


+ (void)setBaseFontName:(NSString *)baseFontName
{
  if (!baseFontName)
    [PTDToolOptions.sharedOptions restoreDefaultForOption:PTDTextToolOptionBaseFontName ofToolClass:self];
  else
    [PTDToolOptions.sharedOptions setObject:baseFontName forOption:PTDTextToolOptionBaseFontName ofToolClass:self];
}


+ (NSArray<NSNumber *> *)defaultFontSizes
{
  return [PTDToolOptions.sharedOptions objectForOption:PTDTextToolOptionDefaultFontSizes ofToolClass:self];
}


+ (void)setDefaultFontSizes:(NSArray<NSNumber *> *)defaultFontSizes
{
  if (!defaultFontSizes)
    [PTDToolOptions.sharedOptions restoreDefaultForOption:PTDTextToolOptionDefaultFontSizes ofToolClass:self];
  else
    [PTDToolOptions.sharedOptions setObject:defaultFontSizes forOption:PTDTextToolOptionDefaultFontSizes ofToolClass:self];
}


+ (NSString *)toolIdentifier
{
  return PTDToolIdentifierTextTool;
}


+ (PTDRingMenuItem *)menuItem
{
  return [PTDRingMenuItem itemWithImage:[NSImage imageNamed:@"PTDToolIconText"] target:nil action:nil];
}


- (void)reloadOptions
{
  self.fontSize = [[PTDToolOptions.sharedOptions objectForOption:PTDTextToolOptionFontSize ofToolClass:self.class] doubleValue];
  self.textAlignment = [[PTDToolOptions.sharedOptions objectForOption:PTDTextToolOptionTextAlignment ofToolClass:self.class] integerValue];
  self.color = [PTDToolOptions.sharedOptions objectForOption:PTDBrushToolOptionColor ofToolClass:nil];
  
  self.resolvedFont = [NSFont fontWithName:[self.class baseFontName] size:self.fontSize];
  
  if (_textView) {
    _textView.font = self.resolvedFont;
    _textView.textColor = self.color;
    [self updateTextViewFrame];
  }
}


- (void)activate
{
  self.cursor = [PTDCursor cursorFromCursor:[NSCursor IBeamCursor]];
}


- (void)mouseClickedAtPoint:(NSPoint)point
{
  if (!_textView) {
    [self beginTextEditingAtPoint:point];
  } else {
    [self endTextEditing];
  }
}


- (void)beginTextEditingAtPoint:(NSPoint)point
{
  self.cursor = nil;
  
  _textView = [[PTDTextToolView alloc] init];
  [self.currentDrawingSurface beginTextEditingWithTextView:_textView];
  
  point = [_textView.superview ptd_backingAlignedPoint:point];
  _baselinePivot = point;
  
  _textView.backgroundColor = [NSColor clearColor];
  _textView.drawsBackground = NO;
  
  NSRect textViewRect;
  NSRect canvasRect = self.currentDrawingSurface.bounds;
  textViewRect.origin.x = point.x;
  textViewRect.origin.y = 0;
  textViewRect.size.width = canvasRect.size.width - point.x;
  textViewRect.size.height = point.y;
  _textView.frame = textViewRect;
  
  _textView.font = self.resolvedFont;
  _textView.textColor = self.color;
  
  if ([[NSUserDefaults standardUserDefaults] boolForKey:@"debug"]) {
    [_textView.layoutManager _setDrawsDebugBaselines:YES];
  }
  
  _textView.delegate = self;
  [self updateTextViewFrame];
}


- (void)textDidChange:(NSNotification *)notification
{
  [self updateTextViewFrame];
}


- (void)updateTextViewFrame
{
  CGPoint newOrigin;
  
  if (_textView.string.length > 0) {
    /* We finish setting up the text view now otherwise the initial caret
     * positioning and baseline are screwed up.
     *   Empty text fields are hard... I guess? */
    _textView.alignment = self.textAlignment;
    _textView.textContainer.heightTracksTextView = NO;
    _textView.textContainer.widthTracksTextView = NO;
    _textView.horizontallyResizable = YES;
    _textView.verticallyResizable = YES;
  }
  
  CGFloat baselineOffset = _textView.ptd_firstBaselineOffsetFromTop;
  newOrigin.y = _baselinePivot.y - _textView.frame.size.height + baselineOffset;
  
  CGFloat xBorder = _textView.textContainerInset.width + _textView.textContainer.lineFragmentPadding;
  if (_textView.alignment == NSTextAlignmentCenter) {
    newOrigin.x = _baselinePivot.x - _textView.frame.size.width / 2.0;
  } else if (_textView.alignment == NSTextAlignmentRight) {
    newOrigin.x = _baselinePivot.x - _textView.frame.size.width + xBorder;
  } else {
    newOrigin.x = _baselinePivot.x - xBorder;
  }
  
  [_textView setFrameOrigin:[_textView.superview ptd_backingAlignedPoint:newOrigin]];
  
  /* adjust text container size limit */
  if (_textView.string.length > 0) {
    CGFloat maxHeight = newOrigin.y + _textView.frame.size.height;
    CGFloat maxWidth;
    NSRect canvasRect = _textView.superview.bounds;
    CGFloat leftSide = _baselinePivot.x;
    CGFloat rightSide = canvasRect.size.width - _baselinePivot.x;
    if (_textView.alignment == NSTextAlignmentCenter) {
      maxWidth = (MIN(leftSide, rightSide) + xBorder) * 2.0;
    } else if (_textView.alignment == NSTextAlignmentRight) {
      maxWidth = leftSide + xBorder;
    } else {
      maxWidth = rightSide + xBorder;
    }
    _textView.maxSize = NSMakeSize(maxWidth, maxHeight);
    _textView.textContainer.size = NSMakeSize(maxWidth, maxHeight);
  }
}


- (void)endTextEditing
{
  _textView.insertionPointColor = NSColor.clearColor;
  _textView.selectedRange = NSMakeRange(0, 0);
  NSRect theRect = _textView.visibleRect;
  NSBitmapImageRep *tempImage = [_textView bitmapImageRepForCachingDisplayInRect:theRect];
  [_textView cacheDisplayInRect:_textView.visibleRect toBitmapImageRep:tempImage];
  
  [self.currentDrawingSurface beginCanvasDrawing];
  NSRect pixRect;
  pixRect.origin = _textView.frame.origin;
  pixRect.size = tempImage.size;
  [tempImage drawInRect:pixRect fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0 respectFlipped:YES hints:nil];
  [self.currentDrawingSurface endCanvasDrawing];
  
  [self.currentDrawingSurface endTextEditing:_textView];
  _textView = nil;
  
  self.cursor = [PTDCursor cursorFromCursor:[NSCursor IBeamCursor]];
}


- (void)deactivate
{
  if (_textView) {
    [self endTextEditing];
  }
}


- (nullable PTDRingMenuRing *)optionMenu
{
  PTDRingMenuRing *res = [PTDRingMenuRing ring];
  
  [res beginGravityMassGroupWithAngle:M_PI_2 / 3.0];
  NSArray <NSNumber *> *sizes = self.class.defaultFontSizes;
  for (NSNumber *size in sizes) {
    PTDRingMenuItem *item = [self menuItemForFontSize:size.integerValue];
    [res addItem:item];
  }
  [res endGravityMassGroup];
  
  [res addSpringWithElasticity:1000];
  
  [res beginGravityMassGroupWithAngle:M_PI_2 / 3.0];
  [res addItem:[self menuItemForTextAlignment:NSTextAlignmentLeft]];
  [res addItem:[self menuItemForTextAlignment:NSTextAlignmentCenter]];
  [res addItem:[self menuItemForTextAlignment:NSTextAlignmentRight]];
  [res endGravityMassGroup];
  
  [res addSpringWithElasticity:1000];
  
  NSArray <NSColor *> *colors = [[PTDToolOptions sharedOptions] objectForOption:PTDBrushToolOptionColorOptions ofToolClass:nil];
  for (NSColor *color in colors) {
    PTDRingMenuItem *item = [self menuItemForTextColor:color];
    [res addItem:item];
  }
  
  [res addSpringWithElasticity:1000];
  return res;
}


- (PTDRingMenuItem *)menuItemForTextColor:(NSColor *)color
{
  NSImage *img = [NSImage imageWithSize:NSMakeSize(16, 16) flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
    PTDDrawCircularColorSwatch(NSMakeRect(3, 3, 16-6, 16-6), color);
    return YES;
  }];
  PTDRingMenuItem *itm = [PTDRingMenuItem itemWithImage:img target:self action:@selector(changeColor:)];
  itm.representedObject = color;
  if ([color isEqual:self.color])
    itm.state = NSControlStateValueOn;
  return itm;
}


- (PTDRingMenuItem *)menuItemForFontSize:(CGFloat)size
{
  NSString *strSize = [NSString stringWithFormat:@"%d", (int)size];
  
  PTDRingMenuItem *itm = [PTDRingMenuItem itemWithText:strSize target:self action:@selector(changeFontSize:)];
  itm.tag = size;
  if (size == self.fontSize)
    itm.state = NSControlStateValueOn;
  return itm;
}


- (PTDRingMenuItem *)menuItemForTextAlignment:(NSTextAlignment)alignment
{
  NSImage *image;
  if (alignment == NSTextAlignmentCenter)
    image = [NSImage imageNamed:@"PTDTextAlignCenter"];
  else if (alignment == NSTextAlignmentRight)
    image = [NSImage imageNamed:@"PTDTextAlignRight"];
  else
    image = [NSImage imageNamed:@"PTDTextAlignLeft"];
  
  PTDRingMenuItem *itm = [PTDRingMenuItem itemWithImage:image target:self action:@selector(changeTextAlignment:)];
  itm.tag = alignment;
  if (alignment == _textAlignment)
    itm.state = NSControlStateValueOn;
  return itm;
}


- (void)changeColor:(id)sender
{
  [[PTDToolOptions sharedOptions] setObject:sender forOption:PTDBrushToolOptionColor ofToolClass:nil];
}


- (void)changeFontSize:(id)sender
{
  [[PTDToolOptions sharedOptions] setObject:@([sender tag]) forOption:PTDTextToolOptionFontSize ofToolClass:self.class];
}


- (void)changeTextAlignment:(id)sender
{
  [[PTDToolOptions sharedOptions] setObject:@([sender tag]) forOption:PTDTextToolOptionTextAlignment ofToolClass:self.class];
}


@end
