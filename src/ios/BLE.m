/*
 
 Copyright (c) 2013 RedBearLab
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 
 */

#import "BLE.h"
#import "BLEDefines.h"

@implementation BLE

@synthesize delegate;
@synthesize CM;
@synthesize peripherals;
@synthesize activePeripheral;

static bool isConnected = false;
static bool done = false;
static int rssi = 0;

/*
 * BLE service UUIDs
 */

CBUUID *redBearLabsServiceUUID;
CBUUID *adafruitServiceUUID;
CBUUID *lairdServiceUUID;
CBUUID *blueGigaServiceUUID;
CBUUID *hm10ServiceUUID;
CBUUID *hc02ServiceUUID;
CBUUID *hc02AdvUUID;

/*
 * Active service / characteristic UUIDs
 */

CBUUID *serialServiceUUID;
CBUUID *readCharacteristicUUID;
CBUUID *writeCharacteristicUUID;


/*
 * ============================================================
 * MARK: - Basic BLE state
 * ============================================================
 */

- (BOOL)isConnected
{
    return isConnected;
}

- (void)readRSSI
{
    if (activePeripheral) {
        [activePeripheral readRSSI];
    }
}


/*
 * ============================================================
 * MARK: - Read / Write
 * ============================================================
 */

- (void)read
{
    if (!activePeripheral) {
        NSLog(@"READ ERROR: No active peripheral");
        return;
    }

    if (!serialServiceUUID || !readCharacteristicUUID) {
        NSLog(@"READ ERROR: Service or characteristic UUID not configured");
        return;
    }

    NSLog(@"READ");
    NSLog(@"Service UUID: %@", serialServiceUUID.UUIDString);
    NSLog(@"Characteristic UUID: %@", readCharacteristicUUID.UUIDString);

    [self readValue:serialServiceUUID
 characteristicUUID:readCharacteristicUUID
                   p:activePeripheral];
}


- (void)write:(NSData *)d
{
    NSLog(@"========== BLE WRITE REQUEST ==========");

    if (!d) {
        NSLog(@"WRITE ERROR: Data is nil");
        return;
    }

    if (!activePeripheral) {
        NSLog(@"WRITE ERROR: No active peripheral");
        return;
    }

    NSLog(@"Peripheral: %@", activePeripheral.name);
    NSLog(@"Peripheral UUID: %@",
          activePeripheral.identifier.UUIDString);

    NSLog(@"Peripheral state: %ld",
          (long)activePeripheral.state);

    NSLog(@"Data length: %lu",
          (unsigned long)d.length);

    if (!serialServiceUUID) {
        NSLog(@"WRITE ERROR: serialServiceUUID is nil");
        return;
    }

    if (!writeCharacteristicUUID) {
        NSLog(@"WRITE ERROR: writeCharacteristicUUID is nil");
        return;
    }

    NSLog(@"Service UUID: %@",
          serialServiceUUID.UUIDString);

    NSLog(@"Write Characteristic UUID: %@",
          writeCharacteristicUUID.UUIDString);

    [self writeValue:serialServiceUUID
 characteristicUUID:writeCharacteristicUUID
                   p:activePeripheral
                 data:d];

    NSLog(@"========================================");
}


- (void)enableReadNotification:(CBPeripheral *)p
{
    if (!p) {
        return;
    }

    if (!serialServiceUUID || !readCharacteristicUUID) {
        NSLog(@"NOTIFICATION ERROR: UUID not configured");
        return;
    }

    [self notification:serialServiceUUID
  characteristicUUID:readCharacteristicUUID
                   p:p
                  on:YES];
}


/*
 * ============================================================
 * MARK: - Notification
 * ============================================================
 */

