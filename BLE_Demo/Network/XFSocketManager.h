//
//  XFSocketManager.h
//  BLEDataGateway
//
//  Created by 先锋电子技术 on 16/5/16.
//  Copyright © 2016年 BDE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetRefer.h"
#import "BleCardInfo.h"

typedef NS_ENUM(NSUInteger,SocketConnectType) {
    SocketConnectType_Failed,       //连接失败
    SocketConnectType_Timeout,      //连接超时
};

@protocol XFSocketDelegate;

static const NSString* METERS_OF_GAS_FOR_SENDING_KEY = @"GasAmount";

@interface XFSocketManager : NSObject

+ (XFSocketManager *)sharedManager;
@property (nonatomic,weak) id<XFSocketDelegate> delegate;

@property (nonatomic,assign)    CardDataType    dataType;
@property (nonatomic,copy)      NSString*       host;
@property (nonatomic,copy)      NSString*       port;

- (void)connectWithData:(NSData *)data userInfo:(NSDictionary *)userInfo completed:(void (^)(NSData* responseData,CardDataType dataType))callback;
- (void)stopConnect;

@end

@protocol XFSocketDelegate <NSObject>
@optional
- (void)socket:(XFSocketManager *)manager handleEvent:(SocketConnectType)event;

@end