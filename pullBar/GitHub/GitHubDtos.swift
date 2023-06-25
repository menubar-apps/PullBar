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
    var commits: CommitsNodes?
    var labels: Nodes<Label>
    var isDraft: Bool
    
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
        case commits
        case labels
        case isDraft
    }
}


struct Nodes<T: Codable & Hashable>: Codable, Hashable {
    var nodes: [T]
    
    enum CodingKeys: String, CodingKey {
        case nodes
    }
}

struct Review: Codable {
    var totalCount: Int
    var edges: [UserEdge]
    
    enum CodingKeys: String, CodingKey {
        case totalCount
        case edges
    }
}

struct UserEdge: Codable {
    var node: UserNode
    
    enum CondigKeys: String, CodingKey {
        case node
    }
}

struct UserNode: Codable {
    var author: User
    
    enum CodingKeys: String, CodingKey {
        case author
    }
}

struct User: Codable {
    var login: String
    var avatarUrl: URL?
    
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

struct CommitsNodes: Codable {
    var nodes: [Commit]

    enum CodingKeys: String, CodingKey {
        case nodes
    }
}

struct Commit: Codable, Hashable {
    var commit: CheckSuites
    
    enum CodingKeys: String, CodingKey {
        case commit
    }
}

struct CheckSuites: Codable, Hashable {
    var checkSuites: CheckSuitsNodes?
    var statusCheckRollup: StatusCheckRollup?
    
    enum CodingKeys: String, CodingKey {
        case checkSuites
        case statusCheckRollup
    }
}


struct CheckSuitsNodes: Codable, Hashable {
    var nodes: [CheckSuit]

    enum CodingKeys: String, CodingKey {
        case nodes
    }
}

struct App: Codable, Hashable {
    var name: String?
    enum CodingKeys: String, CodingKey {
        case name
    }
}

struct CheckSuit: Codable, Hashable {
    var app: App?
    var checkRuns: CheckRun
    
    enum CodingKeys: String, CodingKey {
        case checkRuns
        case app
    }
}

struct CheckRun: Codable, Hashable {
    var totalCount: Int
    var nodes: [Check]
    
    enum CodingKeys: String, CodingKey {
        case totalCount
        case nodes
    }
}

struct Check: Codable, Hashable {
    var name: String
    var conclusion: String?
    var detailsUrl: URL
    
    enum CodingKeys: String, CodingKey {
        case name
        case conclusion
        case detailsUrl
    }
}

struct LatestRelease: Codable {
    
    var name: String
    var assets: [Asset]
    
    enum CodingKeys: String, CodingKey {
        case name
        case assets
    }
}

struct Asset: Codable {
    var name: String
    var browserDownloadUrl: String
    
    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadUrl = "browser_download_url"
    }
}

struct Label: Codable, Hashable {
    var name: String
    var color: String
    
    enum CodingKeys: String, CodingKey {
        case name
        case color
    }
}

struct StatusCheckRollup: Codable, Hashable {
    var state: String
    var contexts: ContextNodes
    
    enum CodingKeys: String, CodingKey {
        case state
        case contexts
    }
}

struct ContextNodes: Codable, Hashable {
    var nodes: [ContextNode]
    
    enum CodingKeys: String, CodingKey {
        case nodes
    }
}

struct ContextNode: Codable, Hashable {
    var name: String?
    var context: String?
    var conclusion: String?
    var state: String?
    var title: String?
    var description: String?
    var detailsUrl: URL?
    var targetUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case context
        case conclusion
        case state
        case title
        case description
        case detailsUrl
        case targetUrl
    }
}
