//
//  BugCommandHandler.swift
//  Outlander
//
//  Created by Joseph McBride on 11/14/17.
//  Copyright © 2017 Joe McBride. All rights reserved.
//

import Foundation

@objcMembers
class BugCommandHandler : NSObject, CommandHandler {

    class func newInstance() -> BugCommandHandler {
        return BugCommandHandler()
    }

    func canHandle(_ command: String) -> Bool {
        return command.lowercased().hasPrefix("#bug")
    }

    func handle(_ command: String, with withContext: GameContext) {
        let url = URL(string: "https://github.com/joemcbride/outlander-osx/issues/new")
        NSWorkspace.shared.open(url!)
    }
}
