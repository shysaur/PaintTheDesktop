//
//  PTDTool.h
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 10/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PTDRingMenu.h"

NS_ASSUME_NONNULL_BEGIN

@class PTDDrawingSurface;
@class PTDCursor;

extern NSString * const PTDToolCursorDidChangeNotification;

@interface PTDTool : NSObject

- (instancetype)init NS_DESIGNATED_INITIALIZER;

@property (class, readonly, nonatomic) NSString *toolIdentifier;

@property (nonatomic, weak) PTDDrawingSurface *currentDrawingSurface;

- (void)brushDidChange;

- (void)dragDidStartAtPoint:(NSPoint)point;
- (void)dragDidContinueFromPoint:(NSPoint)prevPoint toPoint:(NSPoint)nextPoint;
- (void)dragDidEndAtPoint:(NSPoint)point;

- (void)mouseClickedAtPoint:(NSPoint)point;

@property (nonatomic, nullable) PTDCursor *cursor;

- (void)activate;
- (void)deactivate;

+ (PTDRingMenuItem *)menuItem;
- (nullable PTDRingMenuRing *)optionMenu;

@end

NS_ASSUME_NONNULL_END
