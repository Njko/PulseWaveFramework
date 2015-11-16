//
//  PWEtactCommands.m
//  PulseWave CocoaPod
//
//  Created by Yann Lapeyre on 19/07/2015.
//  Modified by Nicolas Linard on 30/10/2015.
//  Copyright (c) 2015 Medes-IMPS. All rights reserved.
//

#import "PWEtactCommands.h"
#import "PWByteUtils.h"

@implementation PWEtactCommands

#pragma mark - Public class methods
// Hardware description
+(NSData *) hardwareDescription {
    UInt8 cmd[3] = {0x02,0x00,0x02};
    return [[NSData alloc]initWithBytes:cmd length:3];
}

// sofwtare description
+(NSData *) softwareDescription {
    UInt8 cmd[3] = {0x03,0x00,0x03};
    return [[NSData alloc]initWithBytes:cmd length:3];
}


// Veriosn of the connected hardware
+(NSData *) hardwareVersion {
    UInt8 cmd[3] = {0x04,0x00,0x04};
    return [[NSData alloc]initWithBytes:cmd length:3];
}

// Version of the software
+(NSData *) softwareVersion {
    UInt8 cmd[3] = {0x05,0x00,0x05};
    return [[NSData alloc]initWithBytes:cmd length:3];
}

// Version of the serial protocol
+(NSData *) bartVersion {
    UInt8 cmd[3] = {0x06,0x00,0x06};
    return [[NSData alloc]initWithBytes:cmd length:3];
}


// Count available data stored in the device
+(NSData *)dataCount {
    UInt8 cmd[3] = {0x60,0x00,0x60};
    return [[NSData alloc]initWithBytes:cmd length:3];
}

// unload data rom device for the given type and range
+(NSData *)unloadData:(UInt8)type fromIndex:(UInt32)minIndex toIndex:(UInt32)maxIndex {
    
    //TODO - check coherence between the type and the index range
    UInt8 cmd[3] = {0xe2,0x10,0x00};
    NSMutableData *data = [[NSMutableData alloc] initWithBytes:cmd length:3];
    [data appendBytes:&type length:sizeof(type)];
    
    // add the index range
    [data appendData:[PWByteUtils reverseUInt32:minIndex]];
    [data appendData:[PWByteUtils reverseUInt32:maxIndex]];
    
    // add the CRC
    UInt8 crc = [PWEtactCommands computeCrc:data];
    [data appendBytes:&crc length:sizeof(crc)];
    
    NSLog(@"%@",[data description]);
    return data;
}

+(NSData *)buildAck:(UInt8)cmd {
    UInt8 ack[3]={cmd,0x01,0xa5};
    NSMutableData *data = [[NSMutableData alloc] initWithBytes:ack length:3];
    // add the CRC
    UInt8 crc = [PWEtactCommands computeCrc:data];
    [data appendBytes:&crc length:sizeof(crc)];
    NSLog(@"ACK crc %d",crc);
    return data;
}

// Compute CRC for the given bytes
+(UInt8)computeCrc:(NSData *)data {
    UInt8 crc = 0;
    UInt8 datas[data.length];
    [data getBytes:&datas length:data.length];
    for(int i=0; i<data.length; i++){
        crc ^= datas[i];
    }
    return crc;
}

@end
