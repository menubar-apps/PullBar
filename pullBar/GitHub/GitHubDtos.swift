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
    var nameWithOwner: String? = nil
    
    enum CodingKeys: String, CodingKey {
        case name
        case nameWithOwner
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
    var startedAt: Date?
    var completedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case name
        case context
        case conclusion
        case state
        case title
        case description
        case detailsUrl
        case targetUrl, status, startedAt, completedAt
    }
}


struct GraphQLError: Codable { var message: String }
struct PageInfo: Codable { var hasNextPage: Bool; var endCursor: String? }
struct ReviewThreads: Codable {
    var totalCount: Int
    var nodes: [ReviewThread]
}
struct ReviewThread: Codable {
    var isResolved: Bool
    var comments: ReviewThreadComments?

    var hasReplyAfterViewer: Bool {
        guard !isResolved, let comments = comments else { return false }
        let submitted = comments.nodes.filter { $0.state == "SUBMITTED" }
        guard let lastOwnComment = submitted.filter({ $0.viewerDidAuthor }).map({ $0.createdAt }).max() else {
            return false // Participation is required; owning the PR is not enough.
        }
        return submitted.contains { !$0.viewerDidAuthor && $0.createdAt > lastOwnComment }
    }

    var awaitingReply: Bool {
        guard !isResolved, replyHistoryComplete, let comments = comments else { return false }
        let submitted = comments.nodes.filter { $0.state == "SUBMITTED" }
        guard let latest = submitted.map({ $0.createdAt }).max() else { return false }
        // Ambiguous timestamp ties must not hide someone else's response.
        return submitted.filter { $0.createdAt == latest }.allSatisfy { $0.viewerDidAuthor }
    }

    var replyHistoryComplete: Bool {
        guard !isResolved else { return true }
        guard let comments = comments else { return false }
        return comments.nodes.count == comments.totalCount
    }
}
struct ReviewThreadComments: Codable {
    var totalCount: Int
    var nodes: [ReviewThreadComment]
}
struct ReviewThreadComment: Codable {
    var viewerDidAuthor: Bool
    var createdAt: Date
    var state: String
}

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
    var discussionsAwaitingReply: Int { reviewThreads.nodes.filter { $0.awaitingReply }.count }
    var actionableDiscussions: Int { unresolvedThreads - discussionsAwaitingReply }
    var discussionSummary: String {
        let summary = "\(unresolvedThreads) unresolved discussion\(unresolvedThreads == 1 ? "" : "s")"
        guard discussionsAwaitingReply > 0 else { return summary }
        if discussionsAwaitingReply == unresolvedThreads && reviewThreads.nodes.count == reviewThreads.totalCount {
            return summary + " · Awaiting reply"
        }
        return summary + " · Awaiting reply in \(discussionsAwaitingReply)"
    }
    var conversationsWithRepliesAfterViewer: Int {
        reviewThreads.nodes.filter { $0.hasReplyAfterViewer }.count
    }
    var replyHistoryComplete: Bool {
        reviewThreads.nodes.count == reviewThreads.totalCount
            && reviewThreads.nodes.allSatisfy { $0.replyHistoryComplete }
    }
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
            return "CI failed · other checks running — " + runningDurationLabel()
        }
        if ciState == .running { return ciState.rawValue + " — " + runningDurationLabel() }
        return ciState.rawValue
    }
    func runningDurationLabel(now: Date = Date()) -> String {
        let running = (commits?.nodes.first?.commit.statusCheckRollup?.contexts.nodes ?? [])
            .filter { $0.status == "IN_PROGRESS" }
        let durations = running.compactMap { $0.executionDuration(now: now) }
        guard let longest = durations.max() else { return "duration unavailable" }
        let prefix = running.count > 1
            ? (durations.count == running.count ? "longest " : "longest known ") : ""
        return prefix + ContextNode.formatDuration(longest)
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
        if actionableDiscussions > 0 { reasons.append(discussionSummary) }
        if hasUnreadReview(since: lastRead) { reasons.append("New review comments") }
        if mergeable == "CONFLICTING" { reasons.append("Resolve conflicts") }
        if readyToMerge { reasons.append("Ready to merge") }
        return reasons
    }
}

