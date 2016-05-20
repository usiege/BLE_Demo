//
//  BluetoochManager.m
//  BLE_Demo
//
//  Created by 先锋电子技术 on 16/5/18.
//  Copyright © 2016年 先锋电子技术. All rights reserved.
//

#import "XFBluetoochManager.h"
#import "PeripheralDevice.h"
#import "Bluetooth40Layer.h"

#import "BLEManageController.h"

static XFBluetoochManager* _bluetoochManager = nil;

@interface XFBluetoochManager () <Bluetooth40LayerDelegate>
{
    Bluetooth40Layer* _sharedBluetoothLayer;
}

@end

@implementation XFBluetoochManager

+ (instancetype)shareInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _bluetoochManager = [[XFBluetoochManager alloc] init];
    });
    return _bluetoochManager;
}

- (instancetype)init{
    if (self = [super init]) {
        _seekedDevices = [NSMutableArray array];
        _sharedBluetoothLayer = [Bluetooth40Layer sharedInstance];
        _sharedBluetoothLayer.delegate = self;
        
    }
    
    return self;
}

- (void)startSearchPeriphralsUntil:(NSDate *)date{
    NSTimeInterval time = [date timeIntervalSinceDate:[NSDate date]];
    NSLog(@"interval time is :%f",time);
    [_sharedBluetoothLayer startScan:time withServices:nil];
}

- (void)stopSearchPeriphrals{
    [_sharedBluetoothLayer stopScan];
}

- (void)startConnectPeriphralDevice:(PeripheralDevice *)pDevice{
    [_sharedBluetoothLayer createDataChannelWithDevice:pDevice];
}

- (void)stopConectPeriphralDevice:(PeripheralDevice *)pDevice{
    [_sharedBluetoothLayer disconnectWithDevice:pDevice];
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

- (void)isConnectingPeripheralDevice:(PeripheralDevice *)device withState:(BT40LayerResultTypeDef)state{
    
    BLEManageController* Public_BleController = [BLEManageController sharedInstance];
    Public_BleController.actionsort=12;
    Public_BleController.requesetcount=1;
    [Public_BleController actionreadandwrite];
}


@end