//
//  DatabaseTrace.m
//  sqift
//
//  Created by Dave Camp on 3/26/15.
//  Copyright (c) 2015 thinbits. All rights reserved.
//

#import "DatabaseTrace.h"

static NSMutableDictionary  *functions = nil;

@implementation DatabaseTrace

+ (void)enableTrace:(BOOL)enable database:(sqlite3*)database
{
    @autoreleasepool {
        if (sqlite3_trace(database, enable ? traceFunc : nil, nil) != SQLITE_OK)
        {
            NSLog(@"Failed to register trace function");
        }
    }
    
}

+ (int)addBlock:(FunctionBlock)block withName:(NSString*)name toDatabase:(sqlite3*)database
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        functions = [NSMutableDictionary dictionary];
    });
    
    int  result = SQLITE_OK;
    
    @autoreleasepool {
        // Unregister existing function
        result = [self removeBlockForName:name inDatabase:database];
        
        if (block != nil && result == SQLITE_OK)
        {
            functions[name] = block;
            
            result = sqlite3_create_function_v2(database, "sqliteFunction", -1, SQLITE_UTF8, NULL, sqliteFunction, NULL, NULL, NULL);
        }
    }
    
    return result;
}

+ (int)removeBlockForName:(NSString*)name inDatabase:(sqlite3*)database
{
    int  result = SQLITE_OK;
    
    @autoreleasepool {
        // Unregister existing function
        if (functions[name] != nil)
        {
            result = sqlite3_create_function_v2(database, "sqliteFunction", -1, SQLITE_UTF8, NULL, NULL, NULL, NULL, NULL);
            [functions removeObjectForKey:name];
        }
    }
    
    return result;
}


void traceFunc(void *refcon ,const char* string)
{
    @autoreleasepool {
        NSLog(@"sqlite trace: %s", string);
    }
}

void sqliteFunction(sqlite3_context *context, int argc, sqlite3_value **argv)
{
    @autoreleasepool {
        if (argc == 2)
        {
            NSString *name = [NSString stringWithUTF8String:(const char *)sqlite3_value_text(argv[0])];
            int64_t rowid = sqlite3_value_int64(argv[1]);
            
            if ([name length] != 0)
            {
                FunctionBlock block = functions[name];
                if (block != nil)
                {
                    block(rowid);
                }
                else
                {
                    NSLog(@"Trigger called for unknown name");
                }
            }
        }
    }
}

@end
