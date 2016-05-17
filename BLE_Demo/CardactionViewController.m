//
//  CardactionViewController.m
//  BLEDataGateway
//
//  Created by luokai on 15/10/26.
//  Copyright © 2015年 BDE. All rights reserved.
//

#import "CardactionViewController.h"
#import "FoundNewPortViewController.h"
#import "RegExCategories.h"
#import "BLEManageController.h"

//extern BLEManageController *Public_BleController;


@interface CardactionViewController ()
{
    BLEManageController *Public_BleController;
}
@end

@implementation CardactionViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    Public_BleController = [BLEManageController sharedInstance];
    
    self.chongzhilab.pattern=@"^((0|[1-9]{1}\\d{0,5}))(?:\\.)\\d{2}$";
    
    NSDate *  senddate=[NSDate date];
    
    NSDateFormatter  *dateformatter=[[NSDateFormatter alloc] init];
    
    [dateformatter setDateFormat:@"YYYY-MM-dd  HH:mm:ss"];
    
    NSString *  locationString=[dateformatter stringFromDate:senddate];
    
//    NSLog(@"locationString:%@",locationString);
    
    self.cardmoney.text = Public_BleController.databuff;
    self.chaxuntime.text = locationString;
    
    if (Public_BleController.cardchoiseabc == 1) {
        self.cardname.text = @"燃气卡";
    }else if (Public_BleController.cardchoiseabc == 2){
        self.cardname.text = @"深圳通";
    }else if(Public_BleController.cardchoiseabc == 3){
        self.cardname.text = @"银行卡";
    }
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



/////查询
-(IBAction)Bluechaxun:(id)sender
{
    
    if(Public_BleController.outputDevice.state == BT40DeviceState_DataReady){
        
//        if (Public_BleController.cardchoiseabc == 3) {
//            Public_BleController.actionsort =10;
//            Public_BleController.requesetcount=1;
//            [Public_BleController actionbankchaxun];
//        }else{
//            Public_BleController.actionsort = 5;
//            Public_BleController.requesetcount = 1;
//            [Public_BleController actiontaizhouchaxun];
//        }
//
//        alert= [[UIAlertView alloc]initWithTitle:@"正在通讯，请稍后...." message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:nil];
//        [NSTimer scheduledTimerWithTimeInterval:2.0f target:self selector: @selector(performDismisschaxun)  userInfo:nil repeats:NO];
//        [alert show];
        Public_BleController.actionsort=12;
        Public_BleController.requesetcount=1;
        [Public_BleController actionreadandwrite];
        
    }else{
        
    }
}


/////充值
-(IBAction)Bluechongzhi:(id)sender
{
    if(Public_BleController.outputDevice.state == BT40DeviceState_DataReady){
        
//        if(([self.chongzhilab.text  isEqual:@"0.00"])|| self.chongzhilab.text.length>9||([self.chongzhilab.text  isEqual:@""])){
//            alert= [[UIAlertView alloc]initWithTitle:@"请输入正确的金额" message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
//            [alert show];
//        }else{
//            if (Public_BleController.cardchoiseabc == 3) {
//                Public_BleController.actionsort =11;
//                Public_BleController.requesetcount=1;
//                [Public_BleController actionmybankchongzhi:self.chongzhilab.text];
//            }else{
//                Public_BleController.actionsort = 6;
//                Public_BleController.requesetcount =1;
//                [Public_BleController actionMytaizhouchongzhi:self.chongzhilab.text];
//            }
//
//            alert= [[UIAlertView alloc]initWithTitle:@"正在通讯，请稍后...." message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:nil];
//            [NSTimer scheduledTimerWithTimeInterval:2.0f target:self selector: @selector(performDismisschaxun)  userInfo:nil repeats:NO];
//            [alert show];
//        }
    }else{
        
        
    }

}


-(void)performDismisschaxun
{
    [alert dismissWithClickedButtonIndex:0 animated:NO];
    alert= [[UIAlertView alloc]initWithTitle:@"成功！" message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];

    
    NSDate *  senddate=[NSDate date];
    
    NSDateFormatter  *dateformatter=[[NSDateFormatter alloc] init];
    
    [dateformatter setDateFormat:@"YYYY-MM-dd  HH:mm:ss"];
    
    NSString *  locationString=[dateformatter stringFromDate:senddate];
    
    
    //    NSLog(@"locationString:%@",locationString);
    self.cardmoney.text = Public_BleController.databuff;
    self.chaxuntime.text = locationString;

    //    [alert release];
}




/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

///回收键盘
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"tuichu ");
    if(![self.chongzhilab.text containsString:@"."] && ![self.chongzhilab.text isEqual:@""]){
         self.chongzhilab.text = [self.chongzhilab.text stringByAppendingString:@".00"];
    }
    else if([self.chongzhilab.text isMatch:RX(@"^((0|[1-9]{1}\\d{1,5})).\\d{0}$")]) {
        self.chongzhilab.text = [self.chongzhilab.text stringByAppendingString:@"00"];
    }else{
        
        if ([self.chongzhilab.text isMatch:RX(@"^((0|[1-9]{1}\\d{1,5})).\\d{1}$")]) {
            
            self.chongzhilab.text = [self.chongzhilab.text stringByAppendingString:@"0"];
        }
    }
    
    [self.view endEditing:YES];
}



@end
