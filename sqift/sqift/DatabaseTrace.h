//
//  DatabaseTrace.h
//  sqift
//
//  Created by Dave Camp on 3/26/15.
//  Copyright (c) 2015 thinbits. All rights reserved.
//

@import Foundation;
@import sqlite3_ios_simulator;

typedef void (^FunctionBlock)(int64_t rowid);

@interface DatabaseTrace : NSObject

+ (void)enableTrace:(BOOL)enable database:(sqlite3*)database;
+ (int)addBlock:(FunctionBlock)block withName:(NSString*)name toDatabase:(sqlite3*)database;
+ (int)removeBlockForName:(NSString*)name inDatabase:(sqlite3*)database;

@end
