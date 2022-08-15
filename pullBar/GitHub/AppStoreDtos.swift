//
//  AppstoreDtos.swift
//  pullBar
//
//  Created by Pavel Makhov on 2022-08-14.
//

import Foundation

struct Releases: Codable {
    
    var results: [Release]
    
    enum CodingKeys: String, CodingKey {
        case results
    }
}

struct Release: Codable {
    
    var version: String
    var trackViewUrl: URL
    
    enum CodingKeys: String, CodingKey {
        case version
        case trackViewUrl
    }
}
