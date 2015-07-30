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
{
    BOOL _bookBuy;
}

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

- (void)setBuyPolicy:(NSArray *)buyRates howTo:(BOOL)bookBuy
{
    
}

- (void)setSellPolicy:(NSArray *)sellRates
{
    
}

- (BOOL)runSimulation
{
    //TODO Police 설정되어있는지 확인

    int countBuyTime = 0;      //매입횟수
    UInt countBuyAmount = 0;    //매입수량
    UInt totalBuyCost = 0;      //총매입금액
    UInt unitBuyFund = 10000000;    //투자단위
    
    float costSum = self.itemInfo.taxBuy + self.itemInfo.feeBuy + self.itemInfo.taxSell + self.itemInfo.feeSell;
    
    BOOL foundDate = NO;
    int countDay = 0;
    
    for (STItemPrice *itemPrice in self.itemPrices)
    {
        if ([itemPrice.priceDate isEqualToString:@"2014.12.01"])
            foundDate = YES;

        if (foundDate == NO) continue;
        
        if (countBuyTime == 0)
        {
            float costPerStock = itemPrice.priceEnd + (itemPrice.priceEnd * (self.itemInfo.taxBuy + self.itemInfo.feeBuy));
            
            countBuyTime++;
            countBuyAmount = unitBuyFund / costPerStock;
            totalBuyCost = countBuyAmount * itemPrice.priceEnd;

            UInt nextBuyPrice = itemPrice.priceEnd - (itemPrice.priceEnd * 0.03f);                 //추가 매입 3%
            NSLog(@"BUY (D+%d) 매입가 %d 다음매입가 %d (%d -> %d)", countDay, itemPrice.priceEnd, nextBuyPrice, countBuyAmount, countBuyAmount);
            continue;
        }

        countDay++;

        float averageBuyPrice = (float)totalBuyCost / (float)countBuyAmount;      //평단가
        float targetSellPrice = averageBuyPrice + (averageBuyPrice * (0.03f + costSum));   //목표 수익률 3%
        
        if (targetSellPrice >= itemPrice.priceLow && targetSellPrice <= itemPrice.priceHigh)
        {
            NSLog(@"SELL SUCCESS (D+%d)", countDay);
            break;
        }
        
        float targetBuyPrice = averageBuyPrice - (averageBuyPrice * 0.03f);                 //추가 매입 3%
        if (targetBuyPrice >= itemPrice.priceEnd)
        {
            float costPerStock = itemPrice.priceEnd + (itemPrice.priceEnd * (self.itemInfo.taxBuy + self.itemInfo.feeBuy));
            
            countBuyTime++;
            UInt buyAmount = (unitBuyFund * powf(2, MAX(0, countBuyTime-2))) / costPerStock;
            countBuyAmount += buyAmount;
            totalBuyCost += buyAmount * itemPrice.priceEnd;
            

            averageBuyPrice = (float)totalBuyCost / (float)countBuyAmount;      //평단가
            UInt nextBuyPrice = averageBuyPrice - (averageBuyPrice * 0.03f);                 //추가 매입 3%
            float downRate = ((averageBuyPrice / (float)itemPrice.priceEnd) - 1) * 100; //하락폭
            NSLog(@"BUY (D+%d) 매입가 %d / 평단가 %.0f 다음매입가 %d %.1f%% (%d -> %d) ", countDay, itemPrice.priceEnd, averageBuyPrice, nextBuyPrice, downRate, buyAmount, countBuyAmount);
        }
    }
    
    return YES;
}

- (BOOL)runSimulationWithStartPrice
{
    //TODO Police 설정되어있는지 확인
    
    int countBuyTime = 0;      //매입횟수
    UInt countBuyAmount = 0;    //매입수량
    UInt totalBuyCost = 0;      //총매입금액
    UInt unitBuyFund = 10000000;    //투자단위
    
    float costSum = self.itemInfo.taxBuy + self.itemInfo.feeBuy + self.itemInfo.taxSell + self.itemInfo.feeSell;
    
    BOOL foundDate = NO;
    int countDay = 0;
    
    for (STItemPrice *itemPrice in self.itemPrices)
    {
        if ([itemPrice.priceDate isEqualToString:@"2014.12.01"])
            foundDate = YES;
        
        if (foundDate == NO) continue;
        
        if (countBuyTime == 0)
        {
            float costPerStock = itemPrice.priceStart + (itemPrice.priceStart * (self.itemInfo.taxBuy + self.itemInfo.feeBuy));
            
            countBuyTime++;
            countBuyAmount = unitBuyFund / costPerStock;
            totalBuyCost = countBuyAmount * itemPrice.priceStart;
            
            UInt nextBuyPrice = itemPrice.priceStart - (itemPrice.priceStart * 0.03f);                 //추가 매입 3%
            NSLog(@"BUY (D+%d) 매입가 %d 다음매입가 %d (%d -> %d)", countDay, itemPrice.priceStart, nextBuyPrice, countBuyAmount, countBuyAmount);

            countDay++;
            continue;
        }

        float averageBuyPrice = (float)totalBuyCost / (float)countBuyAmount;      //평단가
        float targetBuyPrice = averageBuyPrice - (averageBuyPrice * 0.03f);                 //추가 매입 3%
        
        if (targetBuyPrice >= itemPrice.priceStart)
        {
            float costPerStock = itemPrice.priceStart + (itemPrice.priceStart * (self.itemInfo.taxBuy + self.itemInfo.feeBuy));
            
            countBuyTime++;
            UInt buyAmount = (unitBuyFund * powf(2, MAX(0, countBuyTime-2))) / costPerStock;
            countBuyAmount += buyAmount;
            totalBuyCost += buyAmount * itemPrice.priceStart;
            
            
            averageBuyPrice = (float)totalBuyCost / (float)countBuyAmount;      //평단가
            UInt nextBuyPrice = averageBuyPrice - (averageBuyPrice * 0.03f);                 //추가 매입 3%
            float downRate = ((averageBuyPrice / (float)itemPrice.priceStart) - 1) * 100; //하락폭
            NSLog(@"BUY (D+%d) 매입가 %d / 평단가 %.0f 다음매입가 %d %.1f%% (%d -> %d) ", countDay, itemPrice.priceStart, averageBuyPrice, nextBuyPrice, downRate, buyAmount, countBuyAmount);
        }
        
        averageBuyPrice = (float)totalBuyCost / (float)countBuyAmount;      //평단가
        float targetSellPrice = averageBuyPrice + (averageBuyPrice * (0.03f + costSum));   //목표 수익률 3%
        
        if (targetSellPrice >= itemPrice.priceLow && targetSellPrice <= itemPrice.priceHigh)
        {
            NSLog(@"SELL SUCCESS (D+%d)", countDay);
            break;
        }

        countDay++;
    }
    
    return YES;
}


@end
