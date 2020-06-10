//
//  PTDTool.h
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 10/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PTDTool <NSObject>

@property (class, readonly) NSString *toolIdentifier;

- (void)dragDidStartAtPoint:(NSPoint)point;
- (void)dragDidContinueFromPoint:(NSPoint)prevPoint toPoint:(NSPoint)nextPoint;
- (void)dragDidEndAtPoint:(NSPoint)point;

- (void)deactivate;

- (nullable NSMenu *)optionMenu;

@end

NS_ASSUME_NONNULL_END
