//
//  PTDRingMenu.h
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 16/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class PTDRingMenu;

@interface PTDRingMenuWindow : NSWindowController

- (instancetype)initWithRingMenu:(PTDRingMenu *)menu;

@end

NS_ASSUME_NONNULL_END
