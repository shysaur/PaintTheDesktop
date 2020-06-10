//
//  PTDCursor.h
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 10/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTDCursor : NSObject

@property (nonatomic) NSImage *image;
@property (nonatomic) NSPoint hotspot;

@end

NS_ASSUME_NONNULL_END
