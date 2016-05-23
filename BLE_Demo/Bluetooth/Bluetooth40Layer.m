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
#import "BluetoochManager.h"

//#import "BleCardHandler.h"

#define BLUETOOCH_QUEUE_IDENTIFER   "com.bde.BDEWristBand.CentralQ"

#define LOCAL_DEVICE_NAMES          @"LocalDeviceID"
#define BLUETOOCHMANAGER            [BluetoochManager shareInstance]

//函数处理结果返回值
typedef NS_ENUM(NSInteger, UtilityFuncHandleResultDef) {
    UtilityFuncHandleResult_Success,
    UtilityFuncHandleResult_Existed,
    UtilityFuncHandleResult_Added,
    UtilityFuncHandleResult_Err,
    UtilityFuncHandleResultEnd
};



@interface Bluetooth40Layer ()
<CBCentralManagerDelegate,CBPeripheralDelegate>
{
    //搜索变量定义
    NSTimer                 *scanTimer;
    NSMutableArray*         _localDeviceNames;
}

@property (strong,nonatomic) CBCentralManager* centralManager;
//@property (nonatomic,strong) NSMutableArray* cardHandlers;

@end

@implementation Bluetooth40Layer
{
    
}


static Bluetooth40Layer * _sharedInstance = nil;

PeripheralDevice* _currentDisposedDevice;

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
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:centralQ];
        
        _localDeviceNames = [[NSMutableArray alloc] init];
        
        scanTimer = nil;
        self.state = BT40LayerState_Idle;
    }
    count = 0;
    pagecou = 0;
    return self;
}

+ (PeripheralDevice *)currentDisposedDevice{
    return _currentDisposedDevice;
}


//搜索蓝牙
-(void)startScan:(NSTimeInterval)seconds withServices:(NSString *)service{
    
    if (self.state == BT40LayerState_Searching) {
        [self stopScan];
    }
    
    if (_centralManager) {
        
        NSArray *services = @[[CBUUID UUIDWithString:BUSINESS_SERVICE_UUID_STRING]
                              ];
        NSDictionary *scanOption = @{CBCentralManagerScanOptionAllowDuplicatesKey:@(NO)};//服务暂时不用
        
        [_centralManager scanForPeripheralsWithServices:services options:scanOption];
        printf("start scan peripheral .... \n");
        
        scanTimer = [NSTimer scheduledTimerWithTimeInterval:seconds target:self selector:@selector(scanTimeoutHandler:) userInfo:nil repeats:NO];
        self.state = BT40LayerState_Searching;
    }
}


//开始链接
-(void)startConnectWithDevice:(PeripheralDevice *)device{
  
    if (self.state == BT40LayerState_Searching) {
        [self stopScan];
    }
    
    if (_centralManager && device.peripheral &&
        device.peripheral.state == CBPeripheralStateDisconnected) {
        
        //连接外围设备
        [_centralManager connectPeripheral:device.peripheral options:nil];
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
            [_centralManager cancelPeripheralConnection:device.peripheral];
            NSLog(@"\n-- disconnect with device :%@\n",device.identifier);
        }
    }
}

//遍历特征，发送数据
- (BOOL)sendData:(NSData *)data toDevice:(PeripheralDevice *)device{
    if(device == nil) return NO;
    
    if (device.peripheral != nil && device.peripheral.state == CBPeripheralStateConnected) {
        printf("\n write data : %s \n\n",[data.description UTF8String]);
        CBCharacteristic *txCharac = [self getCharacteristicOfDevice:device];
        if(txCharac){
            [device.peripheral writeValue:data forCharacteristic:txCharac type:CBCharacteristicWriteWithResponse];
        }
        return YES;
    }
    return NO;
}

#pragma mark  Util Function

-(CBCharacteristic *)getCharacteristicOfDevice:(PeripheralDevice *)device{
    for (CBService *service in device.peripheral.services){
        if ([service.UUID isEqual:[CBUUID UUIDWithString:BUSINESS_SERVICE_UUID_STRING]]){
            for (CBCharacteristic *characteristic in service.characteristics){
                NSLog(@"characteristic %@", [characteristic.UUID UUIDString]);
                if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:WRITE_CHARACTERISTIC_UUID_STRING]]){
                    NSLog(@"find it");
                    return characteristic;
                }
            }
        }
    }
    return nil;
}

#pragma mark-TimeroutHandler

