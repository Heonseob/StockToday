//
//  STMainViewController.m
//  StockToday
//
//  Created by csaint on 2015. 7. 15..
//  Copyright (c) 2015년 DaumKakao. All rights reserved.
//

#import "STMainViewController.h"

#import <GCDAsyncSocket.h>
#import <AFNetworking.h>
#import <FMDB.h>
#import <JSONKit.h>

#define SCHEMA_VERSION 1

@interface STMainViewController ()

@property (weak) IBOutlet NSButton* openDatabase;
@property (weak) IBOutlet NSButton* updateKOSPIList;
@property (weak) IBOutlet NSButton* updateKOSDAQList;

@property (strong) FMDatabase *db;
@property (strong) NSOperationQueue *queue;

@property (strong) AFHTTPRequestOperationManager *operationManager;

@end

@implementation STMainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.operationManager = [[AFHTTPRequestOperationManager alloc] init];
    self.operationManager.responseSerializer = [AFHTTPResponseSerializer serializer];

//    AFHTTPRequestSerializer *requestSerializer = self.operationManager.requestSerializer;
//    [requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
//    self.operationManager.responseSerializer = [AFJSONResponseSerializer serializer];

    self.queue = [NSOperationQueue new];
    self.queue.maxConcurrentOperationCount = 1;
    self.queue.name = @"StockToday";
}

- (IBAction)openDatabase:(id)sender
{
    BOOL open = [self openDatabaseFile];
    if (open == NO)
        return;
    
    NSLog(@"OpenDatabase Success");
}

- (IBAction)updateKOSPIListPressed:(id)sender
{
    [self updateStockItemList:YES];
}

- (IBAction)updateKOSDAQListPressed:(id)sender
{
    [self updateStockItemList:NO];
}

- (void) updateStockItemList:(BOOL)kospi
{
    NSString *stockListAPI = nil;
    
    if (kospi)
        stockListAPI = @"http://stock.daum.net/xml/xmlallpanel.daum?stype=P&type=S"; //KOSPI (가나다=S / 업종순=U)
    else
        stockListAPI = @"http://stock.daum.net/xml/xmlallpanel.daum?stype=Q&type=S"; //KOSDAQ (가나다=S / 업종순=U)

    [self.operationManager GET:stockListAPI parameters:nil
                       success:^(AFHTTPRequestOperation *operation, id responseObject) {
                           
                           NSString *stockInfo = [[NSString alloc] initWithUTF8String:[(NSData *)responseObject bytes]];
                           stockInfo = [stockInfo stringByReplacingOccurrencesOfString:@"timeinfo" withString:@"\"info\""];
                           stockInfo = [stockInfo stringByReplacingOccurrencesOfString:@"kospi" withString:@"\"kospi\""];
                           stockInfo = [stockInfo stringByReplacingOccurrencesOfString:@"kosdaq" withString:@"\"kosdaq\""];
                           stockInfo = [stockInfo stringByReplacingOccurrencesOfString:@"item" withString:@"\"item\""];
                           stockInfo = [stockInfo stringByReplacingOccurrencesOfString:@"date" withString:@"\"date\""];
                           stockInfo = [stockInfo stringByReplacingOccurrencesOfString:@"time" withString:@"\"time\""];
                           stockInfo = [stockInfo stringByReplacingOccurrencesOfString:@"message" withString:@"\"message\""];
                           stockInfo = [stockInfo stringByReplacingOccurrencesOfString:@"cost" withString:@"\"cost\""];
                           stockInfo = [stockInfo stringByReplacingOccurrencesOfString:@"updn" withString:@"\"updn\""];
                           stockInfo = [stockInfo stringByReplacingOccurrencesOfString:@"rate" withString:@"\"rate\""];
                           stockInfo = [stockInfo stringByReplacingOccurrencesOfString:@"code" withString:@"\"code\""];
                           stockInfo = [stockInfo stringByReplacingOccurrencesOfString:@"name" withString:@"\"name\""];
                           stockInfo = [stockInfo stringByReplacingOccurrencesOfString:@"var dataset =" withString:@""];
                           stockInfo = [stockInfo stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@""];
                           stockInfo = [stockInfo stringByReplacingOccurrencesOfString:@";" withString:@""];
                           
                           NSDictionary* info = [stockInfo objectFromJSONString];
                           if (info == nil)
                           {
                               NSLog(@"StockItemList SUCCESS, BUT JSON Parsing Fail");
                               return;
                           }
                           
                           NSArray *itemArray = [info objectForKey:@"item"];
                           if (itemArray == nil)
                           {
                               NSLog(@"StockItemList SUCCESS, BUT StockData invalid");
                               return;
                           }
                           
                           //NSMutableDictionary *itemList = [NSMutableDictionary new];

                           [self.db beginTransaction];

                           int index = 0;
                           NSString *itemCode = nil, *itemName = nil, *queryItemInsert = nil;
                           for (NSDictionary* item in itemArray)
                           {
                               itemCode = [item objectForKey:@"code"];
                               itemName = [item objectForKey:@"name"];
                               
                               if (itemCode == nil || itemName == nil)
                                   continue;
                               
                               if (itemCode.length > 6)
                                   continue;
                               
                               queryItemInsert = [NSString stringWithFormat:@"INSERT OR IGNORE INTO SHItemInfo (code,name,marketType) VALUES ('%@', '%@', %d);", itemCode, itemName, kospi?0:1];
                               if ([self.db executeUpdate:queryItemInsert] == NO)
                               {
                                   
                               }
                               
                               //itemList[itemCode] = itemName;
                               NSLog(@"%4d : [%@] %@", index++, itemCode, itemName);
                           }
                           
                           [self.db commit];
                           
                       } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                           NSLog(@"StockItemList FAIL - %@", error);
                       }];
}

