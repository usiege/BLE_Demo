//
//  Bluetooth40Layer.m
//  BDEWrsitBand
//
//  Created by 王 维 on 8/12/14.
//  Copyright (c) 2014 BDE. All rights reserved.
//

#import "Bluetooth40Layer.h"

#import "common.h"
#import "ConverUtil.h"

#import "Bluetooth40Common.h"
#import "PeripheralDevice.h"
#import "XFBluetoochManager.h"

#define BLUETOOCH_QUEUE_IDENTIFER   "com.bde.BDEWristBand.CentralQ"

#define LOCAL_DEVICE_NAMES          @"LocalDeviceID"
#define BLUETOOCHMANAGER            [XFBluetoochManager shareInstance]



//函数处理结果返回值
typedef NS_ENUM(NSInteger, UtilityFuncHandleResultDef) {
    UtilityFuncHandleResult_Success,
    UtilityFuncHandleResult_Existed,
    UtilityFuncHandleResult_Added,
    UtilityFuncHandleResult_Err,
    UtilityFuncHandleResultEnd
};

@interface Bluetooth40Layer () <CBCentralManagerDelegate,CBPeripheralDelegate>
{
    //搜索变量定义
    NSTimer                 *scanTimer;
    NSMutableArray*         _localDeviceNames;
    
    //当前正在处理的设备
    PeripheralDevice*       _currentDisposedDevice;
}
@end

@implementation Bluetooth40Layer
{
    
}

@synthesize _CM;

static Bluetooth40Layer * _sharedInstance = nil;
+(instancetype)sharedInstance{
    
    //用在类方法中，返回一个单例
    static dispatch_once_t once_token;
    
    dispatch_once(&once_token, ^{
        if (_sharedInstance == nil) {
            _sharedInstance = [[Bluetooth40Layer alloc] init];
        }
    });
    return _sharedInstance;
}

//初始化
-(id)init{
    
    self =  [super init];
    if (self) {
        dispatch_queue_t centralQ = dispatch_queue_create(BLUETOOCH_QUEUE_IDENTIFER, DISPATCH_QUEUE_CONCURRENT);
        _CM = [[CBCentralManager alloc] initWithDelegate:self queue:centralQ];
        
        _localDeviceNames = [[NSMutableArray alloc] init];
        scanTimer = nil;
        self.state = BT40LayerState_Idle;
    }
    count = 0;
    pagecou = 0;
    return self;
}

//搜索蓝牙
-(void)startScan:(NSTimeInterval)seconds withServices:(NSString *)service{
    
    if (self.state == BT40LayerState_Searching) {
        [self stopScan];
    }
    
    if (_CM) {
        
        NSArray *services = @[[CBUUID UUIDWithString:BUSINESS_SERVICE_UUID_STRING]
                              ];
        NSDictionary *scanOption = @{CBCentralManagerScanOptionAllowDuplicatesKey:@(NO)};//服务暂时不用
        
        [_CM scanForPeripheralsWithServices:services options:scanOption];
        printf("start scan peripheral .... \n");
        
        scanTimer = [NSTimer scheduledTimerWithTimeInterval:seconds target:self selector:@selector(scanTimeoutHandler:) userInfo:nil repeats:NO];
        self.state = BT40LayerState_Searching;
    }
    
    
}
-(void)createDataChannelWithDevice:(PeripheralDevice *)device{
    
    if (self.state == BT40LayerState_Searching) {
        [self stopScan];
    }
    [self startConnectWithDevice:device];
}

//遍历特征，发送数据
-(BOOL)sendData:(NSData *)data toDevice:(PeripheralDevice *)device{
    
    //if (device.state == BT40DeviceState_DataReady) {
  if(device == nil)
    return false;
  
        if (device.peripheral != nil && device.peripheral.state == CBPeripheralStateConnected) {
            printf("\nwrite data : %s \n\n",[data.description UTF8String]);
            CBCharacteristic *txCharac = [self getTXCharacteristicOfDevice:device];
            if(txCharac)
            {
                [device.peripheral writeValue:data forCharacteristic:txCharac type:CBCharacteristicWriteWithResponse];
            }
            return YES;
        }
    //}
    return NO;
    
}

