//
//  Bluetooth40Common.h
//  BDEWrsitBand
//
//  Created by 王 维 on 8/13/14.
//  Copyright (c) 2014 BDE. All rights reserved.
//

#ifndef BDEWrsitBand_Bluetooth40Common_h
#define BDEWrsitBand_Bluetooth40Common_h


enum{
    MESSAGE_READ = 0,
    MESSAGE_WRITE,
    MESSAGE_UI,
    MESSAGE_WRITEDATA,
    MESSAGE_ERROR,
    MESSAGE_SOCKET,
};

//
#define CARD_4442               8
#define CARD_READ_4442          @"010100"
#define CARD_WRITE_4442         @"010200"
#define CARD_CHECKPASS_4442     @"01030000"
#define CARD_CHANGEPASS_4442    @"01050000"

//超时
#define  TIMEOUT_TIME_SECONDS_CONSISTENT                5
#define  TIMEOUT_TIME_SECONDS_CONNECT_PROCEDURE_        TIMEOUT_TIME_SECONDS_CONSISTENT
//#define  TIMEOUT_TIME_SECONDS_DISCOVER_PROCEDURE_       TIMEOUT_TIME_SECONDS_CONSISTENT
//#define  TIMEOUT_TIME_SECONDS_CONFIGURE_PROCEDURE_      TIMEOUT_TIME_SECONDS_CONSISTENT

//蓝牙设备类型
#define  BUSINESS_SERVICE_UUID_STRING        @"0000FF10-0000-0040-4855-4959554e0000"
//写数据服务
#define  WRITE_CHARACTERISTIC_UUID_STRING    @"0000FF11-0000-0040-4855-4959554e0000"
//读数据服务
#define  READ_CHARACTERISTIC_UUID_STRING     @"0000FF12-0000-0040-4855-4959554e0000"

#define  BUSINESS_SERVICE_UUID_VALUE         @"00005301-0000-0041-4c50-574953450000"
#define  TX_CHARACTERISTIC_UUID_VALUE        @"00005302-0000-0041-4c50-574953450000"
#define  RX_CHARACTERISTIC_UUID_VALUE        @"00005303-0000-0041-4c50-574953450000"





#endif
