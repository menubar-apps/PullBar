//
//  NSImageExtensions.swift
//  pullBar
//
//  Created by Pavel Makhov on 2021-11-21.
//

import Foundation
import SwiftUI

extension NSImage {

    static func imageFromUrl(fromURL url: URL) -> NSImage? {
        guard let data = try? Foundation.Data(contentsOf: url) else { return nil }
        guard let image = NSImage(data: data) else { return nil }
        return image
    }
    
    func tint(color: NSColor) -> NSImage {
        let newImage = NSImage(size: self.size)
        newImage.lockFocus()

        // Draw with specified transparency
        let imageRect = NSRect(origin: .zero, size: self.size)
        self.draw(in: imageRect, from: imageRect, operation: .sourceOver, fraction: color.alphaComponent)

        // Tint with color
        color.withAlphaComponent(1).set()
        imageRect.fill(using: .sourceAtop)

        newImage.unlockFocus()
        return newImage
    }
    
}
