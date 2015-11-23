//
//  PWDataReaderController.m
//  PulwaveAnalyser
//
//  Created by Nicolas Linard on 03/11/2015.
//  Copyright © 2015 MEDES. All rights reserved.
//


#import <CocoaLumberjack/CocoaLumberjack.h>
#import "PWDataReaderController.h"
#import "PWReader.h"
#define PW_BAUDS_RATE 9600

@interface PWDataReaderController()
@property (nonatomic) BOOL connected;
@property (nonatomic, strong) RscMgr *rscMgr;
@property (nonatomic, strong) PWReader *reader;
@property (nonatomic, strong) NSThread *commThread;

@end

@implementation PWDataReaderController

static const DDLogLevel ddLogLevel = DDLogLevelVerbose;

#pragma mark - init
-(instancetype)init {
    self.connected = FALSE;
    DDLogInfo(@"init PWDataReaderController");
    [self configureRscMgr];
     
    return self;
}

- (void) startCommThread:(id)object
{
    // initialize RscMgr on this thread
    self.rscMgr = [[RscMgr alloc] init];
    [self.rscMgr setDelegate:self];
    // run the run loop
    [[NSRunLoop currentRunLoop] run];
}

-(void)configureRscMgr {
    if (self.commThread == nil)
    {
        DDLogInfo(@"Configuring thread");
        self.commThread = [[NSThread alloc] initWithTarget:self
                                                  selector:@selector(startCommThread:)
                                                    object:nil];
        DDLogInfo(@"Launching thread");
        [self.commThread start];
    }
}

#pragma mark - Serial Port Configuration
-(void)configureSerialPort {
    
    [self.rscMgr getDataFromBytesAvailable]; // clear the rx stream
    
    // configure the port
    [self.rscMgr setBaud:PW_BAUDS_RATE];
    
    serialPortConfig portCfg;
    [self.rscMgr getPortConfig:&portCfg];
    portCfg.parity = SERIAL_PARITY_NONE;
    portCfg.stopBits = STOPBITS_1;
    portCfg.rxFlowControl = RXFLOW_NONE;
    portCfg.txFlowControl = TXFLOW_NONE;
    portCfg.dataLen = SERIAL_DATABITS_8;
    
    [self.rscMgr setPortConfig:&portCfg requestStatus: NO];
}

#pragma mark - Public methods
-(void)startToAcquire {
    if (self.connected) {
        if (!self.reader) {
            self.reader = [[PWReader alloc] init];
            self.reader.delegate = self;
        }
        UInt8 startByte = 0x31;
        [self.rscMgr write:&startByte Length:1];
    }
}

-(void)stopToAcquire {
    if (self.connected) {
        UInt8 startByte = 0x30;
        [self.rscMgr write:&startByte Length:1];
    }
}

-(BOOL) isDeviceConnected {
    return self.connected;
}

#pragma mark - RscMgrDelegate protocol

-(void)cableConnected:(NSString *)protocol {
    [self configureSerialPort];
    self.connected = YES;
    DDLogInfo(@"Cable Connected");
    [self performSelectorOnMainThread:@selector(updateCableStatus) withObject:nil waitUntilDone:NO];
}

-(void)cableDisconnected {
    self.connected = NO;
    DDLogInfo(@"Cable Disconnected");
    [self performSelectorOnMainThread:@selector(updateCableStatus) withObject:nil waitUntilDone:NO];
}

-(void) updateCableStatus{
    [self.delegate didChangeConnectionStatus:self.connected];
}

-(void)readBytesAvailable:(UInt32)length{
    
    NSData *data = [self.rscMgr getDataFromBytesAvailable];
    if(self.reader){
        [self.reader newBytesRead:data];
    }
}

-(void)portStatusChanged{
    DDLogInfo(@"Port Status changed");
}

#pragma mark - PWReaderDelegate protocol
-(void)newPulseWaveValue:(NSString *)value{
    [self.delegate didReceiveValue:value];
}

@end
