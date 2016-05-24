//
//  XFSocketManager.h
//  BLEDataGateway
//
//  Created by 先锋电子技术 on 16/5/16.
//  Copyright © 2016年 BDE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetRefer.h"

@protocol XFSocketDelegate;
@interface XFSocketManager : NSObject

+ (XFSocketManager *)sharedManager;
@property (nonatomic,weak) id<XFSocketDelegate> delegate;

- (void)connectHostWithIP:(NSString *)host port:(NSString *)port data:(NSData *)data completed:(void (^)(NSData* data))callback;

@end

@protocol XFSocketDelegate <NSObject>

/**
 *  @brief socket可以发送字节
 */
- (void)socketEventHasSpaceAvailable;

@end