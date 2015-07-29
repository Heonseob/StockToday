//
//  STStockCrawler.m
//  StockToday
//
//  Created by csaint on 2015. 7. 29..
//  Copyright (c) 2015년 DaumKakao. All rights reserved.
//

#import "STStockCrawler.h"

#import <AFNetworking.h>
#import <JSONKit.h>

@interface STStockCrawler ()

@property (strong) AFHTTPRequestOperationManager *operationManager;

@end


@implementation STStockCrawler

- (id)init
{
    if ((self = [super init]))
    {
        self.operationManager = [[AFHTTPRequestOperationManager alloc] init];
        self.operationManager.responseSerializer = [AFHTTPResponseSerializer serializer];
    }
    
    return self;
}

- (void)updateStockItemList:(BOOL)kospi
                    success:(void (^)(NSArray *itemArray))success
                    failure:(void (^)(NSString *errorMessage))failure
{
    NSString *stockListURL = nil;
    
    if (kospi)
        stockListURL = @"http://stock.daum.net/xml/xmlallpanel.daum?stype=P&type=S"; //KOSPI (가나다=S / 업종순=U)
    else
        stockListURL = @"http://stock.daum.net/xml/xmlallpanel.daum?stype=Q&type=S"; //KOSDAQ (가나다=S / 업종순=U)
    
    [self.operationManager GET:stockListURL parameters:nil
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
                               failure(@"Stock List JSON Error");
                               return;
                           }
                           
                           NSArray *itemArray = [info objectForKey:@"item"];
                           if (itemArray == nil)
                           {
                               failure(@"Stock List JSON Item Invalid");
                               return;
                           }
                           
                           success(itemArray);
                           
                       } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                           
                           failure(@"Stock List Request Failed");
                           
                       }];
}

- (void)updateStockItemPrice:(NSString *)itemCode page:(int)pageIndex
                     success:(void (^)(NSArray *dateArray))success
                     failure:(void (^)(NSString *errorMessage, NSString *itemCode, int pageIndex))failure
{
    //http://stock.daum.net/item/quote_yyyymmdd_sub.daum?page=%d&code=%s&modify=0   //수정주가 적용안함
    
    NSString* url = [NSString stringWithFormat:@"http://stock.daum.net/item/quote_yyyymmdd_sub.daum?page=%d&code=%@&modify=0", pageIndex, itemCode];
    
    [self.operationManager GET:url parameters:nil
                       success:^(AFHTTPRequestOperation *operation, id responseObject) {
                           
                           NSString* requestURL = [operation.request.URL absoluteString];
                           NSRange range = NSMakeRange(0, requestURL.length);
                           NSUInteger resultPosition = 0;
                           
                           NSString* pageIndex = [self substringWithInterString:requestURL frontString:@"?page=" frontFindRange:range rearString:@"&code" rearFindLength:10 resultPosition:&resultPosition];
                           range = NSMakeRange(resultPosition - 5, 10);
                           NSString* itemCode = [self substringWithInterString:requestURL frontString:@"&code=" frontFindRange:range rearString:@"&modify" rearFindLength:15 resultPosition:&resultPosition];
                           
                           if ([(NSData *)responseObject length] == 0)
                           {
                               failure(@"Stock Price Data is NULL", itemCode, [pageIndex intValue]);
                               return;
                           }
                           
                           NSString *stockHtml = [[NSString alloc] initWithUTF8String:[(NSData *)responseObject bytes]];
                           NSMutableArray *dateArray = [self parseStockPriceList:stockHtml];
                           
                           if (dateArray == nil)
                           {
                               failure(@"Stock Price Page Error", itemCode, [pageIndex intValue]);
                               return;
                           }
                           
                           success(dateArray);
                           
                       } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                           
                           NSString* requestURL = [operation.request.URL absoluteString];
                           NSRange range = NSMakeRange(0, requestURL.length);
                           NSUInteger resultPosition = 0;
                           
                           NSString* pageIndex = [self substringWithInterString:requestURL frontString:@"?page=" frontFindRange:range rearString:@"&code" rearFindLength:10 resultPosition:&resultPosition];
                           range = NSMakeRange(resultPosition - 5, 10);
                           NSString* itemCode = [self substringWithInterString:requestURL frontString:@"&code=" frontFindRange:range rearString:@"&modify" rearFindLength:15 resultPosition:&resultPosition];
                           
                           failure(@"Stock Price Page Failed", itemCode, [pageIndex intValue]);
                       }];
}

#pragma mark - Utility Function

- (NSString*)substringWithInterString:(NSString*)targetString
                          frontString:(NSString*)frontString
                       frontFindRange:(NSRange)range
                           rearString:(NSString *)rearString
                       rearFindLength:(NSUInteger)length
                       resultPosition:(NSUInteger*)lastPosition
{
    range = [targetString rangeOfString:frontString options:NSLiteralSearch range:range];
    if (range.location == NSNotFound) return nil;
    
    NSUInteger substringPosition = range.location + range.length;
    
    range = NSMakeRange(substringPosition, length);
    range = [targetString rangeOfString:rearString options:NSLiteralSearch range:range];
    if (range.location == NSNotFound) return nil;
    
    *lastPosition = range.location + range.length;
    NSString* substring = [targetString substringWithRange:NSMakeRange(substringPosition, range.location - substringPosition)];
    return substring;
}

