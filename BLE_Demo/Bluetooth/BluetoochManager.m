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
#import "ConverUtil.h"

static BluetoochManager* _bluetoochManager = nil;

//6-7位是开始，8-9位是长度
#define CARD_READ4442_COMMAND_FOR_FIRSTTIME      @"0101000080"
#define CARD_READ4442_COMMAND_FOR_SECONDTIME     @"0101008080"

#define CARD_CHECKPASS4442_COMMAND               @"0103000003"
#define CARD_WRITE4442_COMMAND_FOR_ONCE          @"01020020e0"//写卡开始位置是20，长度是224
#define CARD_CHANGPASS4442_COMMAND               @"0105000003"

static const NSUInteger STANTARD_CARDDATA_LENGTH = 512; //卡片最长可读写长度

extern NSString* DEVICE_PARSED_DATA_KEY;
extern NSString* DEVICE_CARD_READED_DATA_KEY;


@interface BluetoochManager ()
<Bluetooth40LayerDelegate
>
{
    Bluetooth40Layer*   _sharedBleLayer;
    
    BOOL                _beenWritedCard;        //写卡是否已完成
//    CardOperationType   _lastOperation;         //上次执行的操作
}

@property (nonatomic,strong)    NSMutableData*      readResultData;     //读卡后的结果
@property (nonatomic,strong)    NSData*             writeData;          //要写入卡的数据

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
        
        _writeData = nil;
        _beenWritedCard = NO;
        
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
                
            }else if(state == BT40LayerState_IsAccessing){
                pDevice.stateType = PeripheralState_Connected;
            }else if (state == BT40LayerState_Idle){
                pDevice.stateType = PeripheralState_Disconnected;
                printf("外围设备 %s 已断开！\n",[pDevice.peripheral.name UTF8String]);
            }
//            [self delegateActionWithData:nil device:pDevice result:NO operationType:GasCardOperation_READ];
        }];
    }
}

- (void)writeData:(NSData *)data toPeriphralDevice:(PeripheralDevice *)pDevice{
    if(!pDevice) return;
    pDevice.operationType = GasCardOperation_WRITE;
    if(_sharedBleLayer.state == BT40LayerState_IsAccessing){
        return;
    }
    _writeData = data;
    [pDevice setValue:data forKey:DEVICE_PARSED_DATA_KEY];
    
    if(pDevice.stateType == PeripheralState_Connected){
        //开始写卡
        [_sharedBleLayer writeData:_writeData toDevice:pDevice];
    }else if (pDevice.stateType == PeripheralState_Disconnected){
        [_sharedBleLayer startConnectWithDevice:pDevice completed:^(BT40LayerStateTypeDef state) {
            if (state == BT40LayerState_Connecting) {
                //开始写卡
                [_sharedBleLayer writeData:_writeData toDevice:pDevice];
            }else if(state == BT40LayerState_IsAccessing){
                pDevice.stateType = PeripheralState_Connected;
            }else if (state == BT40LayerState_Idle){
                pDevice.stateType = PeripheralState_Disconnected;
                printf("外围设备 %s 已断开！\n",[pDevice.peripheral.name UTF8String]);
            }
        }];
    }
}


- (void)delegateActionWithData:(NSData *)data device:(PeripheralDevice *)device result:(BOOL)isSuccess operationType:(PeripheralOperationType)type{
    NSLog(@"读写数据回调");
    
    _sharedBleLayer.state = BT40LayerState_Idle;
    device.stateType = PeripheralState_Disconnected;
    
    if(type == GasCardOperation_READ){
        if ([self.delegate respondsToSelector:@selector(bluetoochManager:didEndReadWithResponseData:fromDevice:result:)]) {
            [self.delegate bluetoochManager:self didEndReadWithResponseData:data fromDevice:device result:isSuccess];
        }
    }else if (type == GasCardOperation_WRITE){
        if ([self.delegate respondsToSelector:@selector(bluetoochManager:didEndWriteWithResponseData:fromDevice:result:)]) {
            [self.delegate bluetoochManager:self didEndWriteWithResponseData:data fromDevice:device result:isSuccess];
        }
    }
}

//连接
- (void)startConnectPeriphralDevice:(PeripheralDevice *)pDevice{
    [_sharedBleLayer startConnectWithDevice:pDevice completed:^(BT40LayerStateTypeDef state) {
        
    }];
}

