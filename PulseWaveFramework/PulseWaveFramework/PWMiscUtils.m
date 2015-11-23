//
//  StringUtils.m
//  BodyCapSerial
//
//  Created by Yann Lapeyre on 23/07/2015.
//  Copyright (c) 2015 Medes-IMPS. All rights reserved.
//

#import "PWMiscUtils.h"


@implementation PWMiscUtils

+(NSInteger)countLineFromString:(NSString *)text{
    return [[text componentsSeparatedByCharactersInSet:
                         [NSCharacterSet newlineCharacterSet]] count];
}

+(NSString *)deleteFirstLine:(NSString *)text{
    NSRange range = [text rangeOfString:@"\n"];
    return [text substringFromIndex:range.location+1];
}

+(void)displayLocalNotification:(NSString *)message{
    
    // configure the notification
    UILocalNotification* localNotification = [[UILocalNotification alloc] init];
    localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:1];
    localNotification.alertBody = [NSString stringWithFormat:@"%@",message];
    localNotification.timeZone = [NSTimeZone defaultTimeZone];
    
    // display it
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

@end
