//
//  BleCardHandler.h
//  BLE_Demo
//
//  Created by 先锋电子技术 on 16/5/19.
//  Copyright © 2016年 先锋电子技术. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 蓝牙卡片的数据读取类，卡片的数据处理过程被封装在此类中
*/

@class PeripheralDevice;
@protocol BleCardHandlerDelegate;


@interface BleCardHandler : NSObject

/**
 *  @brief 创建一个对应外围设备的读卡器
 *
 *  @param device 需要读的蓝牙卡
 *
 *  @return BleCardHandler
 */
- (instancetype)initWithPeripheralDevice:(PeripheralDevice *)device;


@property (nonatomic,weak) id<BleCardHandlerDelegate> delegate;

/**
 *  @brief 蓝牙卡对应设备信息
 */
@property (nonatomic,readonly,strong) PeripheralDevice* device;

/**
 *  @brief 开始处理蓝牙卡请求
 */
- (void)cardRequestWithCommand:(NSString *)command;

/**
 *  @brief 处理卡数据
 *
 *  @param data 蓝牙卡数据
 */
-(void)dataProcessing:(NSData*)data;

/**
 *  @brief 结束发送
 *
 *  @param type
 */
-(void)sendfollow:(int)type;
@end


@protocol BleCardHandlerDelegate <NSObject>

/**
 *  @brief 在蓝牙卡处理数据过程中发送数据
 */
- (void)bleCardHandler:(BleCardHandler *)cardHandler sendData:(NSData *)data;

/**
 *  @brief 卡片请求后的数据
 *
 *  @param data 
 */
- (void)bleCardHandler:(BleCardHandler *)cardHander didReceiveData:(NSData *)data;

@end






