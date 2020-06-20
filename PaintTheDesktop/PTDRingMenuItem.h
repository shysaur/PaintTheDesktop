//
//  PTDRingMenuItem.h
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 17/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTDRingMenuItem : NSObject

+ (PTDRingMenuItem *)itemWithImage:(NSImage *)image target:(nullable id)target action:(nullable SEL)action;
+ (PTDRingMenuItem *)itemWithText:(NSString *)text target:(nullable id)target action:(nullable SEL)action;

@property (nonatomic) NSImage *image;
@property (nonatomic, nullable) NSImage *selectedImage;

- (void)setText:(NSString *)text;

@property (nonatomic, weak) id target;
@property (nonatomic) SEL action;

@property (nonatomic) NSInteger tag;
@property (nonatomic, nullable) id representedObject;

@end

NS_ASSUME_NONNULL_END
