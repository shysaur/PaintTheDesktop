//
// PTDBrushColorPrefsCollectionViewDelegate.m
// PaintTheDesktop -- Created on 10/04/2021.
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

#import "PTDBrushColorPrefsCollectionViewDelegate.h"
#import "PTDBrushColorCollectionViewItem.h"
#import "PTDBrushTool.h"
#import "PTDToolOptions.h"
#import "PTDCollectionViewFlowLayout.h"


@implementation PTDBrushColorPrefsCollectionViewDelegate


- (void)setCollectionView:(NSCollectionView *)collectionView
{
  [super setCollectionView:collectionView];
  
  [self.collectionView registerForDraggedTypes:@[NSPasteboardTypeColor]];
  [self.collectionView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:YES];
  [self.collectionView setDraggingSourceOperationMask:NSDragOperationNone forLocal:NO];
}


- (PTDBrushColorCollectionViewItem *)createItemWithColor:(NSColor *)color
{
  PTDBrushColorCollectionViewItem *item = [[PTDBrushColorCollectionViewItem alloc] initWithColor:color];
  item.target = self;
  return item;
}


+ (NSSize)itemSize
{
  return PTDBrushColorCollectionViewItem.size;
}


- (void)reset
{
  PTDBrushTool.defaultColors = nil;
}


- (void)saveItems:(NSArray <PTDBrushColorCollectionViewItem *> *)items
{
  NSMutableArray *newColors = [NSMutableArray array];
  for (PTDBrushColorCollectionViewItem *item in items) {
    [newColors addObject:item.color];
  }
  PTDBrushTool.defaultColors = [newColors copy];
}


- (NSArray <PTDBrushColorCollectionViewItem *> *)loadItems
{
  NSArray *colors = PTDBrushTool.defaultColors;
  NSMutableArray <PTDBrushColorCollectionViewItem *> *res = [NSMutableArray array];
  for (NSColor *color in colors) {
    PTDBrushColorCollectionViewItem *item = [self createItemWithColor:color];
    [res addObject:item];
  }
  return res;
}


- (id<NSPasteboardWriting>)pasteboardWriterForItem:(PTDBrushColorCollectionViewItem *)item
{
  return item.color;
}


- (void)updateItem:(PTDBrushColorCollectionViewItem *)item withPasteboard:(NSPasteboard *)pb
{
  NSColor *color = [pb readObjectsForClasses:@[[NSColor class]] options:nil][0];
  item.color = color;
}


- (PTDBrushColorCollectionViewItem *)newItemFromPasteboard:(nullable NSPasteboard *)pb
{
  NSColor *color;
  if (pb) {
    color = [pb readObjectsForClasses:@[[NSColor class]] options:nil][0];
  } else {
    color = [NSColor blackColor];
  }
  return [self createItemWithColor:color];
}


@end
