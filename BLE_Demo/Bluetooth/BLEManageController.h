//
//  BLEManageController.h
//  BLEDataGateway
//
//  Created by 王 维 on 8/27/14.
//  Copyright (c) 2014 BDE. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    _channelType_Input,
    _channelType_Output,
}ChannelType;

typedef NS_ENUM(int,MESSAGE_TYPE)
{
    MESSAGE_READ = 0,
    MESSAGE_WRITE = 1,
    MESSAGE_UI = 2,
    MESSAGE_WRITEDATA = 3,
    MESSAGE_ERROR = 4,
    MESSAGE_SOCKET = 5
};

@class DeviceInforModel;

@interface BLEManageController : NSObject
{
    NSTimer *check15Timer;          //////1015 超时计时
    NSTimer *checkrecive;           //////等待接受 超时
    NSTimer *checkpackge;           //////接受数据包［20字节］超时
    NSTimer *checkfollow;           //////等待正确小数据包接入超时

    int outtimecount;                      //////超时记述
    int lastcountfill;                  ////// 上一个包序号
    int maxnow;                     //////总包数
    
    bool check15page;               //////收到1015标志
    BOOL lostpackge;                ////// 丢包标志
    int  writecount;                ////执行次数
    NSString * chongzhibuff;
    NSString * req;
    NSString * requesetgetcount;
    
    NSData *recivedata;
    
    NSString *busshangchu;
    unsigned char sequenceBuf[2];  ///截取13-14 8
    unsigned char sesKey[16];      ////kong4  16
    unsigned char macKey[16];    ///kong3      16
    unsigned char resultBuf[8];  ///kong1  8
    unsigned char cardChallenge[6];  ///截取15-20  6
    unsigned char MAC[8];   ///kong2  8
    
    NSString *busxiazai0;
    NSString *busxiazai1;
    NSString *busxiazai2;
    NSString *busxiazai3;
    NSString *busxiazai4;
    NSString *busxiazai5;
    NSString *busxiazai6;
    NSString *busxiazai7;
    NSString *busxiazai8;
    NSString *busxiazai9;
    NSString *busxiazai10;
    NSString *busxiazai11;
    NSString *busxiazai12;
    NSString *busxiazai13;
    NSString *busxiazai14;
    NSString *busxiazai15;
    NSString *busxiazai16;
    NSString *busxiazai17;
    NSString *busxiazai18;
    NSString *busxiazai19;
    NSString *busxiazai20;
    NSString *busxiazai21;
    NSString *busxiazai22;
    NSString *busxiazai23;
    NSString *busxiazai24;
    NSString *busxiazai25;
    NSString *busxiazai26;
    NSString *busxiazai27;
    NSString *busxiazai28;
    NSString *busxiazai29;
    NSString *busxiazai30;
    NSString *busxiazai31;

    NSString *testmail1;
    NSString *testmail2;
    NSString *testmail3;
    NSString *testmail4;
    NSString *testmail5;
    NSString *testmail6;
    NSString *testmailshanchu7;
    
    NSString *bankrequset1;
    NSString *bankrequset2;
    NSString *bankrequset3;
    NSString *bankrequsethuoqu;
    NSString *bankcharg1;
    NSString *bankcharg2;
    NSString *bankcharg3;
    
    NSString *rqread;

}


//@property(assign,nonatomic) unsigned char *sequenceBuf;
//@property(assign,nonatomic) unsigned char *cardChallenge;
//@property(assign,nonatomic) unsigned char *sesKey;      ////kong4  16
//@property(assign,nonatomic) unsigned char *macKey;    ///kong3      16
//@property(assign,nonatomic) unsigned char *resultBuf;  ///kong1  8
////    unsigned char *cardChallenge[6];  ///截取15-20  6
//@property(assign,nonatomic) unsigned char *MAC;   ///kong2  8
//@property(assign,nonatomic) unsigned char *hostChallenge;

@property(assign,nonatomic)   int requesetcount;              //////执行第几个指令
@property(assign,nonatomic)   int actionsort;                 //////执行指令类型

