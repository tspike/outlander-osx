//
//  MainWindowController.h
//  Outlander
//
//  Created by Joseph McBride on 1/22/14.
//  Copyright (c) 2014 Joe McBride. All rights reserved.
//

#import "Commands.h"

@interface MainWindowController : NSWindowController <Commands>

- (id)init;
- (void)command:(NSString *)command;
- (void)showLogin;
- (void)dismissLogin;
- (void)showSheet:(NSView *)view;
- (void)endSheet;
@end
