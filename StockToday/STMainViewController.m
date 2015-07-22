//
//  STMainViewController.m
//  StockToday
//
//  Created by csaint on 2015. 7. 15..
//  Copyright (c) 2015년 DaumKakao. All rights reserved.
//

#import "STMainViewController.h"
#import "STDatabaseManager.h"

#import <GCDAsyncSocket.h>
#import <AFNetworking.h>
#import <JSONKit.h>

@interface STMainViewController () <NSTableViewDataSource>

@property (weak) IBOutlet NSButton* openDatabase;
@property (weak) IBOutlet NSButton* updateKOSPIList;
@property (weak) IBOutlet NSButton* updateKOSDAQList;
@property (weak) IBOutlet NSButton* updateItemPrice;
@property (weak) IBOutlet NSPopUpButton* popupStockList;
@property (weak) IBOutlet NSTableView* tableStockPrice;

@property (strong) AFHTTPRequestOperationManager *operationManager;

@property (strong) NSMutableArray *stockPrices;

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

    [self.popupStockList addItemWithTitle:@"035420:::네이버"];     //default
    [self.popupStockList selectItemAtIndex:0];
    
}

- (IBAction)openDatabase:(id)sender
{
}

- (IBAction)updateKOSPIListPressed:(id)sender
{
    [self updateStockItemList:YES];
}

- (IBAction)updateKOSDAQListPressed:(id)sender
{
    [self updateStockItemList:NO];
}

- (IBAction)updateItemPricePressed:(id)sender
{
    NSString* selectItem = [self.popupStockList titleOfSelectedItem];
    if (selectItem == nil || [selectItem length] == 0)
        return;
    
    NSArray* itemComponent = [selectItem componentsSeparatedByString:@":::"];
    if (itemComponent == nil || itemComponent.count != 2)
        return;

    NSString* itemCode = [itemComponent objectAtIndex:0];
    
    [DATABASE resetItemTable:itemCode];
    [self updateStockItemPrice:itemCode page:1];
    
    //[DATABASE resetItemTable:@"035720"];
    //[self updateStockItemPrice:@"035720" page:89];
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////

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
                           
                           [DATABASE insertItemInfo:itemArray market:kospi];
                           
                           [self.popupStockList removeAllItems];

                           int index = 0, popupSelectIndex = 0;
                           NSString *itemCode = nil, *itemName = nil, *popupName;
                           for (NSDictionary* item in itemArray)
                           {
                               itemCode = [item objectForKey:@"code"];
                               itemName = [item objectForKey:@"name"];
                               
                               if (itemCode == nil || itemName == nil)
                                   continue;
                               
                               if (itemCode.length > 6)
                                   continue;
                               
                               if (kospi)
                               {
                                   if ([itemName isEqualToString:@"NAVER"])
                                       popupSelectIndex = index;
                               }
                               else
                               {
                                   if ([itemName isEqualToString:@"다음카카오"])
                                       popupSelectIndex = index;
                               }
                               
                               popupName = [NSString stringWithFormat:@"%@:::%@", itemCode, itemName];
                               [self.popupStockList addItemWithTitle:popupName];

                               NSLog(@"%4d : [%@] %@", index++, itemCode, itemName);
                           }
                           
                           [self.popupStockList selectItemAtIndex:popupSelectIndex];
                           
                           
                       } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                           NSLog(@"StockItemList FAIL - %@", error);
                       }];
}

