//
//  MainWindowController.m
//  Outlander
//
//  Created by Joseph McBride on 1/22/14.
//  Copyright (c) 2014 Joe McBride. All rights reserved.
//

#import "MainWindowController.h"
#import "TestViewController.h"
#import "ProgressBarViewController.h"
#import "NSView+Categories.h"
#import "LoginViewController.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <ReactiveCocoa/EXTScope.h>
#import "SettingsWindowController.h"
#import "AppSettingsLoader.h"
#import "TextTag.h"
#import "NSString+Categories.h"
#import "MacroHandler.h"
#import "GameCommandRelay.h"
#import "Outlander-Swift.h"

@interface MainWindowController ()
    @property (nonatomic, strong) LoginViewController *loginViewController;
    @property (nonatomic, strong) SettingsWindowController *settingsWindowController;
//    @property (nonatomic, strong) AutoMapperWindowController *autoMapperWindowController;
    @property (nonatomic, strong) IBOutlet NSPanel *sheet;
    @property (nonatomic, strong) NSViewController *currentViewController;
    @property (nonatomic, strong) ChooseProfileViewController *chooseProfileViewController;
    @property (nonatomic, strong) GameContext *gameContext;
@end

@implementation MainWindowController {
    AppSettingsLoader *_appSettingsLoader;
    MacroHandler *_macroHandler;
}

- (id)initWithSettings:(AppSettings *)settings {
	self = [super initWithWindowNibName:NSStringFromClass([self class]) owner:self];
	if(self == nil) return nil;
    
    _gameContext = [GameContext newInstance];
    _gameContext.settings.defaultProfile = settings.defaultProfile;
    _gameContext.settings.profile = settings.defaultProfile;
    _gameContext.settings.checkForApplicationUpdates = settings.checkForApplicationUpdates;
    _appSettingsLoader = [[AppSettingsLoader alloc] initWithContext:_gameContext];
    _macroHandler = [[MacroHandler alloc] initWith:_gameContext and:[[GameCommandRelay alloc] initWith:_gameContext.events]];
    
    _loginViewController = [[LoginViewController alloc] init];
    
    _loginViewController.cancelCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {

        _gameContext.settings.password = @"";
        
        [self endSheet];
        return [RACSignal empty];
    }];
    
    _loginViewController.connectCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        
        [self endSheet];
        [self command:@"connect"];
        return [RACSignal empty];
    }];
    
    _settingsWindowController = [[SettingsWindowController alloc] init];
    
//    _autoMapperWindowController = [[AutoMapperWindowController alloc] initWithWindowNibName:@"AutoMapperWindowController"];
//    [_autoMapperWindowController setContext:_gameContext];

    _chooseProfileViewController = [[ChooseProfileViewController alloc]
                                    initWithNibName:@"ChooseProfileViewController"
                                    bundle:nil];
   
    _chooseProfileViewController.gameContext = _gameContext;
    _chooseProfileViewController.okCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        [self endSheet];

        [_gameContext.classSettings clear];
        
        [_appSettingsLoader loadProfile:_chooseProfileViewController.selectedProfile];

        [[self currentVC] reloadTheme];
        [[self currentVC] removeAllWindows];
        [[self currentVC] loadWindows];

        [self echoText:[NSString stringWithFormat:@"Loaded profile: %@\n", _gameContext.pathProvider.profileFolder] withMono:YES];

        [self.window setFrame:NSMakeRect(_gameContext.layout.primaryWindow.x,
                                         _gameContext.layout.primaryWindow.y,
                                         _gameContext.layout.primaryWindow.width,
                                         _gameContext.layout.primaryWindow.height)
                      display:YES
                      animate:NO];
        
        [self showLogin];
        
        return [RACSignal empty];
    }];
    
    _chooseProfileViewController.cancelCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        [self endSheet];
        return [RACSignal empty];
    }];
    
    [_gameContext.events subscribe:self token:@"disconnected"];
    [_gameContext.events subscribe:self token:@"OL:map:reload"];
    
	return self;
}

- (void)echo:(NSString *)text withPreset: (NSString *)preset {
    [[self.gameContext events] echoText:text mono:YES preset:preset];
}

- (void) windowDidBecomeKey: (NSNotification*) note {
    [self registerMacros];
}

- (void) windowDidResignKey: (NSNotification*) note {
    [self unRegisterMacros];
}

- (void)handle:(NSString * __nonnull)token data:(NSDictionary * __nonnull)data {
    if ([token isEqualToString:@"disconnected"]) {
        [self saveSettings];
    }

//    if([token isEqualToString:@"OL:map:reload"]) {
//        [_autoMapperWindowController loadMaps];
//    }
}

- (TestViewController *)currentVC {
    return (TestViewController *)_currentViewController;
}

- (void)windowDidMove:(NSNotification *)notification {
    [self updateWindowLayout];
}

- (void)windowDidResize:(NSNotification *)notification {
    [self updateWindowLayout];
}

