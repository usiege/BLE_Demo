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

@end

const NSString*  DEVICE_CARD_READED_DATA_KEY = @"cardReadedData";
const NSString*  DEVICE_PARSED_DATA_KEY = @"parsedData"; //不能加static


//static inline void test(void){ return;}

@implementation PeripheralDevice

-(id)init{
    self = [super init];
    if (self) {
        // initiate code
        self.readedData = nil;
        self.parsedData = nil;
        self.name = nil;
        self.identifier = nil;
        self.operationType = CardOperation_Idle;
        self.stateType = PeripheralState_Disconnected;
        
        self.peripheral = nil;
        self.rssi = nil;
        self.manufactureData = nil;
    }
    return self;
}

- (NSData *)readedData{
    return _cardReadedData;
}

- (void)setReadedData:(NSData *)readedData{
    _cardReadedData = readedData;
}

- (NSData *)parsedData{
    return _parsedData;
}

- (void)setParsedData:(NSData *)parsedData{
    _parsedData = parsedData;
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
        [self initilization];
    }
    return self;
}


- (void)initilization{
    self.readedData = nil;
    self.parsedData = nil;
    self.name = nil;
    self.identifier = nil;
    self.operationType = CardOperation_Idle;
    self.stateType = PeripheralState_Disconnected;
    
    self.peripheral = nil;
    self.rssi = nil;
    self.manufactureData = nil;
}

-(void)encodeWithCoder:(NSCoder *)aCoder{
    
    [aCoder encodeObject:self.name forKey:kDeviceInforModelNameString];
    [aCoder encodeObject:self.identifier forKey:kDeviceInforModelIdentifierString];
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
