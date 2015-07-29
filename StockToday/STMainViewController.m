//
//  STMainViewController.m
//  StockToday
//
//  Created by csaint on 2015. 7. 15..
//  Copyright (c) 2015년 DaumKakao. All rights reserved.
//

#import "STMainViewController.h"
#import "STDatabaseManager.h"

#import "STStockCrawler.h"
#import "STTradeSimulation.h"

#import <WebKit/WebKit.h>
#import <GCDAsyncSocket.h>
#import <FBKVOController.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

#define KEY_LAST_MARKET             @"LAST_MAKET"
#define KEY_LAST_KOSPI              @"LAST_KOSPI"
#define KEY_LAST_KOSDAQ             @"LAST_KOSDAQ"

#define NOTIFICATION_ITEM_PRICE     @"ItemPriceComplete"

@interface STMainViewController () <NSTableViewDataSource,NSAlertDelegate>

@property (weak) IBOutlet NSPopUpButton* popupItemMarket;
@property (weak) IBOutlet NSPopUpButton* popupItemList;
@property (weak) IBOutlet NSButton* resetItemPrice;

@property (weak) IBOutlet NSProgressIndicator* indicatorListWait;
@property (weak) IBOutlet NSProgressIndicator* indicatorPriceWait;
@property (weak) IBOutlet NSTableView* tableStockPrice;

@property (strong) STStockCrawler* stockCrawler;
@property (strong) NSMutableArray *stockPrices;

@property (strong) FBKVOController *fbKVO;
@property (strong) NSString *selectItemCode;

@end

