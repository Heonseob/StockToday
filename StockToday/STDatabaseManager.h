//
//  STDatabaseManager.h
//  StockToday
//
//  Created by csaint on 2015. 7. 21..
//  Copyright (c) 2015년 DaumKakao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FMDB.h>

#define DATABASE [STDatabaseManager sharedInstance]

@interface STDatabaseManager : NSObject

+ (STDatabaseManager *)sharedInstance;

//- (BOOL)transactionBegin;
//- (BOOL)transactionCommit;

- (BOOL)openDatabase;
- (BOOL)closeDatabase;

- (int)insertItemInfo:(NSArray *)itemArray market:(BOOL)kospi;

@end
