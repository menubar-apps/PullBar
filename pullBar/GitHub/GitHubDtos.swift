//
//  BitbucketDtos.swift
//  pullBar
//
//  DTO models for the Bitbucket Data Center (Bitbucket Server) REST API,
//  /rest/api/1.0. Adapted from the original GitHub GraphQL models.
//

import Foundation

struct DashboardResponse: Codable {
    var isLastPage: Bool
    var nextPageStart: Int?
    var values: [BitbucketPull]

    enum CodingKeys: String, CodingKey {
        case isLastPage
        case nextPageStart
        case values
    }
}

struct BitbucketPull: Codable {
    var id: Int
    var title: String
    var state: String
    var createdDate: Int64
    var author: BitbucketParticipant
    var reviewers: [BitbucketParticipant]?
    var toRef: BitbucketRef
    var links: BitbucketLinks?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case state
        case createdDate
        case author
        case reviewers
        case toRef
        case links
    }

    var created: Date {
        Date(timeIntervalSince1970: Double(createdDate) / 1000.0)
    }

    /// Approvals exposed by Bitbucket's dashboard: reviewers who marked the PR approved.
    var approvedViewerCount: Int {
        (reviewers ?? []).filter { $0.approved == true }.count
    }

    var repositoryName: String {
        let repository = toRef.repository
        if let name = repository.name, !name.isEmpty {
            return name
        }
        return repository.slug
    }

    var authorName: String {
        let user = author.user
        return user.displayName.isEmpty ? user.name : user.displayName
    }

    var url: URL? {
        links?.selfLink?.first.flatMap { URL(string: $0.href) }
    }
}

struct BitbucketParticipant: Codable {
    var user: BitbucketUser
    var approved: Bool?

    enum CodingKeys: String, CodingKey {
        case user
        case approved
    }
}

struct BitbucketUser: Codable {
    var name: String
    var displayName: String
    var links: BitbucketLinks?

    enum CodingKeys: String, CodingKey {
        case name
        case displayName
        case links
    }
}

struct BitbucketRef: Codable {
    var repository: BitbucketRepository

    enum CodingKeys: String, CodingKey {
        case repository
    }
}

struct BitbucketRepository: Codable {
    var slug: String
    var name: String?
    var project: BitbucketProject?

    enum CodingKeys: String, CodingKey {
        case slug
        case name
        case project
    }
}

struct BitbucketProject: Codable {
    var key: String

    enum CodingKeys: String, CodingKey {
        case key
    }
}

struct BitbucketLinks: Codable {
    var selfLink: [BitbucketHref]?
    var avatar: [BitbucketHref]?

    enum CodingKeys: String, CodingKey {
        case selfLink = "self"
        case avatar
    }
}

struct BitbucketHref: Codable {
    var href: String

    enum CodingKeys: String, CodingKey {
        case href
    }
}