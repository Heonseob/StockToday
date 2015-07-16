//
//  AppDelegate.m
//  StockToday
//
//  Created by csaint on 2015. 7. 15..
//  Copyright (c) 2015년 DaumKakao. All rights reserved.
//

#import "AppDelegate.h"
#import "STMainWindowController.h"

@interface AppDelegate ()

@property (strong) STMainWindowController *mainWindowController;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.mainWindowController = [[STMainWindowController alloc] initWithWindowNibName:@"STMainWindowController"];
    [self.mainWindowController showWindow:self];
    //[self.mainWindowController window];
//    [self.mainWindowController.window makeKeyAndOrderFront:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{

}

- (BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)application
{
    return YES;
}


@end
