//
//  BLEManageController.m
//  BLEDataGateway
//
//  Created by 王 维 on 8/27/14.
//  Copyright (c) 2014 BDE. All rights reserved.
//

#import "BLEManageController.h"

#import "Bluetooth40Layer.h"
#import "DeviceInforModel.h"
#import "common.h"
#import "ConverUtil.h"
#import "Alg3DES.h"


static NSInteger CARD_4442 = 8;
static NSString* CARD_READ_4442 = @"010100";
static NSString* CARD_WRITE_4442 = @"010200";
static NSString* CARD_CHECKPASS_4442 = @"01030000";
static NSString* CARD_CHANGEPASS_4442 = @"01050000";

@interface BLEManageController () <Bluetooth40LayerDelegate>

@end


@implementation BLEManageController {
    Bluetooth40Layer *_btLayer;
    char wholeBytes[350];
    BOOL outputIs;
    BOOL inputIs;
    
}

@synthesize j;

@synthesize Battery_voltage;

@synthesize Driving_Speed;

@synthesize Engine_Speed;

@synthesize Driving_Course;

@synthesize Fuel_Consumption;

@synthesize Total_Fuel_Consumption;

@synthesize Remaining_Oil;

@synthesize serial;
@synthesize pagecount;
@synthesize isendsend;

@synthesize databuff;
@synthesize datastring;

@synthesize requset1;
@synthesize requset2;
@synthesize requset3;
@synthesize requset4;
@synthesize requset5;
@synthesize requsetnow;
@synthesize requesetcount;
@synthesize actionsort;

@synthesize requsetcreat;
@synthesize requsetcancel;
@synthesize requsetcharg;
@synthesize requsetconsume;
@synthesize requsetgetall;
@synthesize requsetquery;
@synthesize requsetgetname;

@synthesize requsetdatesend;

@synthesize requsetxiazaixuanzhe;
@synthesize requsetxiazaisuijishu;
@synthesize requsetxiazaihuoqu;
@synthesize requsetxiazaimiyao;

@synthesize cardchoiseabc;

@synthesize requsetxiazaihuoqu2;

@synthesize requsetgetallis;
@synthesize isgongjiaoxiazai;

static BLEManageController *_instance = nil;

+ (instancetype)sharedInstance{
    
    static dispatch_once_t once_token;
    
    dispatch_once(&once_token, ^{
        if (_instance == nil) {
            _instance = [[BLEManageController alloc] init];
        }
    });

    return _instance;
    
}

//初始化
- (id)init{
    self = [super init];
    if (self) {
        
        _btLayer = [Bluetooth40Layer sharedInstance];
        _btLayer.delegate = self;
        self.countOfFoundDevices = 0;
        
        self.foundDevicesArray = [[NSMutableArray alloc] init];
        self.dataArr = [[NSMutableArray alloc] init];
        self.dataRevArray = [[NSMutableArray alloc] init];
           
        // 获取配置文件
        NSString *path = [[NSBundle mainBundle] pathForResource:@"BusInitInfo" ofType:@"plist"];
        NSDictionary *data = [[NSDictionary alloc] initWithContentsOfFile:path];
        NSAssert(nil!=data, @"Read plist file failed!");
           
           
        [self initInstance];
        [self initRequestWithDic:data[@"request"]];
        busshangchu = data[@"busshangchu"];
        [self initBusxiazaiWithDic:data[@"busxiazai"]];
        [self initTestmailWithDic:data[@"testmail"]];
        [self initBankWithDic:data[@"bank"]];
        rqread = data[@"rqread"];
           
           
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotificationOut:) name:@"outputIsConnect" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotificationIn:) name:@"inputIsConnect" object:nil];
        
        [_instance addObserver:self forKeyPath:@"countOfFoundDevices" options:NSKeyValueObservingOptionNew context:nil];
        [_instance addObserver:self forKeyPath:@"inputDevice" options:NSKeyValueObservingOptionNew context:nil];
        [_instance addObserver:self forKeyPath:@"outputDevice" options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (void)initInstance{
    j = 0;
    
    checkfollow = nil;
    checkpackge = nil;
    checkrecive = nil;
    check15Timer = nil;
    outtimecount = 0;
    lostpackge = NO;
    maxnow = 0;
    lastcountfill = 0;
    check15page = NO;
    pagecount = 0;
    serial = 0;
    isendsend =YES;
    
    requsetgetallis= NO;
    
    requesetcount=1;
    requsetnow=nil;
    databuff =@"0";
    actionsort = 0;
    cardchoiseabc = 0;
    
    isgongjiaoxiazai = false;
    writecount = 0;
}
- (void)initBankWithDic:(NSDictionary *)dic{
    bankrequset1 = dic[@"bankrequset1"];
    bankrequset2 = dic[@"bankrequset2"];
    bankrequset3 = dic[@"bankrequset3"];
    bankrequsethuoqu = dic[@"bankrequsethuoqu"];
    bankcharg1 = dic[@"bankcharg1"];
    bankcharg2 = dic[@"bankcharg2"];
    bankcharg3 = dic[@"bankcharg3"];
}
- (void)initTestmailWithDic:(NSDictionary *)dic{
    testmail1 = dic[@"item1"];
    testmail2 = dic[@"item2"];
    testmail3 = dic[@"item3"];
    testmail4 = dic[@"item4"];
    
    testmail5 = dic[@"item5"];
    testmail6 = dic[@"item6"];
    testmailshanchu7 = dic[@"shanchu7"];
}
- (void)initRequestWithDic:(NSDictionary *)dic{
    requset1=dic[@"item1"];
    requset2=dic[@"item2"];
    requset3=dic[@"item3"];
    requset4=dic[@"item4"];
    requset5=dic[@"item5"];
    
    requsetcreat = dic[@"creat"];
    requsetquery = dic[@"query"];;//@"8021000005"; 查询
    requsetcharg = dic[@"charg"];//@"8022000007";充值
    
    requsetdatesend = dic[@"datasend"]; ///日期
    
    requsetconsume = dic[@"consume"];
    requsetcancel = dic[@"cancel"];
    requsetgetall = dic[@"getall"];
    
    requesetgetcount = dic[@"getcount"];
    requsetgetname = dic[@"getname"];
    
    
    requsetxiazaixuanzhe=dic[@"xiazaixuanzhe"];
    requsetxiazaisuijishu=dic[@"xiazaisuijishu"];
    requsetxiazaihuoqu=dic[@"xiazaihuoqu"];
    requsetxiazaimiyao=dic[@"xiazaimiyao"];
    requsetxiazaihuoqu2=dic[@"xiazaihuoqu2"];
}
- (void)initBusxiazaiWithDic:(NSDictionary *)dic{
    busxiazai0 = dic[@"item0"];
    busxiazai1 = dic[@"item1"];
    busxiazai2 = dic[@"item2"];
    busxiazai3 = dic[@"item3"];
    busxiazai4 = dic[@"item4"];
    busxiazai5 = dic[@"item5"];
    busxiazai6 = dic[@"item6"];
    busxiazai7 = dic[@"item7"];
    busxiazai8 = dic[@"item8"];
    busxiazai9 = dic[@"item9"];
    busxiazai10 = dic[@"item10"];
    busxiazai11 = dic[@"item11"];
    busxiazai12 = dic[@"item12"];
    busxiazai13 = dic[@"item13"];
    busxiazai14 = dic[@"item14"];
    busxiazai15 = dic[@"item15"];
    busxiazai16 = dic[@"item16"];
    busxiazai17 = dic[@"item17"];
    busxiazai18 = dic[@"item18"];
    busxiazai19 = dic[@"item19"];
    busxiazai20 = dic[@"item20"];
    busxiazai21 = dic[@"item21"];
    busxiazai22 = dic[@"item22"];
    busxiazai23 = dic[@"item23"];
    busxiazai24 = dic[@"item24"];
    busxiazai25 = dic[@"item25"];
    busxiazai26 = dic[@"item26"];
    busxiazai27 = dic[@"item27"];
    busxiazai28 = dic[@"item28"];
    busxiazai29 = dic[@"item29"];
    busxiazai30 = dic[@"item30"];
    busxiazai31 = dic[@"item31"];

}

-(void)receiveNotificationOut:(NSNotification*)notify{
    NSNumber *number = notify.object;
    BOOL boolValue = [number boolValue];
    if (boolValue ) {
        outputIs = boolValue;
    }
    else{
        outputIs = boolValue;
    }

}
-(void)receiveNotificationIn:(NSNotification*)notify{
    NSNumber *number = notify.object;
    BOOL boolValue = [number boolValue];
    if (boolValue ) {
        inputIs = boolValue;
    }
    else{
        inputIs = boolValue;
    }
    
}
//扫描蓝牙
- (void)startScanWithChannelType:(ChannelType)_type{
    self.channelType = _type;
//    self.countOfFoundDevices = 0;
    [self.foundDevicesArray removeAllObjects];
    [_btLayer startScan:20.0 withServices:nil];
}
//停止扫描
- (void)stopScan{
    [_btLayer stopScan];
}
//连接蓝牙
- (void)createDataChannelWithDevice:(DeviceInforModel *)device withType:(ChannelType)_cType{
    self.channelType = _cType;
    if (self.channelType == _channelType_Input) {
        if (self.inputDevice != nil) {
           
        }
    }else{
        if (self.outputDevice != nil) {
           
        }
    }
    
    [_btLayer createDataChannelWithDevice:device];
    
 
}

- (void)sendData:(NSData *)data toDevice:(DeviceInforModel *)device{
    
    if (data != nil) {
        
        [_btLayer sendData:data toDevice:device];
  
       }
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:@"switchStatus" object:nil];
    
}


