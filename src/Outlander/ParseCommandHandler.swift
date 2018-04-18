//
//  ParseCommandHandler.swift
//  Outlander
//
//  Created by Joseph McBride on 4/15/15.
//  Copyright (c) 2015 Joe McBride. All rights reserved.
//

import Foundation

@objcMembers
class ParseCommandHandler : NSObject, CommandHandler {
    
    class func newInstance() -> ParseCommandHandler {
        return ParseCommandHandler()
    }
    
    func canHandle(_ command: String) -> Bool {
        return command.lowercased().hasPrefix("#parse")
    }
    
    func handle(_ command: String, with withContext: GameContext) {
        let idx = command.index(command.startIndex, offsetBy: 6)
        var text: String = String(command[idx..<command.endIndex])
        text = text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        let dict = ["text": text]
        
        withContext.events.publish("ol:game-parse", data: dict as Dictionary<String, AnyObject>)
    }
}
