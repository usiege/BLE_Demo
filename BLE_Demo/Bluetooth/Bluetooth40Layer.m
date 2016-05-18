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

#define LOCAL_DEVICE_NAMES @"LocalDeviceID"
#define BLUETOOCHMANAGER [XFBluetoochManager shareInstance]

//函数处理结果返回值
typedef NS_ENUM(NSInteger, UtilityFuncHandleResultDef) {
    UtilityFuncHandleResult_Success,
    UtilityFuncHandleResult_Existed,
    UtilityFuncHandleResult_Added,
    UtilityFuncHandleResult_Err,
    UtilityFuncHandleResultEnd
};


@implementation Bluetooth40Layer
{
    //搜索变量定义
    NSTimer                 *scanTimer;
    NSMutableArray*         _localDeviceNames;
}

@synthesize _CM;


+(instancetype)sharedInstance{
    static Bluetooth40Layer * _sharedInstance = nil;
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
        dispatch_queue_t centralQ = dispatch_queue_create("com.bde.BDEWristBand.CentralQ", DISPATCH_QUEUE_CONCURRENT);
        _CM = [[CBCentralManager alloc] initWithDelegate:self queue:centralQ];
        
        _localDeviceNames = [[NSMutableArray alloc] init];
        scanTimer = nil;
        self.state = BT40LayerState_Idle;
    }
    count = 0;
    pagecou = 0;
    return self;
}

-(NSArray *)fetchConnectedDevices{

    NSArray *resultArray = nil;
    if (_CM!=nil) {
        //Returns a list of the peripherals (containing any of the specified services) currently connected to the system.
        resultArray = [_CM retrieveConnectedPeripheralsWithServices:nil];
    }
    return resultArray;
}
//搜索蓝牙
-(void)startScan:(NSTimeInterval)seconds withServices:(NSString *)service{
    
    if (self.state == BT40LayerState_Searching) {
        [self stopScan];
    }
    
    if (_CM) {
        
        NSArray *services = @[[CBUUID UUIDWithString:BUSINESS_SERVICE_UUID_STRING]];
        NSDictionary *scanOption = @{CBCentralManagerScanOptionAllowDuplicatesKey:@(YES)};//服务暂时不用
        
        [_CM scanForPeripheralsWithServices:services options:scanOption];
        printf("start scan peripheral .... \n");
        
        scanTimer = [NSTimer scheduledTimerWithTimeInterval:seconds target:self selector:@selector(scanTimeoutHandler:) userInfo:nil repeats:NO];
        
        self.state = BT40LayerState_Searching;
    }
    
    
}
-(void)createDataChannelWithDevice:(PeripheralDevice *)device{
    [self startConnectWithDevice:device];
    if (self.state == BT40LayerState_Searching) {
        [self stopScan];
    }
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
                if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:TX_CHARACTERISTIC_UUID_STRING]])
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

- (void)cancelTimer:(NSTimer *)_timer{
    printf("cancel timer ! \n");
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
}

- (void)enableNotifyPropertyOfCharacteristic:(CBCharacteristic *)characteristic peripheral:(CBPeripheral *)peripheral on:(BOOL)bOn{
    
    [peripheral setNotifyValue:bOn forCharacteristic:characteristic];
    
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
//    NSLog(@"advertisement data is :%@",advertisementData);
    
    NSString* identifer = [peripheral.identifier UUIDString];
    peripheral.delegate = self;
    
    //根据设备的UUID进行检索
    if (![_localDeviceNames containsObject:identifer]) {
        
        [_localDeviceNames addObject:identifer];
        NSLog(@"device identifier is :%@",identifer);
        
        PeripheralDevice *device = [[PeripheralDevice alloc] init];
        device.identifier = [peripheral.identifier UUIDString];
        device.rssi = RSSI;
        device.name = peripheral.name;
        device.advertisementData = advertisementData;
        device.peripheral = peripheral;
        [BLUETOOCHMANAGER addNewDevice:device];
        
    }else{
        return;
    }
}

-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    printf("didConnectPeripheral , name = %s\n",[peripheral.name UTF8String]);
    PeripheralDevice *device = [BLUETOOCHMANAGER getDeviceByPeripheral:peripheral];
    
    [self cancelTimer:device.connectTimer];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (device.state == BT40DeviceState_Connecting){
            [peripheral discoverServices:nil];
            printf(" -- service discovering .... \n");
            peripheral.delegate = self;
            device.state = BT40DeviceState_Discovering;
            device.discoverTimer = [NSTimer scheduledTimerWithTimeInterval:TIMEOUT_TIME_SECONDS_DISCOVER_PROCEDURE_ target:self selector:@selector(discoverTimeoutHandler:) userInfo:device repeats:NO];
        }
    });
}


