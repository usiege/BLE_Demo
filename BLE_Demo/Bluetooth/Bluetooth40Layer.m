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
#import "BleCardHandler.h"

#define BLUETOOCH_QUEUE_IDENTIFER   "com.bde.BDEWristBand.CentralQ"

#define LOCAL_DEVICE_NAMES          @"LocalDeviceID"
#define BLUETOOCHMANAGER            [BluetoochManager shareInstance]

//extern NSString* DEVICE_PARSED_DATA_KEY;
//extern NSString* DEVICE_CARD_READED_DATA_KEY;

//函数处理结果返回值
typedef NS_ENUM(NSInteger, UtilityFuncHandleResultDef) {
    UtilityFuncHandleResult_Success,
    UtilityFuncHandleResult_Existed,
    UtilityFuncHandleResult_Added,
    UtilityFuncHandleResult_Err,
    UtilityFuncHandleResultEnd
};

typedef void (^ConnectCallBack)(BT40LayerStateTypeDef state);

@interface Bluetooth40Layer ()
<CBCentralManagerDelegate,CBPeripheralDelegate>
{
    //搜索变量定义
    NSTimer*                _scanTimer;
    NSTimer*                _connectTimer;
    
    NSMutableArray*         _localDeviceNames; //保存在本地的设备名称
    
    ConnectCallBack         _connectCallBack;
}

@property (strong,nonatomic) CBCentralManager* centralManager;

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
        
        _scanTimer = nil;
        _connectTimer = nil;
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
        
        _scanTimer = [NSTimer scheduledTimerWithTimeInterval:seconds target:self selector:@selector(scanTimeoutHandler:) userInfo:nil repeats:NO];
        self.state = BT40LayerState_Searching;
    }
}


//开始链接
-(void)startConnectWithDevice:(PeripheralDevice *)device completed:(void (^)(BT40LayerStateTypeDef))callback{
    
    _connectCallBack = callback;
    self.state = BT40LayerState_Connecting;
    
    if (device.peripheral.state == CBPeripheralStateDisconnected) {
        //连接外围设备
        [_centralManager connectPeripheral:device.peripheral options:nil];
        _connectTimer = [NSTimer scheduledTimerWithTimeInterval:TIMEOUT_TIME_SECONDS_CONNECT_PROCEDURE_ target:self selector:@selector(connectTimeoutHandler:) userInfo:nil repeats:NO];
        device.stateType = PeripheralState_Disconnected;
        return;
    }else{
        //连接设备
        device.stateType = PeripheralState_Connected;
        if(_connectCallBack)
            _connectCallBack(BT40LayerState_Connecting);
        return;
    }
}

//断开蓝牙
-(void)disconnectWithDevice:(PeripheralDevice *)device{
    self.state = BT40LayerState_Connecting;
    NSLog(@"\n-- disconnect with device :%@\n",device.identifier);
    if(device && device.peripheral && device.peripheral.state != CBPeripheralStateDisconnected)
        [_centralManager cancelPeripheralConnection:device.peripheral];
}

//读卡
- (void)readDataFromPeriphralDevice:(PeripheralDevice *)device{
    _currentDisposedDevice = device;
    if (device.stateType == PeripheralState_Connected
        && device.operationType == GasCardOperation_READ
        ){
        [device.peripheral discoverServices:nil];
        printf(" -- service discovering .... \n");
    }
}

- (void)writeData:(NSData *)data toDevice:(PeripheralDevice *)device{
    _currentDisposedDevice = device;
    if (device.stateType == PeripheralState_Connected
        && device.operationType == GasCardOperation_WRITE){
        //要发送的数据，写入设备中
        [device.peripheral discoverServices:nil];
        printf(" -- service discovering .... \n");
    }
}

//发送数据
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

#pragma mark-TimeroutHandler

-(void)stopScan{
    printf("停止蓝牙扫描！ \n");
    if (_scanTimer != nil) {
        [_centralManager stopScan];
        [_scanTimer invalidate];
        _scanTimer = nil;
        self.state = BT40LayerState_Idle;
    }
}

