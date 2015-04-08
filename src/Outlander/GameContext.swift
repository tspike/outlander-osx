//
//  GameContext.swift
//  Outlander
//
//  Created by Joseph McBride on 4/7/15.
//  Copyright (c) 2015 Joe McBride. All rights reserved.
//

import Foundation

@objc
public class GameContext {
    
    class func newInstance() -> GameContext {
        return GameContext()
    }
    
    public var settings:AppSettings
    public var pathProvider:AppPathProvider
    public var layout:Layout?
    
    public var mapZone:MapZone? {
        didSet {
            
            var zoneId = ""
            
            if self.mapZone != nil {
                zoneId = self.mapZone!.id
            }
            
            self.globalVars.setCacheObject(zoneId, forKey: "zoneid")
            
        }
    }
    
    public var highlights:OLMutableArray
    public var aliases:OLMutableArray
    public var macros:OLMutableArray
    public var globalVars:TSMutableDictionary
    
    init() {
        self.settings = AppSettings()
        self.pathProvider = AppPathProvider(settings: settings)
        self.highlights = OLMutableArray()
        self.aliases = OLMutableArray()
        self.macros = OLMutableArray()
        self.globalVars = TSMutableDictionary(name: "com.outlander.globalvars")
        
        self.globalVars.setCacheObject(">", forKey: "prompt")
        self.globalVars.setCacheObject("Empty", forKey: "lefthand")
        self.globalVars.setCacheObject("Empty", forKey: "righthand")
        self.globalVars.setCacheObject("None", forKey: "preparedspell")
        self.globalVars.setCacheObject("0", forKey: "tdp")
    }
}