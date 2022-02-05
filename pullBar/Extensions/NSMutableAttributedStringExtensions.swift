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
    func appendString(string: String) -> NSMutableAttributedString {
        self.append(NSMutableAttributedString(string: string))
        
        return self
    }

    @discardableResult
    func appendString(string: String, color: NSColor = NSColor.gray) -> NSMutableAttributedString {
        var attributes = [NSAttributedString.Key: AnyObject]()
        attributes[.foregroundColor] = color
        self.append(NSMutableAttributedString(string: string, attributes: attributes))
        
        return self
    }
    
    @discardableResult
    func appendIcon(iconName: String, color: NSColor = NSColor.gray) -> NSMutableAttributedString {
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