- (NSMutableArray *)parseStockPriceList:(NSString*)html
{
    if (html == nil || html.length == 0)
        return nil;
    
    if ([html rangeOfString:@"등락률"].location == NSNotFound)
        return nil;
    
    html = [html stringByReplacingOccurrencesOfString:@"<span class=\"stUp2\"><em>↑</em>" withString:@""];
    html = [html stringByReplacingOccurrencesOfString:@"<span class=\"stUp2\"><em>&nbsp;</em>" withString:@""];
    html = [html stringByReplacingOccurrencesOfString:@"<span class=\"stUp\"><em>▲</em>" withString:@""];
    html = [html stringByReplacingOccurrencesOfString:@"<span class=\"stDn2\"><em>&nbsp;</em>" withString:@"-"];
    html = [html stringByReplacingOccurrencesOfString:@"<span class=\"stDn2\"><em>↓</em>" withString:@"-"];
    html = [html stringByReplacingOccurrencesOfString:@"<span class=\"stDn\"><em>▼</em>" withString:@"-"];
    html = [html stringByReplacingOccurrencesOfString:@"<span class=\"stFt\"><em>-</em>" withString:@""];
    
    NSRange range = NSMakeRange(0, html.length);
    NSUInteger resultPosition = 0;
    
    NSMutableArray *stockPriceList = [[NSMutableArray alloc] init];
    NSString *itemDate, *itemStart, *itemHigh, *itemLow, *itemEnd, *itemUpDown, *itemAmount;
    
    while ((itemDate = [self substringWithInterString:html frontString:@"<td class=\"datetime2\">" frontFindRange:range rearString:@"</td>" rearFindLength:20 resultPosition:&resultPosition]) != nil)
    {
        itemStart = itemHigh = itemLow = itemEnd = itemUpDown = itemAmount = nil;
        
        range = NSMakeRange(resultPosition, 100);
        itemStart = [self substringWithInterString:html frontString:@"<td class=\"num\">" frontFindRange:range rearString:@"</td>" rearFindLength:20 resultPosition:&resultPosition];
        if (itemStart == nil) return nil;
        
        range = NSMakeRange(resultPosition, 100);
        itemHigh = [self substringWithInterString:html frontString:@"<td class=\"num\">" frontFindRange:range rearString:@"</td>" rearFindLength:20 resultPosition:&resultPosition];
        if (itemHigh == nil) return nil;
        
        range = NSMakeRange(resultPosition, 100);
        itemLow = [self substringWithInterString:html frontString:@"<td class=\"num\">" frontFindRange:range rearString:@"</td>" rearFindLength:20 resultPosition:&resultPosition];
        if (itemLow == nil) return nil;
        
        range = NSMakeRange(resultPosition, 100);
        itemEnd = [self substringWithInterString:html frontString:@"<td class=\"num\">" frontFindRange:range rearString:@"</td>" rearFindLength:20 resultPosition:&resultPosition];
        if (itemEnd == nil) return nil;
        
        range = NSMakeRange(resultPosition, 100);
        itemUpDown = [self substringWithInterString:html frontString:@"<td class=\"num\">" frontFindRange:range rearString:@"</span>" rearFindLength:20 resultPosition:&resultPosition];
        if (itemUpDown == nil) return nil;
        
        range = NSMakeRange(resultPosition, 200);
        itemAmount = [self substringWithInterString:html frontString:@"<td class=\"num\">" frontFindRange:range rearString:@"</td>" rearFindLength:20 resultPosition:&resultPosition];
        if (itemAmount == nil) return nil;
        
        range = NSMakeRange(resultPosition, html.length - resultPosition);
        
        if ([[itemDate substringWithRange:NSMakeRange(0, 2)] intValue] > 50)
            itemDate = [NSString stringWithFormat:@"19%@", itemDate];
        else
            itemDate = [NSString stringWithFormat:@"20%@", itemDate];
        
        itemStart = [itemStart stringByReplacingOccurrencesOfString:@"," withString:@""];
        itemHigh = [itemHigh stringByReplacingOccurrencesOfString:@"," withString:@""];
        itemLow = [itemLow stringByReplacingOccurrencesOfString:@"," withString:@""];
        itemEnd = [itemEnd stringByReplacingOccurrencesOfString:@"," withString:@""];
        itemUpDown = [itemUpDown stringByReplacingOccurrencesOfString:@"," withString:@""];
        itemAmount = [itemAmount stringByReplacingOccurrencesOfString:@"," withString:@""];
        
        //NSLog(@"%@ - %@ - %@ - %@ - %@ - %@ - %@", itemDate, itemStart, itemHigh, itemLow, itemEnd, itemUpDown, itemAmount);
        [stockPriceList addObject:[NSArray arrayWithObjects:itemDate,
                                   @([itemStart integerValue]),
                                   @([itemHigh integerValue]),
                                   @([itemLow integerValue]),
                                   @([itemEnd integerValue]),
                                   @([itemUpDown integerValue]),
                                   @([itemAmount integerValue]), nil]];
    }
    
    return stockPriceList;
}

@end