///发送完成
-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    NSLog(@"发送结束");
    
    if(error!=nil){
        NSLog(@"发送失败");
        if(count<3){
//            [Public_BleController sendfollow:0];
        }
        count++;

    }else{
        NSLog(@"发送成功");
//        dispatch_async(dispatch_get_global_queue(0, 0), ^{[Public_BleController sendfollow:1];});
//          [Public_BleController sendfollow:1];
          count=0;
    }

}

//开始链接
-(void)startConnectWithDevice:(PeripheralDevice *)device{
  
    if (_CM && device.peripheral &&
        device.peripheral.state == CBPeripheralStateDisconnected) {
        
        [_CM connectPeripheral:device.peripheral options:nil];
    
        device.state = BT40DeviceState_Connecting;
        device.connectTimer = [NSTimer scheduledTimerWithTimeInterval:TIMEOUT_TIME_SECONDS_CONNECT_PROCEDURE_
                                                               target:self
                                                             selector:@selector(connectTimeoutHandler:)
                                                             userInfo:device
                                                              repeats:NO];
    }
}

//断开蓝牙
-(void)disconnectWithDevice:(PeripheralDevice *)device{
    if (device != nil && device.state != BT40DeviceState_Idle) {
        if (device.peripheral != nil &&
            device.peripheral.state != CBPeripheralStateDisconnected) {
            [_CM cancelPeripheralConnection:device.peripheral];
            NSLog(@"\n-- disconnect with device :%@\n",device.advertisementData);
        }
    }
}


#pragma mark-TimeroutHandler

- (void)configureTimeoutHandler:(NSTimer *)_timer{

    printf("configure Timeout Handler\n");
    PeripheralDevice *device = _timer.userInfo;
    if (device != nil && device.state == BT40DeviceState_Configuring) {
        device.state = BT40DeviceState_Disconnecting;
        [self disconnectWithDevice:device];
    }

}

-(void)scanTimeoutHandler:(NSTimer *)_timer{
    
    if (self.state == BT40LayerState_Searching) {
        [self stopScan];
    }

}

- (void)connectTimeoutHandler:(NSTimer *)_timer{
    printf("connect Timeout Handler\n");
    PeripheralDevice *device = _timer.userInfo;
    if (device != nil && device.state == BT40DeviceState_Connecting) {
        device.state = BT40DeviceState_Disconnecting;
        [self disconnectWithDevice:device];
    }
}

- (void)discoverTimeoutHandler:(NSTimer *)_timer{
    printf("discover Timeout Handler \n");
    PeripheralDevice *device = _timer.userInfo;
    if (device != nil && device.state == BT40DeviceState_Discovering) {
        device.state = BT40DeviceState_Disconnecting;
        [self disconnectWithDevice:device];
    }
}

-(void)stopScan{
    if (scanTimer != nil) {
        [_CM stopScan];
        [scanTimer invalidate];
        scanTimer = nil;
        self.state = BT40LayerState_Idle;
    }
}

#pragma mark    Utility Function

-(CBCharacteristic *)getTXCharacteristicOfDevice:(PeripheralDevice *)device{

    for (CBService *service in device.peripheral.services)
    {
         if ([service.UUID isEqual:[CBUUID UUIDWithString:BUSINESS_SERVICE_UUID_STRING]])
        {

            for (CBCharacteristic *characteristic in service.characteristics)
            {
                NSLog(@"characteristic %@", [characteristic.UUID UUIDString]);
                if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:WRITE_CHARACTERISTIC_UUID_STRING]])
                {
                  NSLog(@"find it");
                  return characteristic;
                }
            }
        }
    }
    return nil;
}

- (void)dataChannelReadyForDevice:(PeripheralDevice *)device{

    NSLog(@"==== dataChannelReadyForDevice : %@ ====",device.advertisementData);
    if (device != nil) {
        
        if ([self.delegate respondsToSelector:@selector(didCreateDataChannelWithDevice:withResult:)]) {
            [self.delegate didCreateDataChannelWithDevice:device  withResult:BT40LayerResult_Success];
        }
        
    }
    
}

- (void)enableNotifyPropertyOfCharacteristic:(CBCharacteristic *)characteristic peripheral:(CBPeripheral *)peripheral on:(BOOL)bOn{
    
    [peripheral setNotifyValue:bOn forCharacteristic:characteristic];
    
}


//超时取消操作
- (void)cancelTimer:(NSTimer *)_timer{
    printf("cancel timer ! \n");
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
}

