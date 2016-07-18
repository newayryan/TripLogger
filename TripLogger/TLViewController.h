//
//  ViewController.h
//  TripLogger
//
//  Created by Wei Liu on 7/16/16.
//  Copyright © 2016 WL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface TLViewController : UIViewController

@property (nonatomic, strong) IBOutlet UISwitch *logSwitch;
@property (nonatomic, strong) IBOutlet UITableView *tableView;

// core data
@property (readonly, nonatomic, strong) NSManagedObjectContext  *managedObjectContext;
@property (readonly, nonatomic, strong) NSManagedObjectModel    *managedObjectModel;
@property (readonly, nonatomic, strong) NSPersistentStoreCoordinator  *persistentStoreCoordinator;

// core data helpers
- (void)saveContext;
- (NSURL *)applicationDocumentDirectory;

-(IBAction)switchValueChanged:(id)sender;
@end