#pragma  mark - BluetoothLayer Delegate

- (void)didBluetoothStateChange:(BT40LayerStatusTypeDef)btStatus{
    if (LOG) printf("didBluetoothStateChange to : %ld\n",btStatus);
}

- (void)didFoundDevice:(DeviceInforModel *)device{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (LOG) printf("didFoundDevice : %s\n",[device.name.description UTF8String]);//[device.name.description UTF8String]);
         if (self.channelType == _channelType_Output)
           {
            // if ([device.peripheral.name rangeOfString:@"SIVISION"].location != NSNotFound)
                {
                    
                  [self.foundDevicesArray addObject:device];
                
                }
           }
        
         else
           {
           //if ([device.peripheral.name rangeOfString:@"SIVISION"].location != NSNotFound)
               {
               
               }
          // else
               {
                   
               [self.foundDevicesArray addObject:device];
                   
               }
           }
         self.countOfFoundDevices  =  self.foundDevicesArray.count;
       
    });
    
}

- (void)didCreateDataChannelWithDevice:(DeviceInforModel *)device withResult:(BT40LayerResultTypeDef)result{
    
    if (LOG) printf("create data channel result : %@\n",result);
    if (self.channelType == _channelType_Input)
       {
        self.inputDevice = device;
        NSLog(@"add inputDevice ");
       }
    else
       {
        self.outputDevice = device;
        NSLog(@"add outputDevice ");
       }
  
    dispatch_async(dispatch_get_main_queue(), ^{
        if (LOG) printf("didCreateDataChannelWithDevice : %s\n",[device.name.description UTF8String]);
        
    });
    
}

- (void)didDisconnectWithDevice:(DeviceInforModel *)device{
    if (LOG) printf("didDisconnect With Device : %s\n",[device.name.description UTF8String]);
    if(outputIs ){
      self.outputDevice = nil;
    }else{
    [self createDataChannelWithDevice:self.outputDevice withType:_channelType_Output];
    }
     if(inputIs)
    {
     self.inputDevice = nil;
     
    }else{
      [self createDataChannelWithDevice:self.inputDevice withType:_channelType_Input];
    }
    
}



- (void)didReceivedData:(NSData *)data fromChannelWithDevice:(DeviceInforModel *)device{
   [self dataProcessing:data];
   
}


