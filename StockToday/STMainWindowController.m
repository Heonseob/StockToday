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
}

@end
