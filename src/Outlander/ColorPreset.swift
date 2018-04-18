//
//  ColorPreset.swift
//  Outlander
//
//  Created by Joseph McBride on 1/20/17.
//  Copyright © 2017 Joe McBride. All rights reserved.
//

import Foundation

@objc
open class ColorPreset : NSObject {
    @objc var name:String
    @objc var color:String
    @objc var backgroundColor:String?
    @objc var presetClass:String?

    init(_ name:String, _ color:String) {
        self.name = name
        self.color = color
    }

    init(_ name:String, _ color:String, _ presetClass:String) {
        self.name = name
        self.color = color
        self.presetClass = presetClass
    }
    
    init(_ name:String, _ color:String, _ backgroundColor:String, _ presetClass:String) {
        self.name = name
        self.color = color
        self.backgroundColor = backgroundColor
        self.presetClass = presetClass
    }
}