//////数据接收处理
-(void)dataProcessing:(NSData*)data{
    
        recivedata=data;
    
//     if (data.length>=2 && (([[ConverUtil data2HexString:data] hasPrefix:@"1015"]) ||( [[ConverUtil data2HexString:data] hasPrefix:@"12"]))) {
        if (data.length>=2 && ([[ConverUtil data2HexString:data] hasPrefix:@"1015"])) {
        NSLog(@"接收到1015报文\n");
         check15page = YES;
         // 关闭1015定时器
         if(check15Timer != nil){
             [check15Timer invalidate];
             check15Timer = nil;
         }
         maxnow = 0 ;
         lastcountfill = 0;
         
         outtimecount=0;
         [_dataRevArray removeAllObjects];
         
         // 开启接受数据等待定时器
            if(checkrecive!=nil){
                [checkrecive invalidate];
                checkrecive = nil;
            }
         dispatch_async(dispatch_get_main_queue(), ^{
             checkrecive = [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(CheckreciveSelector:) userInfo:nil repeats:NO];
         });
        return;
        }else if (( [[ConverUtil data2HexString:data] hasPrefix:(@"1011")])||( [[ConverUtil data2HexString:data] hasPrefix:(@"1012")])||( [[ConverUtil data2HexString:data] hasPrefix:(@"1014")])|| [[[ConverUtil data2HexString:data] substringWithRange:NSMakeRange(1, 3)] isEqual:@"012"]){
            
            
            NSLog(@"接收到正确结尾报文\n");
            
            check15page = YES;
            // 关闭1015定时器
            if(check15Timer != nil){
                [check15Timer invalidate];
                check15Timer = nil;
            }
            maxnow = 0 ;
            lastcountfill = 0;
            
            outtimecount=0;
            [_dataRevArray removeAllObjects];
            
            // 开启接受数据等待定时器
            if(checkrecive!=nil){
                [checkrecive invalidate];
                checkrecive = nil;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                checkrecive = [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(CheckreciveSelector:) userInfo:nil repeats:NO];
            });
        }
    
    NSLog(@"datawith =%@",[[ConverUtil data2HexString:data] substringWithRange:NSMakeRange(1, 3)]);
    
    if(check15page){
        /////收到recive关闭定时
        if(checkrecive != nil){
            [checkrecive invalidate];
            checkrecive = nil;
            outtimecount = 0;
        }
        
        //////收到数据包关闭等待packge;
        if(checkpackge !=nil)
        {
            [checkpackge invalidate];
            checkpackge = nil;
            outtimecount = 0;
        }
        
        Byte tempValue[20] = {0};
        [data getBytes:tempValue length:data.length];
        
        int max = tempValue[0]>>4;
        int current = tempValue[0]&0x0F;
        /////丢包状态，等待正确包接入
        if(lostpackge && current!=(lastcountfill+1)){
            return;
        }else{
            
            ///////正确包接入，取消时钟
            if(checkfollow!=nil){
                [checkfollow invalidate];
                checkfollow = nil;
            }
            lostpackge = NO;
        }
        
        /////判断第一个包是否丢失
        if([_dataRevArray count] == 0 && current!=0){
            NSLog(@"第一个数据包丢失\n");
            [self ErrorRecovery:0];
//            lostpackge = YES;
            return;

        }
        //////记录第一个数据，
        if ([_dataRevArray count] == 0 && current==0){
            maxnow = max;
            lastcountfill = current;
            
        }else{
            ////////重复包丢弃
            if(current<=lastcountfill){
                NSLog(@"重复包丢弃\n");
                return;
            }
            
            //////判断中间是否有丢包
            if((current-lastcountfill)>1){
                NSLog(@"第%d个包丢失\n",lastcountfill+2);
                [self ErrorRecovery:lastcountfill+1];
                lostpackge = YES;
                return;
            }
            
            ////判断最后一个包是否丢失
            if([_dataRevArray count]!=0 && maxnow!=max){
                NSLog(@"最后一个包丢失\n");
                return;
            }
            lastcountfill = current;
        }
        
        if(current == maxnow-1){
            [_dataRevArray addObject:data];
            for (int i=0; i<[_dataRevArray count]; i++) {
                if (i == 0) {
                    datastring =[[ConverUtil data2HexString:[_dataRevArray objectAtIndex:i]] substringFromIndex:12];
                }else{
                    datastring = [datastring stringByAppendingString:[[ConverUtil data2HexString:[_dataRevArray objectAtIndex:i]] substringFromIndex:2]];
                }
            }
            
            
            
//            for (NSData *data in dataRevArray)
            {
               
                
//                datastring =[[ConverUtil data2HexString:data] substringFromIndex:12];
//                
//                if(actionsort == 1){
//                    datastring = [datastring substringToIndex:4];
//                }else if (actionsort == 2){
//                    datastring = [datastring substringToIndex:4];
//                }else if (actionsort == 3){
//                
//                }else if (actionsort == 4){
//                
//                }
//                
                
                
//                printf(@"%lu",strtoul(databuff, NULL, 16));
//                NSData *mydata = [ConverUtil stringToByte:databuff];
//                Byte *mybyte = (Byte*)[mydata bytes];
                
                
                
                NSLog(@"接收到的有效数据:%@\n",datastring);
                
            }
            
            
            [_dataRevArray removeAllObjects];
            
            if (actionsort == 1) {
                if (requesetcount>3) {
                    datastring = [datastring substringToIndex:4];
                    databuff = [self hex2tenstring:datastring];
                   
                }
                [self actionfollow1];
            }else if(actionsort == 2){
                NSLog(@"requesetcount=%d",requesetcount);
                if (requesetcount>4) {
                    datastring = [datastring substringToIndex:4];
                   
                    databuff = [self hex2tenstring:datastring];
                   
                }
                [self actionfollow];
            }else if(actionsort == 3){
                if(requesetcount>3&&![datastring isEqual:@"6A83"]){
                    databuff = [datastring substringFromIndex:24];
                    databuff = [databuff substringToIndex:10];
                }
                
                [self actiongetall];
            }else if (actionsort == 4){
                [self actioncreat];
            }else if(actionsort == 5){
                if(requesetcount>2&&![datastring isEqual:@"6A86"]){
                    datastring = [datastring substringToIndex:8];
                    
                    databuff = [self hex2tenstring:datastring];
                    NSLog(@"查询databuff:%@\n",databuff);
                    
                }
                [self actiontaizhouchaxun];
            }else if(actionsort ==6){
                
                if(requesetcount>4&&![datastring isEqual:@"6A86"]){
                    datastring = [datastring substringToIndex:8];
                    
                    databuff = [self hex2tenstring:datastring];
                }
                [self actiontaizhouchongzhi];
            }else if (actionsort ==7){
                NSLog(@"requesetcount=%d",requesetcount);
                if(requesetcount==4){
                    databuff = [datastring substringToIndex:56];
                     NSLog(@"databuff:%@\n",databuff);
                    [self xiazaimiyao:databuff];
                }
                [self actiongongjiaoxiazai];
            }else if(actionsort==8){
                NSLog(@"requesetcount=%d",requesetcount);
                if(requesetcount==4){
                    databuff = [datastring substringToIndex:56];
                    NSLog(@"databuff:%@\n",databuff);
                    [self xiazaimiyao:databuff];
                }
                [self actiongongjiaoxiezai];
            }else if (actionsort == 9){
                NSLog(@"requesetcount=%d",requesetcount);
                if(requesetcount==4){
                    databuff = [datastring substringToIndex:56];
                    NSLog(@"databuff:%@\n",databuff);
                    [self xiazaimiyao:databuff];
                }
                [self actiontestxiazai];
            }else if(actionsort == 10){
                if(requesetcount>2&&![datastring isEqual:@"6A83"]){
                    datastring = [[datastring substringFromIndex:6] substringToIndex:12];
                    NSLog(@"查询datastring:%@\n",datastring);
                    databuff = [self int2tenstring:datastring];
                    NSLog(@"查询databuff:%@\n",databuff);
                    
                }
                [self actionbankchaxun];
            }else if (actionsort == 11){
                [self actionbankchongzhi];
            }else if(actionsort == 12){
                [self actionreadandwrite];
            }

            check15page = NO;
            if(checkrecive != nil){
                [checkrecive invalidate];
                checkrecive=nil;
            }
            if(check15Timer != nil){
                [check15Timer invalidate];
                check15Timer=nil;
            }
            
            return;
        }
        
        [_dataRevArray addObject:data];
        ///////开启小包等待超时200ms
        dispatch_async(dispatch_get_main_queue(), ^{
            checkrecive = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(CheckpackgeSelector:) userInfo:nil repeats:NO];
        });
    }

}

