//
// PTDAbstractPrefsCollectionViewDelegate.h
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

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTDAbstractPrefsCollectionViewDelegate : NSObject <NSCollectionViewDelegate, NSCollectionViewDataSource, NSCollectionViewDelegateFlowLayout>

@property (nonatomic) IBOutlet NSCollectionView *collectionView;

- (IBAction)reset:(id)sender;
- (IBAction)addItem:(id)sender;
- (IBAction)deleteItem:(id)sender;

@property (nonatomic, readonly) BOOL canDelete;

- (void)saveOptions:(id)sender;

#pragma mark - Abstract Methods

+ (NSSize)itemSize;

- (void)reset;
- (void)saveItems:(NSArray <NSCollectionViewItem *> *)items;
- (NSArray <NSCollectionViewItem *> *)loadItems;

- (id<NSPasteboardWriting>)pasteboardWriterForItem:(NSCollectionViewItem *)item;
- (void)updateItem:(NSCollectionViewItem *)item withPasteboard:(NSPasteboard *)pb;
- (NSCollectionViewItem *)newItemFromPasteboard:(nullable NSPasteboard *)pb;

@end

NS_ASSUME_NONNULL_END