-(void)scanTimeoutHandler:(NSTimer *)_timer{
    printf("扫描已超时! \n");
    if (self.state == BT40LayerState_Searching) {
        [self stopScan];
    }
    [self cancelTimer:_timer];
}

-(void)stopScan{
    printf("停止扫描！ \n");
    if (scanTimer != nil) {
        [_centralManager stopScan];
        [scanTimer invalidate];
        scanTimer = nil;
        self.state = BT40LayerState_Idle;
    }
}

- (void)connectTimeoutHandler:(NSTimer *)_timer{
    printf("连接已超时! \n");
    PeripheralDevice *device = _timer.userInfo;
    if (device != nil && device.state == BT40DeviceState_Connecting) {
        device.state = BT40DeviceState_Disconnecting;
        [self disconnectWithDevice:device];
    }
    [self cancelTimer:_timer];
}

- (void)discoverTimeoutHandler:(NSTimer *)_timer{
    printf("发现服务已超时! \n");
    PeripheralDevice *device = _timer.userInfo;
    if (device != nil && device.state == BT40DeviceState_Discovering) {
        device.state = BT40DeviceState_Disconnecting;
        [self disconnectWithDevice:device];
    }
    [self cancelTimer:_timer];
}
- (void)configureTimeoutHandler:(NSTimer *)_timer{
    
    printf("服务配置已超时！\n");
    PeripheralDevice *device = _timer.userInfo;
    if (device != nil && device.state == BT40DeviceState_Configuring) {
        device.state = BT40DeviceState_Disconnecting;
        [self disconnectWithDevice:device];
    }
    [self cancelTimer:_timer];
}

//超时取消操作
- (void)cancelTimer:(NSTimer *)_timer{
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
            status = BT40LayerStatus_PoweredOff;
            break;
        case CBCentralManagerStatePoweredOn:
            status = BT40LayerStatus_PoweredOn;
            break;
        case CBCentralManagerStateResetting:
            status = BT40LayerStatus_Resetting;
            break;
        case CBCentralManagerStateUnauthorized:
            status = BT40LayerStatus_Unauthorized;
            break;
        case CBCentralManagerStateUnknown:
            status = BT40LayerStatus_Unknown;
            break;
        case CBCentralManagerStateUnsupported:
            status = BT40LayerStatus_Unsupported;
            break;
        default:
            status = BT40LayerStatusEnd;
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
        [BLUETOOCHMANAGER addNewDevice:device];
        
    }else{
        return;
    }
}


-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    printf("已连接上设备：");
    printf("name = %s\n",[peripheral.name UTF8String]);
    
    //获取当前连接设备
    PeripheralDevice *device = [BLUETOOCHMANAGER getDeviceByPeripheral:peripheral];
    if(!device) return;
    
    peripheral.delegate = self;
    _currentDisposedDevice = device;//连接之后发现服务，服务特性扫描均在当前设备中
    
    
    if ([self.delegate respondsToSelector:@selector(didConnectedPeripheralDevice:)])
        [self.delegate didConnectedPeripheralDevice:device];
    
//    NSArray<CBUUID*>* uuids =@[[CBUUID UUIDWithString:WRITE_CHARACTERISTIC_UUID_STRING],
//                               [CBUUID UUIDWithString:READ_CHARACTERISTIC_UUID_STRING]];
    //发现服务
    dispatch_sync(dispatch_get_main_queue(), ^{
        
        [peripheral discoverServices:nil];
        printf(" -- service discovering .... \n");
        device.state = BT40DeviceState_Discovering;
        //发现超时处理
        device.discoverTimer = [NSTimer scheduledTimerWithTimeInterval:TIMEOUT_TIME_SECONDS_DISCOVER_PROCEDURE_ target:self selector:@selector(discoverTimeoutHandler:) userInfo:device repeats:NO];
    });
}


//断开回调处理
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    printf("设备 %s 已断开！\n",[peripheral.name UTF8String]);
    
    PeripheralDevice *device = _currentDisposedDevice;
    if (!device) return;
    
    device.state = BT40DeviceState_Idle;
    if ([self.delegate respondsToSelector:@selector(didDisconnectedPeripheralDevice:)])
        [self.delegate didDisconnectedPeripheralDevice:device];
    
    

    //取消操作
    [self cancelTimer:device.connectTimer];
    [self cancelTimer:device.discoverTimer];
    [self cancelTimer:device.configureTimer];
}

