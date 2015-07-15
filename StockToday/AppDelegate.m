//
//  AppDelegate.m
//  StockToday
//
//  Created by csaint on 2015. 7. 15..
//  Copyright (c) 2015년 DaumKakao. All rights reserved.
//

#import "AppDelegate.h"
#import "STMainViewController.h"

@interface AppDelegate () <NSWindowDelegate>

@property (weak) IBOutlet NSWindow *window;
@property (strong) IBOutlet STMainViewController *mainViewController;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.window.delegate = self;
    self.mainViewController = [[STMainViewController alloc] initWithNibName:@"STMainViewController" bundle:nil];
    self.window.contentViewController = self.mainViewController;
    
    [self.window makeFirstResponder:self.mainViewController];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{

}

//- (BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)application
//{
//    return YES;
//}

- (void)windowWillClose:(NSNotification *)notification
{
    [NSApp terminate:self];
}


@end