- (void)notification:(CBUUID *)serviceUUID
characteristicUUID:(CBUUID *)characteristicUUID
                 p:(CBPeripheral *)p
                on:(BOOL)on
{
    CBService *service =
        [self findServiceFromUUID:serviceUUID p:p];

    if (!service) {

        NSLog(@"Could not find service with UUID %@",
              serviceUUID.UUIDString);

        return;
    }

    CBCharacteristic *characteristic =
        [self findCharacteristicFromUUID:characteristicUUID
                                 service:service];

    if (!characteristic) {

        NSLog(@"Could not find characteristic with UUID %@",
              characteristicUUID.UUIDString);

        return;
    }

    NSLog(@"Setting notification %@ for %@",
          on ? @"ON" : @"OFF",
          characteristic.UUID.UUIDString);

    [p setNotifyValue:on
   forCharacteristic:characteristic];
}


/*
 * ============================================================
 * MARK: - Utility
 * ============================================================
 */

- (UInt16)frameworkVersion
{
    return RBL_BLE_FRAMEWORK_VER;
}


- (NSString *)CBUUIDToString:(CBUUID *)cbuuid
{
    if (!cbuuid) {
        return @"NULL";
    }

    NSData *data = cbuuid.data;

    if ([data length] == 2) {

        const unsigned char *tokenBytes =
            [data bytes];

        return [NSString stringWithFormat:
                @"%02x%02x",
                tokenBytes[0],
                tokenBytes[1]];
    }

    else if ([data length] == 16) {

        NSUUID *nsuuid =
            [[NSUUID alloc] initWithUUIDBytes:data.bytes];

        return [nsuuid UUIDString];
    }

    return [cbuuid description];
}


/*
 * ============================================================
 * MARK: - Read value
 * ============================================================
 */

- (void)readValue:(CBUUID *)serviceUUID
characteristicUUID:(CBUUID *)characteristicUUID
                 p:(CBPeripheral *)p
{
    CBService *service =
        [self findServiceFromUUID:serviceUUID p:p];

    if (!service) {

        NSLog(@"READ ERROR: Service not found: %@",
              serviceUUID.UUIDString);

        return;
    }

    CBCharacteristic *characteristic =
        [self findCharacteristicFromUUID:characteristicUUID
                                 service:service];

    if (!characteristic) {

        NSLog(@"READ ERROR: Characteristic not found: %@",
              characteristicUUID.UUIDString);

        return;
    }

    [p readValueForCharacteristic:characteristic];
}


/*
 * ============================================================
 * MARK: - WRITE VALUE
 * ============================================================
 */