//连接失败回调
-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@"didFailToConnectPeripheral error:%@",error);
}

//周边蓝牙协议
#pragma mark - CBPeripheral Delegate
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    
    PeripheralDevice *device = _currentDisposedDevice;
    if(!device) return;
    
    if(error){
        NSLog(@"发现服务错误：%@",error);
        if ([self.delegate respondsToSelector:@selector(isConnectingPeripheralDevice:withState:)])
            [self.delegate isConnectingPeripheralDevice:device withState:BT40LayerResult_DiscoverFailed];
        [self disconnectWithDevice:device];
        return;
    }
    
    printf("发现周边设备的服务:\n");
    printf("==== didDiscoverServices ==== \n");

    
    for (CBService *service in peripheral.services) {
        printf("-- service : %s\n",[[service.UUID UUIDString] UTF8String]);
        dispatch_sync(dispatch_get_main_queue(), ^{
            [peripheral discoverCharacteristics:nil forService:service];
        });
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    printf("发现服务 :(%s)\n",[[service.UUID UUIDString] UTF8String]);
    
    PeripheralDevice *device = _currentDisposedDevice;
    if(!device) return;
    
    if (error) {
        NSLog(@"There is a error in peripheral:didDiscoverCharacteristicsForService:error: which called:%@",error);
        if ([self.delegate respondsToSelector:@selector(isConnectingPeripheralDevice:withState:)])
            [self.delegate isConnectingPeripheralDevice:device withState:BT40LayerResult_DiscoverFailed];
        
        [self disconnectWithDevice:device];
        return;
    }
    
    NSLog(@"service characteristics is %@",service.characteristics);
    
    printf("开始读取服务数据...\n");
    for (CBCharacteristic *characteristic in service.characteristics) {
        if (characteristic.properties & CBCharacteristicPropertyNotify) {
//            [peripheral readValueForCharacteristic:characteristic];
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
    }
    device.configureTimer = [NSTimer scheduledTimerWithTimeInterval:TIMEOUT_TIME_SECONDS_CONFIGURE_PROCEDURE_ target:self selector:@selector(configureTimeoutHandler:) userInfo:device repeats:NO];
    device.state = BT40DeviceState_Configuring;
    
}

//中心读取外设实时数据
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    printf("didUpdateNotificationStateForCharacteristic: (%s)\n",[[characteristic.UUID UUIDString] UTF8String]);
    PeripheralDevice *device = _currentDisposedDevice;
    if(!device) return;
    
    if(error){
        printf("error is : %s\n",[error.description UTF8String]);
        if ([self.delegate respondsToSelector:@selector(isConnectingPeripheralDevice:withState:)])
            [self.delegate isConnectingPeripheralDevice:device withState:BT40LayerResult_DiscoverFailed];
        
        [self disconnectWithDevice:device];
        return;
    }
    
    NSLog(@"中心读取外设实时数据");
    
    if (device.state == BT40DeviceState_Configuring) {
        
        [self cancelTimer:device.configureTimer];
        device.state = BT40DeviceState_DataReady;
        
        //回调
        if ([self.delegate respondsToSelector:@selector(isConnectingPeripheralDevice:withState:)])
            [self.delegate isConnectingPeripheralDevice:device withState:BT40LayerResult_Success];
        
        return;
    }
}

//获取外设发来的数据，不论是read和notify,获取数据都是从这个方法中读取。
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    
    if (error) {
        NSLog(@"There is a error in peripheral:didUpdateValueForCharacteristic:error: which called:%@",error);
        return;
    }
    
    NSLog(@"characteristic data is:%@ ",characteristic.value);
    NSLog(@"characteristic data length is %ld",characteristic.value.length);


    if ([self.delegate respondsToSelector:@selector(didReceivedData:fromPeripheralDevice:)]){
        [self.delegate didReceivedData:characteristic.value fromPeripheralDevice:_currentDisposedDevice];
    }
    
}

///发送完成
//用于检测中心向外设写数据是否成功
-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    NSLog(@"发送结束");
    
    if(error!=nil){
        NSLog(@"发送失败");
        if(count<3){
//        [self.delegate sendFollowWithType:0];
        }
        count++;
    }else{
        NSLog(@"发送成功");
//        [self.delegate sendFollowWithType:1];
        count=0;
    }
}





@end