///////下载应用 数据密钥截取
-(void)xiazaimiyao:(NSString*)Mydatabuff
{
    unsigned char hostChallenge[8]={0x11,0x22,0x33,0x44,0x55,0x66,0x77,0x88};

    NSString *sequenceBufstr = [Mydatabuff substringWithRange:NSMakeRange(24, 4)];
    NSLog(@"sequenceBufstr==%@",sequenceBufstr);
 
    NSString *cardChallengestr = [Mydatabuff substringWithRange:NSMakeRange(28, 12)];
    NSLog(@"cardChallengestr==%@",cardChallengestr);
    Byte temp[2],temp1[6];
    NSData *mydata = [ConverUtil stringToByte:sequenceBufstr];
    [mydata getBytes:temp length:mydata.length];

    for (int i=0; i<mydata.length; i++) {
        sequenceBuf[i]= (unsigned char)temp[i];
        printf("%x\n",sequenceBuf[i]);
    }
    
    printf("///////////////////\n");
    
    mydata = [ConverUtil stringToByte:cardChallengestr];
    [mydata getBytes:temp1 length:mydata.length];
    for(int i=0; i<mydata.length;i++){
        cardChallenge[i] = (unsigned char)temp1[i];
        printf("%x\n",cardChallenge[i]);
    }
    
    printf("111111111111111111111\n");
    generateSessionKey(sequenceBuf,sesKey,macKey);
    
    for (int i=0; i<2; i++) {
        printf("%x\n",sequenceBuf[i]);
    }
    
    generateHostCryptogram(resultBuf, sequenceBuf, cardChallenge, hostChallenge, sesKey);
    generateMac(resultBuf, MAC, macKey);
    
    NSString *resultstr;
    NSString *macstr;
    
    Byte retemp[8],retemp1[8];

    for (int i=0; i<8; i++) {
        retemp[i]=(Byte)resultBuf[i];
    }
    NSData *mydatare = [[NSData alloc] initWithBytes:retemp length:8];
    resultstr = [ConverUtil data2HexString:mydatare];
    NSLog(@"resultstr=%@",resultstr);
    
    for (int i=0; i<8; i++) {
        retemp1[i] = (Byte)MAC[i];
    }
    
    NSData *mydatamac = [[NSData alloc] initWithBytes:retemp1 length:8];
    macstr = [ConverUtil data2HexString:mydatamac];
    NSLog(@"macstr=%@",macstr);
    

    
    requsetxiazaimiyao = [requsetxiazaimiyao stringByAppendingString:resultstr];
    requsetxiazaimiyao = [requsetxiazaimiyao stringByAppendingString:macstr];
    
    NSLog(@"requsetxiazaimiyao = %@",requsetxiazaimiyao);
    
}



///////进制转换
-(NSString*)hex2tenstring:(NSString*)hexdata
{
    NSString *tensting;
    
    char datachar[350];
    long int dataint;
    strcpy(datachar, (char*)[hexdata UTF8String]);
    dataint = strtol(datachar, NULL, 16);
    
    NSLog(@"dataint = %ld",dataint);
    double datafloat = (double)dataint/100;
    NSLog(@"datafloat = %.2f",datafloat);
    
    tensting = [NSString stringWithFormat:@"%.2f",datafloat];
    
    return tensting;
}


-(NSString*)int2tenstring:(NSString*)hexdata
{
    NSString *tensting;
    NSString *geweiString;
    NSString *xiaoshuString;
    
    geweiString = [hexdata substringToIndex:10];
    xiaoshuString = [hexdata substringFromIndex:10];
    
    char datachar[350];
    long int dataint;
    strcpy(datachar, (char*)[geweiString UTF8String]);
    dataint = strtol(datachar, NULL, 10);
    
//    NSLog(@"dataint = %ld",dataint);
//    double datafloat = (double)dataint/100;
//    NSLog(@"datafloat = %.2f",datafloat);
    tensting = [NSString stringWithFormat:@"%ld",dataint];
    
    tensting = [tensting stringByAppendingString:@"."];
    tensting = [tensting stringByAppendingString:xiaoshuString];
    
    NSLog(@"%@",tensting);
    
    return tensting;
}



-(void)actionchongzhi:(NSString*) chongzhi withnumber:(NSString*)cardnumber
{
//    chongzhi = [[NSString alloc] initWithFormat:@"%x",[chongzhi intValue]];
//    
//    NSLog(@"%lu",(unsigned long)chongzhi.length);
//    if(chongzhi.length<4){
//        for (int i=0; i<=(4-chongzhi.length+1); i++) {
//            chongzhi = [@"0" stringByAppendingString:chongzhi];
//        }
//        NSLog(@"chongzhi == %@",chongzhi);
//        
//    }
//    
//    requsetcharg =[requsetcharg stringByAppendingString:cardnumber];
//    requsetcharg =[requsetcharg stringByAppendingString:chongzhi];
//    
//    
//    requsetquery =[requsetquery stringByAppendingString:cardnumber];
//    
//    [self actionfollow];
}



