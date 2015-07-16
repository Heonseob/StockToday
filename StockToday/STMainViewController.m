//
//  STMainViewController.m
//  StockToday
//
//  Created by csaint on 2015. 7. 15..
//  Copyright (c) 2015년 DaumKakao. All rights reserved.
//

#import "STMainViewController.h"

#import <GCDAsyncSocket.h>
#import <AFNetworking.h>
#import <FMDB.h>
#import <JSONKit.h>

@interface STMainViewController ()

@property (weak) IBOutlet NSButton* updateStockList;
@property (weak) IBOutlet NSButton* updateStockData;

@property (strong) AFHTTPRequestOperationManager *operationManager;

@end

@implementation STMainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.operationManager = [[AFHTTPRequestOperationManager alloc] init];

}

- (IBAction)updateStockListPressed:(id)sender
{
    // http://stock.daum.net/xml/xmlallpanel.daum?stype=P&type=S //KOSPI (가나다=S / 업종순=U)
    // http://stock.daum.net/xml/xmlallpanel.daum?stype=Q&type=S //KOSDAQ (가나다=S / 업종순=U)

    self.operationManager.responseSerializer = [AFHTTPResponseSerializer serializer];

//    AFHTTPRequestSerializer *requestSerializer = self.operationManager.requestSerializer;
//    [requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
//    self.operationManager.responseSerializer = [AFJSONResponseSerializer serializer];

    NSString *url = @"http://stock.daum.net/xml/xmlallpanel.daum?stype=P&type=S";
    
    [self.operationManager GET:url parameters:nil
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
                      NSArray *itemArray = [info objectForKey:@"item"];
                      
                      NSString *itemCode = nil, *itemName = nil;
                      int index = 0;
                      for (NSDictionary* item in itemArray)
                      {
                          itemCode = [item objectForKey:@"code"];
                          itemName = [item objectForKey:@"name"];
                        
                          NSLog(@"%4d : [%@] %@", index++, itemCode, itemName);
                      }
                      
                      
                      
                      //NSLog(@"SUCCESS - %@", stockInfo);
                  } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                      NSLog(@"FAIL - %@", error);
                  }];

    
}

- (IBAction)updateStockDataPressed:(id)sender
{
    
}

@end
