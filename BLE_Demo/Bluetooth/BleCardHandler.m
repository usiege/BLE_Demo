//
//  BleCardHandler.m
//  BLE_Demo
//
//  Created by 先锋电子技术 on 16/5/19.
//  Copyright © 2016年 先锋电子技术. All rights reserved.
//

#import "BleCardHandler.h"

#import "PeripheralDevice.h"
#import "ConverUtil.h"
#import "Bluetooth40Layer.h"

@interface BleCardHandler ()
{
    NSTimer *check15Timer;          //////1015 超时计时
    NSTimer *checkrecive;           //////等待接受 超时
    NSTimer *checkpackge;           //////接受数据包［20字节］超时
    NSTimer *checkfollow;           //////等待正确小数据包接入超时
    
    bool check15page;               //////收到1015标志
//    int  maxnow;                    //////总包数
    int  lastcountfill;             ////// 上一个包序号
    int  outtimecount;              //////超时记述
    BOOL lostpackge;                ////// 丢包标志
    
    
//    NSData* recivedata;
}

@property (assign,nonatomic) int      requesetcount;//////执行第几个指令
@property (assign,nonatomic) int      actionsort;   //////执行指令类型

@property (copy,nonatomic  )  NSString * requsetnow;
@property (assign,nonatomic)  BOOL     isendsend;
@property (assign,nonatomic)  int      serial;   //发送的第n个包
@property (assign,nonatomic)  NSUInteger pagecount;


@property (nonatomic,strong)   NSMutableArray*  dataArr;
@property (strong,nonatomic)   NSMutableArray*  dataRevArray;
@property(nonatomic,copy)      NSString*        datastring;
@property(nonatomic,strong)    NSData*          receiveData;

@end


@implementation BleCardHandler

- (instancetype)initWithPeripheralDevice:(PeripheralDevice *)device{
    if (self = [super init]) {
        _device = device;
        _dataArr = [NSMutableArray array];
        _dataRevArray = [NSMutableArray array];
    }
    return self;
}

- (void)actionreadandwrite{
    
    [self cardRequestWithCommand:@"01010000FF"];
}


- (void)cardRequestWithCommand:(NSString *)command{
    
    _requsetnow = command;
    NSUInteger length=0;
    Byte temp[350]={0};
    Byte temp1[350]={0};
    
    if(_isendsend){
        check15page=NO;
        _serial=0;
        _pagecount=0;
        _isendsend = NO;
        [_dataArr removeAllObjects];
    }
    
    NSUInteger oneortow=0;
    oneortow=[command length];
    
    if((command == nil)||(oneortow%2!=0)) return;
    printf("卡片请求命令：%s",[command UTF8String]);
    
    
    NSData *valueData = [ConverUtil stringToByte:command];
    NSLog(@"有效数据段:%@ Length:%lu",valueData,(unsigned long)valueData.length);
    [valueData getBytes:temp1 length:valueData.length];
    
    length=[valueData length];
    
    temp[0]=0x08;
    temp[3]=length/256;
    temp[4]=length%256;
    temp[1]=(length+2)/256;
    temp[2]=(length+2)%256;
    
    for(int i=0;i<length;i++){
        temp[i+5]=temp1[i];
    }
    
    [self sendData:temp Length:length+5];
}

////发送数据
-(void)sendData:(Byte*)byte Length:(NSUInteger)length{
    
    if((length%19)==0){
        _pagecount=(length/19);
    }else{
        _pagecount=(length/19)+1;
    }
    
    int follow=0;
    int lastcount=0;
    NSData * tmp;
    
    printf("pagenum:%ld\n",_pagecount);
    printf("serial:%d\n",_serial);
    
    for(int n=0;n<_pagecount;n++){
        
        Byte twinty[20]={0};
        
        twinty[0] = (_pagecount<<4)+n;
        if(n+1==_pagecount){
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
            
        }else{
            for(int i=1; i<=19;i++){
                twinty[i] = byte[follow];
                follow++;
            }
            tmp = [NSData dataWithBytes:twinty length:20];
            
        }
        NSLog(@"小包数据:%@ Length:%lu",tmp,tmp.length);
        [_dataArr addObject:tmp];
    }
    
    printf("进入发送第 %d 包 \n",_serial+1);
    [self sendsmalldata:_dataArr dserial:_serial];
}


