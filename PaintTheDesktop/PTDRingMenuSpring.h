//
//  PTDRingMenuSpring.h
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 17/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTDRingMenuSpring : NSObject

@property (nonatomic) CGFloat initialLength;
@property (nonatomic) CGFloat elasticConstant;

@end

NS_ASSUME_NONNULL_END
