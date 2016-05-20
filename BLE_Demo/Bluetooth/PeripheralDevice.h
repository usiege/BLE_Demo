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


/*
 *  状态机制枚举定义
 *  当前蓝牙逻辑层状态被分为以下:
 *  Idle            蓝牙未使用
 *  Connecting      蓝牙在与外设建立连接
 *  Discovering     蓝牙发现设备Service及Characteristic
 *  Configuring     蓝牙配置相关Service及Characteristic
 *  DataReady       蓝牙数据通路可使用
 *  Disconnecting   正在断开与外设的连接
 *  Reconnecting    正在试图与外设进行重连
 */
typedef NS_ENUM(NSInteger, BT40DeviceStateTypeDef) {
    
    BT40DeviceState_Idle,            //已断开
    BT40DeviceState_Connecting,      //已连接...
    BT40DeviceState_Discovering,     //已发现服务...
    BT40DeviceState_Configuring,     //
    BT40DeviceState_DataReady,       //
    BT40DeviceState_Disconnecting,   //
    BT40DeviceState_Reconnecting,    //
    
    BT40DeviceStateEnd
    
};

@interface PeripheralDevice : NSObject<NSCopying,NSCoding>

@property (nonatomic, strong)   CBPeripheral * peripheral;
@property (nonatomic, strong)   NSData * manufactureData;

@property (nonatomic, copy)     NSString * name;
@property (nonatomic, copy)     NSString * identifier;
@property (nonatomic,strong)    NSNumber * rssi;
@property (nonatomic,strong)    NSDictionary* advertisementData;

@property (assign,nonatomic)  BT40DeviceStateTypeDef    state;

@property (nonatomic, strong) NSTimer *connectTimer;
@property (nonatomic, strong) NSTimer *discoverTimer;
@property (nonatomic, strong) NSTimer *configureTimer;

@property (assign,nonatomic)  int countOfNotiCharac;//计数设置的通知属笥

+(BOOL)checkDeviceA:(PeripheralDevice *)deviceA sameAsDeviceB:(PeripheralDevice *)deviceB;


@end
