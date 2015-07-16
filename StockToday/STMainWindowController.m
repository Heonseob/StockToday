//
//  STMainWindowController.m
//  StockToday
//
//  Created by csaint on 2015. 7. 16..
//  Copyright (c) 2015년 DaumKakao. All rights reserved.
//

#import "STMainWindowController.h"
#import "STMainViewController.h"

@interface STMainWindowController ()

@property (strong) STMainViewController *mainViewController;

@end

@implementation STMainWindowController

- (void)awakeFromNib
{
    self.mainViewController = [[STMainViewController alloc] initWithNibName:@"STMainViewController" bundle:nil];
    self.contentViewController = self.mainViewController;
    
//    NSRect viewFrame = self.mainViewController.view.frame;
//    NSRect windowFrame = self.window.frame;
//    NSRect newWindowFrame = NSMakeRect(windowFrame.origin.x, windowFrame.origin.y, viewFrame.size.width, viewFrame.size.height);
//    [self.window setFrame:newWindowFrame display:YES];
    
    [self.window makeFirstResponder:self.mainViewController];
    
}

- (void)windowDidLoad
{
    [super windowDidLoad];

}

@end