//断开回调处理
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@"didDisconnectPeripheral%@\n",peripheral.name);
    
    PeripheralDevice *device = [BLUETOOCHMANAGER getDeviceByPeripheral:peripheral];
    if (!device) return;
    
    device.state = BT40DeviceState_Idle;
    [self cancelTimer:device.connectTimer];
    [self cancelTimer:device.discoverTimer];
    [self cancelTimer:device.configureTimer];
    if ([self.delegate respondsToSelector:@selector(didDisconnectWithDevice:)]) {
        [self.delegate didDisconnectWithDevice:device];
    }
}

//连接失败回调
-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@"didFailToConnectPeripheral error:%@",error);
}

//周边蓝牙协议

#pragma mark - CBPeripheral Delegate
//
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    printf("\n ==== didDiscoverServices ==== \n");
    
    PeripheralDevice *device = [BLUETOOCHMANAGER getDeviceByPeripheral:peripheral];
    if(!device) return;
    
    [self cancelTimer:device.discoverTimer];
    
    if (error != nil) {
        
        if ([self.delegate respondsToSelector:@selector(didCreateDataChannelWithDevice:withResult:)]) {
            [self.delegate didCreateDataChannelWithDevice:device withResult:BT40LayerResult_DiscoverFailed];
        }
        [self disconnectWithDevice:device];
        
    }else{
        device.countOfNotiCharac = 0;
        
        for (CBService *service in peripheral.services) {
            printf("-- service : %s\n",[[service.UUID UUIDString] UTF8String]);
            [peripheral discoverCharacteristics:nil forService:service];
        }
        
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    printf("didDiscoverCharacteristicsForService(%s)\n",[[service.UUID UUIDString] UTF8String]);
    
    PeripheralDevice *device = [BLUETOOCHMANAGER getDeviceByPeripheral:peripheral];
    if(!device) return;
    
    if (error != nil) {//出错处理
        printf("error is : %s\n",[error.description UTF8String]);
        if ([self.delegate respondsToSelector:@selector(didCreateDataChannelWithDevice:withResult:)]) {
            [self.delegate didCreateDataChannelWithDevice:device withResult:BT40LayerResult_DiscoverFailed];
        }
        
        [self disconnectWithDevice:device];
        
    }else{
        
        for (CBCharacteristic *characteristic in service.characteristics) {
            printf(" -> charac : %s,property(0x%02x) ",[[characteristic.UUID UUIDString] UTF8String],characteristic.properties);
            
                if (characteristic.properties & CBCharacteristicPropertyNotify) {
//            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:RX_CHARACTERISTIC_UUID_STRING]])
//            {
//                printf("s%")
                [self enableNotifyPropertyOfCharacteristic:characteristic peripheral:peripheral on:YES];
                device.countOfNotiCharac++;
                printf("countOfNOtiCharac = %d\n",device.countOfNotiCharac);
            }else
            {
                printf("\n");
            }
            
            if (device.countOfNotiCharac != 0) {
                device.configureTimer = [NSTimer scheduledTimerWithTimeInterval:TIMEOUT_TIME_SECONDS_CONFIGURE_PROCEDURE_ target:self selector:@selector(configureTimeoutHandler:) userInfo:device repeats:NO];
                device.state = BT40DeviceState_Configuring;
            }
        }
        
        int serviceIndex = [peripheral.services indexOfObject:service];
        
        if (serviceIndex == peripheral.services.count - 1) {
            printf("\n\n ==== found all characteristics and services ==== \n\n");
            
        }
        
    }
}

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

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    
    PeripheralDevice *device = [BLUETOOCHMANAGER getDeviceByPeripheral:peripheral];
    
    if (error != nil) {
        printf("接收失败");
    }else{
        if ([self.delegate respondsToSelector:@selector(didReceivedData:fromChannelWithDevice:)])
        {
            NSLog(@"Rev:%@  Length:%lu",[ConverUtil data2HexString:characteristic.value],(unsigned long)characteristic.value.length);
            //            if (characteristic.value.length>=2 && [[ConverUtil data2HexString:characteristic.value] hasPrefix:@"1015"]){
            //                printf("接收到1015报文\n");
            //            }
            
            [self.delegate didReceivedData:characteristic.value fromChannelWithDevice:device];
        }
    }
}




//-(void)peripheral:(CBPeripheral *)peripheral di

@end
