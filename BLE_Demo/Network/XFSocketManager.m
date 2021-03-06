//
//  XFSocketManager.m
//  BLEDataGateway
//
//  Created by 先锋电子技术 on 16/5/16.
//  Copyright © 2016年 BDE. All rights reserved.
//

#import "XFSocketManager.h"

#import "NetRefer.h"
#import "AsyncSocket.h"
#import "ConverUtil.h"

#import "Bluetooth40Layer.h"
#import "PeripheralDevice.h"

typedef void(^ScoketCallback)(NSData* data,CardDataType dataType);

#define SINGNAL_READDATA_PRE    @"LYGASGS150100010001" //发送读卡数据
#define SINGNAL_WRITEDATA_PRE   @"LYGASGS210100010001" //发送写卡数据
//LYGAS00002016

#define SOCKET_OVERTIME_SECOND      3.0

extern NSString* DEVICE_PARSED_DATA_KEY;
extern NSString* DEVICE_CARD_READED_DATA_KEY;

@interface XFSocketManager () <NSStreamDelegate>
{
    NSInputStream*      _inputStream;
    NSOutputStream*     _outputStream;
    
    /**
     *  @brief 需要发送的用户信息
     */
    NSDictionary*       _userInfo;
}

@property (nonatomic,copy)   ScoketCallback   sCallback;
@property (nonatomic,strong) NSData*         receiveData; //外部接收到的数据

@property (nonatomic,strong) NSTimer*        cancelTimer;

@end

@implementation XFSocketManager

+ (XFSocketManager *)sharedManager
{
    static XFSocketManager *manager;
    if (!manager)
    {
        manager = [[XFSocketManager alloc] init];
    }
    return manager;
}

- (id)init{
    if (self = [super init]){
        self.receiveData = [[NSData alloc] init];
        _userInfo = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)dealloc{
    _inputStream = nil;
    _outputStream = nil;
}

- (void)connectWithData:(NSData *)data userInfo:(NSDictionary *)userInfo completed:(void (^)(NSData *, CardDataType))callback{
    
    NSData* bleData = [Bluetooth40Layer currentDisposedDevice].readedData;
    if(data == bleData)
        self.receiveData = data;
    
    self.sCallback = callback;
    
    _userInfo = userInfo;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self.cancelTimer = [NSTimer scheduledTimerWithTimeInterval:SOCKET_OVERTIME_SECOND target:self selector:@selector(connectCancelAction:) userInfo:nil repeats:NO];
        [self connectToHostUseStreamWithIP:self.host port:self.port.intValue data:data];
    });
    
}

- (void)connectCancelAction:(id)sender{
    NSLog(@"Socket 连接已超时！");
    
    //取消超时
    [_cancelTimer invalidate];
    _cancelTimer = nil;
    
    //停止连接
    [self stopConnect];
    
    //回调
    if([self.delegate respondsToSelector:@selector(socket:handleEvent:)])
        [self.delegate socket:self handleEvent:SocketConnectType_Timeout];
}

- (void)connectToHostUseStreamWithIP:(NSString *)host port:(int)port data:(NSData *)data{
    // 1.建立连接
    // 定义C语言输入输出流
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)host, port, &readStream, &writeStream);
    
    // 把C语言的输入输出流转化成OC对象
    _inputStream = (__bridge NSInputStream *)(readStream);
    _outputStream = (__bridge NSOutputStream *)(writeStream);
    
    // 设置代理
    _inputStream.delegate = self;
    _outputStream.delegate = self;
    
    // 把输入输入流添加到运行循环
    [_inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    // 打开输入输出流
    [_inputStream open];
    [_outputStream open];
    
    //发送数据
    [[NSRunLoop currentRunLoop] run];
}

