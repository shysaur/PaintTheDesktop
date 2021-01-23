//
// PTDTool.h
// PaintTheDesktop -- Created on 10/06/2020.
//
// Copyright (c) 2020 Daniele Cattaneo
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
#import "PTDRingMenu.h"

NS_ASSUME_NONNULL_BEGIN

@class PTDDrawingSurface;
@class PTDCursor;
@class PTDBrush;

@interface PTDTool : NSObject

- (instancetype)init NS_DESIGNATED_INITIALIZER;

@property (class, readonly, nonatomic) NSString *toolIdentifier;

@property (nonatomic, weak) PTDDrawingSurface *currentDrawingSurface;
@property (nonatomic) PTDBrush *currentBrush;

- (void)dragDidStartAtPoint:(NSPoint)point;
- (void)dragDidContinueFromPoint:(NSPoint)prevPoint toPoint:(NSPoint)nextPoint;
- (void)dragDidEndAtPoint:(NSPoint)point;

- (void)mouseClickedAtPoint:(NSPoint)point;

- (void)modifierFlagsChanged;

@property (nonatomic, nullable) PTDCursor *cursor;

- (void)activate;
- (void)deactivate;

+ (PTDRingMenuItem *)menuItem;

- (void)willOpenOptionMenuAtPoint:(NSPoint)point;
- (nullable PTDRingMenuRing *)optionMenu;

@end

NS_ASSUME_NONNULL_END
