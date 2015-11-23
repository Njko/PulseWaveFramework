//
//  PWReaderDelegate.h
//  PulseWaveFramework
//
//  Created by Nicolas Linard on 23/11/2015.
//  Copyright © 2015 MEDES. All rights reserved.
//

#ifndef PWReaderDelegate_h
#define PWReaderDelegate_h

@protocol PWReaderDelegate

-(void)newPulseWaveValue:(NSString *)value;

@end

#endif /* PWReaderDelegate_h */
