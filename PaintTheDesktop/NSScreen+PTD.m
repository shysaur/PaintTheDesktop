//
// NSScreen+PTD.m
// PaintTheDesktop -- Created on 12/06/2020.
//
// Copyright (c) 2020 Daniele Cattaneo
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

#import "NSScreen+PTD.h"


@implementation NSScreen (PTD)


- (CGDirectDisplayID)ptd_displayID
{
  return [self.deviceDescription[@"NSScreenNumber"] unsignedIntValue];
}


- (NSString *)ptd_name
{
  if (@available(macOS 10.15, *)) {
    return self.localizedName;
  } else {
    CGDirectDisplayID display = [self ptd_displayID];
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    io_service_t dispSvc = CGDisplayIOServicePort(display);
    #pragma clang diagnostic pop
    NSDictionary *properties = CFBridgingRelease(IODisplayCreateInfoDictionary(dispSvc, kIODisplayOnlyPreferredName));
    return [[properties[@kDisplayProductName] allValues] firstObject];
  }
}


@end
