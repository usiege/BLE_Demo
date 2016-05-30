//
//  Bluetooth40Layer.h
//  BDEWrsitBand
//
//  Created by 王 维 on 8/12/14.
//  Copyright (c) 2014 BDE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>


/*
 定义一些模块用类型
 */

/*
 *  蓝牙状态枚举定义
 */

typedef NS_ENUM(NSInteger, BT40LayerStatusTypeDef) {

    BT40LayerStatus_Unknown             = 0x00,
	BT40LayerStatus_Resetting           = 0x01,
	BT40LayerStatus_Unsupported         = 0x02,
	BT40LayerStatus_Unauthorized        = 0x03,
	BT40LayerStatus_PoweredOff          = 0x04,
	BT40LayerStatus_PoweredOn           = 0x05,
    
    BT40LayerStatusEnd
};


/*
 * 蓝牙连接过程状态
 */
typedef NS_ENUM(NSInteger, BT40LayerStateTypeDef) {
    
    BT40LayerState_Idle,            //无状态
    
    BT40LayerState_Searching,       //正在查找
    BT40LayerState_Connecting,      //蓝牙与外围设备正在连接状态
    BT40LayerState_ConnectFailed,   //蓝牙连接失败
    BT40LayerState_IsAccessing,     //蓝牙设备正在存取

};

@class PeripheralDevice;
//代理声明
@protocol Bluetooth40LayerDelegate;


/*
 *  类名 Bluetooth40Layer
 *  描述 封装与蓝牙4.0进行的各种操作，如搜索，连接，发现服务，数据交互等，使用单例模式，资源共享
 */

@interface Bluetooth40Layer : NSObject 
{
    int count;
    int pagecou;
}

@property (nonatomic,assign)        id<Bluetooth40LayerDelegate>    delegate;
@property (nonatomic,assign)        BT40LayerStateTypeDef state;    //蓝牙连接的状态

+ (instancetype)sharedInstance;//单例模式静态接口
+ (PeripheralDevice *)currentDisposedDevice;//返回当前正在处理的设备

/*      
 *      函数名称:   startScan
 *      功能描述:   开始搜索设备
 *      返回值:     无
 *      参数:  @seconds   搜索时长多少，如果此值为0，代表一直搜索
 */
-(void)startScan:(NSTimeInterval)seconds withServices:(NSString *)service;

/*
 *      函数名称:   stopScan
 *      功能描述:   停止搜索设备
 *      返回值:     无
 *      参数:      无
 */

-(void)stopScan;

/*
 *      函数名称:   startConnectWithDevice
 *      功能描述:   与设备建立数据连接
 *      返回值:     无
 *      参数:      建立数据通道的设备
 *      参见:
 */
-(void)startConnectWithDevice:(PeripheralDevice *)device completed:(void(^)(BT40LayerStateTypeDef state))callback;

/**
 *  @brief 断开连接
 */
-(void)stopConnect;
/**
 *  @brief 读取外围设备数据外围设备的服务
 *
 *  @param device 外围设备
 */
- (void)readDataFromPeriphralDevice:(PeripheralDevice *)device;

/**
 *  @brief 向外围设备写入数据
 *
 *  @param data   要写入的数据
 *  @param device 要写入的设备
 */
- (void)writeData:(NSData *)data toDevice:(PeripheralDevice *)device;

/*
 *      函数名称:    sendData:toDevice:
 *      功能描述:    发送数据
 *      返回值:      是否发送成功
 *      参数:        向设备发送数据
 *      参见:
 */
-(BOOL)sendData:(NSData *)data toDevice:(PeripheralDevice *)device;

/*
 *      函数名称:   disconnecDataChannelWithDevice
 *      功能描述:   断开数据通道,应用层断开逻辑连接。因平台特性，已经绑定的设备，数据链路断不掉，而逻辑链路可以断掉
 *      返回值:     无
 *      参数:      建立了数据通道的设备类
 *      参见:
 */
-(void)disconnectWithDevice:(PeripheralDevice *)device;


@end

/*
 *      协议声明
 */


@protocol Bluetooth40LayerDelegate <NSObject>

@optional

/*
 * 发现新的外围设备时
 */
- (void)bluetoochLayer:(Bluetooth40Layer *)bluetoochLayer didFoundNewPerigheralDevice:(PeripheralDevice *)device;


@optional

/*
 *  描述: 当蓝牙状态改变时，接口返回状态值
 *
 *  参见: 
 */
-(void)bluetoochLayer:(Bluetooth40Layer *)bluetoochLayer didBluetoothStateChange:(BT40LayerStatusTypeDef)btStatus;



/****************************************************/

/**
 *  @brief 正在与外围设备连接中
 *
 *  @param bluetoochLayer
 *  @param device         连接中的设备
 *  @param state          蓝牙层连接状态
 */
-(void)bluetoochLayer:(Bluetooth40Layer *)bluetoochLayer isConnectingPeripheralDevice:(PeripheralDevice *)device withState:(BT40LayerStateTypeDef)state;


/**
 *  @brief 向外围设置中写入数据成功会调用此函数，
 *
 *  @param device 要写入的设备
 *  @param error  error会包含写入失败的信息
 */
- (void)bluetoochLayer:(Bluetooth40Layer *)bluetoochLayer didWriteDataPeripheralDevice:(PeripheralDevice *)device error:(NSError *)error;

@required


@end





