//
// PTDTextSizeEditorController.m
// PaintTheDesktop -- Created on 02/01/22.
//
// Copyright (c) 2022 Daniele Cattaneo
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

#import "PTDTextSizePrefsTableViewController.h"
#import "PTDTextTool.h"


@interface PTDTextSizePrefsTableViewController ()

@property (nonatomic, weak) IBOutlet NSTableView *tableView;

- (IBAction)reset:(id)sender;
- (IBAction)addItem:(id)sender;
- (IBAction)deleteItem:(id)sender;

@property (nonatomic) BOOL canDelete;

@end


@implementation PTDTextSizePrefsTableViewController


- (void)setTableView:(NSTableView *)tableView
{
  _tableView = tableView;
  
  NSNumberFormatter *fmt = [[NSNumberFormatter alloc] init];
  fmt.numberStyle = NSNumberFormatterDecimalStyle;
  fmt.minimum = @(2.0);
  [_tableView.tableColumns[0].dataCell setFormatter:fmt];
  
  [_tableView registerForDraggedTypes:@[NSPasteboardTypeString]];
  [_tableView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:YES];
  [_tableView setDraggingSourceOperationMask:NSDragOperationNone forLocal:NO];
}


- (void)reset:(id)sender
{
  PTDTextTool.defaultFontSizes = nil;
  [self.tableView reloadData];
}


- (void)addItem:(id)sender
{
  NSMutableArray *sizes = [PTDTextTool.defaultFontSizes mutableCopy];
  NSInteger position = self.tableView.selectedRow + 1;
  if (position < 1 || position > sizes.count)
    position = sizes.count;
  [sizes insertObject:@(24) atIndex:position];
  PTDTextTool.defaultFontSizes = [sizes copy];
  [self.tableView reloadData];
}


- (void)deleteItem:(id)sender
{
  NSMutableArray *sizes = [PTDTextTool.defaultFontSizes mutableCopy];
  NSInteger position = self.tableView.selectedRow;
  if (position < 0)
    return;
  [sizes removeObjectAtIndex:position];
  PTDTextTool.defaultFontSizes = [sizes copy];
  [self.tableView reloadData];
}


- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
  self.canDelete = self.tableView.selectedRow >= 0;
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
  return PTDTextTool.defaultFontSizes.count;
}


- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
  return [PTDTextTool.defaultFontSizes objectAtIndex:row];
}


- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
  NSMutableArray *sizes = [PTDTextTool.defaultFontSizes mutableCopy];
  [sizes replaceObjectAtIndex:row withObject:object];
  PTDTextTool.defaultFontSizes = [sizes copy];
}


- (id<NSPasteboardWriting>)tableView:(NSTableView *)tableView pasteboardWriterForRow:(NSInteger)row
{
  NSNumber *n = [PTDTextTool.defaultFontSizes objectAtIndex:row];
  return [NSString stringWithFormat:@"%lf", n.doubleValue];
}


- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
  if (info.draggingSource == self.tableView)
    return NSDragOperationMove;
  return NSDragOperationNone;
}


- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation
{
  NSPasteboard *pb = info.draggingPasteboard;
  NSString *string = [pb readObjectsForClasses:@[[NSString class]] options:nil][0];
  NSNumber *n = [NSNumber numberWithDouble:MAX(2.0, string.doubleValue)];
  
  NSMutableArray *sizes = [PTDTextTool.defaultFontSizes mutableCopy];
  NSInteger oldLocation = [sizes indexOfObject:n];
  if (oldLocation == NSNotFound)
    return NO;
  if (row == oldLocation)
    return YES;
  [sizes removeObjectAtIndex:oldLocation];
  if (row > oldLocation)
    row--;
  [sizes insertObject:n atIndex:row];
  PTDTextTool.defaultFontSizes = [sizes copy];
  return YES;
}


@end