- (void)writeValue:(CBUUID *)serviceUUID
characteristicUUID:(CBUUID *)characteristicUUID
                 p:(CBPeripheral *)p
               data:(NSData *)data
{
    NSLog(@"========== WRITE VALUE ==========");

    if (!p) {
        NSLog(@"ERROR: Peripheral is nil");
        return;
    }

    if (!data) {
        NSLog(@"ERROR: Data is nil");
        return;
    }

    NSLog(@"Peripheral UUID: %@",
          p.identifier.UUIDString);

    NSLog(@"Peripheral name: %@",
          p.name);

    NSLog(@"Peripheral state: %ld",
          (long)p.state);

    NSLog(@"Service UUID requested: %@",
          serviceUUID.UUIDString);

    NSLog(@"Characteristic UUID requested: %@",
          characteristicUUID.UUIDString);

    NSLog(@"Data length: %lu",
          (unsigned long)data.length);


    /*
     * Find service
     */

    CBService *service =
        [self findServiceFromUUID:serviceUUID p:p];

    if (!service) {

        NSLog(@"ERROR: SERVICE NOT FOUND");

        NSLog(@"Available services:");

        for (CBService *availableService in p.services) {

            NSLog(@"  %@",
                  availableService.UUID.UUIDString);
        }

        return;
    }

    NSLog(@"SERVICE FOUND: %@",
          service.UUID.UUIDString);


    /*
     * Find characteristic
     */

    CBCharacteristic *characteristic =
        [self findCharacteristicFromUUID:characteristicUUID
                                 service:service];

    if (!characteristic) {

        NSLog(@"ERROR: WRITE CHARACTERISTIC NOT FOUND");

        NSLog(@"Available characteristics for service %@:",
              service.UUID.UUIDString);

        for (CBCharacteristic *availableCharacteristic
             in service.characteristics) {

            NSLog(@"  %@ | properties=%lu",
                  availableCharacteristic.UUID.UUIDString,
                  (unsigned long)availableCharacteristic.properties);
        }

        return;
    }

    NSLog(@"WRITE CHARACTERISTIC FOUND: %@",
          characteristic.UUID.UUIDString);

    NSLog(@"Characteristic properties: %lu",
          (unsigned long)characteristic.properties);


    /*
     * Check Write Without Response
     */

    if (characteristic.properties &
        CBCharacteristicPropertyWriteWithoutResponse) {

        NSLog(@"Characteristic supports WRITE WITHOUT RESPONSE");


        /*
         * CoreBluetooth has flow control for
         * Write Without Response.
         */

        if (![p canSendWriteWithoutResponse]) {

            NSLog(@"Peripheral is NOT ready for Write Without Response");

            return;
        }


        /*
         * Determine maximum write size.
         */

        NSUInteger maximumLength =
            [p maximumWriteValueLengthForType:
                CBCharacteristicWriteWithoutResponse];

        NSLog(@"Maximum Write Without Response length: %lu",
              (unsigned long)maximumLength);


        /*
         * If the ESC/POS data fits into one packet,
         * send it directly.
         */

        if (data.length <= maximumLength) {

            NSLog(@"Writing %lu bytes",
                  (unsigned long)data.length);

            [p writeValue:data
       forCharacteristic:characteristic
                    type:CBCharacteristicWriteWithoutResponse];

            NSLog(@"writeValue WITHOUT RESPONSE called");

        }

        /*
         * If data is larger than the allowed size,
         * split it into chunks.
         */

        else {

            NSLog(@"Data is larger than maximum write size");
            NSLog(@"Splitting data into chunks");


            NSUInteger offset = 0;

            while (offset < data.length) {

                NSUInteger remaining =
                    data.length - offset;

                NSUInteger chunkLength =
                    MIN(remaining, maximumLength);

                NSData *chunk =
                    [data subdataWithRange:
                        NSMakeRange(offset, chunkLength)];

                NSLog(@"Writing chunk: offset=%lu length=%lu",
                      (unsigned long)offset,
                      (unsigned long)chunk.length);


                /*
                 * Check flow control before each chunk.
                 */

                if (![p canSendWriteWithoutResponse]) {

                    NSLog(@"Peripheral not ready while sending chunks");

                    return;
                }


                [p writeValue:chunk
           forCharacteristic:characteristic
                        type:CBCharacteristicWriteWithoutResponse];

                offset += chunkLength;
            }

            NSLog(@"All chunks sent");
        }
    }


    /*
     * Write WITH RESPONSE
     */

    else if (characteristic.properties &
             CBCharacteristicPropertyWrite) {

        NSLog(@"Characteristic supports WRITE WITH RESPONSE");

        [p writeValue:data
   forCharacteristic:characteristic
                type:CBCharacteristicWriteWithResponse];

        NSLog(@"writeValue WITH RESPONSE called");
    }


    /*
     * Not writable
     */

    else {

        NSLog(@"ERROR: Characteristic is NOT writable");

        NSLog(@"Properties: %lu",
              (unsigned long)characteristic.properties);
    }

    NSLog(@"=================================");
}


/*
 * ============================================================
 * MARK: - BLE setup
 * ============================================================
 */

- (void)controlSetup
{
    self.CM =
        [[CBCentralManager alloc] initWithDelegate:self
                                             queue:nil];

    NSLog(@"CBCentralManager created");
}


/*
 * ============================================================
 * MARK: - Scan
 * ============================================================
 */

