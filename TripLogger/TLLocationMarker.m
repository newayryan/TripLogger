//
//  TLLocationMarker.m
//  TripLogger
//
//  Created by Wei Liu on 7/17/16.
//  Copyright © 2016 WL. All rights reserved.
//

#import "TLLocationMarker.h"
#import "TLBackgroundTaskHandler.h"

// 4.4704 meters/second = 10 miles/hour
static CLLocationSpeed const kMinSpeed = 4.4704;
static CGFloat const kMaxDis = 20;

@interface TLLocationMarker ()

// Background mode - method 1
@property (nonatomic) BOOL isBackgroundMode;
@property (nonatomic) BOOL shouldDeferUpdates;
// Background mode - method 2
@property (nonatomic) NSTimer *startUpdateLocationTimer;
@property (nonatomic) NSTimer *stopUpdateLocationTimer;


@property (nonatomic) CLLocation              *startLocation;     // when current trip starts
@property (nonatomic, strong) CLPlacemark     *startPlaceMark;    // place when current trip starts
@property (nonatomic, strong) CLGeocoder      *geocoder;          // used for reverse geocode location
@property (nonatomic, strong) NSMutableArray  *locationsInOneMinute; // remember locations in the past one minute

@end

@implementation TLLocationMarker

- (instancetype)init {
  if (self = [super init]) {
    [self initData];
    [self addNotifications];
  }
  return self;
}

- (void)initData {
  _isBackgroundMode = NO;
  _shouldDeferUpdates = NO;
  _geocoder = [CLGeocoder new];
  _locationsInOneMinute = [NSMutableArray array];
}

- (void)addNotifications {
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)dealloc {
  // May not need currently
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

#pragma mark - Public methods

- (void)startUpdatingLocation {

  // Check location service is enabled
  if ([CLLocationManager locationServicesEnabled]) {
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    
    if (status == kCLAuthorizationStatusDenied || status == kCLAuthorizationStatusRestricted) {
      // User doesn't enable location, here simply display the message
      if ([self.delegate respondsToSelector:@selector(showAlertMessage:)]) {
        [self.delegate showAlertMessage:NSLocalizedString(@"Location service is not enabled", nil)];
      }
    } else {
      TLLocationMarker.sharedLocationManager.delegate = self;
      TLLocationMarker.sharedLocationManager.desiredAccuracy = kCLLocationAccuracyBest;
      TLLocationMarker.sharedLocationManager.distanceFilter = kCLDistanceFilterNone;
      // we actually don't need this since we are targeting iOS 9
      if ([TLLocationMarker.sharedLocationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [TLLocationMarker.sharedLocationManager requestAlwaysAuthorization];
      }
      [TLLocationMarker.sharedLocationManager startUpdatingLocation];
    }
  }
}

- (void)stopUpdatingLocation {
  [TLLocationMarker.sharedLocationManager stopUpdatingLocation];
  [self clearData];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
  CLLocation *curLocation = [locations lastObject];
  
  {
    // When should consider current location is the "startLocation"
    if (curLocation.speed > kMinSpeed && self.startLocation == nil) {
      
      UIBackgroundTaskIdentifier ident = UIBackgroundTaskInvalid;
      if (self.isBackgroundMode) {
        // Start the background task
        ident = [TLBackgroundTaskHandler.sharedBackgroundTaskHandler startNewBackgroundTask];
      }
      
      self.startLocation = curLocation;
      // Reverse Geocoding
      [self.geocoder reverseGeocodeLocation:self.startLocation completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        if (error == nil && [placemarks count] > 0) {
          self.startPlaceMark = [placemarks firstObject];
        }
        if (ident != UIBackgroundTaskInvalid) {
          [TLBackgroundTaskHandler.sharedBackgroundTaskHandler endBackgroundTask:ident];
        }
      }];
      return;
    }

    // check if device is still for more than 1 minute
    if (self.startLocation != nil) {
      if (self.locationsInOneMinute.count > 0) {
        
        // Get first CLLocation object in self.locationsInOneMinute, and based on the rule how we add CLLocation object to this array we know it is a CLLocation object we obtained in <= 1 minute, then calculate the distance between this CLLocation object and current one.
        CLLocation *first = [self.locationsInOneMinute firstObject];
        NSTimeInterval timePassed = [curLocation.timestamp timeIntervalSinceDate:first.timestamp];
        NSLog(@"time passed: %f", timePassed);
        NSLog(@"distance passed: %f", fabs([curLocation distanceFromLocation:first]));
        
        // Here we consider it is still if for the past one minute it moves less than kMaxDis meters (20 for now)
        if (fabs([curLocation distanceFromLocation:first]) < kMaxDis) {
          UIBackgroundTaskIdentifier ident = UIBackgroundTaskInvalid;
          if (self.isBackgroundMode) {
            // Start the background task
            ident = [TLBackgroundTaskHandler.sharedBackgroundTaskHandler startNewBackgroundTask];
          }
          
          [self.geocoder reverseGeocodeLocation:curLocation completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
            if (error == nil && [placemarks count] > 0) {
              // record it here
              CLPlacemark *currentPlacemark = [placemarks lastObject];
              
              if ([self.delegate respondsToSelector:@selector(addRecordForFromLocation:andTime:toLocation:andTime:)]) {
                // call delegate method to store this trip informatino
                [self.delegate addRecordForFromLocation:self.startPlaceMark.addressDictionary[@"FormattedAddressLines"][0] andTime:self.startLocation.timestamp toLocation:currentPlacemark.addressDictionary[@"FormattedAddressLines"][0] andTime:first.timestamp];
                [self clearData];
              }
              if (ident != UIBackgroundTaskInvalid) {
                [TLBackgroundTaskHandler.sharedBackgroundTaskHandler endBackgroundTask:ident];
              }
            }
          }];
          
        } else {
          // We can get rid of CLLocation object obtained more than 1 minute ago in the array
          if (timePassed/60 > 1) {
            [self.locationsInOneMinute removeObjectAtIndex:0];
          }
          [self.locationsInOneMinute addObject:curLocation];
        }
      } else {
        [self.locationsInOneMinute addObject:curLocation];
      }
    }
  }
  
  [self startBackgroundModeIfNeeded];
//  [self startBackgroundModeIfNeeded1];
}

