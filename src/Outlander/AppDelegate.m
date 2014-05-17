//
//  AppDelegate.m
//  Outlander
//
//  Created by Joseph McBride on 1/22/14.
//  Copyright (c) 2014 Joe McBride. All rights reserved.
//

#import "AppDelegate.h"
#import "MainWindowController.h"

@interface AppDelegate()
    @property (nonatomic, strong) MainWindowController *mainWindowController;
@end

@implementation AppDelegate

- (void)awakeFromNib {
}

- (IBAction)newAction:(id)sender {
}

- (IBAction)connectAction:(id)sender {
    [self.mainWindowController showLogin];
}

- (IBAction)saveProfileAction:(id)sender {
    [self.mainWindowController command:@"saveProfile"];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
	self.mainWindowController = [[MainWindowController alloc] init];
	[self.mainWindowController.window makeKeyAndOrderFront:nil];
}

@end
