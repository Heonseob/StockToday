//
//  STDatabaseManager.m
//  StockToday
//
//  Created by csaint on 2015. 7. 21..
//  Copyright (c) 2015년 DaumKakao. All rights reserved.
//

#import "STDatabaseManager.h"

#define SCHEMA_VERSION 1

@interface STDatabaseManager ()

@property (assign) BOOL isDatabaseOpen;
@property (strong) FMDatabase *db;
@property (strong) NSOperationQueue *queue;

@end

@implementation STDatabaseManager

+ (STDatabaseManager *)sharedInstance
{
    static STDatabaseManager *sharedDataStore = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedDataStore = [[STDatabaseManager alloc] init];
    });
    
    return sharedDataStore;
}

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        self.isDatabaseOpen = NO;
        
        self.queue = [NSOperationQueue new];
        self.queue.maxConcurrentOperationCount = 1;
        self.queue.name = @"StockToday";
    }
    
    return self;
}

//- (BOOL)transactionBegin
//{
//    if (self.isDatabaseOpen == NO)
//        return NO;
//
//    return [self.db beginTransaction];
//}
//
//- (BOOL)transactionCommit
//{
//    if (self.isDatabaseOpen == NO)
//        return NO;
//
//    return [self.db commit];
//}

- (BOOL)openDatabase
{
    if (self.isDatabaseOpen)
        return YES;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *dir = [paths objectAtIndex:0];
    dir = [dir stringByAppendingPathComponent:@"StockToday.db"];
    
    do {
        self.db = [FMDatabase databaseWithPath:dir];
        if (self.db == nil || ![self.db open])
        {
            NSLog(@"[DATABASE] Couldn't open database at path: %@", dir);
            return NO;
        }
        
        if ([self.db getSchema] == nil)
        {
            NSLog(@"[DATABASE] Database is invalid: %@", self.db.lastError);
            NSError *error;
            if ([[NSFileManager defaultManager] removeItemAtPath:dir error:&error])
                continue;
            
            NSLog(@"[DATABASE] Couldn't delete database file: %@", error);
            return NO;
        }
        
    } while (NO);
    
    [self.db setShouldCacheStatements:YES];
    [self.db setCrashOnErrors:YES];
    [self.db setLogsErrors:YES];
    
    int schemaVersion = 0;
    FMResultSet *rs = [self.db executeQuery:@"PRAGMA user_version"];
    if ([rs next])
        schemaVersion = [rs intForColumnIndex:0];
    [rs close];
    
    BOOL openSuccess = NO;
    
    @try
    {
        [self.db executeQuery:@"PRAGMA secure_delete = 1"];
        [self.db executeQuery:@"PRAGMA journal_mode = wal"];
        [self.db executeQuery:@"PRAGMA synchronous = 1"];
        [self.db executeQuery:@"PRAGMA fullfsync = 1"];
        
        if (schemaVersion < SCHEMA_VERSION)
        {
            //[self.db beginTransaction];
            
            for (NSString *query in [self queryArrayForCreatingBaseSchema])
            {
                if ([self.db executeUpdate:query] == NO)
                {
                    [[NSException exceptionWithName:@"STDATABASE"
                                             reason:self.db.lastError.localizedDescription
                                           userInfo:@{ @"error": self.db.lastError }] raise];
                }
            }
            
            //[self.db commit];
            
            [self.db executeUpdate:[NSString stringWithFormat:@"PRAGMA user_version = %d", SCHEMA_VERSION]];
        }

        NSLog(@"[DATABASE] open Success");
        openSuccess = YES;
    }
    @catch (NSException *exception)
    {
        openSuccess = NO;
        
        NSError *error;
        if (![[NSFileManager defaultManager] removeItemAtPath:self.db.databasePath error:&error])
            NSLog(@"[DATABASE] Couldn't delete database file: %@", error);
        @throw;
    }
    
    self.isDatabaseOpen = openSuccess;
    return openSuccess;
}

- (BOOL)closeDatabase
{
    if (self.isDatabaseOpen == NO)
        return YES;

    BOOL closeSuccess = [self.db close];
    if (closeSuccess == YES)
    {
        self.isDatabaseOpen = NO;
        NSLog(@"[DATABASE] close Success");
    }

    return closeSuccess;
}

- (int)insertItemInfo:(NSArray *)itemInfo market:(BOOL)kospi
{
    if (self.isDatabaseOpen == NO)
        return 0;

    [self.db beginTransaction];
    
    int index = 0;
    NSString *itemCode, *itemName;
    for (NSDictionary* item in itemInfo)
    {
        itemCode = itemName = nil;
        itemCode = [item objectForKey:@"code"];
        itemName = [item objectForKey:@"name"];
        
        if (itemCode == nil || itemName == nil)
            continue;
        
        if (itemCode.length > 6)
            continue;
        
        if ([self.db executeUpdate:[NSString stringWithFormat:@"INSERT OR IGNORE INTO SHItemInfo (code,name,marketType) VALUES ('%@', '%@', %d);",
                                    itemCode, itemName, kospi?0:1]] == NO)
            continue;

        if ([self openItemTable:itemCode] == NO)
            continue;

        //NSLog(@"[DATABASE] %4d : [%@] %@", index++, itemCode, itemName);
    }
    
    [self.db commit];

    return index;
}

