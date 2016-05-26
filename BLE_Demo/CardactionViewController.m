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
#import "BleCardModel.h"


@interface CardactionViewController ()<BluetoochDelegate,XFSocketDelegate>
{
    BluetoochManager*   _sharedBTManager;
    XFSocketManager*    _sharedSocketManager;
}

@property (strong) UIActivityIndicatorView* aiView;

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
    
    self.aiView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    UIBarButtonItem* aiItem = [[UIBarButtonItem alloc] initWithCustomView:_aiView];
    self.navigationItem.rightBarButtonItem = aiItem;
    
    self.Sendchaxunaction.enabled = YES;
    self.Sendchongzhiaction.enabled = NO;
}

- (void)setupData{
    self.chongzhilab.pattern=@"^((0|[1-9]{1}\\d{0,5}))(?:\\.)\\d{2}$";
    
    NSDate *  senddate=[NSDate date];
    NSDateFormatter  *dateformatter=[[NSDateFormatter alloc] init];
    [dateformatter setDateFormat:@"YYYY-MM-dd  HH:mm:ss"];
    NSString *  locationString=[dateformatter stringFromDate:senddate];
    NSLog(@"locationString:%@",locationString);
}



/////查询
-(IBAction)Bluechaxun:(id)sender{
    
    self.device.operationType = GasCardOperation_READ;
    [_sharedBTManager readDataFromPeriphralDevice:self.device];
}

/////充值
-(IBAction)Bluechongzhi:(id)sender{
    
    self.device.operationType = GasCardOperation_WRITE;
    [_sharedBTManager writeData:@"" toPeriphralDevice:self.device];
}


//接收到蓝牙卡版本数据
- (void)didReceiveDisposedData:(NSData *)data fromDevice:(PeripheralDevice *)device{
    
//    [_sharedBTManager stopConectPeriphralDevice:device];
    
    NSLog(@"发送数据到服务器，开始解析");
    [XFSocketManager sharedManager].dataType = GasCardDataType_READ;
    [XFSocketManager sharedManager].host = RELEASE_BLUETOOCH_HOST_IP;
    [XFSocketManager sharedManager].port = RELEASE_BLUETOOCH_HOST_PORT;
    
    
//    NSBlockOperation* parseOp = [NSBlockOperation blockOperationWithBlock:^{
//        [[XFSocketManager sharedManager] connectWithData:data userInfo:nil completed:^(NSData *responseData,CardDataType type) {
//            
//            
//            
//            self.Sendchongzhiaction.enabled = YES;
//            //        NSLog(@"服务器返回的数据：%@",responseData);
//            
//            if (responseData) {
//                
//                BleCardInfo* infoIwish = [BleCardModel parseGasCardDataWithReponseData:responseData dataType:GasCardDataType_READ];
//                
//                NSLog(@"%@",infoIwish);
//                
//                self.cardname.text = infoIwish.username;
//                self.cardnumber.text = infoIwish.userID;
//                self.chaxuntime.text = [NSDate date].description;
//                
//            }
//            
//            
//        }];
//    }];
//    [[NSOperationQueue mainQueue] addOperation:parseOp];
    
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