// Diagnostic output deliberately does not participate in action / merge rules.
extension Pull {
    func ciDiagnosticLines(checkLimit: Int? = nil, now: Date = Date()) -> [String] {
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
                    let duration = check.executionDuration(now: now).map(ContextNode.formatDuration) ?? "unavailable"
                    lines.append("    Duration: \(duration)")
                    if checkLimit == nil {
                        let formatter = ISO8601DateFormatter()
                        let started = check.startedAt.map { formatter.string(from: $0) } ?? "null"
                        let completed = check.completedAt.map { formatter.string(from: $0) } ?? "null"
                        lines.append("    startedAt=\(started) · completedAt=\(completed)")
                    }
                } else {
                    lines.append("  \(displayName): status=\(check.state ?? "null")")
                    lines.append("    Duration unavailable: legacy commit status")
                }
            }
            if shown.count < nodes.count { lines.append("  +\(nodes.count - shown.count) checks — hover for details") }
            if nodes.count < rollup.contexts.totalCount { lines.append("  Incomplete: additional checks not fetched") }
        }
        return lines
    }
}

extension ContextNode {
    func executionDuration(now: Date = Date()) -> TimeInterval? {
        guard let started = startedAt else { return nil }
        let end: Date
        switch status {
        case "IN_PROGRESS": end = now
        case "COMPLETED":
            guard let completed = completedAt else { return nil }
            end = completed
        default: return nil // Queued checks have not started executing.
        }
        let elapsed = end.timeIntervalSince(started)
        return elapsed >= 0 ? elapsed : nil
    }

    static func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds / 60)
        if minutes == 0 { return "<1 min" }
        if minutes < 60 { return "\(minutes) min" }
        return "\(minutes / 60) h \(minutes % 60) min"
    }
}

struct RecentMerge: Codable {
    var title: String
    var url: URL
    var number: Int
    var mergedAt: Date
    var updatedAt: Date
    var repository: RecentMergeRepository

    static func latest(_ pulls: [RecentMerge], limit: Int) -> [RecentMerge] {
        var seen = Set<URL>()
        return Array(pulls.sorted {
            $0.mergedAt == $1.mergedAt ? $0.url.absoluteString < $1.url.absoluteString : $0.mergedAt > $1.mergedAt
        }.filter { seen.insert($0.url).inserted }.prefix(limit))

    }

    // GitHub sorts by update time, not merge time. Older updated pages cannot
    // contain a more recent merge once this bound is crossed (updated >= merged).
    static func canStopPaging(_ pulls: [RecentMerge], oldestUpdatedAt: Date?, limit: Int) -> Bool {
        let latest = latest(pulls, limit: limit)
        guard latest.count == limit, let cutoff = latest.last?.mergedAt,
              let oldestUpdatedAt = oldestUpdatedAt else { return false }
        return oldestUpdatedAt < cutoff
    }
}
struct RecentMergeRepository: Codable { var nameWithOwner: String }
struct RecentMergesResponse: Codable {
    var data: RecentMergesData?
    var errors: [GraphQLError]?
}
struct RecentMergesData: Codable { var repository: RecentMergesRepository? }
struct RecentMergesRepository: Codable { var pullRequests: RecentMergesConnection }
struct RecentMergesConnection: Codable { var nodes: [RecentMerge]; var pageInfo: PageInfo }

enum RecentMergeSettings {
    static func repositories(from text: String) throws -> [String] {
        let names = text.components(separatedBy: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ",;")))
            .filter { !$0.isEmpty }
        var seen = Set<String>()
        return try names.filter { name in
            guard name.range(of: #"^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$"#, options: .regularExpression) != nil else {
                throw InvalidRepository(name: name)
            }
            return seen.insert(name.lowercased()).inserted
        }
    }
    struct InvalidRepository: LocalizedError {
        var name: String
        var errorDescription: String? { "Invalid repository: \(name). Use owner/repository." }
    }
}
