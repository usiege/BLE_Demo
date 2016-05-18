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

static NSInteger CARD_4442 = 8;
static NSString* CARD_READ_4442 = @"010100";
static NSString* CARD_WRITE_4442 = @"010200";
static NSString* CARD_CHECKPASS_4442 = @"01030000";
static NSString* CARD_CHANGEPASS_4442 = @"01050000";

static XFBluetoochManager* _bluetoochManager = nil;

@interface XFBluetoochManager ()
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
    NSString* UUID = device.UUID;
    BOOL thereis = NO;
    for (PeripheralDevice* device in _seekedDevices) {
        if ([UUID isEqualToString:device.UUID]) {
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


@end