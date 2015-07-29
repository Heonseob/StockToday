//
//  STTradeSimulation.m
//  StockToday
//
//  Created by csaint on 2015. 7. 29..
//  Copyright (c) 2015년 DaumKakao. All rights reserved.
//

#import "STTradeSimulation.h"


@implementation STItemPrice

- (id)init
{
    if ((self = [super init]))
    {
        self.priceDate = nil;
        self.priceStart = 0;
        self.priceHigh = 0;
        self.priceLow = 0;
        self.priceEnd = 0;
    }
    return self;
}

@end

//////////////////////////////////////////////////////////////////////////////////////////

@implementation STTradeSimulation

- (id)init
{
    if ((self = [super init]))
    {

    }

    return self;
}


@end
