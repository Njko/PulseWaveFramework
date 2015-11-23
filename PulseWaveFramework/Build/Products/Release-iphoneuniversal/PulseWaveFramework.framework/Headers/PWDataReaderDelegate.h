//
//  PWDataReaderDelegate.h
//  PulwaveAnalyser
//
//  Created by Nicolas Linard on 03/11/2015.
//  Copyright © 2015 MEDES. All rights reserved.
//

#ifndef PWDataReaderDelegate_h
#define PWDataReaderDelegate_h

@protocol PWDataReaderDelegate <NSObject>

- (void) didChangeConnectionStatus:(BOOL)isConnected;
- (void) didReceiveValue:(NSString *)value;

@end

#endif /* PWDataReaderDelegate_h */
