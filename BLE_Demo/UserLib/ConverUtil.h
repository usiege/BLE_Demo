//
//  ConverUtil.h
//  BLECard
//
//  Created by  STH on 3/17/14.
//  Copyright (c) 2014 Jason. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ConverUtil : NSObject

/**
 64编码
 */
+(NSString *)base64Encoding:(NSData*)text;

/**
 字节转化为16进制数
 */
+(NSString *) parseByte2HexString:(Byte *) bytes;

/**
 字节数组转化16进制数
 */
+(NSString *) parseByteArray2HexString:(Byte[]) bytes;

/*
 将16进制数据转化成NSData（均可用）
 */
+(NSData*) hexString2Data:(NSString*)hexString;
+(NSData*) parseHexToByteArray:(NSString*)hexString;

/*
 将NSData转到十六进制
 */
+ (NSString*) data2HexString:(NSData *)data;

//NSdata 转成 十六进制（可用）
+ (NSString *)convertDataToHexStr:(NSData *)data;


//十六进制数据转成字符
+ (NSString *)stringFromHexString:(NSString *)hexString;

@end