//蓝牙中心协议
#pragma mark    CBCentralManager Delegate
-(void)centralManagerDidUpdateState:(CBCentralManager *)central{
    //状态改变
    BT40LayerStatusTypeDef status = BT40LayerStatusEnd;
    
    switch (central.state) {
        case CBCentralManagerStatePoweredOff:
        {
            status = BT40LayerStatus_PoweredOff;
        }
            break;
        case CBCentralManagerStatePoweredOn:
        {
            status = BT40LayerStatus_PoweredOn;
        }
            break;
        case CBCentralManagerStateResetting:
        {
            status = BT40LayerStatus_Resetting;
        }
            break;
        case CBCentralManagerStateUnauthorized:
        {
            status = BT40LayerStatus_Unauthorized;
        }
            break;
        case CBCentralManagerStateUnknown:
        {
            status = BT40LayerStatus_Unknown;
        }
            break;
        case CBCentralManagerStateUnsupported:
        {
            status = BT40LayerStatus_Unsupported;
        }
            break;
        default:
        {
            status = BT40LayerStatusEnd;
        }
            break;
    }
    
    
    if ([self.delegate respondsToSelector:@selector(didBluetoothStateChange:)]) {
        [self.delegate didBluetoothStateChange:status];
    }
    
}


//扫描到蓝牙后的回调
-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    
    printf("didDiscoverPeripheral\n");
    NSLog(@"advertisement data is :%@",advertisementData);
    NSString* identifer = [peripheral.identifier UUIDString];
    
    
    //根据设备的UUID进行检索
    if (![_localDeviceNames containsObject:identifer]) {
        
        [_localDeviceNames addObject:identifer];
        printf("发现新设备\n");
        NSLog(@"device identifier is :%@",identifer);
        
        PeripheralDevice *device = [[PeripheralDevice alloc] init];
        device.identifier = [peripheral.identifier UUIDString];
        device.rssi = RSSI;
        device.name = peripheral.name;
        device.advertisementData = advertisementData;
        device.peripheral = peripheral;
//        device.UUID =
        [BLUETOOCHMANAGER addNewDevice:device];

    }else{
        return;
    }
}

-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    printf("已连接上设备：");
    printf("name = %s\n",[peripheral.name UTF8String]);
    PeripheralDevice *device = [BLUETOOCHMANAGER getDeviceByPeripheral:peripheral];
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self cancelTimer:device.connectTimer];
    });
    
    peripheral.delegate = self;
    if (device.state == BT40DeviceState_Connecting){
        
        NSArray<CBUUID*>* uuids =@[[CBUUID UUIDWithString:WRITE_CHARACTERISTIC_UUID_STRING],
                                   [CBUUID UUIDWithString:READ_CHARACTERISTIC_UUID_STRING]];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            [peripheral discoverServices:nil];
            
            printf(" -- service discovering .... \n");
            device.state = BT40DeviceState_Discovering;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                device.discoverTimer = [NSTimer scheduledTimerWithTimeInterval:TIMEOUT_TIME_SECONDS_DISCOVER_PROCEDURE_ target:self selector:@selector(discoverTimeoutHandler:) userInfo:device repeats:NO];
                });
            });
    }
}


//断开回调处理
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    printf("连接已断开！\n");
//    NSLog(@"didDisconnectPeripheral:\n%@",peripheral.name);
    
    PeripheralDevice *device = [BLUETOOCHMANAGER getDeviceByPeripheral:peripheral];
    if (!device) return;
    
    device.state = BT40DeviceState_Idle;
    
//    [self cancelTimer:device.connectTimer];
//    [self cancelTimer:device.discoverTimer];
//    [self cancelTimer:device.configureTimer];
    NSLog(@" delegate is :%@",self.delegate);
}

//连接失败回调
-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@"didFailToConnectPeripheral error:%@",error);
}

