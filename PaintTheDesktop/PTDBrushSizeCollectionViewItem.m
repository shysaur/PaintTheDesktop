//
// PTDBrushSizeCollectionViewItem.m
// PaintTheDesktop -- Created on 22/04/2021.
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
#import "PTDBrushSizeCollectionViewItem.h"
#import "PTDBrushSizePrefsCollectionViewDelegate.h"
#import "PTDSizeEditorPopover.h"
#import "PTDGraphics.h"
#import "NSColor+PTD.h"
#import "NSGeometry+PTD.h"


static const CGFloat _Width = 28.0;
static const CGFloat _Height = 28.0;


@implementation PTDBrushSizeCollectionViewItem {
  NSImageView *_imageView;
  NSPopover *_editPopover;
}


- (instancetype)initWithSize:(CGFloat)size
{
  self = [super init];
  _size = size;
  
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
  NSCollectionViewItemHighlightState highlight = self.highlightState;
  BOOL isSelected = self.isSelected && highlight != NSCollectionViewItemHighlightForDeselection;
  
  NSImage *baseImage = PTDBrushSizeIndicatorImage(self.size);
  CGFloat baseImageX = floor((_Width - baseImage.size.width) / 2.0);
  CGFloat baseImageY = floor((_Height - baseImage.size.height) / 2.0);
  
  NSImage *res = [NSImage imageWithSize:NSMakeSize(_Width, _Height) flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
    if (highlight == NSCollectionViewItemHighlightForSelection || isSelected) {
      [[NSColor selectedTextBackgroundColor] set];
      NSRectFill(NSMakeRect(0, 0, _Width, _Height));
    }
    
    [baseImage drawInRect:(NSRect){{baseImageX, baseImageY}, baseImage.size}];
    return YES;
  }];
  return res;
}


- (void)setSize:(CGFloat)size
{
  _size = size;
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
  
  if (selected)
    [self.view.window makeFirstResponder:self];
}


- (void)mouseUp:(NSEvent *)event
{
  if (event.clickCount == 2) {
    [self doEdit];
  } else {
    [super mouseUp:event];
  }
}


- (void)doEdit
{
  PTDSizeEditorPopover *vc = [[PTDSizeEditorPopover alloc] initWithNibName:nil bundle:nil];
  
  _editPopover = [[NSPopover alloc] init];
  _editPopover.behavior = NSPopoverBehaviorTransient;
  _editPopover.contentSize = vc.view.bounds.size;
  _editPopover.contentViewController = vc;
  _editPopover.animates = YES;
  
  vc.textField.doubleValue = self.size;
  vc.textField.target = self;
  vc.textField.action = @selector(finishEditing:);

  [_editPopover showRelativeToRect:(NSRect){PTD_NSRectCenter(self.view.bounds), NSMakeSize(1, 1)} ofView:self.view preferredEdge:NSMaxYEdge];
}


- (void)finishEditing:(NSTextField *)sender
{
  self.size = sender.doubleValue;
  [_editPopover close];
  [NSApp sendAction:@selector(saveOptions:) to:self.target from:self];
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
