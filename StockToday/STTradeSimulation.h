//
//  STTradeSimulation.h
//  StockToday
//
//  Created by csaint on 2015. 7. 29..
//  Copyright (c) 2015년 DaumKakao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface STTradeSimulation : NSObject

@property (nonatomic, strong) NSString *itemCode;

- (void)setBuyPolicy:(NSArray *)buyRates howTo:(BOOL)bookBuy;
- (void)setSellPolicy:(NSArray *)sellRates;

- (BOOL)runSimulation;
- (BOOL)runSimulationWithStartPrice;

@end