- (int)findBLEPeripherals:(int)timeout
{
    if (self.CM.state != CBCentralManagerStatePoweredOn) {

        NSLog(@"CoreBluetooth not correctly initialized");

        NSLog(@"State = %ld (%s)",
              (long)self.CM.state,
              [self centralManagerStateToString:self.CM.state]);

        return -1;
    }


    /*
     * Initialize known BLE service UUIDs.
     */

    redBearLabsServiceUUID =
        [CBUUID UUIDWithString:@RBL_SERVICE_UUID];

    adafruitServiceUUID =
        [CBUUID UUIDWithString:@ADAFRUIT_SERVICE_UUID];

    lairdServiceUUID =
        [CBUUID UUIDWithString:@LAIRD_SERVICE_UUID];

    blueGigaServiceUUID =
        [CBUUID UUIDWithString:@BLUEGIGA_SERVICE_UUID];

    hm10ServiceUUID =
        [CBUUID UUIDWithString:@HM10_SERVICE_UUID];

    hc02ServiceUUID =
        [CBUUID UUIDWithString:@HC02_SERVICE_UUID];

    hc02AdvUUID =
        [CBUUID UUIDWithString:@HC02_ADV_UUID];


    NSLog(@"Starting generic BLE scan");

    NSLog(@"Timeout: %d seconds", timeout);


    /*
     * Scan for ALL BLE peripherals.
     *
     * This is important because the 9Printer may not advertise
     * one of the predefined services.
     */

    [self.CM scanForPeripheralsWithServices:nil
                                    options:nil];


    [NSTimer scheduledTimerWithTimeInterval:(float)timeout
                                     target:self
                                   selector:@selector(scanTimer:)
                                   userInfo:nil
                                    repeats:NO];


    NSLog(@"scanForPeripheralsWithServices started");

    return 0;
}


/*
 * ============================================================
 * MARK: - Connect
 * ============================================================
 */

- (void)connectPeripheral:(CBPeripheral *)peripheral
{
    if (!peripheral) {

        NSLog(@"CONNECT ERROR: Peripheral is nil");

        return;
    }

    NSLog(@"========== CONNECT ==========");

    NSLog(@"Peripheral name: %@",
          peripheral.name);

    NSLog(@"Peripheral UUID: %@",
          peripheral.identifier.UUIDString);


    self.activePeripheral = peripheral;

    self.activePeripheral.delegate = self;

    done = false;
    isConnected = false;


    /*
     * Clear previous service/characteristic configuration.
     */

    serialServiceUUID = nil;
    readCharacteristicUUID = nil;
    writeCharacteristicUUID = nil;


    /*
     * Connect.
     */

    [self.CM connectPeripheral:self.activePeripheral
                       options:@{
                           CBConnectPeripheralOptionNotifyOnDisconnectionKey:
                               @YES
                       }];


    NSLog(@"Connection request sent");

    NSLog(@"============================");
}


/*
 * ============================================================
 * MARK: - Bluetooth state
 * ============================================================
 */

- (const char *)centralManagerStateToString:(int)state
{
    switch (state)
    {
        case CBCentralManagerStateUnknown:
            return "State unknown";

        case CBCentralManagerStateResetting:
            return "State resetting";

        case CBCentralManagerStateUnsupported:
            return "State BLE unsupported";

        case CBCentralManagerStateUnauthorized:
            return "State unauthorized";

        case CBCentralManagerStatePoweredOff:
            return "State BLE powered off";

        case CBCentralManagerStatePoweredOn:
            return "State powered up and ready";

        default:
            return "State unknown";
    }
}


/*
 * ============================================================
 * MARK: - Scan timer
 * ============================================================
 */

- (void)scanTimer:(NSTimer *)timer
{
    [self.CM stopScan];

    NSLog(@"Stopped scanning");

    NSLog(@"Known peripherals: %lu",
          (unsigned long)self.peripherals.count);

    [self printKnownPeripherals];
}


