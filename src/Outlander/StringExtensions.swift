//
//  StringExtensions.swift
//  Parser
//
//  Created by Joseph McBride on 3/20/15.
//  Copyright (c) 2015 Outlander. All rights reserved.
//

import Foundation

extension Double {
    func format(_ f: String) -> String {
        return String(format: "%\(f)f", self)
    }
}

extension String {
    public func trim(_ type:String) -> String {
        let newVal = self.trimPrefix(type)
        return newVal.trimSuffix(type)
    }
    
    public func trimPrefix(_ prefix:String) -> String {
        
        if(self.hasPrefix(prefix)) {
            let idx = self.index(self.startIndex, offsetBy: prefix.count)
            return String(self[idx..<self.endIndex])
        }
        
        return self
    }
    
    public func trimSuffix(_ suffix:String) -> String {
        
        if(self.hasSuffix(suffix)) {
            let idx = self.index(self.endIndex, offsetBy: -1*suffix.count)
            return String(self[self.startIndex ..< idx])
        }
        
        return self
    }
    
    public func replace(_ target: String, withString: String) -> String
    {
        return self.replacingOccurrences(of: target, with: withString, options: NSString.CompareOptions.literal, range: nil)
    }
    
    subscript (i: Int) -> Character {
        return self[self.index(self.startIndex, offsetBy: i)]
    }
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
    subscript (r: Range<Int>) -> String {
        let start = index(startIndex, offsetBy: r.lowerBound)
        let end = index(startIndex, offsetBy: r.upperBound)
        return String(self[start..<end])
    }

    func stringByAppendingPathComponent(_ path: String) -> String {
        
        let nsSt = self as NSString
        
        return nsSt.appendingPathComponent(path)
    }
    
    func toBool() -> Bool? {
        let trueValues = ["true", "yes", "1", "on", "+"]
        let falseValues = ["false", "no", "0", "off", "-"]
        
        let lowerSelf = self.lowercased()
        
        if trueValues.contains(lowerSelf) {
            return true
        }
        
        if falseValues.contains(lowerSelf) {
            return false
        }
        
        return nil
    }
}


extension Array {
    func forEach(_ doThis: (_ element: Element) -> Void) {
        for e in self {
            doThis(e)
        }
    }
    
    func find(_ includedElement: (Element) -> Bool) -> Int? {
        for (idx, element) in self.enumerated() {
            if includedElement(element) {
                return idx
            }
        }
        return nil
    }
}

extension String {
    
    func toDouble() -> Double? {
        enum F {
            static let formatter = NumberFormatter()
        }
        if let number = F.formatter.number(from: self) {
            return number.doubleValue
        }
        return nil
    }
    
    func substringFromIndex(_ index:Int) -> String {
        let idx = self.index(self.startIndex, offsetBy: index)
        return String(self[idx..<self.endIndex])
    }
    
    func indexOfCharacter(_ char: Character) -> Int? {
        if let idx = self.index(of: char) {
            return self.distance(from: self.startIndex, to: idx)
        }
        return nil
    }
    
    func splitToCommands() -> [String] {
        
        var results:[String] = []
        
        let matches = self["((?<!\\\\);)"].matchResults()
        
        var lastIndex = 0
        let length = self.count
        
        for match in matches {
            let matchLength = match.range.location - lastIndex
            let start = self.index(self.startIndex, offsetBy: lastIndex)
            let end = self.index(start, offsetBy: matchLength)
            var str = String(self[start..<end])
            str = str.replacingOccurrences(of: "\\;", with: ";")
            results.append(str)
            
            lastIndex = match.range.location + match.range.length
        }
        
        if lastIndex < length {
            let start = self.index(self.startIndex, offsetBy: lastIndex)
            let end = self.index(start, offsetBy: length - lastIndex)
            var str = String(self[start ..< end])
            str = str.replacingOccurrences(of: "\\;", with: ";")
            results.append(str)
        }
        
        return results
    }
}

