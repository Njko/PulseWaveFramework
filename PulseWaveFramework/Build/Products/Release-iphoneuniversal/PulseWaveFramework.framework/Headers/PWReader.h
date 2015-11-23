//
//  PWReader.h
//  PulseWaveFramework
//
//  Created by Nicolas Linard on 23/11/2015.
//  Copyright © 2015 MEDES. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PWReaderDelegate.h"
@interface PWReader : NSObject

@property (nonatomic, weak) id<PWReaderDelegate> delegate;

-(void)newBytesRead:(NSData *)read;

@end
