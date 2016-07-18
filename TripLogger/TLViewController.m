//
//  ViewController.m
//  TripLogger
//
//  Created by Wei Liu on 7/16/16.
//  Copyright © 2016 WL. All rights reserved.
//

#import "TLViewController.h"
#import "TLTableViewCell.h"
#import "Trip.h"
#import "TLLocationMarker.h"

#import <CoreLocation/CoreLocation.h>

@interface TLViewController () <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, TLLocationMarkerProtocol>

// General
@property (nonatomic, strong) UIAlertController *alertController;

// Core Data
@property (readwrite, nonatomic, strong) NSManagedObjectContext  *managedObjectContext;
@property (readwrite, nonatomic, strong) NSManagedObjectModel    *managedObjectModel;
@property (readwrite, nonatomic, strong) NSPersistentStoreCoordinator  *persistentStoreCoordinator;

// Core Data helpers
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

// Core Location
@property (nonatomic, strong) TLLocationMarker *locationMarker;
@end

@implementation TLViewController

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  // custom navigationBar
  UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"navbar" ]];
  self.navigationItem.titleView = imageView;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  // NSFetchedResultsController
  [self createFetchedResultsController];
  
  // create location marker (to track location - both when app is foreground and background)
  self.locationMarker = [TLLocationMarker new];
  self.locationMarker.delegate = self;
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
  [self.tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
  [self.tableView endUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
  switch (type) {
    case NSFetchedResultsChangeInsert: {
      [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
      break;
    }
    case NSFetchedResultsChangeDelete: {
      [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
      break;
    }
    case NSFetchedResultsChangeUpdate: {
      TLTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
      [cell updateUIWithData:[self.fetchedResultsController objectAtIndexPath:indexPath]];
      break;
    }
    case NSFetchedResultsChangeMove: {
      [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
      [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
      break;
    }
  }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  NSArray *sections = [self.fetchedResultsController sections];
  NSAssert(section<sections.count, @"section number is out of boundary");
  id<NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:section];
  return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  TLTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"tripLogCell"];
  // Obtain the data model and pass it to cell - update the cell UI
  [cell updateUIWithData:[self.fetchedResultsController objectAtIndexPath:indexPath]];
  
  return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  if (section == 0)
    return CGFLOAT_MIN;     // or any small value (probably 1 is better for production app)
  return tableView.sectionHeaderHeight;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    Trip *record = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if (record) {
      [self.fetchedResultsController.managedObjectContext deleteObject:record];
    }
  }
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 60;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - TLLocationMarkerProtocol

- (void)addRecordForFromLocation:(NSString *)fromStr andTime:(NSDate *)fromDate toLocation:(NSString *)toStr andTime:(NSDate *)toDate {
  NSAssert(fromStr&&fromStr.length>0&&toStr&&toStr.length, @"Invalid address");
  NSAssert(fromDate&&toDate, @"Invalid date");

  NSEntityDescription *entity = [NSEntityDescription entityForName:@"Trip" inManagedObjectContext:self.managedObjectContext];
  Trip *record = [[Trip alloc] initWithEntity:entity insertIntoManagedObjectContext:self.managedObjectContext];
  record.startTime = fromDate;
  record.endTime = toDate;
  record.startLocation = fromStr;
  record.endLocation = toStr;
  
  NSError *error = nil;
  if (![self.managedObjectContext save:&error]) {
    if (error != nil) {
      [self showAlertWithMessage:NSLocalizedString(@"Failed to save trip information", nil)];
    }
  }
}

- (void)showAlertMessage:(NSString *)msg {
  [self showAlertWithMessage:msg];
}

#pragma mark - Private / helpers

- (void)showAlertWithMessage:(NSString *)msg {
  if (_alertController == nil) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:ok];
  }
  _alertController.message = msg;
  [self presentViewController:_alertController animated:YES completion:nil];
}

- (void)createFetchedResultsController {
  static NSString *entityName = @"Trip";
  static NSString *sortKey = @"startTime";
  
  NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entityName];
  // sort descriptors
  [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:sortKey ascending:NO]]];
  self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
  self.fetchedResultsController.delegate = self;
  
  // perform fetch
  NSError *error = nil;
  [self.fetchedResultsController performFetch:&error];
  if (error != nil) {
    [self showAlertWithMessage:NSLocalizedString(@"Failed to load past trip information", nil)];
  }
}

#pragma mark - Public / Control methods

-(IBAction)switchValueChanged:(id)sender {
  if ([self.logSwitch isOn]) {
    [self.locationMarker startUpdatingLocation];
  } else {
    [self.locationMarker stopUpdatingLocation];
  }
}

#pragma mark - Core Data

- (NSManagedObjectContext *)managedObjectContext {
  if (_managedObjectContext != nil) {
    return _managedObjectContext;
  }
  
  NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
  if (coordinator != nil) {
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
  }
  return _managedObjectContext;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
  if (_persistentStoreCoordinator != nil) {
    return _persistentStoreCoordinator;
  }
  
  NSURL *storeURL = [[self applicationDocumentDirectory] URLByAppendingPathComponent:@"Trip_Data.sqlite"];
  NSError *error = nil;
  _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
  
  if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
    [self showAlertWithMessage:NSLocalizedString(@"Failed to build trip information", nl)];
  }
  
  return _persistentStoreCoordinator;
}

- (NSManagedObjectModel *)managedObjectModel {
  if (_managedObjectModel != nil) {
    return _managedObjectModel;
  }
  NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Trip_Data" withExtension:@"momd"];
  _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
  return _managedObjectModel;
}

- (void)saveContext {
  NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
  if (managedObjectContext != nil) {
    NSError *error = nil;
    if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
      [self showAlertWithMessage:NSLocalizedString(@"Failed to save trip information", nl)];
    }
  }
}

- (NSURL *)applicationDocumentDirectory {
  return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
