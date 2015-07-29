//
//  STTradeSimulation.h
//  StockToday
//
//  Created by csaint on 2015. 7. 29..
//  Copyright (c) 2015년 DaumKakao. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface STItemPrice : NSObject

@property (atomic, strong) NSString *priceDate;
@property (atomic, assign) UInt *priceStart;
@property (atomic, assign) UInt *priceHigh;
@property (atomic, assign) UInt *priceLow;
@property (atomic, assign) UInt *priceEnd;

@end


@interface STTradeSimulation : NSObject

@property (atomic, strong) NSString *itemCode;
@property (atomic, strong) NSString *itemName;
@property (atomic, assign) float *taxBuy;       //매수 세금
@property (atomic, assign) float *taxSell;      //매도 세금
@property (atomic, assign) float *feeBuy;       //매수 증권수수료
@property (atomic, assign) float *feeSell;      //매도 증권수수료



@end
