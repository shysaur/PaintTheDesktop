//
//  NSNib+PTD.m
//  PaintTheDesktop
//
//  Created by Daniele Cattaneo on 29/06/2020.
//  Copyright © 2020 danielecattaneo. All rights reserved.
//

#import "NSNib+PTD.h"


@implementation NSNib (PTD)


- (id)ptd_instantiateObjectWithIdentifier:(NSString *)ident withOwner:(nullable id)owner
{
  NSArray *itms;
  BOOL res = [self instantiateWithOwner:owner topLevelObjects:&itms];
  if (!res)
    return nil;
  for (id obj in itms) {
    if ([obj respondsToSelector:@selector(identifier)]) {
      NSString *thisIdent = [obj identifier];
      if ([ident isEqual:thisIdent])
        return obj;
    }
  }
  return nil;
}


@end
