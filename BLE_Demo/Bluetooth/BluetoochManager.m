
//
//  BluetoochManager.m
//  BLE_Demo
//
//  Created by 先锋电子技术 on 16/5/18.
//  Copyright © 2016年 先锋电子技术. All rights reserved.
//

#import "BluetoochManager.h"
#import "PeripheralDevice.h"
#import "Bluetooth40Layer.h"

#import "BleCardHandler.h"
#import "BleCardParser.h"
#import "ConverUtil.h"

//6-7位是开始，8-9位是长度
#define CARD_READ4442_COMMAND_FOR_FIRSTTIME      @"0101000080"
#define CARD_READ4442_COMMAND_FOR_SECONDTIME     @"0101008080"

#define CARD_CHECKPASS4442_COMMAND               @"0103000003"
#define CARD_WRITE4442_COMMAND_FOR_ONCE          @"01020020e0"//写卡开始位置是20，长度是224
#define CARD_CHANGPASS4442_COMMAND               @"0105000003"

static BluetoochManager* _bluetoochManager = nil;
static const NSUInteger STANTARD_CARDDATA_LENGTH = 512; //卡片最长可读写长度


@interface BluetoochManager ()
<Bluetooth40LayerDelegate
>
{
    Bluetooth40Layer*   _sharedBleLayer;
}

@property (nonatomic,strong)    NSMutableData*      readResultData;     //读卡后的结果
//@property (nonatomic,strong)    NSData*             writeData;          //要写入卡的数据

//@property (nonatomic,copy)      CardWrittenBlock     cardWrttenCallBack;

@end

@implementation BluetoochManager

+ (instancetype)shareInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _bluetoochManager = [[BluetoochManager alloc] init];
    });
    return _bluetoochManager;
}

- (instancetype)init{
    if (self = [super init]) {
        _seekedDevices = [NSMutableArray array];
        _cardHandlers = [NSMutableArray array];
        
        _readResultData = [NSMutableData data];
        
        _sharedBleLayer = [Bluetooth40Layer sharedInstance];
        _sharedBleLayer.delegate = self;
    }
    return self;
}

//搜索
- (void)startSearchPeriphralsUntil:(NSDate *)date{
    NSTimeInterval time = [date timeIntervalSinceDate:[NSDate date]];
    NSLog(@"interval time is :%f",time);
    [_sharedBleLayer startScan:time withServices:nil];
}

- (void)stopSearchPeriphrals{
    [_sharedBleLayer stopScan];
}

- (void)stopConnectPerpheral{
    [_sharedBleLayer stopConnect];
}


//读写
- (void)readDataFromPeriphralDevice:(PeripheralDevice *)pDevice{
    if(!pDevice) return;
    pDevice.operationType = GasCardOperation_READ;
    
    //读卡前状态为0
    BleCardHandler* ch = [self cardHandlerForPeripheralDevice:pDevice];
    ch.currentState = CardOperationState_idle;
    
    //正在存取卡片数据
    if(_sharedBleLayer.state == BT40LayerState_IsAccessing){
        return;
    }
    
    //是否连接卡片
    if(pDevice.stateType == PeripheralState_Connected){
        //开始读卡
        [_sharedBleLayer readDataFromPeriphralDevice:pDevice];
        //
        [_readResultData resetBytesInRange:NSMakeRange(0, _readResultData.length)];
        [_readResultData setLength:0];
        
    }else if(pDevice.stateType == PeripheralState_Disconnected){
        [_sharedBleLayer startConnectWithDevice:pDevice completed:^(BT40LayerStateTypeDef state) {
            if (state == BT40LayerState_Connecting) {
                //开始读卡
                [_sharedBleLayer readDataFromPeriphralDevice:pDevice];
                //
                [_readResultData resetBytesInRange:NSMakeRange(0, _readResultData.length)];
                [_readResultData setLength:0];
                pDevice.stateType = PeripheralState_Connected;
                
            }else if (state == BT40LayerState_ConnectFailed){
                [self stopConnectPeriphralDevice:pDevice];
                [self delegateActionWithData:nil device:pDevice state:0 operationType:GasCardOperation_READ];
                return ;
            }
            else if(state == BT40LayerState_IsAccessing){
                pDevice.stateType = PeripheralState_Connected;
                
            }else if (state == BT40LayerState_Idle){
                pDevice.stateType = PeripheralState_Disconnected;
                printf("外围设备 %s 已断开！\n",[pDevice.peripheral.name UTF8String]);
                return ;
            }
        }];
    }
}

