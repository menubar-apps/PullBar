//
//  GitHubDtos.swift
//  issueBar
//
//  Created by Pavel Makhov on 2021-11-10.
//

import Foundation

struct GraphQlSearchResp: Codable {
    var data: Data
    
    enum CodingKeys: String, CodingKey {
        case data
    }
}

struct Data: Codable {
    var search: Search

    enum CodingKeys: String, CodingKey {
        case search
    }
}

struct Search: Codable {
    var edges: [Edge]
    var issueCount: Int
    
    enum CodingKeys: String, CodingKey {
        case edges
        case issueCount
    }
}

struct Edges: Codable {
    var edge: [Edge]
    
    enum CodingKeys: String, CodingKey {
        case edge
    }
}

struct Edge: Codable {
    var node: Pull

    enum CodingKeys: String, CodingKey {
        case node
    }
}

struct Pull: Codable {
    var url: URL
    var updatedAt: Date
    var createdAt: Date
    var title: String
    var number: Int
    var deletions: Int?
    var additions: Int?
    var reviews: Review
    var author: User
    var repository: Repository
    
    enum CodingKeys: String, CodingKey {
        case url
        case updatedAt
        case createdAt
        case title
        case number
        case deletions
        case additions
        case reviews
        case author
        case repository
    }
}

struct Review: Codable {
    var totalCount: Int
    
    enum CodingKeys: String, CodingKey {
        case totalCount
    }
}

struct User: Codable {
    var login: String
    var avatarUrl: URL
    
    enum CodingKeys: String, CodingKey {
        case login
        case avatarUrl
    }
}

struct Repository: Codable {
    var name: String
    
    enum CodingKeys: String, CodingKey {
        case name
    }
}

