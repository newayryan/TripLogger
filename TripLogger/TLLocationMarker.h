//
//  TLLocationMarker.h
//  TripLogger
//
//  Created by Wei Liu on 7/17/16.
//  Copyright © 2016 WL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "Trip.h"

@protocol TLLocationMarkerProtocol <NSObject>

- (void)showAlertMessage:(NSString*)msg;
- (void)addRecordForFromLocation:(NSString *)fromStr
                         andTime:(NSDate *)fromDate
                      toLocation:(NSString *)toStr
                         andTime:(NSDate *)toDate;

@end

@interface TLLocationMarker : NSObject <CLLocationManagerDelegate>

@property (nonatomic, weak) id<TLLocationMarkerProtocol> delegate;

- (void)startUpdatingLocation;
- (void)stopUpdatingLocation;

@end