- (void)writeData:(NSData *)data toPeriphralDevice:(PeripheralDevice *)pDevice{
    if(!pDevice) return;
    pDevice.operationType = GasCardOperation_WRITE;
    
    //写卡前状态置空
    BleCardHandler* ch = [self cardHandlerForPeripheralDevice:pDevice];
    ch.currentState = CardOperationState_idle;
    
    //如果此时正在存取数据，直接返回
    if(_sharedBleLayer.state == BT40LayerState_IsAccessing){
        return;
    }
    
    //数据写入设备
    pDevice.parsedData = data;
    
    if(pDevice.stateType == PeripheralState_Connected){
        //开始写卡
        [_sharedBleLayer writeData:data toDevice:pDevice];
    }else if (pDevice.stateType == PeripheralState_Disconnected){
        [_sharedBleLayer startConnectWithDevice:pDevice completed:^(BT40LayerStateTypeDef state) {
            if (state == BT40LayerState_Connecting) {
                //开始写卡
                [_sharedBleLayer writeData:data toDevice:pDevice];
            }else if (state == BT40LayerState_ConnectFailed){
                [self delegateActionWithData:nil device:pDevice state:0 operationType:GasCardOperation_WRITE];
                return ;
            }
            else if(state == BT40LayerState_IsAccessing){
                pDevice.stateType = PeripheralState_Connected;
            }else if (state == BT40LayerState_Idle){
                pDevice.stateType = PeripheralState_Disconnected;
                printf("外围设备 %s 已断开！\n",[pDevice.peripheral.name UTF8String]);
                return ;
            }
        }];
    }
}


- (void)delegateActionWithData:(NSData *)data device:(PeripheralDevice *)device state:(CardOperationState)state operationType:(PeripheralOperationType)type{
    NSLog(@"读写数据回调");
    
    _sharedBleLayer.state = BT40LayerState_Idle;
    device.stateType = PeripheralState_Disconnected;
    
    if(type == GasCardOperation_READ){
        if ([self.delegate respondsToSelector:@selector(bluetoochManager:didEndReadWithResponseData:fromDevice:result:)]) {
            if (state & CardOperationState_ReadCorrect) {
                [self.delegate bluetoochManager:self didEndReadWithResponseData:data fromDevice:device result:YES];
            }else{
                [self.delegate bluetoochManager:self didEndReadWithResponseData:data fromDevice:device result:NO];
            }
        }
    }else if (type == GasCardOperation_WRITE){
        if ([self.delegate respondsToSelector:@selector(bluetoochManager:didEndWriteWithResponseData:fromDevice:result:)]) {
            if (state & CardOperationState_ReadCorrect) {
                [self.delegate bluetoochManager:self didEndWriteWithResponseData:data fromDevice:device result:YES];
            }else{
                [self.delegate bluetoochManager:self didEndWriteWithResponseData:data fromDevice:device result:NO];
            }
        }
    }
}

//连接
- (void)startConnectPeriphralDevice:(PeripheralDevice *)pDevice{
    [_sharedBleLayer startConnectWithDevice:pDevice completed:^(BT40LayerStateTypeDef state) {
        
    }];
}

- (void)stopConnectPeriphralDevice:(PeripheralDevice *)pDevice{
    [_sharedBleLayer disconnectWithDevice:pDevice];
}


#pragma mark
- (PeripheralDevice *)getDeviceByIdentifer:(NSString *)deviceID{
    PeripheralDevice* iWant = nil;
    for (PeripheralDevice* device in _seekedDevices) {
        if (device.identifier == deviceID) {
            iWant = device;
        }
    }
    return iWant;
}

-(PeripheralDevice *)getDeviceByPeripheral:(CBPeripheral *)peripheral{
    PeripheralDevice* iWant = nil;
    for (PeripheralDevice* device in _seekedDevices) {
        if (device.peripheral == peripheral) {
            iWant = device;
        }
    }
    return iWant;
}

- (PeripheralDevice *)deviceInfoWithIdentifer:(NSString *)deviceID{
    PeripheralDevice* iWant = nil;
    
    for (PeripheralDevice* device in _seekedDevices) {
        if ([device.identifier isEqualToString:deviceID]) {
            iWant = device;
        }
    }
    return iWant;
}

- (BOOL)containsDevice:(PeripheralDevice *)device{
    NSString* UUID = device.identifier;
    BOOL thereis = NO;
    for (PeripheralDevice* owned in _seekedDevices) {
        if ([UUID isEqualToString:owned.identifier]) {
            thereis = YES;
        }
    }
    return thereis;
}

- (void)addNewDevice:(PeripheralDevice *)dm{
    if (![_seekedDevices containsObject:dm]) {
        [_seekedDevices addObject:dm];
        if ([self.delegate respondsToSelector:@selector(bluetoochManager:didFoundNewPerigheralDevice:)]) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self.delegate bluetoochManager:self didFoundNewPerigheralDevice:dm];
            });
        }
    }
}

