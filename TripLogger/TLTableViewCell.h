//
//  TLTableViewCell.h
//  TripLogger
//
//  Created by Wei Liu on 7/16/16.
//  Copyright © 2016 WL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Trip.h"

@interface TLTableViewCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UILabel *tripRoute;
@property (nonatomic, strong) IBOutlet UILabel *tripInterval;

- (void)updateUIWithData:(Trip*)trip;

@end
