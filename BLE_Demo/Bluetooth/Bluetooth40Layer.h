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
 *  结果枚举定义
 *  代理返回的各结果值
 *
 */

typedef NS_ENUM(NSInteger, BT40LayerResultTypeDef) {

    //成功
    BT40LayerResult_Success,
    
    //连接过程结果
    BT40LayerResult,
    BT40LayerResult_ConnectFailed,
    BT40LayerResult_DiscoverFailed,
    BT40LayerResult_ConfigureFailed,
    
    
    BT40LayerResultTypeEnd
};


/*
 *  状态机制枚举定义
 *  当前蓝牙逻辑层状态被分为以下:
 *  Idle            蓝牙未使用
 *  Searching       蓝牙在搜索
 *  Connecting      蓝牙在与外设建立连接
 *  Discovering     蓝牙发现设备Service及Characteristic
 *  Configuring     蓝牙配置相关Service及Characteristic
 *  DataReady       蓝牙数据通路可使用
 *  Disconnecting   正在断开与外设的连接
 *  Reconnecting    正在试图与外设进行重连
 */
typedef NS_ENUM(NSInteger, BT40LayerStateTypeDef) {
    
    BT40LayerState_Idle,            //
    BT40LayerState_Searching,       //
    
    BT40LayerStateEnd

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
@property (nonatomic,assign)        BT40LayerStateTypeDef state;

@property (strong,nonatomic)        CBCentralManager* _CM;


//单例模式静态接口
+(instancetype)sharedInstance;

+ (PeripheralDevice *)currentDisposedDevice;
//@property (nonatomic,strong)        PeripheralDevice* currentDisposedDevice;

//实例接口


/*      函数名称:   fetchConnectedDevices
 *      功能描述:   获取已经与系统连接的外设，但是如果要进行数据交互，需要通过createDataChannelWithDevice与其建立数据通道
 *      返回值:     查看DeviceInforModel.h
 *      参数无
 */
//-(NSArray *)fetchConnectedDevices;


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
 *      函数名称:   createDataChannelWithDevice
 *      功能描述:   与设备建立数据通道
 *      返回值:     无
 *      参数:      建立数据通道的设备
 *      参见:
 */
-(void)createDataChannelWithDevice:(PeripheralDevice *)device;



/*
 *      函数名称:   sendData:toDevice:
 *      功能描述:   发送数据
 *      返回值:     是否发送成功
 *      参数:      向设备发送数据
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

-(void)startConnectWithDevice:(PeripheralDevice *)device;

@end




/*
 *      协议声明
 */


@protocol Bluetooth40LayerDelegate <NSObject>

@optional

/*
 * 发现新的外围设备
 */
- (void)didFoundNewPerigheralDevice:(PeripheralDevice *)device;

/*
 * 
 */


@optional

-(void)automoticConnect;

/*
 *  描述: 当蓝牙状态改变时，接口返回状态值
 *
 *  参见: 
 */
-(void)didBluetoothStateChange:(BT40LayerStatusTypeDef)btStatus;

/*
 *  描述: 发现设备代理接口
 *
 *  参见: startScan:withServices:
 *
 */
-(void)didFoundDevice:(PeripheralDevice *)device;

/*
 *  描述: 创建数据通道时，代理反馈结果接口
 *
 *  参见: createDataChannelWithDevice
 */
-(void)didCreateDataChannelWithDevice:(PeripheralDevice *)device withResult:(BT40LayerResultTypeDef)result;

/*
 *  描述: 数据通道接收到数据时的处理接口
 *
 *
 */
-(void)didReceivedData:(NSData *)data fromChannelWithDevice:(PeripheralDevice *)device;

-(void)didReceivedData:(NSData *)data fromChannelWithPeripheral:(CBPeripheral *)peripheral;

/*
 *  描述: 当与设备的连接断开时的处理接口
 *
 *  有可能是被动断开，有可能是主动断开
 *
 */
-(void)didDisconnectWithDevice:(PeripheralDevice *)device;


@required



@end





