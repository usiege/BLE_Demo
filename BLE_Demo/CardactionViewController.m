 //
//  CardactionViewController.m
//  BLEDataGateway
//
//  Created by luokai on 15/10/26.
//  Copyright © 2015年 BDE. All rights reserved.
//

#import "CardactionViewController.h"

#import "RegExCategories.h"
#import "PeripheralDevice.h"
#import "BluetoochManager.h"
#import "XFSocketManager.h"
#import "BleCardParser.h"

#import "ConverUtil.h"
#import "HHAlertView.h"
#import "MBProgressHUD.h"

@interface CardactionViewController ()<BluetoochDelegate,XFSocketDelegate,
HHAlertViewDelegate>
{
    BluetoochManager*   _sharedBTManager;
    XFSocketManager*    _sharedSocketManager;
}

@property (nonatomic,strong) MBProgressHUD*     progress;
@property (nonatomic,strong) HHAlertView*       alertview;

@end

@implementation CardactionViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self createUI];
    [self setupData];
    
    _sharedBTManager = [BluetoochManager shareInstance];
    _sharedBTManager.delegate = self;
    
    _sharedSocketManager = [XFSocketManager sharedManager];
    _sharedSocketManager.delegate = self;
    
}


- (void)viewDidUnload{
    [super viewDidUnload];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)createUI{
    self.title = self.device.name;
    
    
    self.Sendchaxunaction.enabled = YES;
    self.Sendchongzhiaction.enabled = NO;
}

- (void)setupData{
    self.chongzhilab.pattern=@"^((0|[1-9]{1}\\d{0,5}))(?:\\.)\\d{2}$";
    
    NSDate *  senddate=[NSDate date];
    NSDateFormatter  *dateformatter=[[NSDateFormatter alloc] init];
    [dateformatter setDateFormat:@"YYYY-MM-dd  HH:mm:ss"];
    NSString *  locationString=[dateformatter stringFromDate:senddate];
}

- (void)viewDidDisappear:(BOOL)animated{
    [_sharedBTManager stopSearchPeriphrals];
    if (self.progress) {
        [self.progress hideAnimated:YES];
    }
}


/////查询
-(IBAction)Bluechaxun:(id)sender{
    
    self.device.operationType = GasCardOperation_READ;
    NSLog(@"thread %@",[NSThread currentThread]);
    
    self.progress = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    NSBlockOperation* bo = [NSBlockOperation blockOperationWithBlock:^{
       [_sharedBTManager readDataFromPeriphralDevice:self.device];
    }];
    [[NSOperationQueue mainQueue] addOperation:bo];
}

/////充值
-(IBAction)Bluechongzhi:(id)sender{
    
    self.progress = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.device.operationType = GasCardOperation_WRITE;
    
    NSString* str16response = @"4c59474153303030303230313630353237313131333030303030303031303138313233303435363738202020202020c4a3c4e2d3c3bba7202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202030312020202020202030202020202031203631343731373820202020202020202020313437313738202020202020202020203058323045304646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464639373530304331453034333834453030303030303030303030463130303531423030303035313030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030463132303039344646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646463230313630354537303030303135464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464631323334353637384646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646";
    NSData* data = [ConverUtil hexString2Data:str16response];
    
    BleCardInfo* infoIwish = [BleCardParser parseGasCardDataWithReponseData:data dataType:GasCardDataType_WRITE];
//    NSLog(@"%@",infoIwish);
    
    //购气量是（113,8）第9个是购气量，替换成输入的
    
    self.device.checkKey = infoIwish.verifyPw;
    self.device.checkKeyNew = infoIwish.pwNew;
    
    NSData* sendData = [infoIwish.dataBuf dataUsingEncoding:NSUTF8StringEncoding];
    [_sharedBTManager writeData:sendData toPeriphralDevice:self.device];
}



//接收到蓝牙卡版本数据
- (void)bluetoochManager:(BluetoochManager *)manager didEndReadWithResponseData:(NSData *)data fromDevice:(PeripheralDevice *)device result:(BOOL)isSuccess{
    
    NSLog(@"thread %@",[NSThread currentThread]);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        self.Sendchongzhiaction.enabled = YES;
        if (isSuccess) {
            self.alertview = [[HHAlertView alloc] initWithTitle:@"成功" detailText:@"读卡成功,进行网络解析。" cancelButtonTitle:nil otherButtonTitles:@[@"确定"]];
            [self.alertview setEnterMode:HHAlertEnterModeLeft];
            [self.alertview setLeaveMode:HHAlertLeaveModeBottom];
            [self.alertview showWithBlock:^(NSInteger index) {
                NSLog(@"%ld",index);
            }];
        }else{
            self.alertview = [[HHAlertView alloc] initWithTitle:@"失败" detailText:@"读卡失败！" cancelButtonTitle:nil otherButtonTitles:@[@"确定"]];
            self.alertview.mode = HHAlertViewModeError;
            [self.alertview show];
            return;
        }
        [_sharedBTManager stopConnectPerpheral];
    });
    
    
    
    [XFSocketManager sharedManager].dataType = GasCardDataType_READ;
    [XFSocketManager sharedManager].host = RELEASE_BLUETOOCH_HOST_IP;
    [XFSocketManager sharedManager].port = RELEASE_BLUETOOCH_HOST_PORT;
    
    NSLog(@"发送数据到服务器，开始解析");
    dispatch_async(dispatch_get_main_queue(), ^{
        self.progress = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        NSDictionary* userInfo = @{METERS_OF_GAS_FOR_SENDING_KEY:(self.chongzhilab.text?self.chongzhilab.text:@"")};
        [[XFSocketManager sharedManager] connectWithData:data userInfo:userInfo completed:^(NSData *responseData,CardDataType type) {
            NSLog(@"服务器返回的数据：%@",[ConverUtil convertDataToHexStr:responseData]);
            if (responseData) {
                BleCardInfo* infoIwish = [BleCardParser parseGasCardDataWithReponseData:responseData dataType:type];
                NSLog(@"%@",infoIwish);
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.cardname.text = infoIwish.username;
                    self.cardnumber.text = infoIwish.userID;
                    self.chaxuntime.text = [NSDate date].description;
                    self.cardAddr.text = infoIwish.userAddr;
                    self.Sendchongzhiaction.enabled = YES;
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                });
            }
            
            [[XFSocketManager sharedManager] stopConnect];
        }];
    });
}

- (void)socket:(XFSocketManager *)manager handleEvent:(SocketConnectType)event{
    if (event == SocketConnectType_Failed | event == SocketConnectType_Timeout) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        });
    }

}


- (void)bluetoochManager:(BluetoochManager *)manager didEndWriteWithResponseData:(NSData *)data fromDevice:(PeripheralDevice *)device result:(BOOL)isSuccess{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        if (isSuccess) {
            self.alertview = [[HHAlertView alloc] initWithTitle:@"成功" detailText:@"写卡成功！" cancelButtonTitle:nil otherButtonTitles:@[@"确定"]];
            [self.alertview setEnterMode:HHAlertEnterModeLeft];
            [self.alertview setLeaveMode:HHAlertLeaveModeBottom];
            [self.alertview showWithBlock:^(NSInteger index) {
                NSLog(@"%ld",index);
            }];
        }else{
            self.alertview = [[HHAlertView alloc] initWithTitle:@"失败" detailText:@"写卡失败，请重试..." cancelButtonTitle:nil otherButtonTitles:@[@"确定"]];
            self.alertview.mode = HHAlertViewModeError;
            [self.alertview show];
        }
    });
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
