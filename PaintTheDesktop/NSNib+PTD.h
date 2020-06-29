//
//  NSNib+PTD.h
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 29/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSNib (PTD)

- (id)ptd_instantiateObjectWithIdentifier:(NSString *)ident withOwner:(nullable id)owner;

@end

NS_ASSUME_NONNULL_END
