//
// PTDBrushColorCollectionViewItem.m
// PaintTheDesktop -- Created on 24/03/2021.
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

#import <Carbon/Carbon.h>
#import "PTDBrushColorPrefsCollectionViewDelegate.h"
#import "PTDBrushColorCollectionViewItem.h"
#import "PTDGraphics.h"
#import "NSColor+PTD.h"


static const CGFloat _Width = 28.0;
static const CGFloat _Height = 28.0;
static const CGFloat _SwatchWidth = 14.0;
static const CGFloat _SwatchHeight = 14.0;
static const CGFloat _DropIndicatorWidth = 19.5;
static const CGFloat _DropIndicatorHeight = 19.5;
static const CGFloat _DropIndicatorLineWidth = 3.0;


@implementation PTDBrushColorCollectionViewItem {
  NSImageView *_imageView;
}


- (instancetype)initWithColor:(NSColor *)color
{
  self = [super init];
  _color = color;
  
  _imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, _Width, _Height)];
  _imageView.image = [self image];
  _imageView.imageAlignment = NSImageAlignCenter;
  _imageView.imageScaling = NSImageScaleNone;
  self.view = _imageView;
  
  return self;
}


- (BOOL)acceptsFirstResponder
{
  return YES;
}


+ (NSSize)size
{
  return NSMakeSize(_Width, _Height);
}


- (NSImage *)image
{
  NSColor *color = _color;
  NSCollectionViewItemHighlightState highlight = self.highlightState;
  BOOL isSelected = self.isSelected && highlight != NSCollectionViewItemHighlightForDeselection;
  
  NSImage *res = [NSImage imageWithSize:NSMakeSize(_Width, _Height) flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
    if (highlight == NSCollectionViewItemHighlightForSelection || isSelected) {
      [[NSColor selectedTextBackgroundColor] set];
      NSRectFill(NSMakeRect(0, 0, _Width, _Height));
      
    } else if (highlight == NSCollectionViewItemHighlightAsDropTarget) {
      NSBezierPath *bp = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(_Width/2-_DropIndicatorWidth/2, _Height/2-_DropIndicatorHeight/2, _DropIndicatorWidth, _DropIndicatorHeight)];
      [[NSColor ptd_ringMenuHighlightColor] setStroke];
      [bp setLineWidth:_DropIndicatorLineWidth];
      [bp stroke];
    }
    
    PTDDrawCircularColorSwatch(NSMakeRect(_Width/2-_SwatchWidth/2, _Width/2-_SwatchWidth/2, _SwatchWidth, _SwatchHeight), color);
    return YES;
  }];
  return res;
}


- (void)setColor:(NSColor *)color
{
  _color = color;
  _imageView.image = [self image];
  [_imageView setNeedsDisplay:YES];
}


- (void)setHighlightState:(NSCollectionViewItemHighlightState)highlightState
{
  [super setHighlightState:highlightState];
  _imageView.image = [self image];
  [_imageView setNeedsDisplay:YES];
}


- (void)setSelected:(BOOL)selected
{
  [super setSelected:selected];
  _imageView.image = [self image];
  [_imageView setNeedsDisplay:YES];
  
  if (selected) {
    [self.view.window makeFirstResponder:self];
    if ([NSColorPanel sharedColorPanelExists]) {
      NSColorPanel *colorPanel = NSColorPanel.sharedColorPanel;
      colorPanel.color = self.color;
    }
  }
}


- (void)changeColor:(id)sender
{
  NSColorPanel *colorPanel = NSColorPanel.sharedColorPanel;
  self.color = colorPanel.color;
  
  [NSApp sendAction:@selector(saveOptions:) to:self.target from:self];
}


- (void)mouseUp:(NSEvent *)event
{
  if (event.clickCount == 2) {
    NSColorPanel *colorPanel = NSColorPanel.sharedColorPanel;
    [colorPanel orderFront:self];
    [self.view.window makeFirstResponder:self];
  }
  [super mouseUp:event];
}


- (void)doCommandBySelector:(SEL)selector
{
  [super doCommandBySelector:selector];
}


- (void)keyDown:(NSEvent *)event
{
  if (event.keyCode == kVK_Delete) {
    [NSApp sendAction:@selector(deleteItem:) to:self.target from:self];
  } else {
    [super keyDown:event];
  }
}


@end