// Use -allowDeferredLocationUpdatesUntilTraveled in backgroundMode (pass CLLocationDistanceMax), so -didUpdateLocations will be called every 10 seconds
/***************************************************************************************/
- (void)startBackgroundModeIfNeeded1 {
  // If in backgroundMode we will call defer every 10 seconds so here it won't be called frequently
  if (self.isBackgroundMode && !self.shouldDeferUpdates) {
    self.shouldDeferUpdates = YES;
    [TLLocationMarker.sharedLocationManager allowDeferredLocationUpdatesUntilTraveled:CLLocationDistanceMax timeout:10];
  }
}

- (void)locationManager:(CLLocationManager *)manager didFinishDeferredUpdatesWithError:(NSError *)error {
  self.shouldDeferUpdates = NO;
  if (error != nil) {
    [self.delegate showAlertMessage:NSLocalizedString(@"Failed to enable background location update", nil)];
  }
}
/***************************************************************************************/


- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
  switch ([error code]) {
    case kCLErrorNetwork:
    {
      [self.delegate showAlertMessage:NSLocalizedString(@"Please check the network", nil) ];
    }
      break;
    case kCLErrorDenied:
    {
      [self.delegate showAlertMessage:NSLocalizedString(@"Please enable location service", nil)];
    }
      break;
    default:
      break;
  }
}

#pragma mark - Private / Notification methods

- (void)restartLocationUpdates {
//  NSLog(@"start location updates");
  // Don't need the timer - it is a "one time timer"
  if (self.startUpdateLocationTimer) {
    [self.startUpdateLocationTimer invalidate];
    self.startUpdateLocationTimer = nil;
  }
  
  // Reset the CLLocationManager
  TLLocationMarker.sharedLocationManager.delegate = self;
  TLLocationMarker.sharedLocationManager.desiredAccuracy = kCLLocationAccuracyBest;
  TLLocationMarker.sharedLocationManager.distanceFilter = kCLDistanceFilterNone;
  if ([TLLocationMarker.sharedLocationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
    [TLLocationMarker.sharedLocationManager requestAlwaysAuthorization];
  }
  [TLLocationMarker.sharedLocationManager startUpdatingLocation];
}

- (void)stopLocationUpdatesIn10s {
  // Stop
//  NSLog(@"stop location udpates");
  [TLLocationMarker.sharedLocationManager stopUpdatingLocation];
}

- (void)startBackgroundModeIfNeeded {
  
  // Another background model method - two timer to control when to start update locations and when to stop
  if (self.isBackgroundMode) {
    // Update location timer is valid, do nothing
    if (self.startUpdateLocationTimer) {
      return;
    }
    
    // Start update location timer in 20 seconds
    self.startUpdateLocationTimer = [NSTimer scheduledTimerWithTimeInterval:20 target:self selector:@selector(restartLocationUpdates) userInfo:nil repeats:NO];
    
    // cancel and re-fire current stop update location tiemr
    if (self.stopUpdateLocationTimer) {
      [self.stopUpdateLocationTimer invalidate];
      self.stopUpdateLocationTimer = nil;
    }
    self.stopUpdateLocationTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(stopLocationUpdatesIn10s) userInfo:nil repeats:NO];
  }

}

// App goes to background, start background mode
- (void)applicationDidEnterBackground {
  self.isBackgroundMode = YES;
}

- (void)applicationBecomeActive {
  self.isBackgroundMode = NO;
  [TLBackgroundTaskHandler.sharedBackgroundTaskHandler endBackgroundTasks];
  // invalidate timers
  if (self.startUpdateLocationTimer) {
    [self.startUpdateLocationTimer invalidate];
    self.startUpdateLocationTimer = nil;
  }
  if (self.stopUpdateLocationTimer) {
    [self.stopUpdateLocationTimer invalidate];
    self.stopUpdateLocationTimer = nil;
  }
}

- (void)clearData {
  // clean
  [self.locationsInOneMinute removeAllObjects];
  self.startLocation = nil;
  self.startPlaceMark = nil;
  
  if (self.startUpdateLocationTimer) {
    [self.startUpdateLocationTimer invalidate];
    self.startUpdateLocationTimer = nil;
  }
  if (self.stopUpdateLocationTimer) {
    [self.stopUpdateLocationTimer invalidate];
    self.stopUpdateLocationTimer = nil;
  }
}

// create one CLLocationManager instance - singleton is optional currently
+ (CLLocationManager *)sharedLocationManager {
  static CLLocationManager *locationManager = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    locationManager = [CLLocationManager new];
    locationManager.allowsBackgroundLocationUpdates = YES;
    locationManager.pausesLocationUpdatesAutomatically = NO;
  });
  return locationManager;
}


@end
