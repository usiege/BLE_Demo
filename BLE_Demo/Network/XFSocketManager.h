//
//  XFSocketManager.h
//  BLEDataGateway
//
//  Created by 先锋电子技术 on 16/5/16.
//  Copyright © 2016年 BDE. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol XFSocketDelegate;
@interface XFSocketManager : NSObject

+ (XFSocketManager *)sharedManager;

- (void)connectHostWithIP:(NSString *)host port:(NSString *)port completed:(void(^)(NSData * responseData))callback;

@end

@protocol XFSocketDelegate <NSObject>


@end