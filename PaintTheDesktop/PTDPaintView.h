//
//  PTDPaintView.h
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 08/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTDPaintView : NSOpenGLView

@property (nonatomic, readonly) NSGraphicsContext *graphicsContext;
@property (nonatomic, readonly) NSRect paintRect;

@end

NS_ASSUME_NONNULL_END
