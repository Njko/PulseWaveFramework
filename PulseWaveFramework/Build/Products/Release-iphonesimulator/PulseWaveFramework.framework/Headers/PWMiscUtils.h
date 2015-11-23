//
//  StringUtils.h
//  BodyCapSerial
//
//  Created by Yann Lapeyre on 23/07/2015.
//  Copyright (c) 2015 Medes-IMPS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface PWMiscUtils : NSObject
+(NSInteger)countLineFromString:(NSString *)text;

+(NSString *)deleteFirstLine:(NSString *)text;

+(void)displayLocalNotification:(NSString *)message;
@end
