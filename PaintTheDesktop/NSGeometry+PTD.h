//
//  NSGeometry+PTD.h
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 27/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

NS_INLINE NSPoint PTD_NSRectCenter(NSRect rect)
{
  return NSMakePoint(
      rect.origin.x + rect.size.width / 2.0,
      rect.origin.y + rect.size.height / 2.0);
}

NS_ASSUME_NONNULL_END
