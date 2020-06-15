//
//  PTDDrawingSurface.h
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 15/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class PTDPaintView;
@class PTDTransientView;

@interface PTDDrawingSurface : NSObject

- (instancetype)initWithPaintView:(PTDPaintView *)paintView;

- (void)beginCanvasDrawing;
- (void)beginOverlayDrawing;

- (NSRect)bounds;

@end

NS_ASSUME_NONNULL_END
