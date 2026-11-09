//
//  GitHubDtos.swift
//  issueBar
//
//  Created by Pavel Makhov on 2021-11-10.
//

import Foundation

struct GraphQlSearchResp: Codable {
    var data: Data?
    var errors: [GraphQLError]?
    
    enum CodingKeys: String, CodingKey {
        case data
        case errors
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
    var pageInfo: PageInfo
    
    enum CodingKeys: String, CodingKey {
        case edges
        case issueCount
        case pageInfo
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
    var author: User?
    var repository: Repository
    var commits: CommitsNodes?
    var potentialMergeCommit: CheckSuites?
    var labels: Nodes<Label>
    var isDraft: Bool
    var isReadByViewer: Bool
    var viewerDidAuthor: Bool
    var mergeable: String
    var mergeStateStatus: String
    var reviewDecision: String?
    var reviewThreads: ReviewThreads
    var commentReviews: Review
    
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
        case commits, potentialMergeCommit
        case labels
        case isDraft
        case isReadByViewer, viewerDidAuthor
        case mergeable, mergeStateStatus, reviewDecision, reviewThreads, commentReviews
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
    var author: User?
    var viewerDidAuthor: Bool
    var state: String
    var submittedAt: Date?

    enum CodingKeys: String, CodingKey {
        case author
        case viewerDidAuthor
        case state, submittedAt
    }
}

struct User: Codable {
    var login: String
    var avatarUrl: URL?
    
    enum CodingKeys: String, CodingKey {
        case login
        case avatarUrl
    }
    
