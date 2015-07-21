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
    BOOL open = [DATABASE openDatabase];
    if (open == NO)
        return;
    
    NSLog(@"OpenDatabase Success");
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
    
    [self updateStockItemPrice:itemCode];
    
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

- (void)updateStockItemPrice:(NSString *)itemCode
{
    //035420
    //http://finance.naver.com/item/sise_day.nhn?code=%s&page=%d
    //http://stock.daum.net/item/quote_yyyymmdd_sub.daum?page=%d&code=%s&modify=0   //수정주가 적용안함
    //http://stock.daum.net/item/quote_yyyymmdd_sub.daum?page=1&code=035420&modify=1

    //////////////////////////////////////////////////////////////////////////////////////////
    
    //[self.operationManager.operationQueue setMaxConcurrentOperationCount:3];

    for (int i = 1 ; i < 200 ; i++)
    {
        NSString* url = [NSString stringWithFormat:@"http://stock.daum.net/item/quote_yyyymmdd_sub.daum?page=%d&code=%@&modify=0", i, itemCode];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:5.0];
        
        AFHTTPRequestOperation *op = [self.operationManager HTTPRequestOperationWithRequest:request
                                                                                    success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                                                        //NSLog(@"SUCCESS : %@", [operation.request.URL absoluteString]);
                                                                                        NSString *stockHtml = [[NSString alloc] initWithUTF8String:[(NSData *)responseObject bytes]];
                                                                                        [self parseStockPriceList:stockHtml];

                                                                                    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                                                        //NSLog(@"FAILED  : %@", [operation.request.URL absoluteString]);
                                                                                        //NSLog(@"FAILED  : %@", error);
                                                                                    }];

        [self.operationManager.operationQueue addOperation:op];
    }
}


