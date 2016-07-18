//
//  Trip.h
//  TripLogger
//
//  Created by Wei Liu on 7/16/16.
//  Copyright © 2016 WL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface Trip : NSManagedObject

// computed properties, assist for UI display
@property (readonly, nonatomic) NSString *tripRoute;
@property (readonly, nonatomic) NSString *tripInterval;

@end

NS_ASSUME_NONNULL_END

#import "Trip+CoreDataProperties.h"