- (void)updateWindowLayout {
    Layout *layout = _gameContext.layout;
    layout.primaryWindow.x = self.window.frame.origin.x;
    layout.primaryWindow.y = self.window.frame.origin.y;
    layout.primaryWindow.height = self.window.frame.size.height;
    layout.primaryWindow.width = self.window.frame.size.width;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    [_settingsWindowController setContext:_gameContext];
    
//    GameViewController *gv = [[GameViewController alloc] initWithNibName:@"GameViewController" bundle:nil];
//    [self setCurrentViewController:gv];
    
    TestViewController *vc = [[TestViewController alloc] initWithContext:_gameContext];
    [self setCurrentViewController:vc];
    
    NSDictionary *dict = [[NSBundle bundleForClass:self.class] infoDictionary];
    NSString *version = dict[@"CFBundleShortVersionString"];
    
    [self.window setTitle:[NSString stringWithFormat:@"Outlander %@ Alpha", version]];
    
    @weakify(self);
    
    [[_gameContext.globalVars.changed throttle:0.5]subscribeNext:^(id x) {
        
        @strongify(self);
       
        NSString *charInfo = @"";
        NSString *game = [_gameContext.globalVars cacheObjectForKey:@"game"];
        NSString *character = [_gameContext.globalVars cacheObjectForKey:@"charactername"];
        
        if (game == nil) {
            game = @"";
        }
        
        if (character == nil) {
           character = @"";
        }
        
        if (game.length > 0 && character.length > 0) {
            charInfo = [NSString stringWithFormat:@"%@: %@ - ", game, character];
        }
        
        NSDictionary *dict = [[NSBundle bundleForClass:self.class] infoDictionary];
        NSString *version = dict[@"CFBundleShortVersionString"];
        
        [self.window setTitle:[NSString stringWithFormat:@"%@Outlander %@ Alpha", charInfo, version]];
    }];
    
    _loginViewController.context = _gameContext;

    [self printSettings];

    [self.window makeFirstResponder:vc._CommandTextField];
    //[vc._CommandTextField becomeFirstResponder];
}

-(void)echoText:(NSString *)text withMono:(BOOL)mono {
    TestViewController *vc = [self currentVC];

    [vc append:[TextTag tagFor:text
                          mono:mono]
            to:@"main"];
}

- (void)printSettings {
    [self echoText:[NSString stringWithFormat:@"Config: %@\n",
                    _gameContext.pathProvider.configFolder]
          withMono:YES];
    [self echoText:[NSString stringWithFormat:@"Profile: %@\n",
                    _gameContext.pathProvider.profileFolder]
          withMono:YES];
    [self echoText:[NSString stringWithFormat:@"Maps: %@\n",
                    _gameContext.pathProvider.mapsFolder]
          withMono:YES];
    [self echoText:[NSString stringWithFormat:@"Scripts: %@\n",
                    _gameContext.pathProvider.scriptsFolder]
          withMono:YES];
    [self echoText:[NSString stringWithFormat:@"Logs: %@\n\n",
                    _gameContext.pathProvider.logsFolder]
          withMono:YES];
}

- (void)awakeFromNib {

    [_appSettingsLoader load];
//    [_autoMapperWindowController loadMaps];

    [self.window setFrame:NSMakeRect(_gameContext.layout.primaryWindow.x,
                                     _gameContext.layout.primaryWindow.y,
                                     _gameContext.layout.primaryWindow.width,
                                     _gameContext.layout.primaryWindow.height)
                  display:YES
                  animate:NO];
    
    self.window.delegate = self;
}

- (void)setCurrentViewController:(NSViewController *)vc {
	if(_currentViewController == vc) return;
	
	_currentViewController = vc;
	self.window.contentView = _currentViewController.view;
}

- (void) saveSettings {
    TestViewController *vc = [self currentVC];
    
    _gameContext.layout.windows = [vc getWindows];

    [_appSettingsLoader saveConfig];
    [_appSettingsLoader saveLayout];
    [_appSettingsLoader saveProfile];
    [_appSettingsLoader saveVariables];
    [_appSettingsLoader saveHighlights];
    [_appSettingsLoader saveAliases];
    [_appSettingsLoader saveMacros];
    [_appSettingsLoader saveTriggers];
    [_appSettingsLoader saveSubs];
    [_appSettingsLoader saveGags];
    [_appSettingsLoader savePresets];
    [_appSettingsLoader saveVitals];
    [_appSettingsLoader saveClasses];
    
    [vc append:[TextTag tagFor:[@"[%@] settings saved\n" stringFromDateFormat:@"HH:mm"]
                          mono:true]
            to:@"main"];
}

- (void)command:(NSString *)command {
    
    if([command isEqualToString:@"saveSettings"]) {
        
        [self saveSettings];
        
    } else if([command isEqualToString:@"preferences"]){
        
        [_settingsWindowController showWindow:self];
    } else if([command isEqualToString:@"showAutoMapper"]){
        
//        [_autoMapperWindowController showWindow:self];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
//            [_autoMapperWindowController setSelectedZone];
        });

    } else if([_currentViewController conformsToProtocol:@protocol(Commands)]) {
        id<Commands> vc = (id<Commands>)_currentViewController;
        [vc command:command];
    }
}

- (void)showLogin {
    NSRect viewRect = NSMakeRect(0, 0, 308, 120);
    [self showSheet:_loginViewController.view withFrame:viewRect];
}

- (void)showProfiles {
    NSRect viewRect = NSMakeRect(0, 0, 192, 237);
    [_chooseProfileViewController loadProfiles:_gameContext.settings.profile];
    [self showSheet:_chooseProfileViewController.view withFrame:viewRect];
}

- (void)showSheet:(NSView *)view withFrame:(NSRect)frame {
    self.sheet.contentView = view;
    
    [self.sheet setFrame:frame display:YES animate:NO];
    
    [self.window beginSheet:self.sheet completionHandler:nil];
}

- (void)endSheet {
    [NSApp endSheet:self.sheet];
    [self.sheet orderOut:self];
    self.sheet.contentView = nil;
}

- (BOOL)windowShouldClose:(id)sender {
    [self command:@"saveSettings"];
    return YES;
}

- (void)windowWillClose:(NSNotification *)notification {
}

-(void)registerMacros {
    [_macroHandler registerMacros];
}

-(void)unRegisterMacros {
    [_macroHandler unRegisterMacros];
}

@end