-(void)stopConnect{
    printf("停止连接！\n");
    self.state = BT40LayerState_Idle;
    if (_connectTimer != nil) {
        [_connectTimer invalidate];
        _connectTimer = nil;
        PeripheralDevice* device = _currentDisposedDevice;
        if(device && device.peripheral && device.peripheral.state != CBPeripheralStateDisconnected){
            [_centralManager cancelPeripheralConnection:device.peripheral];
        }
    }
}


-(void)scanTimeoutHandler:(NSTimer *)_timer{
    printf("扫描已超时! \n");
    if (self.state == BT40LayerState_Searching) {
        [self stopScan];
        self.state = BT40LayerState_Idle;
    }
    [self cancelTimer:_timer];
}

-(void)connectTimeoutHandler:(NSTimer *)_timer{
    printf("连接已超时! \n");
    [self cancelTimer:_timer];
    [self stopConnect];
}


- (void)cancelTimer:(NSTimer *)_timer{
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
}


#pragma mark  Util Function
-(CBCharacteristic *)getCharacteristicOfDevice:(PeripheralDevice *)device{
    for (CBService *service in device.peripheral.services){
        if ([service.UUID isEqual:[CBUUID UUIDWithString:BUSINESS_SERVICE_UUID_STRING]]){
            for (CBCharacteristic *characteristic in service.characteristics){
                if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:WRITE_CHARACTERISTIC_UUID_STRING]]){
                    return characteristic;
                }
            }
        }
    }
    return nil;
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

    if ([self.delegate respondsToSelector:@selector(bluetoochLayer:didBluetoothStateChange:)]) {
        [self.delegate bluetoochLayer:self didBluetoothStateChange:status];
    }
    
}


//扫描到蓝牙后的回调
-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    
    printf("didDiscoverPeripheral\n");
//    NSLog(@"advertisement data is :%@",advertisementData);
    NSString* identifer = [peripheral.identifier UUIDString];
    self.state = BT40LayerState_Idle;
    
    //根据设备的UUID进行检索
    if (![_localDeviceNames containsObject:identifer]) {
        
        [_localDeviceNames addObject:identifer];
        printf("发现新设备\n");
        printf(":%s",identifer.cString);
        
        PeripheralDevice *device = [[PeripheralDevice alloc] init];
        device.stateType = PeripheralState_Disconnected;
        device.peripheral = peripheral;//重要
        device.identifier = [peripheral.identifier UUIDString];//重要
        device.rssi = RSSI;
        device.name = peripheral.name;
        device.advertisementData = advertisementData;
        [BLUETOOCHMANAGER addNewDevice:device];
        
    }else{
        [_localDeviceNames removeObject:identifer];
        return;
    }
}


//连接到蓝牙设备
-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    
    printf("已连接上外围设备：");
    printf("name = %s\n",[peripheral.name UTF8String]);
    
    //获取当前连接设备
    PeripheralDevice *device = [BLUETOOCHMANAGER getDeviceByPeripheral:peripheral];
    if(!device) return;
    device.stateType = PeripheralState_Connected;
    self.state = BT40LayerState_Connecting;
    
    peripheral.delegate = self;
    
    printf("新建蓝牙卡处理对象！\n");
    //新建卡处理器用于蓝牙卡处理
    BleCardHandler* cardHandler = [[BleCardHandler alloc] initWithPeripheralDevice:device];
    [BLUETOOCHMANAGER.cardHandlers addObject:cardHandler];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_connectCallBack){
            _connectCallBack(self.state);
        };
    });
}


//断开回调处理
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
//    printf("外围设备 %s 已断开！\n",[peripheral.name UTF8String]);
    
    NSLog(@"thread %@",[NSThread currentThread]);
    
    PeripheralDevice *device = _currentDisposedDevice;
    if (!device) return;
    device.stateType = PeripheralState_Disconnected;
    self.state = BT40LayerState_Idle;
    
    printf("删除蓝牙卡处理对象！\n");
    //删除卡处理器
    BleCardHandler* cardHandler = [BLUETOOCHMANAGER cardHandlerForPeripheralDevice:device];
    if(!cardHandler) return;
    [BLUETOOCHMANAGER.cardHandlers removeObject:cardHandler];
    
    if (_connectCallBack && peripheral.state == CBPeripheralStateDisconnected){
        _connectCallBack(self.state);
    };
}