-(void)actioncheck:(NSString*)cardnumber
{
    requsetquery = [requsetquery stringByAppendingString:cardnumber];
    [self actionfollow1];
}


-(void)actioncreat{
    
    switch (requesetcount) {
        case 1:
            [self sendcardrequest:requset1];
            break;
        case 2:
            [self sendcardrequest:requsetcreat];
        default:
            break;
    }
    requesetcount= requesetcount+1;
}




/////////小程序下载
-(void)actiontestxiazai
{
    switch (requesetcount) {
        case 1:
            [self sendcardrequest:requsetxiazaixuanzhe];  /////////00A4040007A0000001510000
            break;
        case 2:
            [self sendcardrequest:requsetxiazaisuijishu];   /////////80500000081122334455667788
            break;
        case 3:
            [self sendcardrequest:requsetxiazaihuoqu];  /////////00C000001C
            break;
        case 4:
            [self sendcardrequest:requsetxiazaimiyao];  ///////8482000010+密钥
            requsetxiazaimiyao = [requsetxiazaimiyao substringToIndex:10];
            break;
        case 5:
            [self sendcardrequest:testmail1];
            break;
        case 6:
            [self sendcardrequest:testmail2];
            break;
        case 7:
            [self sendcardrequest:testmail3];
            break;
        case 8:
            [self sendcardrequest:testmail4];
            break;
        case 9:
            [self sendcardrequest:testmail5];
            break;
        case 10:
            [self sendcardrequest:testmail6];
            break;
        default:
            break;
    }
    requesetcount= requesetcount+1;
}



/////////公交卸载
-(void)actiongongjiaoxiezai
{
    switch (requesetcount) {
        case 1:
            [self sendcardrequest:requsetxiazaixuanzhe];  /////////00A4040007A0000001510000
            break;
        case 2:
            [self sendcardrequest:requsetxiazaisuijishu];   /////////80500000081122334455667788
            break;
        case 3:
            [self sendcardrequest:requsetxiazaihuoqu];  /////////00C000001C
            break;
        case 4:
            [self sendcardrequest:requsetxiazaimiyao];  ///////8482000010+密钥
            requsetxiazaimiyao = [requsetxiazaimiyao substringToIndex:10];
            break;
        case 5:
            [self sendcardrequest:testmailshanchu7];      ///////BUS=80E40080094F0747415343617264 80E40080074F0512345678
            break;
            
        default:
            break;
    }
        requesetcount= requesetcount+1;
}




//////公交下载
-(void)actiongongjiaoxiazai
{
    switch (requesetcount) {

        case 1:
            [self sendcardrequest:requsetxiazaixuanzhe];
            break;
        case 2:
            [self sendcardrequest:requsetxiazaisuijishu];
            break;
        case 3:
            [self sendcardrequest:requsetxiazaihuoqu];
            break;
        case 4:
            [self sendcardrequest:requsetxiazaimiyao];
            requsetxiazaimiyao = [requsetxiazaimiyao substringToIndex:10]; 
            break;
        case 5:
            [self sendcardrequest:busxiazai0];  ////////80E6020013074741534361726407A0000001510000000000
            break;
        case 6:
            [self sendcardrequest:busxiazai1];
            break;
        case 7:
            [self sendcardrequest:busxiazai2];
            break;
        case 8:
            [self sendcardrequest:busxiazai3];
            break;
        case 9:
            [self sendcardrequest:busxiazai4];
            break;
        case 10:
            [self sendcardrequest:busxiazai5];
            break;
        case 11:
            [self sendcardrequest:busxiazai6];
            break;
        case 12:
            [self sendcardrequest:busxiazai7];
            break;
        case 13:
            [self sendcardrequest:busxiazai8];
            break;
        case 14:
            [self sendcardrequest:busxiazai9];
            break;
        case 15:
            [self sendcardrequest:busxiazai10];
            break;
        case 16:
            [self sendcardrequest:busxiazai11];
            break;
        case 17:
            [self sendcardrequest:busxiazai12];
            break;
        case 18:
            [self sendcardrequest:busxiazai13];
            break;
        case 19:
            [self sendcardrequest:busxiazai14];
            break;
        case 20:
            [self sendcardrequest:busxiazai15];
            break;
        case 21:
            [self sendcardrequest:busxiazai16];
            break;
        case 22:
            [self sendcardrequest:busxiazai17];
            break;
        case 23:
            [self sendcardrequest:busxiazai18];
            break;
        case 24:
            [self sendcardrequest:busxiazai19];
            break;
        case 25:
            [self sendcardrequest:busxiazai20];
            break;
        case 26:
            [self sendcardrequest:busxiazai21];
            break;
        case 27:
            [self sendcardrequest:busxiazai22];
            break;
        case 28:
            [self sendcardrequest:busxiazai23];
            break;
        case 29:
            [self sendcardrequest:busxiazai24];
            break;
        case 30:
            [self sendcardrequest:busxiazai25];
            break;
        case 31:
            [self sendcardrequest:busxiazai26];
            break;
        case 32:
            [self sendcardrequest:busxiazai27];
            break;
        case 33:
            [self sendcardrequest:busxiazai28];
            break;
        case 34:
            [self sendcardrequest:busxiazai29];
            break;
        case 35:
            [self sendcardrequest:busxiazai30];
            break;
        case 36:
            [self sendcardrequest:busxiazai31];
            break;
        default:
            break;
    }
    if (requesetcount >4) {
        [self sendcardrequest:requsetxiazaihuoqu2];
    }
    
    requesetcount = requesetcount+1;
    
}




/////taizhoucchaxun
-(void)actiontaizhouchaxun
{
    
    switch (requesetcount) {
        case 1:
            if (cardchoiseabc == 1) {
                requset1 = @"00A40400064741532E424A";
            }else if(cardchoiseabc == 2){
                requset1 = @"00A40400075041592E535A54";
            }
            [self sendcardrequest:requset1];
            break;
        case 2:
            [self sendcardrequest:requsetquery];
            
        default:
            break;
    }
    
        requesetcount= requesetcount+1;
}

