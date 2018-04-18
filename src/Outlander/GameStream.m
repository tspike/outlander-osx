//
//  GameStream.m
//  Outlander
//
//  Created by Joseph McBride on 1/25/14.
//  Copyright (c) 2014 Joe McBride. All rights reserved.
//

#import "GameStream.h"
#import "GameServer.h"
#import "GameParser.h"
#import "GameConnection.h"
#import "TextTag.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "GameCommandRelay.h"
#import "Outlander-Swift.h"

@interface GameStream () { }
    @property (nonatomic, strong) RACSignal *connection;
    @property (nonatomic, strong) GameContext *gameContext;
    @property (nonatomic, strong) GameCommandRelay *commandRelay;
    @property (nonatomic, strong) RACSubject *mainSubject;
    @property (nonatomic, strong) StormFrontTokenizer *tokenizer;
    @property (nonatomic, strong) StormFrontTagStreamer *tagStreamer;
//    @property (nonatomic, strong) ScriptStreamHandler *scriptStreamHandler;
    @property (nonatomic, strong) RoomChangeHandler *roomChangeHandler;
    @property (nonatomic, strong) TDPUpdateHandler *tdpUpdateHandler;
    @property (nonatomic, strong) ExpUpdateHandler *expUpdateHandler;
    @property (nonatomic, strong) TriggerHandler *triggerHandler;

@end

@implementation GameStream

-(id) initWithContext:(GameContext *)context {
    self = [super init];
    if(self == nil) return nil;
    
    self.gameContext = context;
    self.commandRelay = [[GameCommandRelay alloc] initWith:context.events];
    
    self.gameServer = [[GameServer alloc] initWithContext:context];
    self.gameParser = [[GameParser alloc] initWithContext:context];
    self.tokenizer = [StormFrontTokenizer newInstance];
    self.tagStreamer = [StormFrontTagStreamer newInstance];
//    self.scriptStreamHandler = [ScriptStreamHandler newInstance];
    self.roomChangeHandler = [RoomChangeHandler newInstance:self.commandRelay];
    self.tdpUpdateHandler = [TDPUpdateHandler newInstance];
    self.expUpdateHandler = [ExpUpdateHandler newInstance];
    self.triggerHandler = [TriggerHandler newInstance:context relay:self.commandRelay];
    
    __weak GameStream *weakSelf = self;
    self.expUpdateHandler.emitSetting = ^(NSString *key, NSString *value){
        GameStream *strongSelf = weakSelf;
        [strongSelf.gameContext.globalVars setCacheObject:value forKey:key];
    };
    
    self.expUpdateHandler.emitExp = ^(SkillExp *exp) {
        GameStream *strongSelf = weakSelf;
        [strongSelf.exp sendNext:exp];
    };
    
    self.tagStreamer.emitSetting = ^(NSString *key, NSString *value){
        GameStream *strongSelf = weakSelf;
        [strongSelf.gameContext.globalVars setCacheObject:value forKey:key];
    };
    
    self.tagStreamer.emitExp = ^(SkillExp *exp) {
        GameStream *strongSelf = weakSelf;
        [strongSelf.exp sendNext:exp];
    };
    
    self.tagStreamer.emitRoundtime = ^(Roundtime *rt) {
        GameStream *strongSelf = weakSelf;
        [strongSelf.roundtime sendNext:rt];
    };
    
    self.tagStreamer.emitRoom = ^{
        GameStream *strongSelf = weakSelf;
        [strongSelf.gameParser.room sendNext:@""];
    };
    
    self.tagStreamer.emitVitals = ^(Vitals *vital) {
        GameStream *strongSelf = weakSelf;
        [strongSelf.vitals sendNext:vital];
    };
    
    self.tagStreamer.emitSpell = ^(NSString *spell) {
        GameStream *strongSelf = weakSelf;
        [strongSelf.gameParser.spell sendNext:spell];
    };
    
    self.tagStreamer.emitClearStream = ^(NSString *window) {
        GameStream *strongSelf = weakSelf;
        CommandContext *ctx = [[CommandContext alloc] init];
        ctx.command = [NSString stringWithFormat:@"#window clear %@", window];
        
        [strongSelf.commandRelay sendCommand:ctx];
    };
    
    self.tagStreamer.emitWindow = ^(NSString *window, NSString *title, NSString *closedTarget) {
        GameStream *strongSelf = weakSelf;
        NSDictionary *win = @{
            @"name" : window,
            @"title" : title != nil ? title : [NSNull null],
            @"closedTarget" : closedTarget != nil ? closedTarget : [NSNull null]
        };
        [strongSelf.gameContext.events publish:@"OL:window:ensure" data:win];
    };

    self.tagStreamer.emitLaunchUrl = ^(NSString *url) {

        if ([url hasPrefix:@"/forums"]) {
            url = [NSString stringWithFormat:@"http://play.net%@", url];
        }

        NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
        [[NSWorkspace sharedWorkspace] openURL:[req URL]];
    };
    
    self.vitals = self.gameParser.vitals;
    self.indicators = self.gameParser.indicators;
    self.directions = self.gameParser.directions;
    
    self.room = [self.gameParser.room multicast:[RACSubject subject]];
    [self.room connect];
    self.spell = [self.gameParser.spell multicast:[RACSubject subject]];
    [self.spell connect];
    self.exp = self.gameParser.exp;
    self.thoughts = self.gameParser.thoughts;
    self.chatter = self.gameParser.chatter;
    self.arrivals = self.gameParser.arrivals;
    self.deaths = self.gameParser.deaths;
    self.familiar = self.gameParser.familiar;
    self.log = self.gameParser.log;
    self.roundtime = self.gameParser.roundtime;
    
    self.connected = [RACSubject subject];
    self.mainSubject = [RACSubject subject];
    self.subject = [self.mainSubject multicast:[RACSubject subject]];
    [self.subject connect];
    
    [self.gameServer.connected subscribeNext:^(id x) {
        id<RACSubscriber> sub = (id<RACSubscriber>)self.connected;
        [sub sendNext:x];
    }];
    
    return self;
}