//连接失败回调
-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@"连接蓝牙设备失败 error:%@",error);
    
    PeripheralDevice *device = _currentDisposedDevice;
    if (!device) return;
    device.stateType = PeripheralState_Disconnected;
    self.state = BT40LayerState_Idle;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_connectCallBack){
            _connectCallBack(self.state);
        };
    });
}


//周边蓝牙协议
#pragma mark - CBPeripheral Delegate
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    
    PeripheralDevice *device = [BLUETOOCHMANAGER getDeviceByPeripheral:peripheral];
    if(!device) return;
    self.state = BT40LayerState_IsAccessing;
    _currentDisposedDevice = device;//连接之后发现服务，服务特性扫描均在当前设备中
    
    if(error){
        NSLog(@"发现服务错误：%@",error);
        [self disconnectWithDevice:device];
        return;
    }
    printf("发现周边设备的服务:\n");
    
    for (CBService *service in peripheral.services) {
        printf("-- service : %s\n",[[service.UUID UUIDString] UTF8String]);
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    printf("发现服务 :(%s)\n",[[service.UUID UUIDString] UTF8String]);
    
    PeripheralDevice *device = _currentDisposedDevice;
    if(!device) return;
    self.state = BT40LayerState_IsAccessing;
    
    if (error) {
        NSLog(@"There is a error in peripheral:didDiscoverCharacteristicsForService:error: which called:%@",error);
        [self disconnectWithDevice:device];
        return;
    }
    
//    NSLog(@"service characteristics is %@",service.characteristics);
    
    printf("开始读取外围服务数据...\n");
    for (CBCharacteristic *characteristic in service.characteristics) {
        if (characteristic.properties & CBCharacteristicPropertyNotify) {
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
    }
}

//中心读取外设实时数据，该方法只调用一次
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    printf("didUpdateNotificationStateForCharacteristic: (%s)\n",[[characteristic.UUID UUIDString] UTF8String]);
    self.state = BT40LayerState_IsAccessing;
    
    //连接失败
    if(error){
        printf("error is : %s\n",[error.description UTF8String]);
        [self disconnectWithDevice:_currentDisposedDevice];
        return;
    }
    NSLog(@"蓝牙中心读取外设实时数据");
    if ([self.delegate respondsToSelector:@selector(bluetoochLayer:isConnectingPeripheralDevice:withState:)]){
        [self.delegate bluetoochLayer:self isConnectingPeripheralDevice:_currentDisposedDevice withState:BT40LayerState_IsAccessing];
    }
}
    


//读数据返回
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    printf("didUpdateValueForCharacteristic: (%s)\n",[[characteristic.UUID UUIDString] UTF8String]);
    
    //卡处理器处理数据
    BleCardHandler* cardHandler = [BLUETOOCHMANAGER cardHandlerForPeripheralDevice:_currentDisposedDevice];
    if(!cardHandler) return;
    NSLog(@"卡正在读写数据，这个过程可能会被调用多次...");
    //卡正在读取数据，这个是读取卡的过程
    [cardHandler dataProcessing:characteristic.value];
    //    NSLog(@"characteristic data is:%@ ",characteristic.value);
    NSLog(@"characteristic data length is %ld",characteristic.value.length);
    
    static int count = 0;
    NSLog(@"count  === %d",count++);
    
    
    if (error) {
        NSLog(@"There is a error in peripheral:didUpdateValueForCharacteristic:error: which called:%@",error);
        [self disconnectWithDevice:_currentDisposedDevice];
        return;
    }
    
}



//写数据返回
-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    printf("didWriteValueForCharacteristic: (%s)\n",[[characteristic.UUID UUIDString] UTF8String]);
    
    BleCardHandler* cardHandler = [BLUETOOCHMANAGER cardHandlerForPeripheralDevice:_currentDisposedDevice];
    if(!cardHandler) return;
    
    if(error!=nil){
//        NSLog(@"发送失败");
        if(count<3){
            [cardHandler sendfollow:0];
        }
        count++;
    }else{
//        NSLog(@"发送成功");
        [cardHandler sendfollow:1];
        count=0;
    }
    
    if([self.delegate respondsToSelector:@selector(bluetoochLayer:didWriteDataPeripheralDevice:error:)]){
        [self.delegate bluetoochLayer:self didWriteDataPeripheralDevice:_currentDisposedDevice error:error];
    }
}


@end