- (BOOL)openItemTable:(NSString *)itemCode
{
    NSString* queryTable = [NSString stringWithFormat:@"SELECT count(*) FROM sqlite_master WHERE type = 'table' AND name = 'SHItem_%@';", itemCode];
    
    int countTable = 0;
    FMResultSet *rs = [self.db executeQuery:queryTable];
    if ([rs next])
        countTable = [rs intForColumnIndex:0];
    [rs close];
    
    if (countTable == 0)
    {
        for (NSString *query in [self queryArrayForCreatingItemSchema:itemCode])
        {
            if ([self.db executeUpdate:query] == NO)
                return NO;
        }
    }
    
    return YES;
}

- (BOOL)resetItemTable:(NSString *)itemCode
{
    NSString* queryTable = [NSString stringWithFormat:@"SELECT count(*) FROM sqlite_master WHERE type = 'table' AND name = 'SHItem_%@';", itemCode];
    
    int countTable = 0;
    FMResultSet *rs = [self.db executeQuery:queryTable];
    if ([rs next])
        countTable = [rs intForColumnIndex:0];
    [rs close];
    
    if (countTable > 0)
    {
        if ([self.db executeUpdate:[NSString stringWithFormat:@"DROP TABLE IF EXISTS 'SHItem_%@';", itemCode]] == NO)
            return NO;
    }
    
    BOOL openSuccess = [self openItemTable:itemCode];
    return openSuccess;
}

- (int)insertItemPrice:(NSArray *)itemPrice itemCode:(NSString *)itemCode
{
    if (self.isDatabaseOpen == NO)
        return -1;

    if (itemPrice == nil || itemCode == nil)
        return -1;
    
    if (itemPrice.count == 0)
        return 0;
    
    int insertCount = 0;

    [self.db beginTransaction];

    for (NSArray *arrayPrice in itemPrice)
    {
        if ([self.db executeUpdate:[NSString stringWithFormat:@"INSERT INTO SHItem_%@ (date,start,high,low,end,updown,amount) VALUES ('%@',%@,%@,%@,%@,%@,%@);",
                                    itemCode,
                                    [arrayPrice objectAtIndex:0],
                                    [arrayPrice objectAtIndex:1],
                                    [arrayPrice objectAtIndex:2],
                                    [arrayPrice objectAtIndex:3],
                                    [arrayPrice objectAtIndex:4],
                                    [arrayPrice objectAtIndex:5],
                                    [arrayPrice objectAtIndex:6]]] == NO)
            continue;

        insertCount++;
    }

    [self.db commit];
    
    return insertCount;
}

- (BOOL)deleteLastItemPrice:(NSString *)itemCode
{
    if (self.isDatabaseOpen == NO)
        return NO;

    if (itemCode == nil)
        return NO;
    
    NSString *querySQL = [NSString stringWithFormat:@"DELETE FROM SHItem_%@ WHERE date IN (SELECT date FROM SHItem_%@ ORDER BY date DESC limit 2);", itemCode, itemCode];
    if ([self.db executeUpdate:querySQL] == NO)
        return NO;
    
    return YES;
}

- (NSArray *)queryArrayForCreatingBaseSchema
{
    return @[
             (@"CREATE TABLE IF NOT EXISTS SHMarket ("
              "marketType     INTEGER NOT NULL UNIQUE,"
              "name           TEXT NOT NULL UNIQUE,"
              "up_max         REAL NOT NULL DEFAULT 0.30,"
              "down_max       REAL NOT NULL DEFAULT -0.30,"
              "PRIMARY KEY(marketType)"
              ");"),
             
             (@"CREATE TABLE IF NOT EXISTS SHItemInfo ("
              "code           TEXT NOT NULL UNIQUE,"
              "name           TEXT NOT NULL UNIQUE,"
              "marketType     INTEGER NOT NULL,"
              "branchType     INTEGER DEFAULT 0,"
              "tax_buy        REAL NOT NULL DEFAULT 0.0,"
              "tax_sell       REAL NOT NULL DEFAULT 0.0030,"
              "fee_buy        REAL NOT NULL DEFAULT 0.000150,"
              "fee_sell       REAL NOT NULL DEFAULT 0.000150,"
              "PRIMARY KEY(code,name)"
              ");"),
             
             (@"CREATE INDEX IF NOT EXISTS idx_itemInfo_code ON SHItemInfo (code);"),
             (@"CREATE INDEX IF NOT EXISTS idx_itemInfo_name ON SHItemInfo (name);"),
             
             (@"INSERT INTO SHMarket (marketType, name) VALUES (0, 'KOSPI');"),
             (@"INSERT INTO SHMarket (marketType, name) VALUES (1, 'KOSDAQ');")
         ];
}

- (NSArray *)queryArrayForCreatingItemSchema:(NSString*)itemCode
{
    NSString* queryTableName = (@"CREATE TABLE IF NOT EXISTS SHItem_{ITEM_CODE} ("
                                "date   TEXT NOT NULL UNIQUE, /* YYYY-MM-DD */"
                                "start  INTEGER NOT NULL,"
                                "high   INTEGER NOT NULL,"
                                "low    INTEGER NOT NULL,"
                                "end    INTEGER NOT NULL,"
                                "updown INTEGER NOT NULL,"
                                "amount INTEGER NOT NULL,"
                                "PRIMARY KEY(date)"
                                ");");
    
    NSString* queryIndex = (@"CREATE INDEX IF NOT EXISTS idx_item_{ITEM_CODE}_date ON SHItem_{ITEM_CODE} (date);");
    
    queryTableName = [queryTableName stringByReplacingOccurrencesOfString:@"{ITEM_CODE}" withString:itemCode];
    queryIndex = [queryIndex stringByReplacingOccurrencesOfString:@"{ITEM_CODE}" withString:itemCode];
    
    return @[queryTableName, queryIndex];
}


@end
