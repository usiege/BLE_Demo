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
@class BleCardHandler;

@protocol BluetoochDelegate;
@protocol BleCardHandlerDelegate;

/*
 *蓝牙连接管理器
 1.缓存已发现的设备;
 2.搜索蓝牙设备；
 3.蓝牙连接、断开；
 4.获取搜索到的蓝牙设备；
 5.删除蓝牙设备；
*/

@interface BluetoochManager : NSObject <BleCardHandlerDelegate>

+ (instancetype)shareInstance;

@property (nonatomic,weak)      id<BluetoochDelegate> delegate;
@property (nonatomic,strong)    NSMutableArray* seekedDevices;
@property (nonatomic,strong)    NSMutableArray* cardHandlers;


- (void)addNewDevice:(PeripheralDevice *)dm;
- (void)removeDevice:(PeripheralDevice *)dm;
- (void)remoeAllDevices;

- (PeripheralDevice *)getDeviceByIdentifer:(NSString *)deviceID;
- (PeripheralDevice *)getDeviceByPeripheral:(CBPeripheral *)peripheral;
- (BleCardHandler *)cardHandlerForPeripheralDevice:(PeripheralDevice *)device;
/*
 * 开始搜索周边外围设备
 * date 搜索结束时刻
 */
- (void)startSearchPeriphralsUntil:(NSDate *)date;

/**
 *  @brief 停止搜索
 */
- (void)stopSearchPeriphrals;

/**
 *  @brief 从外围设备中读数据
 *
 *  @param pDevice 外围设备
 */
- (void)readDataFromPeriphralDevice:(PeripheralDevice *)pDevice;

/**
 *  @brief 向外围设备中写数据
 *
 *  @param dataString 要写入的信息
 *  @param pDevice    要写入的设备
 */
- (void)writeData:(NSData *)data toPeriphralDevice:(PeripheralDevice *)pDevice;

@end

@protocol BluetoochDelegate <NSObject>

/**
 *  @brief 发现了新的蓝牙设备
 *
 *  @param device 外围设备
 */
- (void)bluetoochManager:(BluetoochManager *)manager didFoundNewPerigheralDevice:(PeripheralDevice *)device;


/**
 *  @brief <#Description#>
 *
 *  @param manager   <#manager description#>
 *  @param data      <#data description#>
 *  @param device    <#device description#>
 *  @param isSuccess <#isSuccess description#>
 */
- (void)bluetoochManager:(BluetoochManager *)manager didEndReadWithResponseData:(NSData *)data fromDevice:(PeripheralDevice *)device result:(BOOL)isSuccess;


/**
 *  @brief <#Description#>
 *
 *  @param manager   <#manager description#>
 *  @param data      <#data description#>
 *  @param device    <#device description#>
 *  @param isSuccess <#isSuccess description#>
 */
- (void)bluetoochManager:(BluetoochManager *)manager didEndWriteWithResponseData:(NSData *)data fromDevice:(PeripheralDevice *)device result:(BOOL)isSuccess;

@end