///////////////////////泰州充值调用
-(void)actionMytaizhouchongzhi:(NSString*)Mychongzhi
{
//    requsetcharg = @"805000020B01 00000010 000000000000";//@"8022000007";充值
    
//    requsetdatesend = @"805200000B 20151021213511 00000000"; ///日期
    
    int intchongzhi = [Mychongzhi floatValue]*100;
    
    Mychongzhi = [[NSString alloc] initWithFormat:@"%x",intchongzhi];
    
    NSLog(@"输入值=%@ ,%lu",Mychongzhi,(unsigned long)[Mychongzhi length]);
    
    int czlength = (int)[Mychongzhi length];
    
    if(Mychongzhi.length<8){
        
        for (int i=0; i<8-czlength; i++) {
            Mychongzhi = [@"0" stringByAppendingString:Mychongzhi];
        }
        NSLog(@"chongzhi == %@",Mychongzhi);
    }
    requsetcharg = [requsetcharg stringByAppendingString:Mychongzhi];
    requsetcharg = [requsetcharg stringByAppendingString:@"000000000000"];
    
    NSDate *  senddate=[NSDate date];
    NSDateFormatter  *dateformatter=[[NSDateFormatter alloc] init];
    [dateformatter setDateFormat:@"YYYYMMddHHmmss"];
    NSString *  locationString=[dateformatter stringFromDate:senddate];
    
    
    requsetdatesend=[requsetdatesend stringByAppendingString:locationString];
    requsetdatesend=[requsetdatesend stringByAppendingString:@"00000000"];
    
    NSLog(@"chongzhiaaa=%@",requsetcharg);
    NSLog(@"Dateaaa=%@",requsetdatesend);
    
    
    [self actiontaizhouchongzhi];
    
}


//////taizhouchongzhi
-(void)actiontaizhouchongzhi
{
    switch (requesetcount) {
        case 1:
            if (cardchoiseabc == 1) {
                requset1 = @"00A40400064741532E424A";
            }else if(cardchoiseabc == 2){
                requset1 = @"00A40400075041592E535A54";
            }
            [self sendcardrequest:requset1];
            break;
        case 2:
            [self sendcardrequest:requsetcharg];
            requsetcharg = [requsetcharg substringToIndex:12];
            break;
        case 3:
            [self sendcardrequest:requsetdatesend];
            requsetdatesend = [requsetdatesend substringToIndex:10];
            break;
        case 4:
            [self sendcardrequest:requsetquery];
            break;
        default:
            break;
    }
    
            requesetcount= requesetcount+1;
}





///////顺序执行命令
-(void)actionfollow
{
    
//    switch (requesetcount) {
//        case 1:
//            [self sendcardrequest:requset1];
//            break;
//        case 2:
//            [self sendcardrequest:requsetcharg];
//            NSLog(@"requsetcharg == %@",requsetcharg);
//            requsetcharg = [requsetcharg substringToIndex:10];
//            break;
//        case 3:
//            [self sendcardrequest:requsetquery];
//            NSLog(@"requsetquery == %@",requsetquery);
//            requsetquery = [requsetquery substringToIndex:10];
//            break;
//    
//        case 4:
//            [self sendcardrequest:requesetgetcount];
//            break;
////        case 5:
////            [self sendcardrequest:requset5];
//////            requesetcount = 0;
////            break;
//            
//        default:
//
//            break;
//    }
//    
//    if ([[ConverUtil data2HexString:recivedata] containsString:@"6A80"])  {
//        
//    }else if([[ConverUtil data2HexString:recivedata] containsString:@"6A83"]){
////        UIAlertView *aler = [[UIAlertView alloc] ]
//    }
//    
//    requesetcount=requesetcount+1;

}
///////////////////银行卡查询充值
-(void)actionmybankchongzhi:(NSString*)Mychongzhi
{
    int intchongzhi = [Mychongzhi floatValue]*100;
    Mychongzhi = [[NSString alloc] initWithFormat:@"%d",intchongzhi];
    
    NSLog(@"输入值=%@ ,%lu",Mychongzhi,(unsigned long)[Mychongzhi length]);
    
    int czlength = (int)[Mychongzhi length];
    
    if(Mychongzhi.length<12){
        
        for (int i=0; i<12-czlength; i++) {
            Mychongzhi = [@"0" stringByAppendingString:Mychongzhi];
        }
        NSLog(@"chongzhi == %@",Mychongzhi);
    }
    bankrequset3 = [bankcharg1 stringByAppendingString:Mychongzhi];
    bankrequset3 = [bankrequset3 stringByAppendingString:bankcharg2];
    
    NSDate *  senddate=[NSDate date];
    NSDateFormatter  *dateformatter=[[NSDateFormatter alloc] init];
    [dateformatter setDateFormat:@"YYYYMMddHHmmss"];
    NSString *  locationString=[dateformatter stringFromDate:senddate];
    locationString = [locationString substringFromIndex:2];
    NSLog(@"locationString=%@",locationString);
    
    bankrequset3=[bankrequset3 stringByAppendingString:locationString];
    bankrequset3=[bankrequset3 stringByAppendingString:bankcharg3];
    
    NSLog(@"bankrequset3=%@",bankrequset3);
//    NSLog(@"Dateaaa=%@",requsetdatesend);
    [self actionbankchongzhi];
    
}


-(void)actionbankchaxun
{
    switch (requesetcount) {
        case 1:
            [self sendcardrequest:bankrequset1];
            break;
        case 2:
            [self sendcardrequest:bankrequset2];
            break;
//        case 3:
//            [self sendcardrequest:bankrequsethuoqu];
//            break;
        default:
            break;
    }
    requesetcount=requesetcount+1;
}

////////////////////燃起读写

-(void)actionreadandwrite
{
    switch (requesetcount) {
        case 1:
            [self sendcardrequest:rqread];
            break;
            
        default:
            break;
    }
    requesetcount=requesetcount+1;
}


//////////////银行卡充值
-(void)actionbankchongzhi
{
    switch (requesetcount) {
        case 1:
            [self sendcardrequest:bankrequset1];
            break;
        case 2:
            [self sendcardrequest:bankrequset3];
            bankrequset3=@"";

            break;
        case 3:
            [self sendcardrequest:bankrequset2];
            actionsort=10;
             break;
        default:
            break;
    }
    requesetcount=requesetcount+1;
}

