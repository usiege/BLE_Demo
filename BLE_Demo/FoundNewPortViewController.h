//
//  FoundNewPortViewController.h
//  BLEDataGateway
//
//  Created by 王 维 on 8/27/14.
//  Copyright (c) 2014 BDE. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "common.h"
#import "BLEManageController.h"
#import "DeviceInforModel.h"
@interface FoundNewPortViewController : UIViewController <UITableViewDataSource,UITableViewDelegate>

@property (strong,nonatomic)   UITableView *foundDevicesTableView;

@property (assign,nonatomic)   ChannelType channelType;

-(void)connectDevice:(DeviceInforModel*)device;

@end