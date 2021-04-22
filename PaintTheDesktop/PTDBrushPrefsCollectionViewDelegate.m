//
// PTDBrushPrefsCollectionViewDelegate.m
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

#import "PTDBrushPrefsCollectionViewDelegate.h"
#import "PTDBrushColorCollectionViewItem.h"
#import "PTDBrushTool.h"
#import "PTDToolOptions.h"
#import "PTDCollectionViewFlowLayout.h"


@implementation PTDBrushPrefsCollectionViewDelegate {
  NSMutableArray <PTDBrushColorCollectionViewItem *> *_items;
  NSInteger _draggedItemIndex;
}


- (void)setCollectionView:(NSCollectionView *)collectionView
{
  _draggedItemIndex = -1;
  
  _collectionView = collectionView;
  
  _items = [[NSMutableArray alloc] init];
  NSArray *colors = PTDBrushTool.defaultColors;
  for (NSColor *color in colors) {
    PTDBrushColorCollectionViewItem *item = [self createItemWithColor:color];
    [_items addObject:item];
  }
  
  _collectionView = collectionView;
  NSCollectionViewFlowLayout *flowLayout = [[PTDCollectionViewFlowLayout alloc] init];
  flowLayout.minimumInteritemSpacing = 3;
  flowLayout.minimumLineSpacing = 3;
  flowLayout.sectionInset = NSEdgeInsetsMake(2, 2, 2, 2);
  flowLayout.estimatedItemSize = PTDBrushColorCollectionViewItem.size;
  _collectionView.collectionViewLayout = flowLayout;
  _collectionView.selectable = YES;
  
  [_collectionView registerForDraggedTypes:@[NSPasteboardTypeColor]];
  [_collectionView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:YES];
  
  _collectionView.delegate = self;
  _collectionView.dataSource = self;
}


- (PTDBrushColorCollectionViewItem *)createItemWithColor:(NSColor *)color
{
  PTDBrushColorCollectionViewItem *item = [[PTDBrushColorCollectionViewItem alloc] initWithColor:color];
  item.target = self;
  return item;
}


- (NSInteger)collectionView:(NSCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
  if (section == 0)
    return _items.count;
  return 0;
}


- (NSSize)collectionView:(NSCollectionView *)collectionView layout:(NSCollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
  return PTDBrushColorCollectionViewItem.size;
}


- (nonnull NSCollectionViewItem *)collectionView:(nonnull NSCollectionView *)collectionView itemForRepresentedObjectAtIndexPath:(nonnull NSIndexPath *)indexPath
{
  return _items[indexPath.item];
}


- (id<NSPasteboardWriting>)collectionView:(NSCollectionView *)collectionView pasteboardWriterForItemAtIndexPath:(NSIndexPath *)indexPath
{
  return _items[indexPath.item].color;
}


- (void)collectionView:(NSCollectionView *)collectionView draggingSession:(NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint forItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths
{
  _draggedItemIndex = indexPaths.anyObject.item;
}


- (NSDragOperation)collectionView:(NSCollectionView *)collectionView validateDrop:(id<NSDraggingInfo>)draggingInfo proposedIndexPath:(NSIndexPath * _Nonnull __autoreleasing * _Nonnull)proposedDropIndexPath dropOperation:(nonnull NSCollectionViewDropOperation *)proposedDropOperation
{
  if (draggingInfo.draggingSource == _collectionView) {
    *proposedDropOperation = NSCollectionViewDropBefore;
    return NSDragOperationMove;
  }
  return NSDragOperationCopy;
}


- (BOOL)collectionView:(NSCollectionView *)collectionView acceptDrop:(id<NSDraggingInfo>)draggingInfo indexPath:(nonnull NSIndexPath *)indexPath dropOperation:(NSCollectionViewDropOperation)dropOperation
{
  NSColor *color = [draggingInfo.draggingPasteboard readObjectsForClasses:@[[NSColor class]] options:nil][0];
  if (dropOperation == NSCollectionViewDropOn) {
    _items[indexPath.item].color = color;
    return YES;
  }
  
  PTDBrushColorCollectionViewItem *item = [self createItemWithColor:color];
  
  NSInteger adjIndex = indexPath.item;
  if (_draggedItemIndex >= 0) {
    [_items removeObjectAtIndex:_draggedItemIndex];
    if (adjIndex > _draggedItemIndex)
      adjIndex--;
  }
  [_items insertObject:item atIndex:adjIndex];
  if (_draggedItemIndex >= 0) {
    [_collectionView moveItemAtIndexPath:[NSIndexPath indexPathForItem:_draggedItemIndex inSection:0] toIndexPath:[NSIndexPath indexPathForItem:adjIndex inSection:0]];
  } else {
    [_collectionView insertItemsAtIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:adjIndex inSection:0]]];
  }
  
  _draggedItemIndex = -1;
  [self saveOptions];
  return YES;
}


- (void)saveOptions
{
  NSMutableArray *newColors = [NSMutableArray array];
  for (PTDBrushColorCollectionViewItem *item in _items) {
    [newColors addObject:item.color];
  }
  PTDBrushTool.defaultColors = [newColors copy];
}


- (void)loadOptions
{
  NSArray *colors = PTDBrushTool.defaultColors;
  [_items removeAllObjects];
  for (NSColor *color in colors) {
    PTDBrushColorCollectionViewItem *item = [self createItemWithColor:color];
    [_items addObject:item];
  }
  [self.collectionView reloadData];
}


- (void)colorChanged:(id)sender
{
  [self saveOptions];
}


- (IBAction)reset:(id)sender
{
  PTDBrushTool.defaultColors = nil;
  [self loadOptions];
}


- (IBAction)addItem:(id)sender
{
  PTDBrushColorCollectionViewItem *itm = [self createItemWithColor:[NSColor blackColor]];
  [_items addObject:itm];
  [_collectionView insertItemsAtIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:_items.count-1 inSection:0]]];
  [self saveOptions];
}


- (IBAction)deleteItem:(id)sender
{
  NSSet <NSIndexPath *> *selected = [_collectionView selectionIndexPaths];
  if (selected.count == 0)
    return;
  
  NSInteger idx = selected.anyObject.item;
  [_items removeObjectAtIndex:idx];
  [_collectionView deleteItemsAtIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:idx inSection:0]]];
  [self saveOptions];
}


+ (NSSet<NSString *> *)keyPathsForValuesAffectingCanDelete
{
  return [NSSet setWithArray:@[@"collectionView.selectionIndexPaths"]];
}


- (BOOL)canDelete
{
  return [_collectionView selectionIndexPaths].count > 0;
}


@end
