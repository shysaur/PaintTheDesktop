//
//  PTDToolManager.h
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 10/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PTDTool.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTDToolManager : NSObject

@property (class, nonatomic, readonly) PTDToolManager *sharedManager;

@property (nonatomic, readonly) id <PTDTool> currentTool;

@property (nonatomic, readonly) NSArray <NSString *> *availableToolIdentifiers;
- (NSString *)toolNameForIdentifier:(NSString *)ti;

- (void)changeTool:(NSString *)newIdentifier;

@end

NS_ASSUME_NONNULL_END
