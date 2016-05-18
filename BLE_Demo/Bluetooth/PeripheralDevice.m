//
//  DeviceInforModel.m
//  BDEWrsitBand
//
//  Created by 王 维 on 8/13/14.
//  Copyright (c) 2014 BDE. All rights reserved.
//

#import "PeripheralDevice.h"

#define  kDeviceInforModelNameString            @"keyDeviceInforModelNameString"
#define  kDeviceInforModelIdentifierString      @"keyDeviceInforModelIdentifierString"



@implementation PeripheralDevice

-(id)init{
    self = [super init];
    if (self) {
        // initiate code
        self.name = nil;
        self.identifier = nil;
        
        [self initAllVariable];
    }
    return self;
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
    self.state = BT40DeviceState_Idle;
    
    self.connectTimer = nil;
    self.discoverTimer = nil;
    self.configureTimer = nil;
    
    self.countOfNotiCharac = 0;
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
