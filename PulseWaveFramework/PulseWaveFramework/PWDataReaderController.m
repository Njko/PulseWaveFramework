//
//  PWDataReaderController.m
//  PulwaveAnalyser
//
//  Created by Nicolas Linard on 03/11/2015.
//  Copyright © 2015 MEDES. All rights reserved.
//


#import <CocoaLumberjack/CocoaLumberjack.h>
#import "PWDataReaderController.h"
#import "PWEtactReader.h"
#import "PWEtactCommands.h"
#import "PWEtactCmd.h"

@interface PWDataReaderController()

@property (nonatomic) BOOL connected;
@property (nonatomic, strong) NSTimer *cmdTimer;
@property (nonatomic, strong) RscMgr *rscMgr;
@property (nonatomic, strong) PWEtactReader *reader;
@property (nonatomic, strong) NSMutableArray *cmds;
@property (nonatomic, strong) NSThread *commThread;

@end

@implementation PWDataReaderController

static const DDLogLevel ddLogLevel = DDLogLevelVerbose;

-(instancetype)init {
    self.cmds = [[NSMutableArray alloc] init];
    self.connected = FALSE;
    DDLogInfo(@"init PWDataReaderController");
    [self configureRscMgr];
     
    return self;
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

- (void) startCommThread:(id)object
{
    // initialize RscMgr on this thread
    self.rscMgr = [[RscMgr alloc] init];
    [self.rscMgr setDelegate:self];
    // run the run loop
    [[NSRunLoop currentRunLoop] run];
}

#pragma mark - RscMgrDelegate protocol + port configuration

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
//    DDLogInfo(@"Cable status update, cable connected? :%@",self.connected?@"YES":@"NO");
    [self.delegate isDeviceConnected:self.connected];
}

-(void)readBytesAvailable:(UInt32)length{
    
    NSData *data = [self.rscMgr getDataFromBytesAvailable];
    if(self.reader){
        [self.reader newBytesRead:data];
    }
}


-(void)configureSerialPort {
    
//    DDLogInfo(@"Configure serial port");
    [self.rscMgr getDataFromBytesAvailable]; // clear the rx stream
    
    // configure the port
    [self.rscMgr setBaud:19200];
    
    serialPortConfig portCfg;
    [self.rscMgr getPortConfig:&portCfg];
    portCfg.parity = SERIAL_PARITY_NONE;
    portCfg.stopBits = STOPBITS_1;
    portCfg.rxFlowControl = RXFLOW_NONE;
    portCfg.txFlowControl = TXFLOW_NONE;
    portCfg.dataLen = SERIAL_DATABITS_8;
    
    [self.rscMgr setPortConfig:&portCfg requestStatus: NO];
}


-(void)portStatusChanged{
//    DDLogInfo(@"Port status changed");
}


#pragma mark - ReaderStatus

-(void)readerStatusChanged:(ReaderStatus)status :(NSString *)optionalText {
    if(status == in_error_status){
        [self performSelectorOnMainThread:@selector(responseError) withObject:nil waitUntilDone:NO];
    }
}

-(void)responseReceived:(UInt8)cmd :(NSObject *)result {
    [self.cmdTimer invalidate];
    switch (cmd) {
        case 0x04:
            DDLogInfo(@"Updating Harware Version to: %@", (NSNumber*)result);
            [self performSelectorOnMainThread:@selector(updateHardwareVersion:) withObject:result waitUntilDone:NO];
            break;
        case 0x05:
            DDLogInfo(@"Updating Software Version to: %@", (NSNumber*)result);
            [self performSelectorOnMainThread:@selector(updateSoftwareVersion:) withObject:result waitUntilDone:NO];
            break;
        case 0x06:
            DDLogInfo(@"Updating Bart Version to: %@", (NSNumber*)result);
            [self performSelectorOnMainThread:@selector(updateBartVersion:) withObject:result waitUntilDone:NO];
            break;
        default:
            break;
    }
    
    // send next command
    if(self.cmds.count >0){
        PWEtactCmd *nextCmd = [self.cmds objectAtIndex:0];
        [self.cmds removeObjectAtIndex:0];
        [self sendCommand:nextCmd];
    }else{
        self.reader = nil;
        [self.delegate deviceStatusChanged:Idle];
    }
    
    
}

#pragma mark - Main thread

-(void)responseError {
    self.reader = nil;
    [self.cmdTimer invalidate];
    [self.delegate deviceStatusChanged:Error];
}

-(void)responseTimeOut {
    self.reader = nil;
    [self.delegate deviceStatusChanged:Error];
}

-(void)updateHardwareVersion:(NSNumber *)versionNumber {
    [self.delegate updateHardwareVersion:versionNumber];
}

-(void)updateSoftwareVersion:(NSNumber *)versionNumber {
    [self.delegate updateSoftwareVersion:versionNumber];
}

-(void)updateBartVersion:(NSNumber *)versionNumber {
    [self.delegate updateBartVersion:versionNumber];
}


-(NSString *)readerStatusToString:(ReaderStatus)status{
    switch (status) {
        case idle_status:
            return @"IDLE";
            
        case in_result_status:
            return @"Handling result";
            
        case in_response_status:
            return @"Handling response";
            
        case in_error_status:
            return @"In error";
            
    }
}


#pragma mark - UI action

-(void)resetAction {
    [self.delegate deviceStatusChanged:Idle];
}


- (void)testAction{
    if(self.connected){
        [self.cmds removeAllObjects];
        [self.cmds addObject:[self integerResultCommand:[PWEtactCommands softwareVersion]]];
        [self.cmds addObject:[self integerResultCommand:[PWEtactCommands bartVersion]]];
        [self sendCommand:[self integerResultCommand:[PWEtactCommands hardwareVersion]]];
        [self.delegate deviceStatusChanged:Check];
    }
}

-(void)sendCommand:(PWEtactCmd *)cmd {
    
    self.reader = cmd.reader;
    self.reader.delegate = self;
    [self.rscMgr writeData: cmd.command];
    self.cmdTimer = [NSTimer scheduledTimerWithTimeInterval:1.5 target:self
                                                   selector:@selector(responseTimeOut)
                                                   userInfo:nil
                                                    repeats:NO];
}


-(PWEtactCmd *)integerResultCommand:(NSData *)cmdData {
    PWEtactCmd *cmd = [[PWEtactCmd alloc] init];
    cmd.command = cmdData;
    cmd.reader = [[PWEtactReader alloc]init];
    cmd.reader.delegate = self;
    cmd.reader.mode = 2;
    return cmd;
}

-(PWEtactCmd *)stringResultCommand:(NSData *)cmdData {
    PWEtactCmd *cmd = [[PWEtactCmd alloc] init];
    cmd.command = cmdData;
    cmd.reader = [[PWEtactReader alloc]init];
    cmd.reader.delegate = self;
    return cmd;
}
@end
