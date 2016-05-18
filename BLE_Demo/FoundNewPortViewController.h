//
//  FoundNewPortViewController.h
//  BLEDataGateway
//
//  Created by 王 维 on 8/27/14.
//  Copyright (c) 2014 BDE. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "common.h"

@interface FoundNewPortViewController : UIViewController <UITableViewDataSource,UITableViewDelegate>

@property (assign,nonatomic)    NSInteger   devicesCount;

@end