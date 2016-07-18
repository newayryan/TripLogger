//
//  Trip.m
//  TripLogger
//
//  Created by Wei Liu on 7/16/16.
//  Copyright © 2016 WL. All rights reserved.
//

#import "Trip.h"

@implementation Trip

// create a NSDateFormatter to improve performance
+ (NSDateFormatter*)dateFormatter {
  static NSDateFormatter *dateFormatter = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    dateFormatter = [NSDateFormatter new];
    dateFormatter.locale = [NSLocale currentLocale];
    dateFormatter.dateFormat = @"hh:mm a";
  });
  return dateFormatter;
}

- (NSString *)tripInterval {
  // TODO: better way to handle nil?
  NSString *from = self.startTime ? [[Trip dateFormatter] stringFromDate:self.startTime] : NSLocalizedString(@"Some time", nil);;
  NSString *to = self.endTime ? [[Trip dateFormatter] stringFromDate:self.endTime] : NSLocalizedString(@"Some time", nil);
  
  NSTimeInterval timeInterval = (self.endTime && self.startTime) ? [self.endTime timeIntervalSinceDate:self.startTime] : 0;
  return [NSString stringWithFormat:@"%@ - %@ (%u min)", from, to, (int)timeInterval/60];
}

- (NSString *)tripRoute {
  NSString *from = (self.startLocation && self.startLocation.length>0) ? self.startLocation : NSLocalizedString(@"Somewhere", nil);
  NSString *to = (self.endLocation && self.endLocation.length>0) ? self.endLocation : NSLocalizedString(@"Somewhere", nil);
  return [NSString stringWithFormat:@"%@ > %@", from, to];
}

@end
