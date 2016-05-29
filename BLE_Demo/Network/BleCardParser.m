//
//  BleCardModel.m
//  BLE_Demo
//
//  Created by 先锋电子技术 on 16/5/24.
//  Copyright © 2016年 先锋电子技术. All rights reserved.
//

#import "BleCardParser.h"
#import "ConverUtil.h"
#import <objc/runtime.h>

@interface BleCardParser ()
{
    
}
@end

@implementation BleCardParser


+ (BleCardInfo *)parseGasCardDataWithReponseData:(NSData *)data dataType:(CardDataType)type{
    BleCardInfo* info = [[BleCardInfo alloc] init];
    if (type == GasCardDataType_READ) {
        
        info.dataType = GasCardDataType_READ;
        
        if(data.length < 213+12) return info;
        
        NSRange readCardSubRanges[11] = {
            
            NSMakeRange(5, 4),
            NSMakeRange(9, 2),
            NSMakeRange(11, 4),
            NSMakeRange(15, 16),
            NSMakeRange(31, 64),
            NSMakeRange(95, 64),
            NSMakeRange(159, 32),
            NSMakeRange(191, 4),
            NSMakeRange(195, 6),
            NSMakeRange(201, 12),
            NSMakeRange(213, 12)
            
        };
        
        info.retCode = [[NSString alloc] initWithData:[data subdataWithRange:readCardSubRanges[0]] encoding:NSUTF8StringEncoding];
        info.retCode = [info.retCode stringByReplacingOccurrencesOfString:@" " withString:@""];
        info.cardType = [[NSString alloc] initWithData:[data subdataWithRange:readCardSubRanges[1]] encoding:NSUTF8StringEncoding];
        info.cardType = [info.cardType stringByReplacingOccurrencesOfString:@" " withString:@""];
        info.gases = [[NSString alloc] initWithData:[data subdataWithRange:readCardSubRanges[2]] encoding:NSUTF8StringEncoding];
        info.gases = [info.gases stringByReplacingOccurrencesOfString:@" " withString:@""];
        info.userID = [[NSString alloc] initWithData:[data subdataWithRange:readCardSubRanges[3]] encoding:NSUTF8StringEncoding];
        info.userID = [info.userID stringByReplacingOccurrencesOfString:@" " withString:@""];
        
        //Gbk编码
        NSStringEncoding encode = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
        info.username = [[NSString alloc] initWithData:[data subdataWithRange:readCardSubRanges[4]] encoding:encode];
        info.username = [info.username stringByReplacingOccurrencesOfString:@" " withString:@""];
        info.userAddr = [[NSString alloc] initWithData:[data subdataWithRange:readCardSubRanges[5]] encoding:encode];
        info.userAddr = [info.userAddr stringByReplacingOccurrencesOfString:@" " withString:@""];
        info.userDesc = [[NSString alloc] initWithData:[data subdataWithRange:readCardSubRanges[6]] encoding:encode];
        info.userDesc = [info.userDesc stringByReplacingOccurrencesOfString:@" " withString:@""];;
        
        info.userSta = [[NSString alloc] initWithData:[data subdataWithRange:readCardSubRanges[7]] encoding:NSUTF8StringEncoding];
        info.userSta = [info.userSta stringByReplacingOccurrencesOfString:@" " withString:@""];
        info.price = [[NSString alloc] initWithData:[data subdataWithRange:readCardSubRanges[8]] encoding:NSUTF8StringEncoding];
        info.price = [info.price stringByReplacingOccurrencesOfString:@" " withString:@""];
        info.maxPurchase = [[NSString alloc] initWithData:[data subdataWithRange:readCardSubRanges[9]] encoding:NSUTF8StringEncoding];
        info.maxPurchase = [info.maxPurchase stringByReplacingOccurrencesOfString:@" " withString:@""];
        info.minPurchase = [[NSString alloc] initWithData:[data subdataWithRange:readCardSubRanges[10]] encoding:NSUTF8StringEncoding];
        info.minPurchase = [info.minPurchase stringByReplacingOccurrencesOfString:@" " withString:@""];
        
//        unsigned int count;
//        objc_property_t *properties = class_copyPropertyList([BleCardInfo class], &count);
//        for(int i = 0; i < count; i++)
//        {
//            objc_property_t property = properties[i];
//            
//            NSLog(@"name:%s",property_getName(property));
//            NSLog(@"value:%@",[info valueForKey:[NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding]]);
//            
//        }
//        free(properties);
        
    }
    else if (type == GasCardDataType_WRITE){
        
        info.dataType = GasCardDataType_WRITE;
        
        if(data.length < 167+512) return info;
        
        NSRange writeCardSubRanges[16] = {
            
            NSMakeRange(5, 4),
            NSMakeRange(9, 8),
            NSMakeRange(17, 4),
            NSMakeRange(21, 8),
            NSMakeRange(29, 2),
            NSMakeRange(31, 16),
            NSMakeRange(47, 64),
            NSMakeRange(111, 2),
            NSMakeRange(113, 8),
            NSMakeRange(121, 6),
            NSMakeRange(127, 2),
            NSMakeRange(129, 16),
            NSMakeRange(145, 16),
            NSMakeRange(161, 4),
            NSMakeRange(165, 2),
            NSMakeRange(167, 512),
            
        };
        
        info.retCode = [[NSString alloc] initWithData:[data subdataWithRange:writeCardSubRanges[0]] encoding:NSUTF8StringEncoding];
        info.transDate = [[NSString alloc] initWithData:[data subdataWithRange:writeCardSubRanges[1]] encoding:NSUTF8StringEncoding];
        info.transTime = [[NSString alloc] initWithData:[data subdataWithRange:writeCardSubRanges[2]] encoding:NSUTF8StringEncoding];
        info.comSeq = [[NSString alloc] initWithData:[data subdataWithRange:writeCardSubRanges[3]] encoding:NSUTF8StringEncoding];
        
        info.cardType = [[NSString alloc] initWithData:[data subdataWithRange:writeCardSubRanges[4]] encoding:NSUTF8StringEncoding];
        info.userID = [[NSString alloc] initWithData:[data subdataWithRange:writeCardSubRanges[5]] encoding:NSUTF8StringEncoding];
        info.userID = [info.userID stringByReplacingOccurrencesOfString:@" " withString:@""];
        
        //Gbk编码
        NSStringEncoding encode = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
        info.username = [[NSString alloc] initWithData:[data subdataWithRange:writeCardSubRanges[6]] encoding:encode];
        info.username = [info.username stringByReplacingOccurrencesOfString:@" " withString:@""];
        
        info.userDesc = [[NSString alloc] initWithData:[data subdataWithRange:writeCardSubRanges[7]] encoding:NSUTF8StringEncoding];
        
        info.amount = [[NSString alloc] initWithData:[data subdataWithRange:writeCardSubRanges[8]] encoding:NSUTF8StringEncoding];
        info.amount = [info.amount stringByReplacingOccurrencesOfString:@" " withString:@""];
        
        info.purchaseCount = [[NSString alloc] initWithData:[data subdataWithRange:writeCardSubRanges[9]] encoding:NSUTF8StringEncoding];
        info.purchaseCount = [info.purchaseCount stringByReplacingOccurrencesOfString:@" " withString:@""];
        
        info.pwLength = [[NSString alloc] initWithData:[data subdataWithRange:writeCardSubRanges[10]] encoding:NSUTF8StringEncoding];
        info.pwLength = [info.pwLength stringByReplacingOccurrencesOfString:@" " withString:@""];
        
        info.verifyPw = [[NSString alloc] initWithData:[data subdataWithRange:writeCardSubRanges[11]] encoding:NSUTF8StringEncoding];
        info.verifyPw = [info.verifyPw stringByReplacingOccurrencesOfString:@" " withString:@""];
        
        info.pwNew = [[NSString alloc] initWithData:[data subdataWithRange:writeCardSubRanges[12]] encoding:NSUTF8StringEncoding];
        info.pwNew = [info.pwNew stringByReplacingOccurrencesOfString:@" " withString:@""];
        
        info.offset = [[NSString alloc] initWithData:[data subdataWithRange:writeCardSubRanges[13]] encoding:NSUTF8StringEncoding];
        info.wrLength = [[NSString alloc] initWithData:[data subdataWithRange:writeCardSubRanges[14]] encoding:NSUTF8StringEncoding];
        
        info.dataBuf = [[NSString alloc] initWithData:[data subdataWithRange:writeCardSubRanges[15]] encoding:NSUTF8StringEncoding];

        
        unsigned int count;
        objc_property_t *properties = class_copyPropertyList([self class], &count);
        for(int i = 0; i < count; i++)
        {
            objc_property_t property = properties[i];
            
            NSLog(@"name:%s",property_getName(property));
            NSString* value = [info valueForKey:[NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding]];
            
        }
        free(properties);
    }
    return info;
}


@end