- (NSMutableArray *)parseStockPriceList:(NSString*)html
{
    html = [html stringByReplacingOccurrencesOfString:@"<span class=\"stUp\"><em>▲</em>" withString:@""];
    html = [html stringByReplacingOccurrencesOfString:@"<span class=\"stDn\"><em>▼</em>" withString:@"-"];
    html = [html stringByReplacingOccurrencesOfString:@"<span class=\"stFt\"><em>-</em>" withString:@""];

    NSRange rangeStarter = {0, html.length};
    NSRange rangeCloser;

    NSMutableArray *stockPriceList = [[NSMutableArray alloc] init];
    
    NSString *itemDate, *itemStart, *itemHigh, *itemLow, *itemEnd, *itemUpDown, *itemAmount;
    
    while ((rangeStarter = [html rangeOfString:@"<td class=\"datetime2\">" options:NSLiteralSearch range:rangeStarter]).location != NSNotFound)
    {
        itemDate = itemStart = itemHigh = itemLow = itemEnd = itemUpDown = itemAmount = nil;
        
        rangeCloser.location = rangeStarter.location + rangeStarter.length;
        rangeCloser.length = 20;
        if ((rangeCloser = [html rangeOfString:@"</td>" options:NSLiteralSearch range:rangeCloser]).location == NSNotFound) continue;
        itemDate = [html substringWithRange:NSMakeRange(rangeStarter.location + rangeStarter.length, rangeCloser.location - (rangeStarter.location+rangeStarter.length))];

        rangeStarter.location = rangeCloser.location + rangeCloser.length;
        rangeStarter.length = 100;
        if ((rangeStarter = [html rangeOfString:@"<td class=\"num\">" options:NSLiteralSearch range:rangeStarter]).location == NSNotFound) continue;

        rangeCloser.location = rangeStarter.location + rangeStarter.length;
        rangeCloser.length = 20;
        if ((rangeCloser = [html rangeOfString:@"</td>" options:NSLiteralSearch range:rangeCloser]).location == NSNotFound) continue;
        itemStart = [html substringWithRange:NSMakeRange(rangeStarter.location + rangeStarter.length, rangeCloser.location - (rangeStarter.location+rangeStarter.length))];

        rangeStarter.location = rangeCloser.location + rangeCloser.length;
        rangeStarter.length = 100;
        if ((rangeStarter = [html rangeOfString:@"<td class=\"num\">" options:NSLiteralSearch range:rangeStarter]).location == NSNotFound) continue;
        
        rangeCloser.location = rangeStarter.location + rangeStarter.length;
        rangeCloser.length = 20;
        if ((rangeCloser = [html rangeOfString:@"</td>" options:NSLiteralSearch range:rangeCloser]).location == NSNotFound) continue;
        itemHigh = [html substringWithRange:NSMakeRange(rangeStarter.location + rangeStarter.length, rangeCloser.location - (rangeStarter.location+rangeStarter.length))];

        rangeStarter.location = rangeCloser.location + rangeCloser.length;
        rangeStarter.length = 100;
        if ((rangeStarter = [html rangeOfString:@"<td class=\"num\">" options:NSLiteralSearch range:rangeStarter]).location == NSNotFound) continue;
        
        rangeCloser.location = rangeStarter.location + rangeStarter.length;
        rangeCloser.length = 20;
        if ((rangeCloser = [html rangeOfString:@"</td>" options:NSLiteralSearch range:rangeCloser]).location == NSNotFound) continue;
        itemLow = [html substringWithRange:NSMakeRange(rangeStarter.location + rangeStarter.length, rangeCloser.location - (rangeStarter.location+rangeStarter.length))];

        rangeStarter.location = rangeCloser.location + rangeCloser.length;
        rangeStarter.length = 100;
        if ((rangeStarter = [html rangeOfString:@"<td class=\"num\">" options:NSLiteralSearch range:rangeStarter]).location == NSNotFound) continue;
        
        rangeCloser.location = rangeStarter.location + rangeStarter.length;
        rangeCloser.length = 20;
        if ((rangeCloser = [html rangeOfString:@"</td>" options:NSLiteralSearch range:rangeCloser]).location == NSNotFound) continue;
        itemEnd = [html substringWithRange:NSMakeRange(rangeStarter.location + rangeStarter.length, rangeCloser.location - (rangeStarter.location+rangeStarter.length))];
        
        rangeStarter.location = rangeCloser.location + rangeCloser.length;
        rangeStarter.length = 100;
        if ((rangeStarter = [html rangeOfString:@"<td class=\"num\">" options:NSLiteralSearch range:rangeStarter]).location == NSNotFound) continue;
        
        rangeCloser.location = rangeStarter.location + rangeStarter.length;
        rangeCloser.length = 20;
        if ((rangeCloser = [html rangeOfString:@"</span>" options:NSLiteralSearch range:rangeCloser]).location == NSNotFound) continue;
        itemUpDown = [html substringWithRange:NSMakeRange(rangeStarter.location + rangeStarter.length, rangeCloser.location - (rangeStarter.location+rangeStarter.length))];

        rangeStarter.location = rangeCloser.location + rangeCloser.length;
        rangeStarter.length = 200;
        if ((rangeStarter = [html rangeOfString:@"<td class=\"num\">" options:NSLiteralSearch range:rangeStarter]).location == NSNotFound) continue;
        
        rangeCloser.location = rangeStarter.location + rangeStarter.length;
        rangeCloser.length = 20;
        if ((rangeCloser = [html rangeOfString:@"</td>" options:NSLiteralSearch range:rangeCloser]).location == NSNotFound) continue;
        itemAmount = [html substringWithRange:NSMakeRange(rangeStarter.location + rangeStarter.length, rangeCloser.location - (rangeStarter.location+rangeStarter.length))];
        
        rangeStarter.location = rangeCloser.location + rangeCloser.length;
        rangeStarter.length = html.length - rangeStarter.location;
        
        if (itemDate == nil || itemStart == nil || itemHigh == nil || itemLow == nil || itemEnd == nil || itemUpDown == nil || itemAmount == nil)
            continue;
        
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
        
        [stockPriceList addObject:[NSArray arrayWithObjects:itemDate,
                                   @([itemStart integerValue]),
                                   @([itemHigh integerValue]),
                                   @([itemLow integerValue]),
                                   @([itemEnd integerValue]),
                                   @([itemUpDown integerValue]),
                                   @([itemAmount integerValue]), nil]];
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
    
    return stockPriceList;
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
