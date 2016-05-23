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

static BluetoochManager* _bluetoochManager = nil;

@interface BluetoochManager ()
<Bluetooth40LayerDelegate,BleCardHandlerDelegate
>
{
    Bluetooth40Layer* _sharedBleLayer;
}
@property (nonatomic,strong) NSMutableArray* cardHandlers;

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
        
        _sharedBleLayer = [Bluetooth40Layer sharedInstance];
        _sharedBleLayer.delegate = self;
        
    }
    
    return self;
}

- (void)startSearchPeriphralsUntil:(NSDate *)date{
    NSTimeInterval time = [date timeIntervalSinceDate:[NSDate date]];
    NSLog(@"interval time is :%f",time);
    [_sharedBleLayer startScan:time withServices:nil];
}

- (void)stopSearchPeriphrals{
    [_sharedBleLayer stopScan];
}

- (void)startConnectPeriphralDevice:(PeripheralDevice *)pDevice{
    [_sharedBleLayer startConnectWithDevice:pDevice];
}

- (void)stopConectPeriphralDevice:(PeripheralDevice *)pDevice{
    [_sharedBleLayer disconnectWithDevice:pDevice];
}

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

#pragma mark -BLELayerDelegate
//正在连接外围设备，连接后的回调
- (void)isConnectingPeripheralDevice:(PeripheralDevice *)device withState:(BT40LayerResultTypeDef)state{

    if(state == BT40LayerResult_Success){
        //燃气卡读写
        BleCardHandler* cardHandler = [self cardHandlerForPeripheralDevice:device];
        if(!cardHandler) return;
        NSString* command = @"01010000FF";
        NSLog(@"正在连接外围设备，连接命令:%@",command);
        [cardHandler cardRequestWithCommand:command];
        
    }else{
        
    }

}

//已经连接上了外围设备，正在进行卡处理
- (void)didConnectedPeripheralDevice:(PeripheralDevice *)device{
    printf("新建蓝牙卡处理器！");
    //新建卡处理器用于蓝牙卡处理
    BleCardHandler* cardHandler = [[BleCardHandler alloc] initWithPeripheralDevice:device];
    cardHandler.delegate = self;
    [_cardHandlers addObject:cardHandler];
    
}

//已经断开与外围设备的连接
- (void)didDisconnectedPeripheralDevice:(PeripheralDevice *)device{
    printf("删除蓝牙卡处理器！");
    //删除卡处理器
    BleCardHandler* cardHandler = [self cardHandlerForPeripheralDevice:device];
    if(!cardHandler) return;
    [_cardHandlers removeObject:cardHandler];
}


//卡正在读取数据，这个是读取卡的过程
- (void)didReceivedData:(NSData *)data fromPeripheralDevice:(PeripheralDevice *)device{
    //卡处理器处理数据
    BleCardHandler* cardHandler = [self cardHandlerForPeripheralDevice:[Bluetooth40Layer currentDisposedDevice]];
    if(!cardHandler) return;
    
    NSLog(@"卡正在读写数据，这个过程可能会被调用多次...");
    
    [cardHandler dataProcessing:data];
}

- (void)sendFollowWithType:(int)type{
    BleCardHandler* cardHandler = [self cardHandlerForPeripheralDevice:[Bluetooth40Layer currentDisposedDevice]];
    if(!cardHandler) return;
    [cardHandler sendfollow:type];
}


#pragma mark -BleCardHandlerDelegate

////卡处理器发送数据
//- (void)bleCardHandler:(BleCardHandler *)cardHandler sendData:(NSData *)data{
//    NSLog(@"%@发送的数据：%@",cardHandler,data);
//    [_sharedBleLayer sendData:data toDevice:[Bluetooth40Layer currentDisposedDevice]];
//}
//
////卡处理器接收数据
//- (void)bleCardHandler:(BleCardHandler *)cardHander didReceiveData:(NSData *)data{
//    NSLog(@"%@接收的数据长度：%ld",cardHander,data.length);
//    
//}



#pragma mark - Util
- (BleCardHandler *)cardHandlerForPeripheralDevice:(PeripheralDevice *)device{
    BleCardHandler* iWant = nil;
    for (BleCardHandler* cardHandler in _cardHandlers) {
        if(cardHandler.device == device){
            iWant = cardHandler;
        }
    }
    return iWant;
}

@end