//
//  PWEtactReader.m
//  PulseWave Pod
//
//  Created by Yann Lapeyre on 29/07/2015.
//  Modified by Nicolas Linard on 30/10/2015.
//  Copyright (c) 2015 Medes-IMPS. All rights reserved.
//

#import "PWEtactReader.h"
#import "PWEtactCommands.h"
#import "PWByteUtils.h"

const UInt8 STRING_READER_MODE = 1;
const UInt8 UINT_READER_MODE = 2;

const int RESULT_SIZE = 4;

@interface PWEtactReader()

@property (nonatomic) ReaderStatus status;
@property (nonatomic, strong) NSMutableData *receivedBytes;
@property (nonatomic) UInt8 currentCommand;
@property (nonatomic, strong) NSData *currentResponse;
@property (nonatomic) int expectedResponseSize;

@end

@implementation PWEtactReader

-(instancetype) init {
    self = [super init];
    if(self){
        self.currentCommand = 0;
        self.expectedResponseSize = 0;
        self.status = idle_status;
        self.receivedBytes = [[NSMutableData alloc] init];
        self.mode = STRING_READER_MODE;
    }
    return self;
}

#pragma mark - Public object methods
-(void)newBytesRead:(NSData *)read {
    [self.receivedBytes appendData:read];
    
    switch(self.status){
        case idle_status:
            if(read.length>2){
                [self handleResult];
            }
            break;
        case in_result_status:
            [self handleResponse];
            break;
        case in_response_status:
            [self handleResponse];
            break;
        case in_error_status:
            break;
    }
    
}

#pragma mark - Private object methods
-(void)handleResult {
    
     // ACK - NACK packet reception
    UInt8 command = [PWByteUtils readOneByteFrom:self.receivedBytes atIndex:0];
    UInt8 size = [PWByteUtils readOneByteFrom:self.receivedBytes atIndex:1];
    UInt8 result = [PWByteUtils readOneByteFrom:self.receivedBytes atIndex:2];
    UInt8 crc = [PWByteUtils readOneByteFrom:self.receivedBytes atIndex:3];
    
    //
    self.currentCommand = command;
    
    // Check CRC
    UInt8 buffer[3];
    buffer[0]= command;
    buffer[1]= size;
    buffer[2] = result;
    
    UInt8 confirm = [PWEtactCommands computeCrc:[[NSData alloc] initWithBytes:buffer length:3]];
    
    // Status progress
    if(crc == confirm){
        self.status = in_result_status;
        [self.delegate readerStatusChanged:self.status :@"Result received ..."];
        if(result == 0xA5){
            // Handle response
            [self handleResponse];
        }
    }else{
        self.status = in_error_status;
        [self.delegate readerStatusChanged:self.status :@"Result CRC invalid."];
    }
}

// handle the response received
-(void)handleResponse {
    
    // response header
    if(self.status == in_result_status){
        //UInt8 command = [ByteUtils readOneByteFrom:self.receivedBytes atIndex:RESULT_SIZE];
        self.expectedResponseSize = [PWByteUtils readOneByteFrom:self.receivedBytes atIndex:RESULT_SIZE+1];
        self.status = in_response_status;
    }
    
    // response body
    if(self.status == in_response_status && self.receivedBytes.length >= RESULT_SIZE+self.expectedResponseSize){
        
        //Check CRC
        UInt8 crc = [PWByteUtils readOneByteFrom:self.receivedBytes atIndex:(int)self.receivedBytes.length-1];
        UInt8 responseBytes[self.expectedResponseSize+2];
        [self.receivedBytes getBytes:&responseBytes range:NSMakeRange(RESULT_SIZE, self.expectedResponseSize+2)];
        UInt8 confirm = [PWEtactCommands computeCrc:[[NSData alloc] initWithBytes:responseBytes length:self.expectedResponseSize+2]];
        
        if(crc == confirm){
            
            UInt8 payload[self.expectedResponseSize];
            [self.receivedBytes getBytes:&payload range:NSMakeRange(RESULT_SIZE+2, self.expectedResponseSize)];
            
            // handle the response payload
            if(self.mode == STRING_READER_MODE){
                [self handleStringPayload:[NSData dataWithBytes:payload length:self.expectedResponseSize]];
            }else if(self.mode == UINT_READER_MODE){
                [self handleUIntPayload:[NSData dataWithBytes:payload length:self.expectedResponseSize]];
            }
            
        }else{
            self.status = in_error_status;
            [self.delegate readerStatusChanged:self.status :[NSString stringWithFormat:@"Invalid crc: %d",confirm]];
        }
    }
}

// handle a response paylaod of type 'String'
-(void)handleStringPayload:(NSData *)payload {
    NSString *response = [[NSString alloc] initWithData:payload encoding:NSUTF8StringEncoding];
    [self.delegate readerStatusChanged:self.status :[NSString stringWithFormat:@"Response received, %@",response]];
    [self.delegate responseReceived:self.currentCommand :response];
}

// handle a response payload of type 'unsigned int'
-(void)handleUIntPayload:(NSData *)payload{
    UInt32 response =[PWByteUtils dataToUInt32:payload];
    [self.delegate readerStatusChanged:self.status :[NSString stringWithFormat:@"Response received, %d",(unsigned int)response]];
    [self.delegate responseReceived:self.currentCommand :[NSNumber numberWithInt:response]];
}


@end