- (void)removeDevice:(PeripheralDevice *)dm{
    if ([_seekedDevices containsObject:dm]) {
        [_seekedDevices removeObject:dm];
    }
}

- (void)remoeAllDevices{
    [_seekedDevices removeAllObjects];
}

#pragma mark -  handler util
- (BleCardHandler *)cardHandlerForPeripheralDevice:(PeripheralDevice *)device{
    BleCardHandler* iWant = nil;
    for (BleCardHandler* cardHandler in _cardHandlers) {
        if(cardHandler.device == device){
            iWant = cardHandler;
        }
    }
    return iWant;
}


#pragma mark -BLELayerDelegate
//与外围设备连接中... （2次）
- (void)bluetoochLayer:(Bluetooth40Layer *)bluetoochLayer isConnectingPeripheralDevice:(PeripheralDevice *)pDevice withState:(BT40LayerStateTypeDef)state{
    
    BleCardHandler* cardHandler = [self cardHandlerForPeripheralDevice:pDevice];
    PeripheralDevice* device = pDevice;
    __weak typeof(self) weakSelf = self;
    
    if(!cardHandler) return;
    
     //燃气卡读写操作
    if(state == BT40LayerState_IsAccessing){
        NSLog(@"与外围设备连接中...");
        if(device.operationType == GasCardOperation_READ){
            
            //进行第一次读请求
            NSString* command = CARD_READ4442_COMMAND_FOR_FIRSTTIME;
            NSLog(@"正在进行第一次读卡请求，命令：%@",command);
            [cardHandler cardRequestWithCommand:command completed:^(NSData *receiveData, CardOperationState state) {
                NSLog(@"第一次读卡结束。");
                [_readResultData appendData:receiveData];
                NSLog(@"%@接收的数据长度：%ld",cardHandler,(unsigned long)_readResultData.length);
                
                //第一次读请求成功后，进行第二次读请求
                if(state == CardOperationState_ReadCorrect
                   && _readResultData.length <= STANTARD_CARDDATA_LENGTH/2 //重要，保证不进行循环请求
                   ){
                    NSString* command = CARD_READ4442_COMMAND_FOR_SECONDTIME;
                    NSLog(@"正在进行第二次读卡请求，命令：%@",command);
                    
                    [cardHandler cardRequestWithCommand:command completed:^(NSData *receiveData, CardOperationState state) {
                        NSLog(@"第二次读卡结束。");
                        [_readResultData appendData:receiveData];
                        NSLog(@"%@接收的数据长度：%ld",cardHandler,(unsigned long)_readResultData.length);
                        NSLog(@"最终的结果数据是：%@",[[NSString alloc] initWithData:_readResultData encoding:NSUTF8StringEncoding]);
                        //设备数据写入
                        device.readedData = _readResultData;
                        [weakSelf delegateActionWithData:_readResultData device:device state:state operationType:GasCardOperation_READ];
                        return ;
                    }];
                }
            }];
        }
        else if(device.operationType == GasCardOperation_WRITE){
            //校验请求
            NSMutableString* commandIwant = [NSMutableString stringWithFormat:CARD_CHECKPASS4442_COMMAND];
            if(!device.checkKey) return;
            [commandIwant appendString:device.checkKey];
            
            NSLog(@"checkKey ------------------->|%@|",[device checkKey]);
            NSLog(@"checkKeyNEW ------------------->|%@|",[device checkKeyNew]);
            
            NSLog(@"正在进行校验，校验命令：%@",commandIwant);
            if(device.checkKey && [device.checkKey isEqualToString:@"147178"])
            [cardHandler cardRequestWithCommand:commandIwant completed:^(NSData *receiveData, CardOperationState state) {
                
                //校验结果如果完成，开始写入卡片数据
                if (cardHandler.currentState & CardOperationState_Checkouted //已校验
                    &&!(cardHandler.currentState & CardOperationState_Written) //未写入
                    && !(cardHandler.currentState & CardOperationState_ChangedPass) //未修改过密码
                    && cardHandler.currentState & CardOperationState_ReadCorrect //读取卡回执成功
                    ) {
                    
                    //请求命令
                    NSMutableString* commandIwant = [[NSMutableString alloc] initWithString:CARD_WRITE4442_COMMAND_FOR_ONCE];
                    NSData* dataIwant = device.parsedData; //要写入的数据，外部接收
                    if(dataIwant.length > 512) return;
                    //截取有效数据
                    dataIwant = [dataIwant subdataWithRange:NSMakeRange(64, 512-64)];
                    //二进制转16进制
                    NSString* stringIwant = [ConverUtil stringFromHexString:[ConverUtil convertDataToHexStr:dataIwant]];
                    //加卡片数据(64-512)位
                    [commandIwant appendString:stringIwant];
                    
                    NSLog(@"校验成功！");
                    NSLog(@"正在写入卡片数据，命令：%@",commandIwant);
                    //清除读卡状态，以方便下一次状态添加
                    cardHandler.currentState = cardHandler.currentState & (~CardOperationState_ReadCorrect);
                    [cardHandler cardRequestWithCommand:commandIwant completed:^(NSData *receiveData, CardOperationState state) {
                        NSLog(@"写卡回调");
                        //清除读取状态
//                        cardHandler.currentState = cardHandler.currentState & (~state);
                        //如果当前为写卡操作，且写入卡数据成功，则进行密码更新
                        if (cardHandler.currentState & CardOperationState_Checkouted //已校验
                            && cardHandler.currentState & CardOperationState_Written //已写入
                            && !(cardHandler.currentState & CardOperationState_ChangedPass) //未修改过密码
                            && cardHandler.currentState & CardOperationState_ReadCorrect //读取卡回执成功
                            ){
                            
                            //密码判断
                            NSString* keyold = device.checkKey;
                            NSString* keyNew = device.checkKeyNew;
                            
                            if(!keyNew || !keyNew) return;
                            
                            if (![keyold isEqualToString:keyNew]) {
                                NSMutableString* commandIwant = [[NSMutableString alloc] initWithString:CARD_CHANGPASS4442_COMMAND];
                                [commandIwant appendString:keyNew];
                                
                                NSLog(@"写卡成功！");
                                NSLog(@"需要更新密码，命令：%@",commandIwant);
                                //清除读卡状态，以方便下一次状态添加
                                cardHandler.currentState = cardHandler.currentState & (~CardOperationState_ReadCorrect);
                                [cardHandler cardRequestWithCommand:commandIwant completed:^(NSData *receiveData, CardOperationState state) {
                                    //清除读卡状态，以方便下一次状态添加
                                    cardHandler.currentState = cardHandler.currentState & (~CardOperationState_ReadCorrect);
                                    [self delegateActionWithData:receiveData device:device state:state operationType:GasCardOperation_WRITE];
                                    return;
                                }];//end 更新
                                //更新请求后将已状态置为： 已写入,已更新，已修改密码
                                cardHandler.currentState = cardHandler.currentState | CardOperationState_ChangedPass;
                                return;
                            }
                            else{
                                NSLog(@"卡片不必更新密码,写卡成功！");
                                //更新请求后将已状态置为： 已写入,已更新，已修改密码
                                cardHandler.currentState = cardHandler.currentState | CardOperationState_ChangedPass;
                                [self delegateActionWithData:nil device:device state:state operationType:GasCardOperation_WRITE];
                                return;
                            }
                        }
                        else{//已经写完卡并收到写卡后的回复错误
                            NSLog(@"写入卡片不成功！");
                            //不成功则状态置为： 已写入,已更新
                            cardHandler.currentState = cardHandler.currentState | CardOperationState_ChangedPass;
                            [self stopConnectPeriphralDevice:device];
                            [self delegateActionWithData:receiveData device:device state:state operationType:GasCardOperation_WRITE];
                            return;
                        }
                        
                    }];// end 写入
                    //写入请求后将已状态置为： 已校验，已写入,未更新
                    cardHandler.currentState = cardHandler.currentState | CardOperationState_Written;//增加已写卡状态；
                }else{
                    NSLog(@"校验失败！");
                    [self delegateActionWithData:receiveData device:device state:state operationType:GasCardOperation_WRITE];
                    return;
                }
                
            }]; // end 校验请求
            //校验请求后将已状态置为： 已校验，未写入,未更新
            cardHandler.currentState = cardHandler.currentState | CardOperationState_Checkouted;//增加已校验状态
        }// end if
    }
    else if(state == BT40LayerState_Idle){
        [self stopConnectPeriphralDevice:device];
        [self delegateActionWithData:nil device:pDevice state:0 operationType:GasCardOperation_READ];
        return;
    }
}

//蓝牙向外围设备写入结果
- (void)bluetoochLayer:(Bluetooth40Layer *)bluetoochLayer didWriteDataPeripheralDevice:(PeripheralDevice *)pDevice error:(NSError *)error{
    
    if (error) {
        NSLog(@"写入设备失败:%@",error);
        [self stopConnectPeriphralDevice:pDevice];
        [self delegateActionWithData:nil device:pDevice state:0 operationType:GasCardOperation_WRITE];
        return;
    }
}

@end