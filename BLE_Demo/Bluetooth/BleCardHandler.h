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

typedef NS_OPTIONS(NSUInteger,CardOperationState) {
    CardOperationState_idle = 0,
    
    CardOperationState_ReadCorrect = 1 << 0, //读卡成功 1
    CardOperationState_ReadWrong = 1 << 1,   //读卡失败 2
    
    CardOperationState_Checkouted = 1 << 2,      //已校验密码 4
    CardOperationState_Written = 1 << 3,         //数据已写入成功 8
    CardOperationState_ChangedPass = 1 << 4,     //已修改密码
};

typedef void (^CardRequestBlock)(NSData* receiveData,CardOperationState state);
typedef void (^CardWrittenBlock)(NSData* receiveData,CardOperationState state);

@interface BleCardHandler : NSObject

/**
 *  @brief 创建一个对应外围设备的读卡器
 *
 *  @param device 需要读的蓝牙卡
 *
 *  @return BleCardHandler
 */
- (instancetype)initWithPeripheralDevice:(PeripheralDevice *)device;

/**
 *  @brief 卡片发送是否结束
 */
@property (assign,nonatomic)  BOOL  sendEnded;

/**
 *  @brief 卡片操作状态
 */
@property (nonatomic,assign) CardOperationState currentState;

/**
 *  @brief 收到的数据
 */
@property (nonatomic,strong,readonly) NSData* receiveData;
/**
 *  @brief 蓝牙卡对应设备信息
 */
@property (nonatomic,readonly,strong) PeripheralDevice* device;

/**
 *  @brief 开始处理蓝牙卡请求
 */
- (void)cardRequestWithCommand:(NSString *)command
                     completed:(void(^)(NSData* receiveData,CardOperationState state))callback;

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
-(void)sendfollowing:(int)type;

@end