- (void)stopConectPeriphralDevice:(PeripheralDevice *)pDevice{
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
- (void)bluetoochLayer:(Bluetooth40Layer *)bluetoochLayer isConnectingPeripheralDevice:(PeripheralDevice *)device withState:(BT40LayerStateTypeDef)state{
    
    NSLog(@"%s",__FUNCTION__);
    
    
    if(state == BT40LayerState_IsAccessing){
        //燃气卡读写
        BleCardHandler* cardHandler = [self cardHandlerForPeripheralDevice:device];
        if(!cardHandler) return;
        
        //燃气卡读写操作
        
        if(device.operationType == GasCardOperation_READ){
            //进行第一次读请求
            NSString* command = CARD_READ4442_COMMAND_FOR_FIRSTTIME;
            [cardHandler cardRequestWithCommand:command];
            NSLog(@"正在读卡，连接命令:%@",command);
        }else if(device.operationType == GasCardOperation_WRITE){
            //校验请求
            NSMutableString* commandIwant = [NSMutableString stringWithFormat:CARD_CHECKPASS4442_COMMAND];
            if(!device.checkKey) return;
            [commandIwant appendString:device.checkKey];
            
            NSLog(@"checkKey ------------------->|%@|",[device checkKey]);
            NSLog(@"checkKeyNEW ------------------->|%@|",[device checkKeyNew]);
            
            if([device.checkKey isEqualToString:@"147178"])
                [cardHandler cardRequestWithCommand:commandIwant];
            NSLog(@"正在进行校验，校验命令：%@",commandIwant);
        }

    }
    NSLog(@"%s 与外围设备连接中...",__FUNCTION__);
}


//先（3次）
- (void)bluetoochLayer:(Bluetooth40Layer *)bluetoochLayer didWriteDataPeripheralDevice:(PeripheralDevice *)device error:(NSError *)error{
    NSLog(@"%s",__FUNCTION__);
    NSLog(@"蓝牙写入外围成功！");
    
    if (error) {
        NSLog(@"写入设备失败:%@",error);
        [self stopConectPeriphralDevice:device];
        [self delegateActionWithData:nil device:device result:NO operationType:GasCardOperation_WRITE];
    }else{
        BleCardHandler* cardHandler = [self cardHandlerForPeripheralDevice:device];
        //如果当前为写卡操作，且写入卡数据成功，则进行密码更新
        if (device.operationType == GasCardOperation_WRITE
            && cardHandler.currentState == CardOperationState_ReadCorrect
            && _beenWritedCard == YES) {
            //密码判断
            NSString* keyold = device.checkKey;
            NSString* keyNew = device.checkKeyNew;
            if (![keyold isEqualToString:keyNew]) {
                NSMutableString* commandIwant = [[NSMutableString alloc] initWithString:CARD_CHANGPASS4442_COMMAND];
                [commandIwant appendString:keyNew];
                [cardHandler cardRequestWithCommand:commandIwant];
                NSLog(@"正在进行密码更新，命令：%@",commandIwant);
            }else{
                NSLog(@"卡片不必更新密码,写卡成功");
                [self delegateActionWithData:nil device:device result:YES operationType:GasCardOperation_WRITE];
            }
            _beenWritedCard = NO;
        }else{
            NSLog(@"%s",__FUNCTION__);
        }
    }
}


#pragma mark -BleCardHandlerDelegate
//卡处理器接收数据 (1次)
- (void)bleCardHandler:(BleCardHandler *)cardHander didReceiveData:(NSData *)data state:(CardOperationState)state{
    NSLog(@"卡处理器处理完成！");
    NSLog(@"%s",__FUNCTION__);
    PeripheralDevice* deviceIwant = [Bluetooth40Layer currentDisposedDevice];
    BleCardHandler* cardHandler = [self cardHandlerForPeripheralDevice:deviceIwant];
    //读写卡数据
    if(deviceIwant.operationType == GasCardOperation_READ){
        [_readResultData appendData:data];
        NSLog(@"%@接收的数据长度：%ld",cardHander,(unsigned long)_readResultData.length);
        
        //第一次读请求成功后，进行第二次读请求
        if(state == CardOperationState_ReadCorrect
           && _readResultData.length < STANTARD_CARDDATA_LENGTH){
            NSString* command = CARD_READ4442_COMMAND_FOR_SECONDTIME;
            [cardHandler cardRequestWithCommand:command];
            NSLog(@"正在进行第二次读卡请求，命令：%@",command);
        }
        else{
            NSLog(@"最终的结果数据是：%@",[[NSString alloc] initWithData:_readResultData encoding:NSUTF8StringEncoding]);
            
            //设备数据写入
            [deviceIwant setValue:_readResultData forKey:DEVICE_CARD_READED_DATA_KEY];
            [self delegateActionWithData:_readResultData device:deviceIwant result:YES operationType:GasCardOperation_READ];
            return;
        }
    }
    else if (deviceIwant.operationType == GasCardOperation_WRITE){
        
        //校验结果如果完成，开始写入卡片数据
        if (state == CardOperationState_ReadCorrect) {
            _beenWritedCard = NO;
            NSMutableString* commandIwant = [[NSMutableString alloc] initWithString:CARD_WRITE4442_COMMAND_FOR_ONCE];
            NSData* dataIwant = _writeData;
            if(dataIwant.length > 679) return;
            dataIwant = [dataIwant subdataWithRange:NSMakeRange(64, 512-64)];
            
            //二进制转16进制
            NSString* stringIwant = [ConverUtil stringFromHexString:[ConverUtil convertDataToHexStr:dataIwant]];
            //加卡片数据(64-512)位
            [commandIwant appendString:stringIwant];
        
            [cardHandler cardRequestWithCommand:commandIwant];
            _beenWritedCard = YES;
            NSLog(@"正在写入卡片数据，命令：%@",commandIwant);
            
        }else{
            //已经写完卡并收到写卡后的回复错误
            if(_beenWritedCard && state == CardOperationState_ReadWrong){
                NSLog(@"写入卡片不成功！");
                [self stopConectPeriphralDevice:deviceIwant];
                [self delegateActionWithData:data device:deviceIwant result:NO operationType:GasCardOperation_WRITE];
            }else{
                [self delegateActionWithData:data device:deviceIwant result:YES operationType:GasCardOperation_WRITE];
            }
            
        }
    }
}

@end