- (void)updateStockItemPrice:(NSString *)itemCode page:(int)pageIndex
{
    //035420
    //http://finance.naver.com/item/sise_day.nhn?code=%s&page=%d
    //http://stock.daum.net/item/quote_yyyymmdd_sub.daum?page=%d&code=%s&modify=0   //수정주가 적용안함
    //http://stock.daum.net/item/quote_yyyymmdd_sub.daum?page=1&code=035420&modify=1

    //////////////////////////////////////////////////////////////////////////////////////////
    
    NSString* url = [NSString stringWithFormat:@"http://stock.daum.net/item/quote_yyyymmdd_sub.daum?page=%d&code=%@&modify=0", pageIndex, itemCode];
    
    [self.operationManager GET:url parameters:nil
                       success:^(AFHTTPRequestOperation *operation, id responseObject) {

                           if ([(NSData *)responseObject length] == 0)
                           {
                               NSLog(@"StockItemPirce SUCCESS - BUT, Data NULL");
                               return;
                           }
                           
                           NSString* requestURL = [operation.request.URL absoluteString];
                           NSRange range = NSMakeRange(0, requestURL.length);
                           NSUInteger resultPosition = 0;
                           
                           NSString* pageIndex = [self substringWithInterString:requestURL frontString:@"?page=" frontFindRange:range rearString:@"&code" rearFindLength:10 resultPosition:&resultPosition];
                           if (pageIndex == nil) return;
                           
                           range = NSMakeRange(resultPosition - 5, 10);
                           NSString* itemCode = [self substringWithInterString:requestURL frontString:@"&code=" frontFindRange:range rearString:@"&modify" rearFindLength:15 resultPosition:&resultPosition];
                           if (itemCode == nil) return;
                           
                           NSString *stockHtml = [[NSString alloc] initWithUTF8String:[(NSData *)responseObject bytes]];
                           NSMutableArray *itemPrice = [self parseStockPriceList:stockHtml];
                           
                           if (itemPrice == nil || itemPrice.count == 0)
                           {
                               NSLog(@"StockItemPirce SUCCESS - BUT, Parsing Price is 0");
                               return;
                           }
                           
                           int insertCount = [DATABASE insertItemPrice:itemPrice itemCode:itemCode];
                           if (insertCount <= 0)
                           {
                               NSLog(@"StockItemPirce SUCCESS - BUT, Insert Price is 0");
                               return;
                           }

                           //    if (stockPriceList.count == 0)
                           //        return 0;
                           //
                           //    self.stockPrices = [NSMutableArray new];
                           //
                           //    for (NSArray *arrayPrice in stockPriceList)
                           //    {
                           //        [self.stockPrices addObject:[NSString stringWithFormat:@"%@ : %@", [arrayPrice objectAtIndex:0], [arrayPrice objectAtIndex:5]]];
                           //    }
                           //    
                           //    [self.tableStockPrice reloadData];
                           //    
                           //    return stockPriceList.count;

                           NSLog(@"StockItemPirce SUCCESS - [%@] PAGE %@ (%ld -> %d)", itemCode, pageIndex, itemPrice.count, insertCount);
                           [self updateStockItemPrice:itemCode page:[pageIndex intValue]+1];

                       } failure:^(AFHTTPRequestOperation *operation, NSError *error) {

                           NSString* requestURL = [operation.request.URL absoluteString];
                           NSRange range = NSMakeRange(0, requestURL.length);
                           NSUInteger resultPosition = 0;
                           
                           NSString* pageIndex = [self substringWithInterString:requestURL frontString:@"?page=" frontFindRange:range rearString:@"&code" rearFindLength:10 resultPosition:&resultPosition];
                           if (pageIndex == nil) return;
                           
                           range = NSMakeRange(resultPosition - 5, 10);
                           NSString* itemCode = [self substringWithInterString:requestURL frontString:@"&code=" frontFindRange:range rearString:@"&modify" rearFindLength:15 resultPosition:&resultPosition];
                           if (itemCode == nil) return;
                           
                           NSLog(@"StockItemPirce FAIL - [%@] PAGE %@ (RETRY)", itemCode, pageIndex);
                           [self updateStockItemPrice:itemCode page:[pageIndex intValue]];
                       }];
}


- (NSMutableArray *)parseStockPriceList:(NSString*)html
{
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

- (NSString*)substringWithInterString:(NSString*)targetString
                          frontString:(NSString*)frontString
                       frontFindRange:(NSRange)range
                           rearString:(NSString *)rearString
                       rearFindLength:(NSUInteger)length
                       resultPosition:(NSUInteger*)lastPosition
{
    range = [targetString rangeOfString:frontString options:NSLiteralSearch range:range];
    if (range.location == NSNotFound)
        return nil;

    NSUInteger substringPosition = range.location + range.length;
    
    range = NSMakeRange(substringPosition, length);
    range = [targetString rangeOfString:rearString options:NSLiteralSearch range:range];
    if (range.location == NSNotFound)
        return nil;
    
    *lastPosition = range.location + range.length;
    
    NSString* substring = [targetString substringWithRange:NSMakeRange(substringPosition, range.location - substringPosition)];
    return substring;
}


#pragma mark - NSTableViewDataSource

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSTableCellView *result = [tableView makeViewWithIdentifier:@"COLUMN_DATA" owner:self];
    result.textField.stringValue = self.stockPrices[row];
    return result;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.stockPrices.count;
}


@end
