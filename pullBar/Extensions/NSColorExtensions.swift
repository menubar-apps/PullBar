//
//  NSColorExtensions.swift
//  pullBar
//
//  Created by Casey Jones on 2021-12-23.
//

import Foundation
import AppKit


extension NSColor {
    /// NSColor initializer accepting hex color string
    ///
    /// ```
    /// NSColor(hex: "#BADA55")
    /// ```
    ///
    /// - Parameter hex: Hex color string, may include a hash (#) prefix
    /// - Returns: an NSColor of given hex color string
    convenience init (hex: String) {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }

        if ((cString.count) != 6) {
            self.init(.gray)
        }

        var rgbValue:UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        self.init(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}