////////////////////

///////查询
-(void)actionfollow1
{
    
    switch (requesetcount) {
        case 1:
            [self sendcardrequest:requset1];
            break;
        case 2:
            [self sendcardrequest:requsetquery];
            NSLog(@"requsetquery查询 == %@",requsetquery);
            requsetquery = [requsetquery substringToIndex:10];
            break;
        case 3:
            [self sendcardrequest:requesetgetcount];
            break;
            
        default:
            
            break;
    }
    requesetcount=requesetcount+1;
    
}


 -(void)actiongetall
{
    switch (requesetcount) {
        case 1:
            [self sendcardrequest:requset1];
            break;
        case 2:
            [self sendcardrequest:requsetgetall];
            break;
        case 3:
            [self sendcardrequest:requsetgetname];
            break;
            
        default:
            break;
    }
    if ([[ConverUtil data2HexString:recivedata] containsString:@"6A83"]) {
        requsetgetallis = NO;
    }else{
        requsetgetallis = YES;
    }
    
    requesetcount=requesetcount+1;
}




-(void)touchuantest
{
    NSString *data=@"5555555555555555555555555555555555555555";
    
    
    
    NSData *mydata =[data dataUsingEncoding:NSUTF8StringEncoding];
    
    [self sendData:mydata toDevice:self.outputDevice];
}


//////接收1015超时处理/////
-(void)Check15Selector:(id)sender
{
    if (outtimecount++ < 3) {
        NSLog(@"没有收到15响应报文，重新发送！\n");
//        [self sendcardrequest:requsetnow];
    } else {
        outtimecount = 0;
        NSLog(@"没有收到15响应报文，并超出发送最大次数限制！\n");
        requsetnow = nil;
    }
    
}


//-(void)ResetAttribut
//{
//    check15Timer = nil;          //////1015 超时计时
//    checkrecive = nil;           //////等待接受 超时
//    checkpackge = nil;           //////接受数据包［20字节］超时
//    checkfollow = nil;           //////等待正确小数据包接入超时
//    
//    outtimecount = 0;                      //////超时记述
//    lastcountfill = 0;                  ////// 上一个包序号
//    maxnow = 0;                     //////总包数
//    
//    check15page = NO;               //////收到1015标志
//    lostpackge = NO;                ////// 丢包标志
//    writecount = 0;                ////执行次数
//}
//



//////等待接受超时处理/////
-(void)CheckreciveSelector:(id)sender
{
    NSLog(@"等待接受数据超时\n");

//    requsetnow = nil;
    
}


/////等待接受packge超时///////
-(void)CheckpackgeSelector:(id)sender
{
    NSLog(@"等待第%d个包超时\n",lastcountfill+2);
    [self ErrorRecovery:lastcountfill+1];
}

-(void)ErrorRecovery:(int)ErrorSerial;
{
    Byte temp[20]={0};
    temp[0] = 0x10;
    temp[1] = 0x13;
    temp[2] = 0x00;
    temp[3] = 0x01;
    temp[4] = (Byte)ErrorSerial;
    NSData *mydata = [[NSData alloc] initWithBytes:temp length:20];
    NSLog(@"纠错包：%@\n",[ConverUtil data2HexString:mydata]);
    [self sendData:mydata toDevice:self.outputDevice];
}


-(void)sendAllData:(NSString*)string{
    NSUserDefaults *switchDefaults = [NSUserDefaults standardUserDefaults];
    if ([switchDefaults integerForKey:@"myOBDSwitch0"] && [switchDefaults integerForKey:@"myOBDSwitch1"]&& [switchDefaults integerForKey:@"myOBDSwitch2"]&& [switchDefaults integerForKey:@"myOBDSwitch3"]&& [switchDefaults integerForKey:@"myOBDSwitch4"]&& [switchDefaults integerForKey:@"myOBDSwitch5"]&& [switchDefaults integerForKey:@"myOBDSwitch6"])
       {
        
        }
    else
       {
    NSString*    Battery_voltage1;
    NSString*    Driving_Speed1;
    NSString*    Engine_Speed1;
    NSString*    Driving_Course1;
    NSString*    Fuel_Consumption1;
    NSString*    Total_Fuel_Consumption1;
    NSString*    Remaining_Oil1;
    NSArray*     array = [string componentsSeparatedByString:@","];
    if ([array[0]  isEqual: @"$OBD-RT"])
        {
       Battery_voltage1 = array[1];         //电瓶电压
       Driving_Speed1 = array[3];           //时速
       Engine_Speed1 = array[2];            //发动机转数
       Remaining_Oil1= array[9];                  //剩余油量
       Battery_voltage = [self cutString:Battery_voltage1];
       Driving_Speed  = [self cutString:Driving_Speed1];
       Engine_Speed = [self cutString:Engine_Speed1];
       Remaining_Oil = [self cutString:Remaining_Oil1];
       if ([switchDefaults integerForKey:@"myOBDSwitch0"] ) {
           Battery_voltage = @"null";
             }
       if ([switchDefaults integerForKey:@"myOBDSwitch1"] ) {
          Driving_Speed = @"null";
             }
       if ([switchDefaults integerForKey:@"myOBDSwitch2"] ) {
           Engine_Speed = @"null";
             }
       if ([switchDefaults integerForKey:@"myOBDSwitch3"] ) {
           Remaining_Oil = @"null";
             }
        }
    if ([array[0]  isEqual: @"$OBD-AMT"])
       {
     
        Driving_Course1= array[3];                    //行驶历程
        Fuel_Consumption1= array[4];                 //本次油耗
        Total_Fuel_Consumption1= array[5];           //累计油耗
        Driving_Course = [self cutString:Driving_Course1];
        Fuel_Consumption = [self cutString:Fuel_Consumption1];
        Total_Fuel_Consumption = [self cutString:Total_Fuel_Consumption1];
        if ([switchDefaults integerForKey:@"myOBDSwitch4"] )
           {
           Driving_Course = @"null";
           }
         if ([switchDefaults integerForKey:@"myOBDSwitch5"] )
           {
             Fuel_Consumption = @"null";
           }
        if ([switchDefaults integerForKey:@"myOBDSwitch6"])
           {
            Total_Fuel_Consumption = @"null";
           }
         
         //发送OBD数据
        Byte i = 4;
        NSData *identifierData = [NSData dataWithBytes:&i length: sizeof(i)];
        [self sendData:identifierData toDevice:self.outputDevice];
        NSString *allStr = [[NSString alloc]initWithFormat:@"%@,%@,%@,%@,%@,%@,%@;\r\n",Battery_voltage,Driving_Speed,Engine_Speed,Driving_Course,Fuel_Consumption,Total_Fuel_Consumption,Remaining_Oil];
        NSData *allData = [allStr dataUsingEncoding:NSUTF8StringEncoding];
        NSLog(@"每隔五秒发的数据：%@",allStr);
        [self sendData:allData toDevice:self.outputDevice];
      /*timer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(sendAllData) userInfo:nil repeats:YES];
      [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
      [[NSRunLoop currentRunLoop]run];*/
       }
     }
  }
