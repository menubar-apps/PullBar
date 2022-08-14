//
//  NSMutableAttributedString.swift
//  FleetBar
//
//  Created by Pavel Makhov on 2021-11-04.
//

import Foundation
import SwiftUI

extension NSMutableAttributedString {

    @discardableResult
    func appendString(string: String, color: NSColor = NSColor.secondaryLabelColor) -> NSMutableAttributedString {
        var attributes = [NSAttributedString.Key: AnyObject]()
        attributes[.foregroundColor] = color
        self.append(NSMutableAttributedString(string: string, attributes: attributes))
        
        return self
    }
    
    
    @discardableResult
    func appendString(string: String, color: NSColor, fontSize: CGFloat = NSFont.systemFontSize) -> NSMutableAttributedString {

        var attributes = [NSAttributedString.Key: AnyObject]()
        attributes[.foregroundColor] = color
        attributes[.font] = NSFont.systemFont(ofSize: fontSize)
        self.append(NSMutableAttributedString(string: string, attributes: attributes))
        
        return self
    }
    
    @discardableResult
    func appendIcon(iconName: String, color: NSColor = NSColor.secondaryLabelColor) -> NSMutableAttributedString {
        let image = NSImage(named: iconName)?.tint(color: color)
        image?.size = NSSize(width: 12, height: 12)
        let image1Attachment = NSTextAttachment()
        image1Attachment.attachmentCell = NSTextAttachmentCell(imageCell: image)
        image1Attachment.image = image
        let image1String = NSMutableAttributedString(attachment: image1Attachment)
        let range = NSMakeRange(0,image1String.length)
        image1String.addAttribute(NSAttributedString.Key.baselineOffset, value: -1.0, range: range)
        self.append(image1String)
        self.appendString(string: " ")
        
        return self
    }

    @discardableResult
    func appendSeparator() -> NSMutableAttributedString {
        self.append(NSMutableAttributedString(string: "   "))
        return self
    }
    
    @discardableResult
    func appendNewLine() -> NSMutableAttributedString {
        self.append(NSMutableAttributedString(string: "\n"))
        return self
    }
}

func hexColor (hex: String) -> NSColor {
    var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

    if (cString.hasPrefix("#")) {
        cString.remove(at: cString.startIndex)
    }

    if ((cString.count) != 6) {
        return NSColor.gray
    }

    var rgbValue:UInt64 = 0
    Scanner(string: cString).scanHexInt64(&rgbValue)

    return NSColor(
        red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
        green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
        blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
        alpha: CGFloat(1.0)
    )
}
