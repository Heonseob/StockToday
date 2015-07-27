//
//  STMainViewController.m
//  StockToday
//
//  Created by csaint on 2015. 7. 15..
//  Copyright (c) 2015년 DaumKakao. All rights reserved.
//

#import "STMainViewController.h"
#import "STDatabaseManager.h"

#import <WebKit/WebKit.h>
#import <GCDAsyncSocket.h>
#import <AFNetworking.h>
#import <JSONKit.h>


#define KEY_LAST_MARKET     @"LAST_MAKET"
#define KEY_LAST_KOSPI      @"LAST_KOSPI"
#define KEY_LAST_KOSDAQ     @"LAST_KOSDAQ"

@interface STMainViewController () <NSTableViewDataSource,NSAlertDelegate>

@property (weak) IBOutlet NSPopUpButton* popupItemMarket;
@property (weak) IBOutlet NSPopUpButton* popupItemList;
@property (weak) IBOutlet NSProgressIndicator* indicatorWait;

@property (weak) IBOutlet NSButton* openDatabase;
@property (weak) IBOutlet NSButton* updateItemPrice;
@property (weak) IBOutlet NSTableView* tableStockPrice;
@property (weak) IBOutlet WebView* webView;

@property (strong) AFHTTPRequestOperationManager *operationManager;
@property (strong) NSMutableArray *stockPrices;

@end

@implementation STMainViewController
{
    BOOL _modeKOSPI;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.operationManager = [[AFHTTPRequestOperationManager alloc] init];
    self.operationManager.responseSerializer = [AFHTTPResponseSerializer serializer];

    [self.webView.mainFrame.frameView setAllowsScrolling:NO];
    [self.webView stringByEvaluatingJavaScriptFromString:@" document.body.style.overflowX='hidden';"];
}

- (void)viewDidAppear
{
    [super viewDidAppear];
    
    NSString* selectMarket = [[NSUserDefaults standardUserDefaults] stringForKey:KEY_LAST_MARKET];
    if ([selectMarket isEqualToString:@"KOSDAQ"])
    {
        [self.popupItemMarket selectItemAtIndex:1];

        _modeKOSPI = NO;
        [self updateStockItemList:NO];
    }
    else
    {
        [self.popupItemMarket selectItemAtIndex:0];

        _modeKOSPI = YES;
        [self updateStockItemList:YES];
    }
}

- (IBAction)popupItemMarketSelected:(id)sender
{
    NSString* selectMarket = [self.popupItemMarket titleOfSelectedItem];
    if (selectMarket == nil || [selectMarket length] == 0)
        return;

    [[NSUserDefaults standardUserDefaults] setObject:selectMarket forKey:KEY_LAST_MARKET];
    
    if ([selectMarket isEqualToString:@"KOSDAQ"])
    {
        _modeKOSPI = NO;
        [self updateStockItemList:NO];
    }
    else
    {
        _modeKOSPI = YES;
        [self updateStockItemList:YES];
    }
}

- (IBAction)popupItemListSelected:(id)sender
{
    NSString* selectItem = [self.popupItemList titleOfSelectedItem];
    if (selectItem == nil || [selectItem length] == 0)
        return;

    NSArray* itemComponent = [selectItem componentsSeparatedByString:@"] "];
    if (itemComponent == nil || itemComponent.count != 2)
        return;

    NSString* itemCode = [itemComponent objectAtIndex:0];
    itemCode = [itemCode stringByReplacingOccurrencesOfString:@"[" withString:@""];

    if (_modeKOSPI)
        [[NSUserDefaults standardUserDefaults] setObject:itemCode forKey:KEY_LAST_KOSPI];
    else
        [[NSUserDefaults standardUserDefaults] setObject:itemCode forKey:KEY_LAST_KOSDAQ];
    
    NSString *url = [NSString stringWithFormat:@"http://hyper.moneta.co.kr/fcgi-bin/DelayedCurrPrice10.fcgi?code=%@", itemCode];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    [self.webView.mainFrame loadRequest:request];
}

- (IBAction)openDatabase:(id)sender
{
    //NSWindow* aa = [[self view] window];
    
    //[self.webView.mainFrame reload];
}



