//
//  TLBackgroundTaskHandler.m
//  TripLogger
//
//  Created by Wei Liu on 7/18/16.
//  Copyright © 2016 WL. All rights reserved.
//

#import "TLBackgroundTaskHandler.h"

@interface TLBackgroundTaskHandler ()

@property (nonatomic, strong) NSMutableArray *taskList;
@property (nonatomic) UIBackgroundTaskIdentifier identifier;
@end

@implementation TLBackgroundTaskHandler

+ (instancetype)sharedBackgroundTaskHandler {
  static TLBackgroundTaskHandler *handler = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    handler = [TLBackgroundTaskHandler new];
  });
  return handler;
}

- (instancetype)init {
  if (self = [super init]) {
    _taskList = [NSMutableArray array];
    _identifier = UIBackgroundTaskInvalid;
  }
  return self;
}

- (UIBackgroundTaskIdentifier)startNewBackgroundTask {
  UIApplication *app = [UIApplication sharedApplication];
  __block UIBackgroundTaskIdentifier taskId = UIBackgroundTaskInvalid;
  taskId = [app beginBackgroundTaskWithExpirationHandler:^{
    NSLog(@"background task %lu will expire", taskId);
    
    [self.taskList removeObject:@(taskId)];
    [app endBackgroundTask:taskId];
    taskId = UIBackgroundTaskInvalid;
  }];
  
  if (self.identifier == UIBackgroundTaskInvalid) {
    self.identifier = taskId;
  } else {
    [self.taskList addObject:@(taskId)];
    [self endBackgroundTasks];
  }
  
  return taskId;
}

- (void)endBackgroundTask:(UIBackgroundTaskIdentifier)identifier {
  
  [[UIApplication sharedApplication] endBackgroundTask:self.identifier];
  [self.taskList removeObject:@(identifier)];
  if (self.identifier == identifier) {
    self.identifier = UIBackgroundTaskInvalid;
  }
}

- (void)endBackgroundTasks {
  UIApplication *app = [UIApplication sharedApplication];
  for (int i = 0; i < self.taskList.count-1; i++) {
    UIBackgroundTaskIdentifier identifier = [[self.taskList objectAtIndex:0] integerValue];
    [app endBackgroundTask:identifier];
    [self.taskList removeObjectAtIndex:0];
  }
}

@end
