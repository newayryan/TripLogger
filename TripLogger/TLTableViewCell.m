//
//  TLTableViewCell.m
//  TripLogger
//
//  Created by Wei Liu on 7/16/16.
//  Copyright © 2016 WL. All rights reserved.
//

#import "TLTableViewCell.h"

@implementation TLTableViewCell

- (void)updateUIWithData:(Trip*)trip {
  NSAssert(trip, @"nil object");
  if (!trip) return;
  // updateCell UI
  self.tripRoute.text = [trip tripRoute];
  self.tripInterval.text = [trip tripInterval];
}

@end
