//
//  PWDataReaderController.h
//  PulwaveAnalyser
//
//  Created by Nicolas Linard on 03/11/2015.
//  Copyright © 2015 MEDES. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RscMgr.h"
#import "PWDataReaderDelegate.h"
#import "PWReaderDelegate.h"

@interface PWDataReaderController : NSObject <RscMgrDelegate, PWReaderDelegate>

@property (nonatomic, strong) id<PWDataReaderDelegate> delegate;

-(BOOL)isDeviceConnected;
-(void)startToAcquire;
-(void)stopToAcquire;
@end
