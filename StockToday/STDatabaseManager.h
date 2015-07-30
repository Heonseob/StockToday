//
//  STDatabaseManager.h
//  StockToday
//
//  Created by csaint on 2015. 7. 21..
//  Copyright (c) 2015년 DaumKakao. All rights reserved.
//

#import <Foundation/Foundation.h>

#define DATABASE [STDatabaseManager sharedInstance]

@interface STItemInfo : NSObject

@property (nonatomic, strong) NSString *infoCode;
@property (nonatomic, strong) NSString *infoName;
@property (nonatomic, assign) float taxBuy;
@property (nonatomic, assign) float taxSell;
@property (nonatomic, assign) float feeBuy;
@property (nonatomic, assign) float feeSell;

@end

@interface STItemPrice : NSObject

@property (nonatomic, strong) NSString *priceDate;
@property (nonatomic, assign) UInt priceStart;
@property (nonatomic, assign) UInt priceHigh;
@property (nonatomic, assign) UInt priceLow;
@property (nonatomic, assign) UInt priceEnd;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////

@interface STDatabaseManager : NSObject

+ (STDatabaseManager *)sharedInstance;

//- (BOOL)transactionBegin;
//- (BOOL)transactionCommit;

- (BOOL)openDatabase;
- (BOOL)closeDatabase;

- (BOOL)openItemTable:(NSString *)itemCode;
- (BOOL)resetItemTable:(NSString *)itemCode;

- (int)insertItemInfo:(NSArray *)itemInfo market:(BOOL)kospi;
- (int)insertItemPrice:(NSArray *)itemPrice itemCode:(NSString *)itemCode;
- (BOOL)deleteLastItemPrice:(NSString *)itemCode;

- (BOOL)selectItemCode:(NSString *)itemCode targetInfo:(STItemInfo *)itemInfo targetPrices:(NSMutableArray *)itemPrices;

@end
