//
//  BleCardInfo.h
//  BLE_Demo
//
//  Created by 先锋电子技术 on 16/5/24.
//  Copyright © 2016年 先锋电子技术. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger,CardDataType) {
    GasCardDataType_READ = 100,
    GasCardDataType_WRITE = 101
};

@interface BleCardInfo : NSObject

@property (nonatomic,copy) NSString*    retCode;//返回码
@property (nonatomic,copy) NSString*    cardType;//卡类型
@property (nonatomic,copy) NSString*    gases;//卡面气量
@property (nonatomic,copy) NSString*    userID;//用户ID
@property (nonatomic,copy) NSString*    username;//用户名称
@property (nonatomic,copy) NSString*    userAddr;//用户地址
@property (nonatomic,copy) NSString*    userDesc;//用户（用气）性质
@property (nonatomic,copy) NSString*    userSta;//用户状态
@property (nonatomic,copy) NSString*    price;//购气单价
@property (nonatomic,copy) NSString*    maxPurchase;//最大可购气量
@property (nonatomic,copy) NSString*    minPurchase;//最小可购气量

@property (nonatomic,copy) NSString*    transDate;//交易获申请日期
@property (nonatomic,copy) NSString*    transTime;//交易获申请时间
@property (nonatomic,copy) NSString*    comSeq;//公司顺序号
@property (nonatomic,copy) NSString*    amount;//购气金额
@property (nonatomic,copy) NSString*    purchaseCount;//购气次数
@property (nonatomic,copy) NSString*    pwLength;//密码长度
@property (nonatomic,copy) NSString*    verifyPw;//写保护密码
@property (nonatomic,copy) NSString*    pwNew;//新密码
@property (nonatomic,copy) NSString*    offset;//写卡起始地址
@property (nonatomic,copy) NSString*    wrLength;//写卡长度
@property (nonatomic,copy) NSString*    dataBuf;//写卡数据

@property (nonatomic,assign) CardDataType dataType;//卡片数据类型（服务器有关）

@end