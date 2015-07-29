//
//  STStockCrawler.h
//  StockToday
//
//  Created by csaint on 2015. 7. 29..
//  Copyright (c) 2015년 DaumKakao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface STStockCrawler : NSObject

- (void)updateStockItemList:(BOOL)kospi
                    success:(void (^)(NSArray *itemArray))success
                    failure:(void (^)(NSString *errorMessage))failure;

@end
