//
// PTDAbstractSizePrefsCollectionViewDelegate.m
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

#import "PTDAbstractSizePrefsCollectionViewDelegate.h"
#import "PTDAbstractSizeCollectionViewItem.h"
#import "PTDUtils.h"
#import "PTDBrushTool.h"
#import "PTDEraserTool.h"


@implementation PTDAbstractSizePrefsCollectionViewDelegate


- (void)setCollectionView:(NSCollectionView *)collectionView
{
  [super setCollectionView:collectionView];
  
  [self.collectionView registerForDraggedTypes:@[NSPasteboardTypeString]];
  [self.collectionView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:YES];
  [self.collectionView setDraggingSourceOperationMask:NSDragOperationNone forLocal:NO];
}


- (PTDAbstractSizeCollectionViewItem *)createItemWithSize:(CGFloat)size
{
  PTDAbstract();
}


- (NSDragOperation)collectionView:(NSCollectionView *)collectionView validateDrop:(id<NSDraggingInfo>)draggingInfo proposedIndexPath:(NSIndexPath * _Nonnull __autoreleasing * _Nonnull)proposedDropIndexPath dropOperation:(nonnull NSCollectionViewDropOperation *)proposedDropOperation
{
  if (draggingInfo.draggingSource == self.collectionView) {
    *proposedDropOperation = NSCollectionViewDropBefore;
    return NSDragOperationMove;
  }
  return NSDragOperationNone;
}


- (id<NSPasteboardWriting>)pasteboardWriterForItem:(PTDAbstractSizeCollectionViewItem *)item
{
  return [NSString stringWithFormat:@"%lf", item.size];
}


- (void)updateItem:(PTDAbstractSizeCollectionViewItem *)item withPasteboard:(NSPasteboard *)pb
{
  NSString *string = [pb readObjectsForClasses:@[[NSString class]] options:nil][0];
  item.size = MAX(2.0, string.doubleValue);
}


- (PTDAbstractSizeCollectionViewItem *)newItemFromPasteboard:(nullable NSPasteboard *)pb
{
  NSString *string;
  if (pb) {
    string = [pb readObjectsForClasses:@[[NSString class]] options:nil][0];
  } else {
    string = @"12.0";
  }
  return [self createItemWithSize:string.doubleValue];
}


@end


@implementation PTDBrushSizePrefsCollectionViewDelegate


+ (NSSize)itemSize
{
  return PTDBrushSizeCollectionViewItem.size;
}


- (void)reset
{
  PTDBrushTool.defaultSizes = nil;
}


- (PTDBrushSizeCollectionViewItem *)createItemWithSize:(CGFloat)size
{
  PTDBrushSizeCollectionViewItem *item = [[PTDBrushSizeCollectionViewItem alloc] initWithSize:size];
  item.target = self;
  return item;
}


- (void)saveItems:(NSArray <PTDBrushSizeCollectionViewItem *> *)items
{
  NSMutableArray *newSizes = [NSMutableArray array];
  for (PTDBrushSizeCollectionViewItem *item in items) {
    [newSizes addObject:@(item.size)];
  }
  PTDBrushTool.defaultSizes = [newSizes copy];
}


- (NSArray <PTDBrushSizeCollectionViewItem *> *)loadItems
{
  NSArray *sizes = PTDBrushTool.defaultSizes;
  NSMutableArray <PTDBrushSizeCollectionViewItem *> *res = [NSMutableArray array];
  for (NSNumber *size in sizes) {
    PTDBrushSizeCollectionViewItem *item = [self createItemWithSize:size.doubleValue];
    [res addObject:item];
  }
  return res;
}


@end


@implementation PTDEraserSizePrefsCollectionViewDelegate


+ (NSSize)itemSize
{
  return PTDEraserSizeCollectionViewItem.size;
}


- (void)reset
{
  PTDEraserTool.defaultSizes = nil;
}


- (PTDEraserSizeCollectionViewItem *)createItemWithSize:(CGFloat)size
{
  PTDEraserSizeCollectionViewItem *item = [[PTDEraserSizeCollectionViewItem alloc] initWithSize:size];
  item.target = self;
  return item;
}


- (void)saveItems:(NSArray <PTDEraserSizeCollectionViewItem *> *)items
{
  NSMutableArray *newSizes = [NSMutableArray array];
  for (PTDEraserSizeCollectionViewItem *item in items) {
    [newSizes addObject:@(item.size)];
  }
  PTDEraserTool.defaultSizes = [newSizes copy];
}


- (NSArray <PTDEraserSizeCollectionViewItem *> *)loadItems
{
  NSArray *sizes = PTDEraserTool.defaultSizes;
  NSMutableArray <PTDEraserSizeCollectionViewItem *> *res = [NSMutableArray array];
  for (NSNumber *size in sizes) {
    PTDEraserSizeCollectionViewItem *item = [self createItemWithSize:size.doubleValue];
    [res addObject:item];
  }
  return res;
}


@end
