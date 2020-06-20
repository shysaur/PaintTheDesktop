//
//  PTDToolManager.h
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 10/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PTDRingMenu.h"

NS_ASSUME_NONNULL_BEGIN

@class PTDTool;
@class PTDBrush;

@interface PTDToolManager : NSObject

@property (class, nonatomic, readonly) PTDToolManager *sharedManager;

@property (nonatomic) PTDBrush *currentBrush;

@property (nonatomic, readonly) PTDTool *currentTool;
@property (nonatomic, readonly, nullable) NSString *previousToolIdentifier;

@property (nonatomic, readonly) NSArray <NSString *> *availableToolIdentifiers;
- (PTDRingMenuItem *)ringMenuItemForSelectingToolIdentifier:(NSString *)ti;

- (void)changeTool:(NSString *)newIdentifier;

@end

NS_ASSUME_NONNULL_END
