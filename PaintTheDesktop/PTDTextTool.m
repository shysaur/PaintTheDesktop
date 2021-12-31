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


NSString * const PTDToolIdentifierTextTool = @"PTDToolIdentifierTextTool";


@interface NSLayoutManager ()

- (void)_setDrawsDebugBaselines:(BOOL)arg1;

@end


@interface PTDTextToolView: NSTextView

@end


@implementation PTDTextToolView


- (nullable NSMenu *)menuForEvent:(NSEvent *)event
{
  if ([event type] == NSEventTypeRightMouseDown)
    [self.superview rightMouseDown:event];
  return nil;
}


@end


@implementation PTDTextTool {
  NSTextView *_textView;
  NSPoint _baselinePivot;
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
  _color = NSColor.blackColor;
  _baseFont = [NSFont userFontOfSize:24];
  _fontSize = 24;
  _textAlignment = NSTextAlignmentLeft;
}


- (NSFont *)resolvedFont
{
  NSFontManager *fm = [NSFontManager sharedFontManager];
  NSFont *newFont = [fm convertFont:self.baseFont toSize:self.fontSize];
  return newFont;
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
  
  _textView.font = [self resolvedFont];
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
  if (_textView.alignment == NSTextAlignmentLeft || _textView.alignment == NSTextAlignmentNatural) {
    newOrigin.x = _baselinePivot.x - xBorder;
  } else if (_textView.alignment == NSTextAlignmentCenter) {
    newOrigin.x = _baselinePivot.x - _textView.frame.size.width / 2.0;
  } else if (_textView.alignment == NSTextAlignmentRight) {
    newOrigin.x = _baselinePivot.x - _textView.frame.size.width + xBorder;
  } else {
    NSLog(@"What is this text alignment (id = %d) that I don't know? Whatever, let's not panic...", (int)_textView.alignment);
    newOrigin.x = _baselinePivot.x - xBorder;
  }
  
  [_textView setFrameOrigin:[_textView.superview ptd_backingAlignedPoint:newOrigin]];
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


- (void)setColor:(NSColor *)color
{
  _color = color;
  if (_textView) {
    _textView.textColor = color;
    [self updateTextViewFrame];
  }
}


- (void)setBaseFont:(NSFont *)baseFont
{
  _baseFont = baseFont;
  if (_textView) {
    _textView.font = [self resolvedFont];
    [self updateTextViewFrame];
  }
}


- (void)setFontSize:(CGFloat)fontSize
{
  _fontSize = fontSize;
  if (_textView) {
    _textView.font = [self resolvedFont];
    [self updateTextViewFrame];
  }
}


- (void)setTextAlignment:(NSTextAlignment)textAlignment
{
  _textAlignment = textAlignment;
  if (_textView && _textView.string.length > 0)
    [self updateTextViewFrame];
}


- (nullable PTDRingMenuRing *)optionMenu
{
  PTDRingMenuRing *res = [PTDRingMenuRing ring];
  
  [res beginGravityMassGroupWithAngle:M_PI_2 / 3.0];
  NSArray <NSNumber *> *sizes = @[@(24), @(48), @(72), @(100)];
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
  
  NSArray <NSColor *> *colors = @[NSColor.blackColor, NSColor.systemRedColor, NSColor.systemBlueColor, NSColor.systemYellowColor, NSColor.systemGreenColor, NSColor.whiteColor];
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
  if ([color isEqual:_color])
    itm.state = NSControlStateValueOn;
  return itm;
}


- (PTDRingMenuItem *)menuItemForFontSize:(CGFloat)size
{
  NSString *strSize = [NSString stringWithFormat:@"%d", (int)size];
  
  PTDRingMenuItem *itm = [PTDRingMenuItem itemWithText:strSize target:self action:@selector(changeFontSize:)];
  itm.tag = size;
  if (size == _fontSize)
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
  [self setColor:sender];
}


- (void)changeFontSize:(id)sender
{
  [self setFontSize:[sender tag]];
}


- (void)changeTextAlignment:(id)sender
{
  [self setTextAlignment:[sender tag]];
}


@end