//周边蓝牙协议
#pragma mark - CBPeripheral Delegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    printf("发现周边设备的服务:\n");
    printf("==== didDiscoverServices ==== \n");
    
    PeripheralDevice *device = [BLUETOOCHMANAGER getDeviceByPeripheral:peripheral];
    if(!device) return;
    
    if (error != nil) {
        
        if ([self.delegate respondsToSelector:@selector(didCreateDataChannelWithDevice:withResult:)]) {
            [self.delegate didCreateDataChannelWithDevice:device withResult:BT40LayerResult_DiscoverFailed];
        }
        [self disconnectWithDevice:device];
        
    }else{
        device.countOfNotiCharac = 0;
        
        for (CBService *service in peripheral.services) {
            printf("-- service : %s\n",[[service.UUID UUIDString] UTF8String]);
            dispatch_sync(dispatch_get_main_queue(), ^{
                [peripheral discoverCharacteristics:nil forService:service];
            });
        }
        
    }
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self cancelTimer:device.discoverTimer];
    });
    
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    printf("发现服务特性:(%s)\n",[[service.UUID UUIDString] UTF8String]);
    
    PeripheralDevice *device = [BLUETOOCHMANAGER getDeviceByPeripheral:peripheral];
    if(!device) return;
    
    if (error) {
        NSLog(@"There is a error in peripheral:didDiscoverCharacteristicsForService:error: which called:%@",error);
        if ([self.delegate respondsToSelector:@selector(didCreateDataChannelWithDevice:withResult:)]) {
            [self.delegate didCreateDataChannelWithDevice:device withResult:BT40LayerResult_DiscoverFailed];
        }
        
        [self disconnectWithDevice:device];
        return;
    }
    
    //characteristic 包含了 service 要传输的数据。当找到 characteristic 之后，可以通过调用CBPeripheral的readValueForCharacteristic:方法来进行读取。
    //当你调用上面这方法后，会回调peripheral:didUpdateValueForCharacteristic:error:方法，
    NSLog(@"service characteristics is %@",service.characteristics);
    
    printf("开始读取服务特性数据...\n");
    for (CBCharacteristic *characteristic in service.characteristics) {
        
        [device.peripheral readValueForCharacteristic:characteristic];
    }
}


//                if (characteristic.properties & CBCharacteristicPropertyNotify) {
//            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:RX_CHARACTERISTIC_UUID_STRING]])
//            {
//                printf("s%")
//                [self enableNotifyPropertyOfCharacteristic:characteristic peripheral:peripheral on:YES];
//                device.countOfNotiCharac++;
//                printf("countOfNOtiCharac = %d\n",device.countOfNotiCharac);
//            }else
//            {
//                printf("\n");
//            }
//
//            if (device.countOfNotiCharac != 0) {
//                device.configureTimer = [NSTimer scheduledTimerWithTimeInterval:TIMEOUT_TIME_SECONDS_CONFIGURE_PROCEDURE_ target:self selector:@selector(configureTimeoutHandler:) userInfo:device repeats:NO];
//                device.state = BT40DeviceState_Configuring;
//            }


//        int serviceIndex = [peripheral.services indexOfObject:service];
//
//        if (serviceIndex == peripheral.services.count - 1) {
//            printf("\n\n ==== found all characteristics and services ==== \n\n");
//
//        }

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    
    if (error) {
        NSLog(@"There is a error in peripheral:didUpdateValueForCharacteristic:error: which called:%@",error);
        return;
    }
    
    NSLog(@"characteristic data is:%@ ",characteristic.value);
    NSLog(@"characteristic data length is %ld",characteristic.value.length);
    
    //    PeripheralDevice *device = [BLUETOOCHMANAGER getDeviceByPeripheral:peripheral];
    
}

#if 0
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    printf("didUpdateNotificationStateForCharacteristic (%s)\n",[[characteristic.UUID UUIDString] UTF8String]);
    PeripheralDevice *device = [BLUETOOCHMANAGER getDeviceByPeripheral:peripheral];
    if(!device) return;
    
    if (error != nil) {
        printf("error is : %s\n",[error.description UTF8String]);
        if ([self.delegate respondsToSelector:@selector(didCreateDataChannelWithDevice:withResult:)]) {
            [self.delegate didCreateDataChannelWithDevice:device withResult:BT40LayerResult_DiscoverFailed];
        }
        
        [self disconnectWithDevice:device];
        
    }else{
        
        device.countOfNotiCharac--;
        printf(" update notification success, %d !! \n",device.countOfNotiCharac);
        
        if (device.countOfNotiCharac == 0 && device.state == BT40DeviceState_Configuring) {
            
            [self cancelTimer:device.configureTimer];
            device.state = BT40DeviceState_DataReady;
            [self dataChannelReadyForDevice:device];
        }
    }
}
#endif

@end
