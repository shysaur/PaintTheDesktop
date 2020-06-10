//
//  PTDTool.h
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 10/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class PTDPaintView;

@interface PTDTool : NSObject

- (instancetype)init NS_DESIGNATED_INITIALIZER;

@property (class, readonly, nonatomic) NSString *toolIdentifier;

@property (nonatomic, weak) PTDPaintView *currentPaintView;

- (void)dragDidStartAtPoint:(NSPoint)point;
- (void)dragDidContinueFromPoint:(NSPoint)prevPoint toPoint:(NSPoint)nextPoint;
- (void)dragDidEndAtPoint:(NSPoint)point;

- (void)mouseClickedAtPoint:(NSPoint)point;

- (void)activate;
- (void)deactivate;

- (nullable NSMenu *)optionMenu;

@end

NS_ASSUME_NONNULL_END
