//
//  Extensions.swift
//  AdvancedMap.Swift
//
//  Created by Aare Undo on 27/06/2017.
//  Copyright © 2017 CARTO. All rights reserved.
//

extension String {
    func index(from: Int) -> Index {
        return self.index(startIndex, offsetBy: from)
    }
    
    func substring(from: Int) -> String {
        let fromIndex = index(from: from)
        return substring(from: fromIndex)
    }
    
    func substring(to: Int) -> String {
        let toIndex = index(from: to)
        return substring(to: toIndex)
    }
    
    func substring(from: Int, to: Int) -> String {
        return substring(from: from).substring(to: to)
    }
    
    func substring(with r: Range<Int>) -> String {
        let startIndex = index(from: r.lowerBound)
        let endIndex = index(from: r.upperBound)
        return substring(with: startIndex..<endIndex)
    }
    
    func index(of: Character) -> Int {
        guard let index = characters.index(of: of) else {
            return -1
        }
        return distance(from: startIndex, to: index)
    }
    
    func lastIndexOf(s: String) -> Int {
        
        if let r: Range<Index> = range(of: s) {
            return distance(from: self.startIndex, to: r.lowerBound)
        }
        
        return -1
    }
}