/*-(void)sendAllData{
    Byte i = 4;
    NSData *identifierData = [NSData dataWithBytes:&i length: sizeof(i)];
    [self sendData:identifierData toDevice:self.outputDevice];
    NSString *allStr = [[NSString alloc]initWithFormat:@"%@,%@,%@,%@,%@,%@,%@;\r\n",Battery_voltage,Driving_Speed,Engine_Speed,Driving_Course,Fuel_Consumption,Total_Fuel_Consumption,Remaining_Oil];
    NSData *allData = [allStr dataUsingEncoding:NSUTF8StringEncoding];
    NSLog(@"每隔五秒发的数据：%@",allStr);
    [self sendData:allData toDevice:self.outputDevice];
    [timer invalidate];
    
}*/
-(NSString*)cutString:(NSString*)str{
    
   NSArray* componentArray = [str componentsSeparatedByString:@"="];
   return componentArray[1];
}

////系统指令
-(void)sendsysterequest:(NSString*)value
{
    int length=0;
    requsetnow = value;
    Byte temp[350]={0};
    Byte temp1[350]={0};
    
    if(isendsend){
        check15page=NO;
        serial=0;
        pagecount=0;
        isendsend = NO;
        [_dataArr removeAllObjects];
    }
    
    int oneortow=0;
    oneortow=[value length];
    printf("value:%lu\n",[value length]);
    
    if((value==nil)||(oneortow%2!=0)){
        return;
    }
    NSLog(@"点击发送2");
    
    
    NSData *valueData = [ConverUtil stringToByte:value];
    NSLog(@"有效数据段:%@ Length:%lu",valueData,(unsigned long)valueData.length);
    [valueData getBytes:temp1 length:valueData.length];
    length=[valueData length];
    printf("length:%d\n",length);
    
    temp[0]=0x01;
    temp[1]=length/256;
    temp[2]=length%256;

    
    for(int i=0;i<length;i++){
        temp[i+3]=temp1[i];
    }
    
    [self SendData:temp Length:length+3];
}


///卡指令
-(void)sendcardrequest:(NSString*)value
{
    int length=0;
    requsetnow = value;
    Byte temp[350]={0};
    Byte temp1[350]={0};
    
    if(isendsend){
        check15page=NO;
        serial=0;
        pagecount=0;
        isendsend = NO;
        [_dataArr removeAllObjects];
    }

    int oneortow=0;
    oneortow=[value length];
    printf("value:%lu\n",[value length]);
    
    if((value==nil)||(oneortow%2!=0)){
        return;
    }
    NSLog(@"点击发送2");
    
    
    NSData *valueData = [ConverUtil stringToByte:value];
    NSLog(@"有效数据段:%@ Length:%lu",valueData,(unsigned long)valueData.length);
    [valueData getBytes:temp1 length:valueData.length];
    length=[valueData length];
    printf("length:%d\n",length);
    
    temp[0]=0x08;
    temp[3]=length/256;
    temp[4]=length%256;
    temp[1]=(length+2)/256;
    temp[2]=(length+2)%256;
    
    for(int i=0;i<length;i++){
        temp[i+5]=temp1[i];
    }
    
    [self SendData:temp Length:length+5];
    
}

////发送数据
-(void)SendData:(Byte*)byte Length:(int)length
{
    if((length%19)==0){
        pagecount=(length/19);
    }else{
        pagecount=(length/19)+1;
    }
    
    int follow=0;
    int lastcount=0;
    NSData * tmp;
    
    
    printf("pagenum:%d\n",pagecount);
    printf("serial:%d\n",serial);
    
    for(int n=0;n<pagecount;n++){
        
        Byte twinty[20]={0};
        
        twinty[0] = (pagecount<<4)+n;
        if(n+1==pagecount){
            if(length%19==0){
                for (int m=1; m<=19; m++) {
                    twinty[m] = byte[follow];
                    follow ++;
                    lastcount++;
                }
            }else{
                
                for(int m=1;m<=(length%19);m++){
                    twinty[m] = byte[follow];
                    follow ++;
                    lastcount++;
                }
            }

            tmp = [NSData dataWithBytes:twinty length:lastcount+1];
            
        }
        else{
            for(int i=1; i<=19;i++){
                twinty[i] = byte[follow];
                follow++;
            }
            tmp = [NSData dataWithBytes:twinty length:20];
            
        }
        NSLog(@"小包数据:%@ Length:%lu",tmp,tmp.length);
        [_dataArr addObject:tmp];
        
    }
    
    [self sendtwinty:_dataArr];
}

/////发送第一个包
-(void)sendtwinty:(NSMutableArray*)data
{
    printf("进入发送第 %d包\n",serial+1);
    [self sendsmalldata:data dserial:serial];
    
}


-(void)sendfollow:(int)type
{
    if(type==0){
        [self sendsmalldata:_dataArr dserial:serial];
    }else{
        serial++;
        if(serial<pagecount){
            NSLog(@"进入发送第 %d包\n",serial+1);
            [self sendsmalldata:_dataArr dserial:serial];
        }
        else{
            printf("结束发送\n");
            isendsend = YES;
//            if (!check15page) {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    check15Timer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(Check15Selector:) userInfo:nil repeats:NO];
//                });
//            }
           
        }
    }
    
}






///数据发送
-(void)sendsmalldata:(NSMutableArray*)data dserial:(int)dserial
{
    NSLog(@"获取数组 %d",dserial);
    NSData *mydata = [data objectAtIndex:dserial];
    
    NSLog(@"send:%@ Length:%lu",mydata,mydata.length);
    [self sendData:mydata toDevice:self.outputDevice];
}


@end

