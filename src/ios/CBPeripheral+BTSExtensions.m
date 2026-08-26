//
//  CBPeripheral+BTSExtensions.m
//  BluetoothSerial Cordova Plugin
//
//  (c) 2103-2015 Don Coleman
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "CBPeripheral+BTSExtensions.h"

static char BTS_ADVERTISING_IDENTIFER;
static char BTS_ADVERTISEMENT_NAME_IDENTIFER;
static char BTS_ADVERTISEMENT_RSSI_IDENTIFER;

@implementation CBPeripheral(com_megster_bluetoothserial_extension)

// AdvertisementData and RSSI are from didDiscoverPeripheral.
// Save the advertisement information so we can pass it to Cordova.
-(void)bts_setAdvertisementData:(NSDictionary *)advertisementData
                            RSSI:(NSNumber *)rssi {

    if (advertisementData) {

        // BLE advertised local name
        NSString *localName =
            [advertisementData objectForKey:CBAdvertisementDataLocalNameKey];

        if (localName) {
            [self setBtsAdvertisementName:localName];
        }

        // Manufacturer data
        NSData *manufacturerData =
            [advertisementData objectForKey:
                CBAdvertisementDataManufacturerDataKey];

        if (manufacturerData && manufacturerData.length > 2) {

            const uint8_t *bytes = manufacturerData.bytes;
            NSUInteger len = manufacturerData.length;

            // Skip manufacturer UUID
            NSData *data =
                [NSData dataWithBytes:bytes + 2
                               length:len - 2];

            NSString *advertising =
                [[NSString alloc] initWithData:data
                                      encoding:NSUTF8StringEncoding];

            if (advertising) {
                [self setBtsAdvertising:advertising];
            }
        }
    }

    [self setBtsAdvertisementRSSI:rssi];
}


#pragma mark - Advertisement data

-(void)setBtsAdvertising:(NSString *)newAdvertisingValue {

    objc_setAssociatedObject(
        self,
        &BTS_ADVERTISING_IDENTIFER,
        newAdvertisingValue,
        OBJC_ASSOCIATION_RETAIN_NONATOMIC
    );
}

-(NSString *)btsAdvertising {

    return objc_getAssociatedObject(
        self,
        &BTS_ADVERTISING_IDENTIFER
    );
}


#pragma mark - Advertisement name

-(void)setBtsAdvertisementName:(NSString *)newAdvertisementName {

    objc_setAssociatedObject(
        self,
        &BTS_ADVERTISEMENT_NAME_IDENTIFER,
        newAdvertisementName,
        OBJC_ASSOCIATION_RETAIN_NONATOMIC
    );
}

-(NSString *)btsAdvertisementName {

    return objc_getAssociatedObject(
        self,
        &BTS_ADVERTISEMENT_NAME_IDENTIFER
    );
}


#pragma mark - RSSI

-(void)setBtsAdvertisementRSSI:(NSNumber *)newAdvertisementRSSIValue {

    objc_setAssociatedObject(
        self,
        &BTS_ADVERTISEMENT_RSSI_IDENTIFER,
        newAdvertisementRSSIValue,
        OBJC_ASSOCIATION_RETAIN_NONATOMIC
    );
}

-(NSNumber *)btsAdvertisementRSSI {

    return objc_getAssociatedObject(
        self,
        &BTS_ADVERTISEMENT_RSSI_IDENTIFER
    );
}

@end