    static var ghost: User {
        return User(login: "ghost", avatarUrl: nil)
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
    var oid: String?
    var checkSuites: CheckSuitsNodes?
    var statusCheckRollup: StatusCheckRollup?
    
    enum CodingKeys: String, CodingKey {
        case checkSuites, oid
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
    var totalCount: Int
    
    enum CodingKeys: String, CodingKey {
        case nodes, totalCount
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
    var status: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case context
        case conclusion
        case state
        case title
        case description
        case detailsUrl
        case targetUrl, status
    }
}


struct GraphQLError: Codable { var message: String }
struct PageInfo: Codable { var hasNextPage: Bool; var endCursor: String? }
struct ReviewThreads: Codable {
    var totalCount: Int
    var nodes: [ReviewThread]
}
struct ReviewThread: Codable { var isResolved: Bool }

enum CIState: String {
    case passed = "CI passed"
    case failed = "CI failed"
    case pending = "CI pending"
    case running = "CI checks running"
    case queued = "CI queued / waiting"
    case missing = "No CI reported"
    case unknown = "CI incomplete / unknown"
}

extension Pull {
    // GitHub returns the latest opinionated review per person, not every
    // historical approval. A later request for changes replaces an approval.
    var approvalCount: Int {
        Set(reviews.edges.filter { $0.node.state == "APPROVED" }
            .compactMap { $0.node.author?.login }).count
    }
    var changesRequested: Bool {
        reviewDecision == "CHANGES_REQUESTED" || reviews.edges.contains { $0.node.state == "CHANGES_REQUESTED" }
    }
    var unresolvedThreads: Int { reviewThreads.nodes.filter { !$0.isResolved }.count }
    var detailsComplete: Bool {
        reviews.edges.count == reviews.totalCount && reviewThreads.nodes.count == reviewThreads.totalCount
    }
    var ciState: CIState {
        guard let rollup = commits?.nodes.first?.commit.statusCheckRollup,
              rollup.contexts.totalCount > 0 else { return .missing }
        // The rollup covers all contexts, including ones beyond the details page.
        if ["FAILURE", "ERROR"].contains(rollup.state) { return .failed }
        if hasRunningChecks { return .running }
        if rollup.contexts.nodes.contains(where: {
            ["QUEUED", "WAITING", "REQUESTED", "PENDING"].contains($0.status ?? "")
        }) { return .queued }
        // Legacy commit statuses do not distinguish running from queued.
        if ["PENDING", "EXPECTED"].contains(rollup.state) { return .pending }
        guard rollup.state == "SUCCESS",
              rollup.contexts.nodes.count == rollup.contexts.totalCount else { return .unknown }
        let contexts = rollup.contexts.nodes
        let allFinished = contexts.allSatisfy {
            if let status = $0.status {
                return status == "COMPLETED" && ["SUCCESS", "NEUTRAL", "SKIPPED"].contains($0.conclusion ?? "")
            }
            return $0.state == "SUCCESS"
        }
        // Skipped / neutral checks alone do not prove that CI actually ran.
        let hasSuccess = contexts.contains { $0.conclusion == "SUCCESS" || $0.state == "SUCCESS" }
        return allFinished && hasSuccess ? .passed : .unknown
    }
    var hasRunningChecks: Bool {
        commits?.nodes.first?.commit.statusCheckRollup?.contexts.nodes.contains {
            $0.status == "IN_PROGRESS"
        } ?? false
    }
    var ciSummary: String {
        if ciState == .failed && hasRunningChecks {
            return "CI failed · other checks running"
        }
        return ciState.rawValue
    }
    var readyToMerge: Bool {
        !isDraft && detailsComplete && approvalCount >= 2 && ciState == .passed
            && !changesRequested && unresolvedThreads == 0
            && mergeable == "MERGEABLE" && mergeStateStatus == "CLEAN"
            && (reviewDecision == nil || reviewDecision == "APPROVED")
    }
    func hasUnreadReview(since lastRead: Date?) -> Bool {
        guard !isReadByViewer else { return false }
        return commentReviews.edges.contains {
            guard !$0.node.viewerDidAuthor, let submitted = $0.node.submittedAt else { return false }
            if let lastRead = lastRead { return submitted > lastRead }
            return !isReadByViewer
        }
    }
    func actionReasons(lastRead: Date?) -> [String] {
        var reasons: [String] = []
        if ciState == .failed { reasons.append("Fix CI") }
        if changesRequested { reasons.append("Changes requested") }
        if unresolvedThreads > 0 { reasons.append("\(unresolvedThreads) unresolved discussions") }
        if hasUnreadReview(since: lastRead) { reasons.append("New review comments") }
        if mergeable == "CONFLICTING" { reasons.append("Resolve conflicts") }
        if readyToMerge { reasons.append("Ready to merge") }
        return reasons
    }
}

// Diagnostic output deliberately does not participate in action / merge rules.
extension Pull {
    func ciDiagnosticLines(checkLimit: Int? = nil) -> [String] {
        var lines = ["GitHub: merge=\(mergeStateStatus) · reviews=\(reviewDecision ?? "null")"]
        for (source, commit) in [("Head", commits?.nodes.first?.commit), ("Test merge", potentialMergeCommit)] {
            guard let commit = commit else {
                lines.append("\(source): commit unavailable")
                continue
            }
            let sha = commit.oid.map { String($0.prefix(7)) } ?? "SHA unavailable"
            guard let rollup = commit.statusCheckRollup else {
                lines.append("\(source) \(sha): no check data (null)")
                continue
            }
            let nodes = rollup.contexts.nodes
            lines.append("\(source) \(sha): \(rollup.state) · \(nodes.count)/\(rollup.contexts.totalCount) checks received")
            // Put unfinished checks before successful ones in the compact preview.
            let sorted = nodes.enumerated().sorted {
                let left = $0.element.status == "COMPLETED" || $0.element.state == "SUCCESS"
                let right = $1.element.status == "COMPLETED" || $1.element.state == "SUCCESS"
                return left == right ? $0.offset < $1.offset : !left
            }.map { $0.element }
            let shown = checkLimit.map { Array(sorted.prefix($0)) } ?? sorted
            for check in shown {
                let name = (check.name ?? check.context ?? "Unnamed check").replacingOccurrences(of: "\n", with: " ")
                let displayName = checkLimit == nil ? name : String(name.prefix(35))
                if check.status != nil || check.name != nil {
                    lines.append("  \(displayName): \(check.status ?? "null") / \(check.conclusion ?? "null")")
                } else {
                    lines.append("  \(displayName): status=\(check.state ?? "null")")
                }
            }
            if shown.count < nodes.count { lines.append("  +\(nodes.count - shown.count) checks — hover for details") }
            if nodes.count < rollup.contexts.totalCount { lines.append("  Incomplete: additional checks not fetched") }
        }
        return lines
    }
}