/*
 * ============================================================
 * MARK: - Peripheral list
 * ============================================================
 */

- (void)printKnownPeripherals
{
    NSLog(@"List of currently known peripherals:");

    for (int i = 0;
         i < self.peripherals.count;
         i++)
    {
        CBPeripheral *p =
            [self.peripherals objectAtIndex:i];

        NSLog(@"%d | UUID=%@ | Name=%@",
              i,
              p.identifier.UUIDString,
              p.name);

        [self printPeripheralInfo:p];
    }
}


- (void)printPeripheralInfo:(CBPeripheral *)peripheral
{
    NSLog(@"------------------------------------");

    NSLog(@"Peripheral Info");

    NSLog(@"UUID: %@",
          peripheral.identifier.UUIDString);

    NSLog(@"Name: %@",
          peripheral.name);

    NSLog(@"State: %ld",
          (long)peripheral.state);

    NSLog(@"------------------------------------");
}


/*
 * ============================================================
 * MARK: - Peripheral discovery
 * ============================================================
 */

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI
{
    /*
     * Save advertisement information.
     *
     * Your CBPeripheral+BTSExtensions implementation stores
     * the advertised name and RSSI.
     */

    [peripheral bts_setAdvertisementData:advertisementData
                                    RSSI:RSSI];


    if (!self.peripherals) {

        self.peripherals =
            [[NSMutableArray alloc]
                initWithObjects:peripheral, nil];

        NSLog(@"First peripheral discovered");
    }

    else {

        BOOL found = NO;

        for (int i = 0;
             i < self.peripherals.count;
             i++)
        {
            CBPeripheral *existingPeripheral =
                [self.peripherals objectAtIndex:i];

            if ([existingPeripheral.identifier
                 isEqual:peripheral.identifier])
            {
                found = YES;

                /*
                 * Update the peripheral object so the latest
                 * advertisement information is retained.
                 */

                [self.peripherals
                    replaceObjectAtIndex:i
                    withObject:peripheral];

                break;
            }
        }

        if (!found) {

            [self.peripherals addObject:peripheral];

            NSLog(@"New peripheral added");
        }
    }


    /*
     * Useful information for debugging.
     */

    NSString *advertisedName =
        [advertisementData
            objectForKey:CBAdvertisementDataLocalNameKey];

    NSLog(@"========== BLE DISCOVERY ==========");

    NSLog(@"Name: %@", peripheral.name);

    NSLog(@"Advertised Name: %@", advertisedName);

    NSLog(@"UUID: %@",
          peripheral.identifier.UUIDString);

    NSLog(@"RSSI: %@", RSSI);

    NSLog(@"===================================");
}


/*
 * ============================================================
 * MARK: - Central state changed
 * ============================================================
 */

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSLog(@"========== Bluetooth State ==========");

    NSLog(@"CoreBluetooth state = %ld",
          (long)central.state);

    NSLog(@"CoreBluetooth state = %s",
          [self centralManagerStateToString:central.state]);

    NSLog(@"=====================================");
}


/*
 * ============================================================
 * MARK: - Connected
 * ============================================================
 */

- (void)centralManager:(CBCentralManager *)central
 didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"========== CONNECTED ==========");

    NSLog(@"Connected peripheral: %@",
          peripheral.name);

    NSLog(@"UUID: %@",
          peripheral.identifier.UUIDString);


    self.activePeripheral = peripheral;

    self.activePeripheral.delegate = self;

    isConnected = false;
    done = false;


    /*
     * Discover ALL services.
     */

    [peripheral discoverServices:nil];

    NSLog(@"Service discovery started");

    NSLog(@"================================");
}


/*
 * ============================================================
 * MARK: - Disconnected
 * ============================================================
 */

