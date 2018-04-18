//
//  Directions.swift
//  Outlander
//
//  Created by Joseph McBride on 4/30/15.
//  Copyright (c) 2015 Joe McBride. All rights reserved.
//

import Foundation

@objcMembers
open class DirectionsView : NSView {
    
    var dir = NSImage(named: NSImage.Name(rawValue: "Directions"))
    var north = NSImage(named: NSImage.Name(rawValue: "North"))
    var south = NSImage(named: NSImage.Name(rawValue: "South"))
    var east = NSImage(named: NSImage.Name(rawValue: "East"))
    var west = NSImage(named: NSImage.Name(rawValue: "West"))
    var northeast = NSImage(named: NSImage.Name(rawValue: "Northeast"))
    var northwest = NSImage(named: NSImage.Name(rawValue: "Northwest"))
    var southeast = NSImage(named: NSImage.Name(rawValue: "Southeast"))
    var southwest = NSImage(named: NSImage.Name(rawValue: "Southwest"))
    var out = NSImage(named: NSImage.Name(rawValue: "Out"))
    var up = NSImage(named: NSImage.Name(rawValue: "Up"))
    var down = NSImage(named: NSImage.Name(rawValue: "Down"))
    
    var availableDirections:[String] = []
    
    open func setDirections(_ dirs:[String]) {
        availableDirections = dirs
        self.needsDisplay = true
    }
    
    open override var isFlipped:Bool {
        get {
            return true
        }
    }
    
    open override func draw(_ dirtyRect: NSRect) {
        
        dir?.draw(in: self.bounds)
        
        if self.availableDirections.index(of: "north") != nil {
            north?.draw(in: self.bounds)
        }
        
        if self.availableDirections.index(of: "south") != nil {
            south?.draw(in: self.bounds)
        }
        
        if self.availableDirections.index(of: "east") != nil {
            east?.draw(in: self.bounds)
        }
        
        if self.availableDirections.index(of: "west") != nil {
            west?.draw(in: self.bounds)
        }
        
        if self.availableDirections.index(of: "northeast") != nil {
            northeast?.draw(in: self.bounds)
        }
        
        if self.availableDirections.index(of: "northwest") != nil {
            northwest?.draw(in: self.bounds)
        }
        
        if self.availableDirections.index(of: "southeast") != nil {
            southeast?.draw(in: self.bounds)
        }
        
        if self.availableDirections.index(of: "southwest") != nil {
            southwest?.draw(in: self.bounds)
        }
        
        if self.availableDirections.index(of: "up") != nil {
            up?.draw(in: self.bounds)
        }
        
        if self.availableDirections.index(of: "down") != nil {
            down?.draw(in: self.bounds)
        }
        
        if self.availableDirections.index(of: "out") != nil {
            out?.draw(in: self.bounds)
        }
    }
}
