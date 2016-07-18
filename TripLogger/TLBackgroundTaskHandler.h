//
//  TLBackgroundTaskHandler.h
//  TripLogger
//
//  Created by Wei Liu on 7/18/16.
//  Copyright © 2016 WL. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TLBackgroundTaskHandler : NSObject

+ (instancetype)sharedBackgroundTaskHandler;

- (UIBackgroundTaskIdentifier)startNewBackgroundTask;
- (void)endBackgroundTask:(UIBackgroundTaskIdentifier)identifier;
- (void)endBackgroundTasks;
@end
