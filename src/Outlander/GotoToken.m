//
//  GotoToken.m
//  Outlander
//
//  Created by Joseph McBride on 6/6/14.
//  Copyright (c) 2014 Joe McBride. All rights reserved.
//

#import "GotoToken.h"

@interface GotoToken () {
    id<Token> _val;
}
@end

@implementation GotoToken

- (instancetype)initWith:(id<Token>)val {
    self = [super init];
    if(!self) return nil;
    
    _val = val;
    
    return self;
}

- (id)eval {
    return [_val eval];
}

-(NSString *)description {
    return [NSString stringWithFormat:@"%@ %@", [super description], _val];
}

@end
