//
//  CardactionViewController.h
//  BLEDataGateway
//
//  Created by luokai on 15/10/26.
//  Copyright © 2015年 BDE. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WTReTextField.h"

@class PeripheralDevice;
@interface CardactionViewController : UIViewController
{
   
}

@property (nonatomic,strong)   PeripheralDevice* device;

@property(nonatomic,retain)    IBOutlet UILabel *cardmoney;
@property(nonatomic,retain)    IBOutlet UILabel *cardnumber;
@property(nonatomic,retain)    IBOutlet UILabel *cardname;
@property(nonatomic,retain)    IBOutlet UILabel *chaxuntime;

@property(nonatomic,retain)    IBOutlet WTReTextField *chongzhilab;

@property(nonatomic,retain)    IBOutlet UIButton *Sendchongzhiaction;
@property(nonatomic,retain)    IBOutlet UIButton *Sendchaxunaction;


-(IBAction)Bluechaxun:(id)sender;
-(IBAction)Bluechongzhi:(id)sender;

@end
