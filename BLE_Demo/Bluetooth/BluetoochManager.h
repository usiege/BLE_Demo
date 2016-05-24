//
//  BluetoochManager.h
//  BLE_Demo
//
//  Created by 先锋电子技术 on 16/5/18.
//  Copyright © 2016年 先锋电子技术. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CBPeripheral;
@class PeripheralDevice;
@protocol BluetoochDelegate;

/*
 *蓝牙连接管理器
 1.缓存已发现的设备;
 2.搜索蓝牙设备；
 3.蓝牙连接、断开；
 4.获取搜索到的蓝牙设备；
 5.删除蓝牙设备；
*/

@interface BluetoochManager : NSObject

+ (instancetype)shareInstance;

@property (nonatomic,weak)      id<BluetoochDelegate> delegate;
@property (nonatomic,strong)    NSMutableArray* seekedDevices;
@property (nonatomic,strong) NSMutableData*         resultData;

- (PeripheralDevice *)getDeviceByPeripheral:(CBPeripheral *)peripheral;
- (PeripheralDevice *)getDeviceByIdentifer:(NSString *)deviceID;
- (void)addNewDevice:(PeripheralDevice *)dm;
- (void)removeDevice:(PeripheralDevice *)dm;
- (void)remoeAllDevices;

/*
 * 开始搜索周边外围设备
 * date 搜索结束时刻
 */
- (void)startSearchPeriphralsUntil:(NSDate *)date;

//停止搜索
- (void)stopSearchPeriphrals;

/*
 * 与外围设备建立连接
 */
- (void)startConnectPeriphralDevice:(PeripheralDevice *)pDevice;

/*
 * 与外围设备断开连接
 */
- (void)stopConectPeriphralDevice:(PeripheralDevice *)pDevice;

@end

@protocol BluetoochDelegate <NSObject>

//发现新的外围设备时
- (void)didFoundNewPerigheralDevice:(PeripheralDevice *)device;

//接收到处理后的数据
- (void)didReceiveDisposedData:(NSData *)data fromDevice:(PeripheralDevice *)device;

@end