- (IBAction)updateItemPricePressed:(id)sender
{
//    NSString* selectItem = [self.popupStockList titleOfSelectedItem];
//    if (selectItem == nil || [selectItem length] == 0)
//        return;
//    
//    NSArray* itemComponent = [selectItem componentsSeparatedByString:@":::"];
//    if (itemComponent == nil || itemComponent.count != 2)
//        return;
//
//    NSString* itemCode = [itemComponent objectAtIndex:0];

    
//    for (int i = 0 ; i < self.popupStockList.numberOfItems ; i++)
//    {
//        NSString* itemInfo = [self.popupStockList itemTitleAtIndex:i];
//
//        NSArray* itemComponent = [itemInfo componentsSeparatedByString:@":::"];
//        if (itemComponent == nil || itemComponent.count != 2)
//            continue;
//        
//        NSString* itemCode = [itemComponent objectAtIndex:0];
//
//        [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
//            [DATABASE resetItemTable:itemCode];
//            [self updateStockItemPrice:itemCode page:1];
//        }];
//    }
//    
//    
//    [[NSOperationQueue mainQueue].operations count];

    
    
    //[DATABASE deleteLastItemPrice:itemCode];
    //[DATABASE resetItemTable:@"035720"];
    //[self updateStockItemPrice:@"035720" page:89];
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)updateStockItemList:(BOOL)kospi
{
    NSString *stockListAPI = nil;

    [self.popupItemList removeAllItems];

    [self.indicatorWait setHidden:NO];
    [self.indicatorWait startAnimation:self];

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
                               [self alertStockItemList:@"Stock List JSON Error" retry:^{
                                   [self updateStockItemList:kospi];
                               }];
                               return;
                           }
                           
                           NSArray *itemArray = [info objectForKey:@"item"];
                           if (itemArray == nil)
                           {
                               [self alertStockItemList:@"Stock List JSON Item Invalid" retry:^{
                                   [self updateStockItemList:kospi];
                               }];
                               return;
                           }
                           
                           [DATABASE insertItemInfo:itemArray market:kospi];
                           
                           [self.popupItemList removeAllItems];
                           
                           NSString* selectItemCode = nil;
                           if (kospi)
                               selectItemCode = [[NSUserDefaults standardUserDefaults] stringForKey:KEY_LAST_KOSPI];
                           else
                               selectItemCode = [[NSUserDefaults standardUserDefaults] stringForKey:KEY_LAST_KOSDAQ];

                           int count = 0, selectIndex = 0;
                           NSString *itemCode = nil, *itemName = nil, *popupName;
                           for (NSDictionary* item in itemArray)
                           {
                               itemCode = [item objectForKey:@"code"];
                               itemName = [item objectForKey:@"name"];
                               
                               if (itemCode == nil || itemName == nil)
                                   continue;
                               
                               if (itemCode.length > 6)
                                   continue;

                               if ([itemCode isEqualToString:selectItemCode] == YES)
                                   selectIndex = count;
                               
                               popupName = [NSString stringWithFormat:@"[%@] %@", itemCode, itemName];
                               [self.popupItemList addItemWithTitle:popupName];
                               count++;
                           }
                           
                           [self.popupItemList selectItemAtIndex:selectIndex];
                           
                           [self.indicatorWait stopAnimation:self];
                           [self.indicatorWait setHidden:YES];

                       } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                           
                           [self alertStockItemList:@"Stock List Request Failed" retry:^{
                               [self updateStockItemList:kospi];
                           }];
                       }];
}

- (void)alertStockItemList:(NSString *)message retry:(void (^)(void))retryBlock
{
    NSAlert *alert = [[NSAlert alloc] init];
    
    [alert addButtonWithTitle:@"다시 시도"];
    [alert addButtonWithTitle:@"앱 종료"];
    
    alert.messageText = message;
    alert.informativeText = @"Failed \"UpdateStockItemList\" Request";
    
    [alert beginSheetModalForWindow:[[self view] window] completionHandler:^(NSModalResponse returnCode){
        if (returnCode == NSAlertFirstButtonReturn)
            retryBlock();
        else
            [NSApp terminate:self];
    }];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)updateStockItemPrice:(NSString *)itemCode page:(int)pageIndex
{
    //http://stock.daum.net/item/quote_yyyymmdd_sub.daum?page=%d&code=%s&modify=0   //수정주가 적용안함
    //http://stock.daum.net/item/quote_yyyymmdd_sub.daum?page=1&code=035420&modify=0

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
                               NSLog(@"StockItemPirce SUCCESS - BUT, Data NULL");
                               return;
                           }

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