@property(strong,nonatomic)   NSMutableArray *dataRevArray;;
@property(strong,nonatomic)   NSMutableArray *dataArr;
@property(assign,nonatomic)   int serial;
@property(assign,nonatomic)   int pagecount;
@property(assign,nonatomic)   int cardyuer;

@property(assign,nonatomic)     BOOL isendsend;
@property(nonatomic,retain)     NSString *datastring;
@property(nonatomic,retain)     NSString *databuff;
@property(nonatomic,retain)     NSString *requsetnow;
@property(nonatomic,retain)     NSString *requset1;
@property(nonatomic,retain)     NSString *requset2;
@property(nonatomic,retain)     NSString *requset3;
@property(nonatomic,retain)     NSString *requset4;
@property(nonatomic,retain)     NSString *requset5;


@property(nonatomic,retain)     NSString *requsetcreat;         ///注册创建
@property(nonatomic,retain)     NSString *requsetcharg;         ///充值
@property(nonatomic,retain)     NSString *requsetconsume;       ///消费
@property(nonatomic,retain)     NSString *requsetcancel;        ///注销
@property(nonatomic,retain)     NSString *requsetquery;          ///查询
@property(nonatomic,retain)     NSString *requsetgetall;         ///获取所有应用
@property(nonatomic,retain)     NSString *requsetgetname;         ///获取所有应用

@property(assign,nonatomic)     int cardchoiseabc;


@property(nonatomic,retain)     NSString *requsetdatesend;         ///获取所有应用

@property(nonatomic,retain)     NSString *requsetxiazaixuanzhe;
@property(nonatomic,retain)     NSString *requsetxiazaisuijishu;
@property(nonatomic,retain)     NSString *requsetxiazaihuoqu;
@property(nonatomic,retain)     NSString *requsetxiazaimiyao;
@property(nonatomic,retain)     NSString *requsetxiazaihuoqu2;

@property(assign,nonatomic)     BOOL requsetgetallis;
@property(assign,nonatomic)     BOOL isgongjiaoxiazai;



@property (assign,nonatomic)   ChannelType channelType;

@property (strong,nonatomic)   NSMutableArray *foundDevicesArray;

@property (assign,nonatomic)    int countOfFoundDevices;

@property (assign,nonatomic)    int countOfLogs;

@property (strong,nonatomic)    DeviceInforModel    *inputDevice;

@property (strong,nonatomic)    DeviceInforModel    *outputDevice;

@property (assign,nonatomic)    int j;

@property (strong,nonatomic)     NSString*        Battery_voltage;

@property (strong,nonatomic)     NSString*        Driving_Speed;

@property (strong,nonatomic)     NSString*        Engine_Speed;

@property (strong,nonatomic)     NSString*        Driving_Course;

@property (strong,nonatomic)     NSString*        Fuel_Consumption;

@property (strong,nonatomic)     NSString*        Total_Fuel_Consumption;

@property (strong,nonatomic)     NSString*        Remaining_Oil;


+ (instancetype)sharedInstance;

- (void)startScanWithChannelType:(ChannelType)_type;

- (void)stopScan;

- (void)createDataChannelWithDevice:(DeviceInforModel *)device withType:(ChannelType)_cType;

-(void)sendData:(NSData *)data toDevice:(DeviceInforModel *)device;
-(void)sendcardrequest:(NSString*)value;
-(void)sendsysterequest:(NSString*)value;
-(void)sendfollow:(int)type;
-(void)actionfollow;
-(void)actionfollow1;
-(void)actioncheck:(NSString*)cardnumber;
-(void)actionchongzhi:(NSString*)chongzi withnumber:(NSString*)cardnumber;
-(void)actiongetall;
-(void)actioncreat;

-(void)actiontaizhouchaxun;
-(void)actiontaizhouchongzhi;

-(void)actionMytaizhouchongzhi:(NSString*)Mychongzhi;

-(void)actiongongjiaoxiazai;
-(void)actiongongjiaoxiezai;

-(void)actiontestxiazai;
-(void)actionbankchaxun;
-(void)actionmybankchongzhi:(NSString*)Mychongzhi;

////////////4442
-(void)actionreadandwrite;


@end
