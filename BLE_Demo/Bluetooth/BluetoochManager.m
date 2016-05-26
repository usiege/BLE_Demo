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
#define CARD_WRITE4442_COMMAND_FOR_ONCE          @"01020020E0"//写卡开始位置是20，长度是224
#define CARD_CHANGPASS4442_COMMAND               @"0105000003"

static const NSUInteger STANTARD_CARDDATA_LENGTH = 512; //卡片最长可读写长度

extern NSString* DEVICE_PARSED_DATA_KEY;
extern NSString* DEVICE_CARD_READED_DATA_KEY;


@interface BluetoochManager ()
<Bluetooth40LayerDelegate
>
{
    Bluetooth40Layer* _sharedBleLayer;
    
    BOOL _beenWritedCard;
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


//读写
- (void)readDataFromPeriphralDevice:(PeripheralDevice *)pDevice{
    if(!pDevice) return;
    pDevice.operationType = GasCardOperation_READ;
    if(_sharedBleLayer.state == BT40LayerState_Connected) return;
    [self startConnectPeriphralDevice:pDevice];
}

- (void)writeData:(NSString *)dataString toPeriphralDevice:(PeripheralDevice *)pDevice{
    if(!pDevice) return;
    pDevice.operationType = GasCardOperation_WRITE;
    NSData* dataIwant = [pDevice valueForKey:DEVICE_PARSED_DATA_KEY];
    
    if(_sharedBleLayer.state == BT40LayerState_Connected) return;
    if(dataIwant)
        [self startConnectPeriphralDevice:pDevice];
}


//连接
- (void)startConnectPeriphralDevice:(PeripheralDevice *)pDevice{
    [_sharedBleLayer startConnectWithDevice:pDevice];
}

- (void)stopConectPeriphralDevice:(PeripheralDevice *)pDevice{
    [_sharedBleLayer disconnectWithDevice:pDevice];
}


#pragma mark
- (PeripheralDevice *)getDeviceByIdentifer:(NSString *)deviceID{
    return nil;
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
        if ([self.delegate respondsToSelector:@selector(didFoundNewPerigheralDevice:)]) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self.delegate didFoundNewPerigheralDevice:dm];
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

//已经连接上了外围设备
- (void)didConnectedPeripheralDevice:(PeripheralDevice *)device{
    
    if (device.operationType == GasCardOperation_READ) {
        //开始读卡
        [_sharedBleLayer readDataFromPeriphralDevice:device];
        //
        [_readResultData resetBytesInRange:NSMakeRange(0, _readResultData.length)];
        [_readResultData setLength:0];
    }else if (device.operationType == GasCardOperation_WRITE){
        //开始写卡
        NSData* dataIwant = [device valueForKey:DEVICE_PARSED_DATA_KEY];
        _writeData = dataIwant;
        if(_writeData){
            [_sharedBleLayer writeData:dataIwant toDevice:device];
        }else{
            NSLog(@"卡片信息还未读取！");
        }
    }
}

//与外围设备连接中...
- (void)isConnectingPeripheralDevice:(PeripheralDevice *)device withState:(BT40LayerStateTypeDef)state{
    //
    
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
            [commandIwant appendString:device.checkKey];
            [cardHandler cardRequestWithCommand:commandIwant];
            NSLog(@"正在进行校验，校验命令：%@",commandIwant);
        }

    }else{
        NSLog(@"%s连接外围设备未成功！",__FUNCTION__);
    }
}

//已经断开与外围设备的连接
- (void)didDisconnectedPeripheralDevice:(PeripheralDevice *)device{
    printf("删除蓝牙卡处理对象！");
    //删除卡处理器
    BleCardHandler* cardHandler = [self cardHandlerForPeripheralDevice:device];
    if(!cardHandler) return;
    [_cardHandlers removeObject:cardHandler];
}


//卡正在读取数据，这个是读取卡的过程
- (void)didReceivedData:(NSData *)data fromPeripheralDevice:(PeripheralDevice *)device{
    
    if(!device) return;
    //卡处理器处理数据
    BleCardHandler* cardHandler = [self cardHandlerForPeripheralDevice:device];
    if(!cardHandler) return;
    
    NSLog(@"卡正在读写数据，这个过程可能会被调用多次...");
#warning 这里有可能出现问题
    [cardHandler dataProcessing:data];
}

- (void)sendFollowWithType:(int)type{
    BleCardHandler* cardHandler = [self cardHandlerForPeripheralDevice:[Bluetooth40Layer currentDisposedDevice]];
    if(!cardHandler) return;
#warning 这里有可能出现问题
    [cardHandler sendfollow:type];
    
    
}


#pragma mark -BleCardHandlerDelegate

//卡处理器接收数据
- (void)bleCardHandler:(BleCardHandler *)cardHander didReceiveData:(NSData *)data state:(CardOperationState)state{

    NSLog(@"卡处理器接收到数据！");
    
    PeripheralDevice* currentDisposedDevice = [Bluetooth40Layer currentDisposedDevice];
    BleCardHandler* cardHandler = [self cardHandlerForPeripheralDevice:
                                   currentDisposedDevice];
    if(!cardHandler) return;
    
    //读写卡数据
    if(currentDisposedDevice.operationType == GasCardOperation_READ){
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
            [currentDisposedDevice setValue:_readResultData forKey:DEVICE_CARD_READED_DATA_KEY];
            
            if ([self.delegate respondsToSelector:@selector(didReceiveDisposedData:fromDevice:)]) {
                [self.delegate didReceiveDisposedData:_readResultData fromDevice:currentDisposedDevice];
            }
            return;
        }
    }
    else if (currentDisposedDevice.operationType == GasCardOperation_WRITE){
        
        //校验结果如果完成，开始写入卡片数据
        if (state == CardOperationState_ReadCorrect) {
            _beenWritedCard = NO;
            NSMutableString* commandIwant = [[NSMutableString alloc] initWithString:CARD_WRITE4442_COMMAND_FOR_ONCE];
            NSData* dataIwant = _writeData;
            if(dataIwant.length > 512) return;
            dataIwant = [dataIwant subdataWithRange:NSMakeRange(64, 512-64)];
            NSString* stringIwant = [ConverUtil data2HexString:dataIwant];
            //加卡片数据(64-512)位
            [commandIwant appendString:stringIwant];
            [cardHandler cardRequestWithCommand:commandIwant];
            _beenWritedCard = YES;
            NSLog(@"正在写入卡片数据，命令：%@",commandIwant);
        }else{
            NSLog(@"写入卡片不成功！");
        }
    }
}

- (void)didWriteDataPeripheralDevice:(PeripheralDevice *)device error:(NSError *)error{
    BleCardHandler* cardHandler = [self cardHandlerForPeripheralDevice:
                                   device];
    if(!cardHandler) return;

    if (error) {
        NSLog(@"写入设备失败:%@",error);
    }else{
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
                _beenWritedCard = NO;
                NSLog(@"正在进行密码更新，命令：%@",commandIwant);
            }else{
                NSLog(@"卡片不必更新密码");
            }
        }else{
            NSLog(@"%s",__FUNCTION__);
        }
    }
}

@end