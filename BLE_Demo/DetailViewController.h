//
//  DetailViewController.h
//  BLE_Demo
//
//  Created by 先锋电子技术 on 16/5/17.
//  Copyright © 2016年 先锋电子技术. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;
@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end