///数据发送
-(void)sendsmalldata:(NSMutableArray*)data dserial:(int)dserial{
    NSLog(@"获取数组 %d",dserial);
    NSData *mydata = [data objectAtIndex:dserial];
    NSLog(@"send:%@ Length:%lu",mydata,mydata.length);
    
    if([self.delegate respondsToSelector:@selector(bleCardHandler:sendData:)]){
        [self.delegate bleCardHandler:self sendData:mydata];
    }
}

-(void)sendfollow:(int)type
{
    if(type==0){
        [self sendsmalldata:_dataArr dserial:_serial];
    }else{
        _serial++;
        if(_serial<_pagecount){
            NSLog(@"sendfollow 进入发送第 %d包\n",_serial+1);
            [self sendsmalldata:_dataArr dserial:_serial];
        }
        else{
            printf("结束发送\n");
            _isendsend = YES;
        }
    }
}



//////数据接收处理
-(void)dataProcessing:(NSData*)data{
    
//    _receiveData=data;
    int maxnow = 0; //总包数
    
    if (data.length>=2 && ([[ConverUtil data2HexString:data] hasPrefix:@"1015"])) {
        NSLog(@"接收到1015报文\n");
        check15page = YES;
        // 关闭1015定时器
        if(check15Timer != nil){
            [check15Timer invalidate];
            check15Timer = nil;
        }
        
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
    
    NSLog(@"datawidth =%@",[[ConverUtil data2HexString:data] substringWithRange:NSMakeRange(1, 3)]);
    
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
        
        //datastring buf
        NSString* datastring = _datastring;
        NSString* databuff = @"0";
        
        if(current == maxnow-1){
            [_dataRevArray addObject:data];
            for (int i=0; i<[_dataRevArray count]; i++) {
                if (i == 0) {
                    datastring =[[ConverUtil data2HexString:[_dataRevArray objectAtIndex:i]] substringFromIndex:12];
                }else{
                    datastring = [datastring stringByAppendingString:[[ConverUtil data2HexString:[_dataRevArray objectAtIndex:i]] substringFromIndex:2]];
                }
            }
            
            NSLog(@"接收到的有效数据:%@\n",datastring);
            NSLog(@"_dataArr is %@",_dataArr);
        
            if([self.delegate respondsToSelector:@selector(bleCardHandler:didReceiveData:)]){
                NSData* dataWanted= [datastring dataUsingEncoding:NSUTF8StringEncoding];
                _receiveData = dataWanted;
                [self.delegate bleCardHandler:self didReceiveData:dataWanted];
            }
        
            [_dataRevArray removeAllObjects];
            
            //卡指令类型判断
            if (_actionsort == 12) {
                NSLog(@"这里是燃气卡的指令判断，当前指令：actionsort = %d",_actionsort);
                [self cardRequestWithCommand:_requsetnow];
            }else{
                
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

-(void)ErrorRecovery:(int)ErrorSerial{
    Byte temp[20]={0};
    temp[0] = 0x10;
    temp[1] = 0x13;
    temp[2] = 0x00;
    temp[3] = 0x01;
    temp[4] = (Byte)ErrorSerial;
    NSData *mydata = [[NSData alloc] initWithBytes:temp length:20];
    NSLog(@"纠错包：%@\n",[ConverUtil data2HexString:mydata]);
    
    //发送纠错包
    [[Bluetooth40Layer sharedInstance] sendData:mydata toDevice:_device];
}


//////等待接受超时处理/////
-(void)CheckreciveSelector:(id)sender{
    NSLog(@"等待接受数据超时\n");
    //    requsetnow = nil;
}

/////等待接受packge超时///////
-(void)CheckpackgeSelector:(id)sender{
    NSLog(@"等待第%d个包超时\n",lastcountfill+2);
    [self ErrorRecovery:lastcountfill+1];
}



///////进制转换
-(NSString*)hex2tenstring:(NSString*)hexdata{
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


-(NSString*)int2tenstring:(NSString*)hexdata{
    NSString *tensting;
    NSString *geweiString;
    NSString *xiaoshuString;
    
    geweiString = [hexdata substringToIndex:10];
    xiaoshuString = [hexdata substringFromIndex:10];
    
    char datachar[350];
    long int dataint;
    strcpy(datachar, (char*)[geweiString UTF8String]);
    dataint = strtol(datachar, NULL, 10);
    
    tensting = [NSString stringWithFormat:@"%ld",dataint];
    
    tensting = [tensting stringByAppendingString:@"."];
    tensting = [tensting stringByAppendingString:xiaoshuString];
    
    return tensting;
}

@end
