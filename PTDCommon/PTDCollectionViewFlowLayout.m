//
// PTDCollectionViewFlowLayout.m
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

#import "PTDCollectionViewFlowLayout.h"

@implementation PTDCollectionViewFlowLayout


- (NSArray<__kindof NSCollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(NSRect)rect
{
  NSArray<__kindof NSCollectionViewLayoutAttributes *> *res = [super layoutAttributesForElementsInRect:rect];
  for (NSCollectionViewLayoutAttributes *itm in res) {
    itm.frame = (NSRect){NSMakePoint(floor(itm.frame.origin.x), floor(itm.frame.origin.y)), itm.frame.size};
  }
  return res;
}


- (nullable NSCollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
  NSCollectionViewLayoutAttributes *itm = [super layoutAttributesForItemAtIndexPath:indexPath];
  itm.frame = (NSRect){NSMakePoint(floor(itm.frame.origin.x), floor(itm.frame.origin.y)), itm.frame.size};
  return itm;
}


- (NSCollectionViewLayoutAttributes *)layoutAttributesForInterItemGapBeforeIndexPath:(NSIndexPath *)indexPath
{
  NSCollectionViewLayoutAttributes *itm = [super layoutAttributesForInterItemGapBeforeIndexPath:indexPath];
  NSRect frame = itm.frame;
  frame.origin.x = floor(frame.origin.x);
  frame.origin.y = floor(frame.origin.y);
  frame.size.width = floor(frame.size.width / 2.0) * 2.0;
  itm.frame = frame;
  return itm;
}


@end
