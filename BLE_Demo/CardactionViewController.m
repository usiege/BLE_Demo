//
//  CardactionViewController.m
//  BLEDataGateway
//
//  Created by luokai on 15/10/26.
//  Copyright © 2015年 BDE. All rights reserved.
//

#import "CardactionViewController.h"
#import "BLEManageController.h"

#import "RegExCategories.h"
#import "PeripheralDevice.h"
#import "XFBluetoochManager.h"


@interface CardactionViewController ()
{
    BOOL addInputDeviceObs;
    BOOL addOutputDeviceObs;
    
//    BLEManageController *_bleController;
    XFBluetoochManager* _sharedBTManager;
}

@property (nonatomic,assign) ChannelType channelType;
@property (strong) UIActivityIndicatorView* aiView;

@end

@implementation CardactionViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self createUI];
    
    _sharedBTManager = [XFBluetoochManager shareInstance];
    addInputDeviceObs = false;
    addOutputDeviceObs = false;
    
    self.chongzhilab.pattern=@"^((0|[1-9]{1}\\d{0,5}))(?:\\.)\\d{2}$";
    
    NSDate *  senddate=[NSDate date];
    NSDateFormatter  *dateformatter=[[NSDateFormatter alloc] init];
    [dateformatter setDateFormat:@"YYYY-MM-dd  HH:mm:ss"];
    NSString *  locationString=[dateformatter stringFromDate:senddate];
    NSLog(@"locationString:%@",locationString);
    
//    self.cardmoney.text = _bleController.databuff;
//    self.chaxuntime.text = locationString;
//    
//    if (_bleController.cardchoiseabc == 1) {
//        self.cardname.text = @"燃气卡";
//    }else if (_bleController.cardchoiseabc == 2){
//        self.cardname.text = @"深圳通";
//    }else if(_bleController.cardchoiseabc == 3){
//        self.cardname.text = @"银行卡";
//    }
    
    //连接卡
    [_sharedBTManager startConnectPeriphralDevice:self.device];
}

-(void)createUI{
    self.title = self.device.name;
    
    self.aiView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    UIBarButtonItem* aiItem = [[UIBarButtonItem alloc] initWithCustomView:_aiView];
    self.navigationItem.rightBarButtonItem = aiItem;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload{
    [super viewDidUnload];
    if(addInputDeviceObs)
    {
        //        [_bleController removeObserver:self forKeyPath:@"inputDevice"];
        addInputDeviceObs = false;
    }
    if(addOutputDeviceObs)
    {
        //        [_bleController removeObserver:self forKeyPath:@"outputDevice"];
        addOutputDeviceObs = false;
    }
}



/////查询
-(IBAction)Bluechaxun:(id)sender{
//    if(_bleController.outputDevice.state == BT40DeviceState_DataReady){
//        _bleController.actionsort=12;
//        _bleController.requesetcount=1;
//        [_bleController actionreadandwrite];
//        
//    }else{
//        
//    }
}


/////充值
-(IBAction)Bluechongzhi:(id)sender
{
//    if(_bleController.outputDevice.state == BT40DeviceState_DataReady){
//    
//    }else{
//        
//        
//    }

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

//    self.cardmoney.text = _bleController.databuff;
    self.chaxuntime.text = locationString;
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