- (void)stopConnect{
    
    // 从运行循环移除
    [_inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    // 关闭输入输出流
    [_inputStream close];
    [_outputStream close];
    
    _inputStream = nil;
    _outputStream = nil;
    
    //超时取消
    [self.cancelTimer invalidate];
    self.cancelTimer = nil;
    
    _sCallback = nil;
    
    NSLog(@"Socket 连接已断开！");
}

- (void)sendDataToSocket{
    
    if(_dataType == GasCardDataType_READ){
        
        NSMutableString* strIwant = [[NSMutableString alloc] init];
        [strIwant appendString:SINGNAL_READDATA_PRE];
        [strIwant appendString:[[NSString alloc] initWithData:self.receiveData encoding:NSUTF8StringEncoding]];
        NSData* dataIwant = [strIwant dataUsingEncoding:NSUTF8StringEncoding];
        [_outputStream write:dataIwant.bytes maxLength:dataIwant.length];
        
    }else if (_dataType == GasCardDataType_WRITE){
        
        NSMutableString* strIwant = [[NSMutableString alloc] init];
        [strIwant appendString:SINGNAL_WRITEDATA_PRE];
        
        NSString* amountStr = @"0000";
        if([_userInfo.allKeys containsObject:METERS_OF_GAS_FOR_SENDING_KEY]){
            amountStr = [_userInfo valueForKey:METERS_OF_GAS_FOR_SENDING_KEY];
            if (amountStr) {
                //右对齐，共四位，左补0，十六进制
                amountStr = [NSString stringWithFormat:@"%04x",amountStr.intValue];
            }
            if(amountStr.length > 4) return;
        }
        
        [strIwant appendString:amountStr];//这里需要添加4位，用于显示购气量
        [strIwant appendString:[[NSString alloc] initWithData:self.receiveData encoding:NSUTF8StringEncoding]];
        NSData* dataIwant = [strIwant dataUsingEncoding:NSUTF8StringEncoding];
        [_outputStream write:dataIwant.bytes maxLength:dataIwant.length];
        
    }else{
        NSLog(@"未知的网络发送数据类型！");
    }
    
}


- (void)readDataFromSocket{
    //建立一个缓冲区 可以放1024个字节
    uint8_t buf[1024];
    // 返回实际装的字节数
    NSInteger len = [_inputStream read:buf maxLength:sizeof(buf)];
    
     // 把字节数组转化成字符串
    NSData *data = [NSData dataWithBytes:buf length:len];
    NSLog(@"data from server is:%lu",data.length);
    
    PeripheralDevice* deviceIwant = [Bluetooth40Layer currentDisposedDevice];
    [deviceIwant setValue:data forKey:DEVICE_PARSED_DATA_KEY];
    
    if(self.sCallback){
        self.sCallback(data,self.dataType);
    }
    
    [_outputStream close];
    [_inputStream close];
}

#pragma mark -Stream callback

-(void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode{
    NSLog(@"%@",[NSThread currentThread]);
    //    NSStreamEventOpenCompleted = 1UL << 0,//输入输出流打开完成
    //    NSStreamEventHasBytesAvailable = 1UL << 1,//有字节可读
    //    NSStreamEventHasSpaceAvailable = 1UL << 2,//可以发放字节
    //    NSStreamEventErrorOccurred = 1UL << 3,// 连接出现错误
    //    NSStreamEventEndEncountered = 1UL << 4// 连接结束
    
    switch (eventCode) {
        case NSStreamEventOpenCompleted:
                NSLog(@"输入输出流打开完成");
                break;
        case NSStreamEventHasBytesAvailable:
                NSLog(@"有字节可读");
                [self readDataFromSocket];
                break;
        case NSStreamEventHasSpaceAvailable:
                NSLog(@"可以发送字节");
            [self sendDataToSocket];
                break;
        case NSStreamEventErrorOccurred:
                NSLog(@"socket连接出现错误");
            [self stopConnect];
            if([self.delegate respondsToSelector:@selector(socket:handleEvent:)])
                [self.delegate socket:self handleEvent:SocketConnectType_Failed];
                break;
        case NSStreamEventEndEncountered:
                NSLog(@"socket连接结束");
     
        // 从运行循环移除
        [_inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [_outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            
            
        // 关闭输入输出流
        [_inputStream close];
        [_outputStream close];
                break;
        default:
                break;
     }
}


#if 0
#pragma mark -AsyncSocket callback

//接收到新的连接请求
- (void)onSocket:(AsyncSocket *)sock didAcceptNewSocket:(AsyncSocket *)newSocket{
    //保存新用户socket
    NSLog(@"新用户加入:%@",[newSocket connectedHost]);
    //尝试读取数据
//    [newSocket readDataWithTimeout:-1 tag:kNewReadTag];
//    for (int i=0; i<clientArray.count; i++)
//    {
//        NSLog(@"   %@",[clientArray[i] connectedHost]);
//    }
}
//主机已连接
- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    NSLog(@"主机:%@已连接",[sock connectedHost]);
//    [sock readDataWithTimeout:-1 tag:kReadAgainTag];
}
//数据读取成功
- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"接收到的数据是:%@ tag:%ld",message,tag);
    
    NSString *receive = @"数据已经接收";
    NSData *receiveData = [receive dataUsingEncoding:NSUTF8StringEncoding];
    
    //向用户返回数据
//    [sock writeData:receiveData withTimeout:-1 tag:kReceiveTag];
    //再次读取数据
//    [sock readDataWithTimeout:-1 tag:kReadContinueTag];
}
//每次回复时的 tag 值是相同的
//向指定主机回复数据
- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    NSLog(@"向主机:%@回复数据成功! tag:%ld",[sock connectedHost],tag);
}

//网络错误
- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err
{
    NSLog(@"主机%@申请断开连接!",[sock connectedHost]);
//    [clientArray removeObject:sock];
}

//客户机已经撤掉连接
- (void)onSocketDidDisconnect:(AsyncSocket *)sock
{
    NSLog(@"断开连接成功");
//    [clientArray removeObject:sock];
}

#endif

@end