-(void) publish:(id)item {
    [self.mainSubject sendNext:item];
}

-(void) complete {
    [self.gameServer disconnect];
    [self.triggerHandler unsubscribe];
    [self.mainSubject sendCompleted];
}

-(void) unsubscribe {
    [self.triggerHandler unsubscribe];
}

-(void) error:(NSError *)error {
    [self.mainSubject sendError:error];
}

-(void) sendCommand:(NSString *)command {
    [self.gameServer sendCommand:command];
}

-(RACMulticastConnection *) connect:(GameConnection *)connection {
    
    [[self.gameServer connect:connection.key
                  toHost:connection.host
                  onPort:connection.port]
     subscribeNext:^(NSString *rawXml) {
         
         TextTag *rawTag = [TextTag tagFor:rawXml mono:YES];
         rawTag.targetWindow = @"raw";
         
         NSArray *rawArray = [NSArray arrayWithObjects:rawTag, nil];
         [self.mainSubject sendNext:rawArray];

         NSArray *nodes = [self.tokenizer tokenize:rawXml];
         NSArray *tags = [self.tagStreamer stream:nodes];
         
         [self.mainSubject sendNext:tags];
         
         NSString *rawText = [self textForTagList:tags];

         [self.triggerHandler handle:nodes text:rawText context:self.gameContext];
         [self.roomChangeHandler handle:nodes text:rawText context:self.gameContext];
         [self.tdpUpdateHandler handle:nodes text:rawText context:self.gameContext];
         [self.expUpdateHandler handle:nodes text:rawText context:self.gameContext];
//         [self.scriptStreamHandler handle:nodes text:rawText context:self.gameContext];
         
     } completed:^{
         [self unsubscribe];
         [self.mainSubject sendCompleted];
     }];
    
    return self.subject;
}

-(NSString *)textForTagList:(NSArray *)tags {
    NSMutableString *text = [[NSMutableString alloc] init];

    for(TextTag *tag in tags) {
        if (tag != nil && [tag.text length] > 0) {
            [text appendString:tag.text];
        }
    }
    
    return text;
}

@end
