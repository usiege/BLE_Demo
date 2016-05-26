//
//  DeviceInforModel.m
//  BDEWrsitBand
//
//  Created by 王 维 on 8/13/14.
//  Copyright (c) 2014 BDE. All rights reserved.
//

#import "PeripheralDevice.h"
#import "BleCardInfo.h"

#define  kDeviceInforModelNameString            @"keyDeviceInforModelNameString"
#define  kDeviceInforModelIdentifierString      @"keyDeviceInforModelIdentifierString"


@interface PeripheralDevice ()
{
    NSData* _cardReadedData;
    NSData* _parsedData;
}
@property (nonatomic,strong) NSData*        cardReadedData;   //设备读取到的卡数据
@property (nonatomic,strong) NSData*        parsedData;     //服务器解析后的数据

@end

const NSString*  DEVICE_CARD_READED_DATA_KEY = @"cardReadedData";
const NSString*  DEVICE_PARSED_DATA_KEY = @"parsedData"; //不能加static


//static inline void test(void){ return;}

@implementation PeripheralDevice

-(id)init{
    self = [super init];
    if (self) {
        // initiate code
        self.cardReadedData = nil;
        self.parsedData = nil;
        self.name = nil;
        self.identifier = nil;
        
        [self initAllVariable];
    }
    return self;
}

- (NSData *)cardReadedData{
    return _cardReadedData;
}

- (void)setCardReadedData:(NSData *)cardReadedData{
    _cardReadedData = cardReadedData;
}



- (NSData *)parsedData{
    return _parsedData;
}

- (void)setParsedData:(NSData *)parsedData{
    _parsedData = parsedData;
}

- (NSString *)checkKey{
    if(!_parsedData) return nil;
    if(_parsedData.length > 129+16) nil;
    return [[NSString alloc] initWithData:[_parsedData subdataWithRange:NSMakeRange(129, 16)] encoding:NSUTF8StringEncoding];
}

- (NSString *)checkKeyNew{
    if(!_parsedData) return nil;
    if(_parsedData.length > 145+16) nil;
    return [[NSString alloc] initWithData:[_parsedData subdataWithRange:NSMakeRange(145, 16)] encoding:NSUTF8StringEncoding];
}


#pragma -NSCopying
-(id)copyWithZone:(NSZone *)zone{
    return 0;
}

#pragma mark -NSCodeing
-(id)initWithCoder:(NSCoder *)aDecoder{
    self = [super init];
    if (self) {
        self.name = [aDecoder decodeObjectForKey:kDeviceInforModelNameString];
        self.identifier = [aDecoder decodeObjectForKey:kDeviceInforModelIdentifierString];
        
        [self initAllVariable];
        
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder{
    
    [aCoder encodeObject:self.name forKey:kDeviceInforModelNameString];
    [aCoder encodeObject:self.identifier forKey:kDeviceInforModelIdentifierString];
}

#pragma mark -Utility
-(void)initAllVariable{
    
    self.peripheral = nil;
    self.rssi = nil;
    self.manufactureData = nil;
    self.operationType = CardOperation_Idle;
    
    self.connectTimer = nil;
    self.discoverTimer = nil;
}


+(BOOL)checkDeviceA:(PeripheralDevice *)deviceA sameAsDeviceB:(PeripheralDevice *)deviceB{
    if (deviceA != nil && deviceB != nil) {
        if ([deviceA.identifier isEqualToString:deviceB.identifier]) {
            return YES;
        }
    }
    return NO;
}

@end
