//
//  File.swift
//  
//
//  Created by ws on 2022/9/14.
//

import Foundation

struct SyntaxReference: Comparable, Hashable {
    let name: String
    let line: Int
    let column: Int

    static func < (lhs: SyntaxReference, rhs: SyntaxReference) -> Bool {
        if lhs.line != rhs.line {
            return lhs.line < rhs.line
        } else if lhs.column != rhs.column {
            return lhs.column < rhs.column
        } else {
            return false
        }
    }
}
