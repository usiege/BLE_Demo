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
 *  Connected       已经建立连接
 *  Disconnecting   正在断开与外设的连接
 
 *  Discovering     蓝牙发现设备Service及Characteristic
 *  Configuring     蓝牙配置相关Service及Characteristic
 
 */
//typedef NS_ENUM(NSInteger, BT40DeviceStateTypeDef) {
//    
//    BT40DeviceState_Idle,            //
//    
////    BT40DeviceState_Connecting,      //
////    BT40DeviceState_Connected,       //
////    BT40DeviceState_Disconnecting,   //
////    
////    BT40DeviceState_Discovering,     //
////    BT40DeviceState_Configuring,     //
//    
////    BT40DeviceState_Reconnecting,    //
//    
//    BT40DeviceStateEnd
//};

/**
 *  @brief 蓝牙卡操作类型
 */
typedef NS_ENUM(NSUInteger,CardOperationType) {
    /**
     *  燃气卡读操作
     */
    GasCardOperation_READ = 1,
    /**
     *  燃气卡写操作
     */
    GasCardOperation_WRITE,
    
    CardOperation_Idle
};

@interface PeripheralDevice : NSObject<NSCopying,NSCoding>

@property (nonatomic, strong)   CBPeripheral * peripheral;
@property (nonatomic, strong)   NSData * manufactureData;

@property (nonatomic, copy)     NSString * name;
@property (nonatomic, copy)     NSString * identifier;
@property (nonatomic,strong)    NSNumber * rssi;
@property (nonatomic,strong)    NSDictionary* advertisementData;


@property (nonatomic, strong)   NSTimer *connectTimer;
@property (nonatomic, strong)   NSTimer *discoverTimer;


@property (nonatomic,assign)    CardOperationType  operationType; //外围设置操作类型
@property (nonatomic,copy)      NSString*       checkKey;      //写数据校验密码
@property (nonatomic,copy)      NSString*       checkKeyNew;   //写数据校验新密码

+(BOOL)checkDeviceA:(PeripheralDevice *)deviceA sameAsDeviceB:(PeripheralDevice *)deviceB;


@end
