//
//  Trip+CoreDataProperties.h
//  TripLogger
//
//  Created by Wei Liu on 7/16/16.
//  Copyright © 2016 WL. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Trip.h"

NS_ASSUME_NONNULL_BEGIN

@interface Trip (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *startLocation;
@property (nullable, nonatomic, retain) NSString *endLocation;
@property (nullable, nonatomic, retain) NSDate *startTime;
@property (nullable, nonatomic, retain) NSDate *endTime;

@end

NS_ASSUME_NONNULL_END
