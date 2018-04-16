//
//  FlippedView.swift
//  Outlander
//
//  Created by Joseph McBride on 5/25/15.
//  Copyright (c) 2015 Joe McBride. All rights reserved.
//

import Foundation

@objc
class FlippedView : NSView {
    override var isFlipped:Bool {
        get {
            return true
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        
//        NSColor.blackColor().setFill()
//        
//        NSRectFill(dirtyRect)
        
        super.draw(dirtyRect)
    }
}
