//
//  BleCardModel.h
//  BLE_Demo
//
//  Created by 先锋电子技术 on 16/5/24.
//  Copyright © 2016年 先锋电子技术. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BleCardInfo.h"

@interface BleCardModel : NSObject

/**
 *  @brief 处理服务器返回的燃气卡数据
 *
 *  @param data 网络返回的数据
 *  @param type 卡片处理数据类型
 *  @return 解析后的结果信息
 */
+ (BleCardInfo *)parseGasCardDataWithReponseData:(NSData *)data dataType:(CardDataType)type;

@end
