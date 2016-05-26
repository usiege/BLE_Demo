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
 *  @brief 外围设备连接状态
 */
typedef NS_ENUM(NSUInteger,PeripheralStateType) {
    /**
     *  已连接上
     */
    PeripheralState_Connected = 1,
    /**
     *  未连接
     */
    PeripheralState_Disconnected,
};

//typedef BOOL PeripheralStateType;

/**
 *  @brief 蓝牙卡操作类型
 */
typedef NS_ENUM(NSUInteger,PeripheralOperationType) {
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

@property (nonatomic,assign)    PeripheralStateType         stateType;      //外围设备状态类型
@property (nonatomic,assign)    PeripheralOperationType     operationType;  //外围设置操作类型

@property (nonatomic,copy)      NSString*       checkKey;      //写数据校验密码
@property (nonatomic,copy)      NSString*       checkKeyNew;   //写数据校验新密码

+(BOOL)checkDeviceA:(PeripheralDevice *)deviceA sameAsDeviceB:(PeripheralDevice *)deviceB;


@end