- (void)centralManager:(CBCentralManager *)central
didDisconnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error
{
    NSLog(@"========== DISCONNECTED ==========");

    NSLog(@"Peripheral: %@",
          peripheral.name);

    NSLog(@"UUID: %@",
          peripheral.identifier.UUIDString);

    if (error) {
        NSLog(@"Disconnect error: %@", error);
    }

    isConnected = false;
    done = false;

    serialServiceUUID = nil;
    readCharacteristicUUID = nil;
    writeCharacteristicUUID = nil;

    [[self delegate] bleDidDisconnect];

    NSLog(@"==================================");
}


/*
 * ============================================================
 * MARK: - Service discovery
 * ============================================================
 */

- (void)peripheral:(CBPeripheral *)peripheral
didDiscoverServices:(NSError *)error
{
    if (error) {

        NSLog(@"========== SERVICE DISCOVERY ERROR ==========");
        NSLog(@"%@", error);
        NSLog(@"============================================");

        return;
    }


    NSLog(@"========== SERVICES DISCOVERED ==========");


    for (CBService *service in peripheral.services) {

        NSLog(@"Service UUID: %@",
              service.UUID.UUIDString);


        /*
         * 9Printer / HC02 service
         */

        if ([service.UUID.UUIDString
             caseInsensitiveCompare:
             @HC02_SERVICE_UUID] == NSOrderedSame)
        {
            NSLog(@"*** 9PRINTER / HC02 SERVICE FOUND ***");

            serialServiceUUID =
                [CBUUID UUIDWithString:@HC02_SERVICE_UUID];

            readCharacteristicUUID =
                [CBUUID UUIDWithString:@HC02_CHAR_TX_UUID];

            writeCharacteristicUUID =
                [CBUUID UUIDWithString:@HC02_CHAR_RX_UUID];

            NSLog(@"Configured service: %@",
                  serialServiceUUID.UUIDString);

            NSLog(@"Configured read characteristic: %@",
                  readCharacteristicUUID.UUIDString);

            NSLog(@"Configured write characteristic: %@",
                  writeCharacteristicUUID.UUIDString);
        }


        /*
         * Discover ALL characteristics for this service.
         */

        [peripheral discoverCharacteristics:nil
                                 forService:service];
    }


    NSLog(@"==========================================");
}


/*
 * ============================================================
 * MARK: - Characteristic discovery
 * ============================================================
 */

- (void)peripheral:(CBPeripheral *)peripheral
didDiscoverCharacteristicsForService:(CBService *)service
             error:(NSError *)error
{
    if (error) {

        NSLog(@"========== CHARACTERISTIC ERROR ==========");

        NSLog(@"Service: %@",
              service.UUID.UUIDString);

        NSLog(@"Error: %@", error);

        NSLog(@"==========================================");

        return;
    }


    NSLog(@"========== CHARACTERISTICS ==========");

    NSLog(@"Service UUID: %@",
          service.UUID.UUIDString);


    BOOL printerWriteCharacteristicFound = NO;


    for (CBCharacteristic *characteristic
         in service.characteristics)
    {
        NSLog(@"Characteristic UUID: %@",
              characteristic.UUID.UUIDString);

        NSLog(@"Properties: %lu",
              (unsigned long)characteristic.properties);


        if (characteristic.properties &
            CBCharacteristicPropertyWriteWithoutResponse)
        {
            NSLog(@"  -> WRITE WITHOUT RESPONSE");
        }


        if (characteristic.properties &
            CBCharacteristicPropertyWrite)
        {
            NSLog(@"  -> WRITE WITH RESPONSE");
        }


        if (characteristic.properties &
            CBCharacteristicPropertyRead)
        {
            NSLog(@"  -> READ");
        }


        if (characteristic.properties &
            CBCharacteristicPropertyNotify)
        {
            NSLog(@"  -> NOTIFY");
        }


        /*
         * Check specifically for the printer's write
         * characteristic.
         */

        if (writeCharacteristicUUID &&
            [characteristic.UUID.UUIDString
             caseInsensitiveCompare:
             writeCharacteristicUUID.UUIDString]
                == NSOrderedSame)
        {
            printerWriteCharacteristicFound = YES;

            NSLog(@"*** PRINTER WRITE CHARACTERISTIC FOUND ***");

            NSLog(@"UUID: %@",
                  characteristic.UUID.UUIDString);

            NSLog(@"Properties: %lu",
                  (unsigned long)characteristic.properties);
        }
    }


    /*
     * Once the actual printer write characteristic
     * has been discovered, the printer is ready.
     */

    if (printerWriteCharacteristicFound && !done) {

        NSLog(@"*** PRINTER BLE READY FOR ESC/POS ***");

        /*
         * Enable notification only if the configured
         * read characteristic exists.
         */

        if (readCharacteristicUUID) {

            [self enableReadNotification:peripheral];
        }


        done = true;
        isConnected = true;

        [[self delegate] bleDidConnect];
    }


    NSLog(@"======================================");
}


