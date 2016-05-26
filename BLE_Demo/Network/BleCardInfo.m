//
//  BleCardInfo.m
//  BLE_Demo
//
//  Created by 先锋电子技术 on 16/5/24.
//  Copyright © 2016年 先锋电子技术. All rights reserved.
//

#import "BleCardInfo.h"

@interface BleCardInfo ()

@end


@implementation BleCardInfo


//- (instancetype)initWithData:(NSData *)data{
//    if (self = [super init]) {
//        
//    }
//    return self;
//}


- (instancetype)initWithData:(NSData *)data type:(CardDataType)type{
    if (self = [super init]) {
        
    }
    return self;
}



- (NSString *)description{
    NSMutableString* desIwish = [NSMutableString string];
    if (self.dataType == GasCardDataType_READ) {
        [desIwish appendString:[NSString stringWithFormat:@"%@/",self.retCode]];
        [desIwish appendString:[NSString stringWithFormat:@"%@/",self.cardType]];
        [desIwish appendString:[NSString stringWithFormat:@"%@/",self.gases]];
        [desIwish appendString:[NSString stringWithFormat:@"%@/",self.userID]];
        [desIwish appendString:[NSString stringWithFormat:@"%@/",self.username]];
        [desIwish appendString:[NSString stringWithFormat:@"%@/",self.userAddr]];
        [desIwish appendString:[NSString stringWithFormat:@"%@/",self.userDesc]];
        [desIwish appendString:[NSString stringWithFormat:@"%@/",self.userSta]];
        [desIwish appendString:[NSString stringWithFormat:@"%@/",self.price]];
        [desIwish appendString:[NSString stringWithFormat:@"%@/",self.maxPurchase]];
        [desIwish appendString:[NSString stringWithFormat:@"%@/",self.minPurchase]];
    }else if (self.dataType == GasCardDataType_WRITE){
        [desIwish appendString:[NSString stringWithFormat:@"%@/",self.retCode]];
        [desIwish appendString:[NSString stringWithFormat:@"%@/",self.transDate]];
        [desIwish appendString:[NSString stringWithFormat:@"%@/",self.transTime]];
        [desIwish appendString:[NSString stringWithFormat:@"%@/",self.comSeq]];
        [desIwish appendString:[NSString stringWithFormat:@"%@/",self.cardType]];
        [desIwish appendString:[NSString stringWithFormat:@"%@/",self.userID]];
        [desIwish appendString:[NSString stringWithFormat:@"%@/",self.username]];
        [desIwish appendString:[NSString stringWithFormat:@"%@/",self.userDesc]];
        [desIwish appendString:[NSString stringWithFormat:@"%@/",self.amount]];
        [desIwish appendString:[NSString stringWithFormat:@"%@/",self.purchaseCount]];
        [desIwish appendString:[NSString stringWithFormat:@"%@/",self.pwLength]];
        [desIwish appendString:[NSString stringWithFormat:@"%@/",self.verifyPw]];
        [desIwish appendString:[NSString stringWithFormat:@"%@/",self.pwNew]];
        [desIwish appendString:[NSString stringWithFormat:@"%@/",self.offset]];
        [desIwish appendString:[NSString stringWithFormat:@"%@/",self.wrLength]];
        [desIwish appendString:[NSString stringWithFormat:@"%@/",self.dataBuf]];
    }
    return desIwish;
}

@end
