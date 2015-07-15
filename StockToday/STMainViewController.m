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
                      NSString *data = [[NSString alloc] initWithUTF8String:[(NSData *)responseObject bytes]];

                      NSDictionary* info = [data objectFromJSONString];
                      
                      
                      NSLog(@"SUCCESS - %@", data);
                  } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                      NSLog(@"FAIL - %@", error);
                  }];

    
}

- (IBAction)updateStockDataPressed:(id)sender
{
    
}

@end
