//
//  StringExtensions.swift
//  pullBar
//
//  Created by Casey Jones on 2021-12-29.
//

import Foundation

extension String {
  /*
   Truncates the string to the specified length number of characters and appends an optional trailing string if longer.
   - Parameter length: Desired maximum lengths of a string
   - Parameter trailing: A 'String' that will be appended after the truncation.
    
   - Returns: 'String' object.
  */
  func trunc(length: Int, trailing: String = "…") -> String {
    return (self.count > length) ? self.prefix(length) + trailing : self
  }
}

extension Bool {
    var intValue: Int {
        return self ? 1 : 0
    }
}