@implementation STMainViewController
{
    BOOL _modeKOSPI;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.stockCrawler = [[STStockCrawler alloc] init];

//    [self.webView.mainFrame.frameView setAllowsScrolling:NO];
//    [self.webView stringByEvaluatingJavaScriptFromString:@" document.body.style.overflowX='hidden';"];
//
//    NSString *url = [NSString stringWithFormat:@"http://hyper.moneta.co.kr/fcgi-bin/DelayedCurrPrice10.fcgi?code=%@", itemCode];
//    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
//    [self.webView.mainFrame loadRequest:request];
    
    self.fbKVO = [FBKVOController controllerWithObserver:self];
    [self.fbKVO observe:self keyPath:@"selectItemCode" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld block:^(id observer, id object, NSDictionary *change){

        if ([[change objectForKey:NSKeyValueChangeNewKey] isEqual:[NSNull null]])
            return;

        NSString *newItemCode = [change objectForKey:NSKeyValueChangeNewKey];
        NSString *oldItemCode = nil;

        if ([[change objectForKey:NSKeyValueChangeOldKey] isEqual:[NSNull null]] == NO)
            oldItemCode = [change objectForKey:NSKeyValueChangeOldKey];

        if ([newItemCode isEqualToString:oldItemCode])
            return;
        
        if ([NSThread currentThread] == [NSThread mainThread])
            [self.fbKVO.observer performSelector:@selector(updateItemPriceDatabase:) withObject:self.selectItemCode];
        else
            [self.fbKVO.observer performSelectorOnMainThread:@selector(updateItemPriceDatabase:) withObject:self.selectItemCode waitUntilDone:NO];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(completeItemPriceDatabase:) name:NOTIFICATION_ITEM_PRICE object:nil];
}

- (void)viewDidAppear
{
    [super viewDidAppear];
    
    NSString* selectMarket = [[NSUserDefaults standardUserDefaults] stringForKey:KEY_LAST_MARKET];
    if ([selectMarket isEqualToString:@"KOSDAQ"])
    {
        [self.popupItemMarket selectItemAtIndex:1];
        [self updateStockItemList:NO];
    }
    else
    {
        [self.popupItemMarket selectItemAtIndex:0];
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
        [self updateStockItemList:NO];
    else
        [self updateStockItemList:YES];
}

- (void)updateStockItemList:(BOOL)kospi
{
    _modeKOSPI = kospi;
    
    [self.popupItemMarket setEnabled:NO];
    [self.popupItemList setEnabled:NO];
    [self.resetItemPrice setEnabled:NO];

    [self.popupItemList removeAllItems];
    [self.indicatorListWait setHidden:NO];
    [self.indicatorListWait startAnimation:self];

    [self.stockCrawler updateStockItemList:kospi success:^(NSArray *itemArray) {

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
            {
                self.selectItemCode = selectItemCode;
                selectIndex = count;
            }
            
            popupName = [NSString stringWithFormat:@"[%@] %@", itemCode, itemName];
            [self.popupItemList addItemWithTitle:popupName];
            count++;
        }
        
        [self.popupItemList selectItemAtIndex:selectIndex];
        [self.indicatorListWait stopAnimation:self];
        [self.indicatorListWait setHidden:YES];

        [self.popupItemMarket setEnabled:YES];
        [self.popupItemList setEnabled:YES];
        [self.resetItemPrice setEnabled:YES];

    } failure:^(NSString *errorMessage) {
        
        [self.popupItemMarket setEnabled:YES];
        [self.popupItemList setEnabled:YES];
        [self.resetItemPrice setEnabled:YES];

        [self alertStockItemList:errorMessage retry:^{
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
    alert.informativeText = @"Failed \"updateStockItemList\" Request";
    
    [alert beginSheetModalForWindow:[[self view] window] completionHandler:^(NSModalResponse returnCode){
        if (returnCode == NSAlertFirstButtonReturn)
            retryBlock();
        else
            [NSApp terminate:self];
    }];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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

    self.selectItemCode = itemCode;
}

- (IBAction)resetItemPricePress:(id)sender
{
    NSString* selectItem = [self.popupItemList titleOfSelectedItem];
    if (selectItem == nil || [selectItem length] == 0)
        return;
    
    NSArray* itemComponent = [selectItem componentsSeparatedByString:@"] "];
    if (itemComponent == nil || itemComponent.count != 2)
        return;
    
    NSString* itemCode = [itemComponent objectAtIndex:0];
    itemCode = [itemCode stringByReplacingOccurrencesOfString:@"[" withString:@""];

    [self.popupItemMarket setEnabled:NO];
    [self.popupItemList setEnabled:NO];
    [self.resetItemPrice setHidden:YES];
    [self.indicatorPriceWait setHidden:NO];
    [self.indicatorPriceWait startAnimation:self];

    [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
        [DATABASE resetItemTable:itemCode];
        [self updateStockItemPrice:itemCode page:1];
    }];
}

- (void)updateItemPriceDatabase:(NSString *)itemCode
{
    [self.popupItemMarket setEnabled:NO];
    [self.popupItemList setEnabled:NO];
    [self.resetItemPrice setHidden:YES];
    [self.indicatorPriceWait setHidden:NO];
    [self.indicatorPriceWait startAnimation:self];

    [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
        [DATABASE deleteLastItemPrice:itemCode];
        [self updateStockItemPrice:itemCode page:1];
    }];
}

- (void)completeItemPriceDatabase:(NSNotification *)notification
{
    [self.popupItemMarket setEnabled:YES];
    [self.popupItemList setEnabled:YES];
    [self.resetItemPrice setHidden:NO];
    [self.indicatorPriceWait stopAnimation:self];
    [self.indicatorPriceWait setHidden:YES];
    
    NSLog(@"StockItemPirce Database Updated");
}

- (void)updateStockItemPrice:(NSString *)itemCode page:(int)pageIndex
{
    [self.stockCrawler updateStockItemPrice:itemCode page:pageIndex success:^(NSArray *dateArray) {
        if (dateArray.count == 0)
        {
            NSLog(@"StockItemPirce Complete - [%@] PAGE:%d (%ld)", itemCode, pageIndex, dateArray.count);
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_ITEM_PRICE object:nil userInfo:nil];
            return;
        }
        
        int insertCount = [DATABASE insertItemPrice:dateArray itemCode:itemCode];
        if (insertCount <= 0)    //COMPLETE
        {
            NSLog(@"StockItemPirce Complete - [%@] PAGE:%d (%ld -> %d)", itemCode, pageIndex, dateArray.count, insertCount);
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_ITEM_PRICE object:nil userInfo:nil];
            return;
        }
        
        if (dateArray.count-1 > insertCount)   //COMPLETE
        {
            NSLog(@"StockItemPirce Complete - [%@] PAGE:%d (%ld -> %d)", itemCode, pageIndex, dateArray.count, insertCount);
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_ITEM_PRICE object:nil userInfo:nil];
            return;
        }
        
        NSLog(@"StockItemPirce Continue - [%@] PAGE:%d (%ld -> %d)", itemCode, pageIndex, dateArray.count, insertCount);
        [self updateStockItemPrice:itemCode page:pageIndex+1];
        
    } failure:^(NSString *errorMessage, NSString *itemCode, int pageIndex) {

        [self.popupItemMarket setEnabled:YES];
        [self.popupItemList setEnabled:YES];
        [self.resetItemPrice setHidden:NO];
        [self.indicatorPriceWait stopAnimation:self];
        [self.indicatorPriceWait setHidden:YES];

        [DATABASE resetItemTable:itemCode];
        [self alertStockItemPrice:errorMessage code:itemCode page:pageIndex retry:^(NSString *itemCode, int pageIndex) {
            [self updateItemPriceDatabase:itemCode];
        }];
    }];
}

- (void)alertStockItemPrice:(NSString *)message code:(NSString *)itemCode page:(int)pageIndex retry:(void (^)(NSString *itemCode, int pageIndex))retryBlock
{
    NSAlert *alert = [[NSAlert alloc] init];
    
    [alert addButtonWithTitle:@"다시 시도"];
    [alert addButtonWithTitle:@"취소"];
    
    alert.messageText = message;
    alert.informativeText = [NSString stringWithFormat:@"Failed \"updateStockItemPrice\"[%@:%d] Request", itemCode, pageIndex];
    
    [alert beginSheetModalForWindow:[[self view] window] completionHandler:^(NSModalResponse returnCode){
        if (returnCode == NSAlertFirstButtonReturn)
            retryBlock(itemCode, pageIndex);
    }];
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

    
    return self.stockPrices.count;
}



@end
