//
//  STMainWindowController.m
//  StockToday
//
//  Created by csaint on 2015. 7. 16..
//  Copyright (c) 2015년 DaumKakao. All rights reserved.
//

#import "STMainWindowController.h"
#import "STMainViewController.h"

#define SAVE_WINDOW_NAME     @"MainWindowController"

@interface STMainWindowController () <NSWindowDelegate>

@property (strong) STMainViewController *mainViewController;

@end

@implementation STMainWindowController

- (void)awakeFromNib
{
    self.mainViewController = [[STMainViewController alloc] initWithNibName:@"STMainViewController" bundle:nil];
    self.contentViewController = self.mainViewController;

    [self.window makeFirstResponder:self.mainViewController];
}

- (void)windowDidLoad
{
    [super windowDidLoad];

    [self.window setFrameAutosaveName:SAVE_WINDOW_NAME];
    
    [self.window makeKeyAndOrderFront:nil];
    [self.window setLevel:NSStatusWindowLevel];
    
    // 1초간 TopMost 윈도우 유지
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self.window setLevel:NSNormalWindowLevel];
    });

}

@end
