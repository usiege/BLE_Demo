//
//  DeviceInforModel.h
//  BDEWrsitBand
//
//  Created by 王 维 on 8/13/14.
//  Copyright (c) 2014 BDE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <CoreBluetooth/CoreBluetooth.h>


/**
 *  设备状态枚举定义
 *
 */
typedef NS_ENUM(NSInteger, BT40DeviceStateTypeDef) {
    
    BT40DeviceState_Idle,            //
    BT40DeviceState_Connecting,      //
    BT40DeviceState_Discovering,     //
    BT40DeviceState_Configuring,     //
    BT40DeviceState_DataReady,       //
    BT40DeviceState_Disconnecting,   //
    BT40DeviceState_Reconnecting,    //
    
    BT40DeviceStateEnd
    
};

@interface DeviceInforModel : NSObject<NSCopying,NSCoding>


@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSString * identifier;
@property (nonatomic, strong) CBPeripheral * peripheral;
@property (nonatomic, strong) NSNumber * rssi;
@property (nonatomic, strong) NSData * manufactureData;
@property (nonatomic, strong) NSString *advertisementDataLocal;

@property (assign,nonatomic)  BT40DeviceStateTypeDef    state;

@property (nonatomic, strong) NSTimer *connectTimer;
@property (nonatomic, strong) NSTimer *discoverTimer;
@property (nonatomic, strong) NSTimer *configureTimer;

@property (assign,nonatomic)  int countOfNotiCharac;//计数设置的通知属笥

+(BOOL)checkDeviceA:(DeviceInforModel *)deviceA sameAsDeviceB:(DeviceInforModel *)deviceB;


@end
