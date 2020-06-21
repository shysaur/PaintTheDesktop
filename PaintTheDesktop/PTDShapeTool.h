//
//  PTDRectangleTool.h
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 15/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import "PTDTool.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTDShapeTool : PTDTool

- (NSBezierPath *)shapeBezierPathInRect:(NSRect)rect;

@end

NS_ASSUME_NONNULL_END