- (BOOL)openDatabaseFile
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *dir = [paths objectAtIndex:0];
    dir = [dir stringByAppendingPathComponent:@"StockToday.db"];
    
    do {
        self.db = [FMDatabase databaseWithPath:dir];
        if (self.db == nil || ![self.db open])
        {
            NSLog(@"Couldn't open database at path: %@", dir);
            return NO;
        }
        
        if ([self.db getSchema] == nil)
        {
            NSLog(@"database is invalid: %@", self.db.lastError);
            NSError *error;
            if ([[NSFileManager defaultManager] removeItemAtPath:dir error:&error])
                continue;
            
            NSLog(@"Couldn't delete database file: %@", error);
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
            [self.db beginTransaction];
            
            for (NSString *query in [self queryArrayForCreatingSchema])
            {
                if ([self.db executeUpdate:query] == NO)
                {
                    [[NSException exceptionWithName:@"DB_CREATE"
                                             reason:self.db.lastError.localizedDescription
                                           userInfo:@{ @"error": self.db.lastError }] raise];
                }
            }
            
            [self.db commit];
            
            [self.db executeUpdate:[NSString stringWithFormat:@"PRAGMA user_version = %d", SCHEMA_VERSION]];
        }
        
        openSuccess = YES;
    }
    @catch (NSException *exception)
    {
        openSuccess = NO;

        NSError *error;
        if (![[NSFileManager defaultManager] removeItemAtPath:self.db.databasePath error:&error])
            NSLog(@"Couldn't delete database file: %@", error);
        @throw;
    }
    
    return openSuccess;
}

- (NSArray *)queryArrayForCreatingSchema
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
             
             (@"CREATE TABLE IF NOT EXISTS SHItem ("
                "code           TEXT NOT NULL,"
                "date           INTEGER NOT NULL,"
                "start          INTEGER NOT NULL,"
                "high           INTEGER NOT NULL,"
                "low            INTEGER NOT NULL,"
                "end            INTEGER NOT NULL,"
                "updown         INTEGER NOT NULL,"
                "rate           REAL NOT NULL,"
                "PRIMARY KEY(code,date)"
                ");"),
             
             (@"CREATE INDEX IF NOT EXISTS idx_item_code ON SHItem (code);"),
             (@"CREATE INDEX IF NOT EXISTS idx_item_date ON SHItem (date);"),
             
             (@"INSERT INTO SHMarket (marketType, name) VALUES (0, 'KOSPI');"),
             (@"INSERT INTO SHMarket (marketType, name) VALUES (1, 'KOSDAQ');")
     ];
}

@end
