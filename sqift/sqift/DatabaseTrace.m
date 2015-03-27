//
//  DatabaseTrace.m
//  sqift
//
//  Created by Dave Camp on 3/26/15.
//  Copyright (c) 2015 thinbits. All rights reserved.
//

#import "DatabaseTrace.h"

@implementation DatabaseTrace

+ (void)enableTrace:(sqlite3*)database
{
    if (sqlite3_trace(database, traceFunc, nil) != SQLITE_OK)
    {
        NSLog(@"Failed to register trace function");
    }
}

void traceFunc(void *refcon ,const char* string)
{
    NSLog(@"%s", string);
}

@end
