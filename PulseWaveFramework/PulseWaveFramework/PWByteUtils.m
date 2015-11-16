//
//  PWByteUtils.m
//  PulseWave CocoaPod
//
//  Created by Yann Lapeyre on 20/07/2015.
//  Modified by Nicolas Linard on 30/10/2015.
//  Copyright (c) 2015 Medes-IMPS. All rights reserved.
//

#import "PWByteUtils.h"

@implementation PWByteUtils

#pragma - Public class methods
+(NSData *)reverseData:(NSData *)source {
    NSMutableData *data = [[NSMutableData alloc] init];
    for(int i = (int)source.length - 1; i >=0; i--){
        [data appendBytes: &source.bytes[i] length:1];
    }
    return [data copy];
}

+(NSData *)reverseUInt32:(UInt32)source {
    NSData *data = [[NSData alloc] initWithBytes:&source length:sizeof(source)];
    return [PWByteUtils reverseData:data];
}

+(UInt32)dataToUInt32:(NSData *)data {
    UInt32 res;
    [[PWByteUtils reverseData:data] getBytes:&res length:4];
    return res;
}

+(NSString *)dataToString:(NSData *)data {
    NSString *received = [[NSString alloc]init];
    for(int i=0; i<data.length; i++){
        UInt8 buf[1];
        [data getBytes:&buf range:NSMakeRange(i, 1)];
        NSString *toAppend = [NSString stringWithFormat:@"%d ", buf[0]];
        received = [received stringByAppendingString:toAppend];
    }
    return received;
}

+(UInt8)readOneByteFrom:(NSData *)source atIndex:(int)index {
    UInt8 buf[1];
    [source getBytes:&buf range:NSMakeRange(index, 1)];
    return buf[0];
}

@end