/*
 * ============================================================
 * MARK: - Notification state
 * ============================================================
 */

- (void)peripheral:(CBPeripheral *)peripheral
didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    if (!error) {

        NSLog(@"Notification state updated");

        NSLog(@"Characteristic: %@",
              characteristic.UUID.UUIDString);

    }

    else {

        NSLog(@"Notification error");

        NSLog(@"Characteristic: %@",
              characteristic.UUID.UUIDString);

        NSLog(@"Error: %@", error);
    }
}


/*
 * ============================================================
 * MARK: - Characteristic value updated
 * ============================================================
 */

- (void)peripheral:(CBPeripheral *)peripheral
didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    if (error) {

        NSLog(@"Update value failed: %@", error);

        return;
    }


    if (!readCharacteristicUUID) {
        return;
    }


    if (![characteristic.UUID.UUIDString
          caseInsensitiveCompare:
          readCharacteristicUUID.UUIDString]
        == NSOrderedSame)
    {
        return;
    }


    if (!characteristic.value) {
        return;
    }


    unsigned char data[20];

    static unsigned char buf[512];

    static int len = 0;

    NSInteger data_len =
        characteristic.value.length;


    if (data_len > sizeof(data)) {
        data_len = sizeof(data);
    }


    [characteristic.value
        getBytes:data
        length:data_len];


    if (data_len == 20) {

        if (len + data_len <= sizeof(buf)) {

            memcpy(&buf[len],
                   data,
                   data_len);

            len += data_len;
        }


        if (len >= 64) {

            [[self delegate]
                bleDidReceiveData:buf
                length:len];

            len = 0;
        }
    }

    else if (data_len < 20) {

        if (len + data_len <= sizeof(buf)) {

            memcpy(&buf[len],
                   data,
                   data_len);

            len += data_len;
        }

        [[self delegate]
            bleDidReceiveData:buf
            length:len];

        len = 0;
    }
}


/*
 * ============================================================
 * MARK: - RSSI
 * ============================================================
 */

- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral
                          error:(NSError *)error
{
    if (!isConnected) {
        return;
    }

    if (error) {
        return;
    }

    if (rssi != peripheral.RSSI.intValue) {

        rssi = peripheral.RSSI.intValue;

        [[self delegate]
            bleDidUpdateRSSI:activePeripheral.RSSI];
    }
}


/*
 * ============================================================
 * MARK: - Find Service
 * ============================================================
 */

- (CBService *)findServiceFromUUID:(CBUUID *)UUID
                                  p:(CBPeripheral *)p
{
    if (!UUID || !p) {
        return nil;
    }


    for (CBService *service in p.services) {

        if ([service.UUID.UUIDString
             caseInsensitiveCompare:
             UUID.UUIDString]
            == NSOrderedSame)
        {
            return service;
        }
    }


    return nil;
}


/*
 * ============================================================
 * MARK: - Find Characteristic
 * ============================================================
 */

