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

@protocol XFSocketDelegate;
@interface XFSocketManager : NSObject

+ (XFSocketManager *)sharedManager;
@property (nonatomic,weak) id<XFSocketDelegate> delegate;

@property (nonatomic,assign)    CardDataType    dataType;
@property (nonatomic,copy)      NSString*       host;
@property (nonatomic,copy)      NSString*       port;

- (void)connectWithData:(NSData *)data userInfo:(NSDictionary *)userInfo completed:(void (^)(NSData* responseData,CardDataType dataType))callback;

@end

@protocol XFSocketDelegate <NSObject>

/**
 *  @brief socket可以发送字节
 */
- (void)socketEventHasSpaceAvailable;

@end