//
//  DatabaseTrace.h
//  sqift
//
//  Created by Dave Camp on 3/26/15.
//  Copyright (c) 2015 thinbits. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface DatabaseTrace : NSObject

+ (void)enableTrace:(sqlite3*)database;

@end