- (CBCharacteristic *)findCharacteristicFromUUID:(CBUUID *)UUID
                                         service:(CBService *)service
{
    if (!UUID || !service) {
        return nil;
    }


    for (CBCharacteristic *characteristic
         in service.characteristics)
    {
        if ([characteristic.UUID.UUIDString
             caseInsensitiveCompare:
             UUID.UUIDString]
            == NSOrderedSame)
        {
            return characteristic;
        }
    }


    return nil;
}


/*
 * ============================================================
 * MARK: - UUID helpers
 * ============================================================
 */

- (BOOL)UUIDSAreEqual:(NSUUID *)UUID1
                 UUID2:(NSUUID *)UUID2
{
    if (!UUID1 || !UUID2) {
        return NO;
    }

    return [UUID1.UUIDString
            caseInsensitiveCompare:UUID2.UUIDString]
            == NSOrderedSame;
}


- (UInt16)swap:(UInt16)s
{
    UInt16 temp = s << 8;
    temp |= (s >> 8);

    return temp;
}


- (int)compareCBUUID:(CBUUID *)UUID1
                UUID2:(CBUUID *)UUID2
{
    if (!UUID1 || !UUID2) {
        return 0;
    }

    return ([UUID1.UUIDString
             caseInsensitiveCompare:
             UUID2.UUIDString]
            == NSOrderedSame) ? 1 : 0;
}


- (int)compareCBUUIDToInt:(CBUUID *)UUID1
                     UUID2:(UInt16)UUID2
{
    if (!UUID1) {
        return 0;
    }

    UInt16 b2 = [self swap:UUID2];

    char b1[16];

    [UUID1.data getBytes:b1
                  length:MIN((NSUInteger)16,
                             UUID1.data.length)];

    return memcmp(b1, (char *)&b2, 2) == 0 ? 1 : 0;
}


- (UInt16)CBUUIDToInt:(CBUUID *)UUID
{
    if (!UUID || UUID.data.length < 2) {
        return 0;
    }

    char b1[16];

    [UUID.data getBytes:b1
                 length:MIN((NSUInteger)16,
                            UUID.data.length)];

    return ((b1[0] << 8) | b1[1]);
}


- (CBUUID *)IntToCBUUID:(UInt16)UUID
{
    char t[16] = {0};

    t[0] = ((UUID >> 8) & 0xff);
    t[1] = (UUID & 0xff);

    NSData *data =
        [[NSData alloc] initWithBytes:t
                               length:16];

    return [CBUUID UUIDWithData:data];
}


/*
 * ============================================================
 * MARK: - Discover services / characteristics
 * ============================================================
 */

- (void)getAllServicesFromPeripheral:(CBPeripheral *)p
{
    if (!p) {
        return;
    }

    NSLog(@"Discovering all services");

    [p discoverServices:nil];
}


- (void)getAllCharacteristicsFromPeripheral:(CBPeripheral *)p
{
    if (!p) {
        return;
    }

    for (CBService *service in p.services) {

        NSLog(@"Discovering characteristics for service %@",
              service.UUID.UUIDString);

        [p discoverCharacteristics:nil
                        forService:service];
    }
}


/*
 * ============================================================
 * MARK: - Hardware support
 * ============================================================
 */

#if !TARGET_OS_IPHONE

- (BOOL)isLECapableHardware
{
    NSString *state = nil;

    switch ([CM state])
    {
        case CBCentralManagerStateUnsupported:

            state =
                @"The platform/hardware doesn't support Bluetooth Low Energy.";

            break;

        case CBCentralManagerStateUnauthorized:

            state =
                @"The app is not authorized to use Bluetooth Low Energy.";

            break;

        case CBCentralManagerStatePoweredOff:

            state =
                @"Bluetooth is currently powered off.";

            break;

        case CBCentralManagerStatePoweredOn:

            return TRUE;

        case CBCentralManagerStateUnknown:

        default:

            return FALSE;
    }

    NSLog(@"Central manager state: %@", state);

    return FALSE;
}

#endif

@end