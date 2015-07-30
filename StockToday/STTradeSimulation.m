//
//  STTradeSimulation.m
//  StockToday
//
//  Created by csaint on 2015. 7. 29..
//  Copyright (c) 2015년 DaumKakao. All rights reserved.
//

#import "STTradeSimulation.h"
#import "STDatabaseManager.h"

@interface STTradeSimulation()

@property (strong) STItemInfo* itemInfo;
@property (strong) NSMutableArray* itemPrices;

@end

@implementation STTradeSimulation

- (void)setItemCode:(NSString *)itemCode
{
    if (_itemCode != nil && [_itemCode isEqualToString:itemCode])
        return;
        
    self.itemInfo = [[STItemInfo alloc] init];
    self.itemPrices = [[NSMutableArray alloc] init];
    
    BOOL prefareData = [DATABASE selectItemCode:itemCode targetInfo:self.itemInfo targetPrices:self.itemPrices];
    
    if (prefareData == NO)
        return;
    
    _itemCode = itemCode;
}

@end
