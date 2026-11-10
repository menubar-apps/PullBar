import Foundation

// Run with:
// swiftc pullBar/GitHub/GitHubDtos.swift Tests/ActionRulesTests.swift -o /tmp/pullbar-action-tests
// /tmp/pullbar-action-tests
@main
struct ActionRulesTests {
    static var checks = 0
    static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        precondition(condition(), message)
        checks += 1
    }

    static func main() throws {
        let fixture = """
        {
          "data": {"search": {
            "issueCount": 1, "pageInfo": {"hasNextPage": false, "endCursor": null},
            "edges": [{"node": {
              "url": "https://github.com/example/repo/pull/1", "number": 1,
              "title": "Example", "createdAt": "2026-11-01T12:00:00Z",
              "updatedAt": "2026-11-08T12:00:00Z", "isDraft": false,
              "isReadByViewer": false, "viewerDidAuthor": true, "author": {"login": "me"},
              "repository": {"name": "example/repo"}, "labels": {"nodes": []},
              "mergeable": "MERGEABLE", "mergeStateStatus": "CLEAN", "reviewDecision": "APPROVED",
              "reviews": {"totalCount": 2, "edges": [
                {"node": {"author": {"login": "alice"}, "viewerDidAuthor": false, "state": "APPROVED"}},
                {"node": {"author": {"login": "bob"}, "viewerDidAuthor": false, "state": "APPROVED"}}
              ]},
              "commentReviews": {"totalCount": 0, "edges": []},
              "reviewThreads": {"totalCount": 0, "nodes": []},
              "commits": {"nodes": [{"commit": {"statusCheckRollup": {
                "state": "SUCCESS", "contexts": {"totalCount": 1, "nodes": [
                  {"name": "Tests", "status": "COMPLETED", "conclusion": "SUCCESS"}
                ]}
              }}}]}
            }}]
          }}
        }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let response = try decoder.decode(GraphQlSearchResp.self, from: Foundation.Data(fixture.utf8))
        let base = response.data!.search.edges[0].node
        expect(base.readyToMerge, "Two distinct approvals and passing CI must be ready")
        expect(base.actionReasons(lastRead: nil) == ["Ready to merge"], "Ready PR is one action")
        var pr = base
        pr.reviews.edges[1].node.author = pr.reviews.edges[0].node.author
        expect(pr.approvalCount == 1 && !pr.readyToMerge, "Duplicate reviewer must not count twice")
        pr = base
        pr.reviews.edges[1].node.state = "CHANGES_REQUESTED"
        expect(pr.approvalCount == 1 && pr.changesRequested && !pr.readyToMerge, "A changed decision removes the approval")
        for state in ["DISMISSED", "COMMENTED", "PENDING"] {
            pr = base
            pr.reviews.edges[1].node.state = state
            expect(pr.approvalCount == 1 && !pr.readyToMerge, "Only APPROVED counts")
        }
        pr = base
        pr.isDraft = true
        expect(!pr.readyToMerge, "Drafts cannot be ready")
        for state in ["BLOCKED", "BEHIND", "UNKNOWN", "DIRTY", "UNSTABLE", "DRAFT", "HAS_HOOKS"] {
            pr = base
            pr.mergeStateStatus = state
            expect(!pr.readyToMerge, "GitHub blockers must prevent ready")
        }
        pr = base
        pr.mergeable = "CONFLICTING"
        expect(!pr.readyToMerge && pr.actionReasons(lastRead: nil).contains("Resolve conflicts"), "Conflicts require action")
        pr = base
        pr.reviewDecision = "REVIEW_REQUIRED"
        expect(!pr.readyToMerge, "Repository may require more than two approvals")
        pr = base
        pr.reviewThreads = ReviewThreads(totalCount: 1, nodes: [ReviewThread(isResolved: false)])
        expect(!pr.readyToMerge && pr.unresolvedThreads == 1, "Unresolved discussion prevents ready")
        pr.reviewThreads.nodes[0].isResolved = true
        expect(pr.readyToMerge, "Resolved discussion clears its action")
        pr.reviewThreads.totalCount = 101
        expect(!pr.readyToMerge && !pr.detailsComplete, "Truncated discussions cannot imply ready")
        pr = base
        pr.reviews.totalCount = 101
        expect(!pr.readyToMerge, "Truncated reviews cannot imply ready")
        pr = base
        pr.commits = nil
        expect(pr.ciState == .missing && !pr.readyToMerge, "Missing CI is not success")
        pr.commits = CommitsNodes(nodes: [])
        expect(pr.ciState == .missing, "Empty commits must not crash")
        for state in ["FAILURE", "ERROR", "PENDING", "EXPECTED", "UNKNOWN"] {
            pr = base
            pr.commits!.nodes[0].commit.statusCheckRollup!.state = state
            expect(!pr.readyToMerge, "Non-success CI must prevent ready")
        }
        pr = base
        pr.commits!.nodes[0].commit.statusCheckRollup!.contexts.totalCount = 101
        expect(pr.ciState == .unknown && !pr.readyToMerge, "Incomplete CI is not success")
        for conclusion in ["SKIPPED", "NEUTRAL", "CANCELLED", "TIMED_OUT", "ACTION_REQUIRED"] {
            pr = base
            pr.commits!.nodes[0].commit.statusCheckRollup!.contexts.nodes[0].conclusion = conclusion
            expect(!pr.readyToMerge, "Without any executed successful check, do not report ready")
        }
        pr = base
        pr.commits!.nodes[0].commit.statusCheckRollup!.contexts.nodes[0].status = "IN_PROGRESS"
        expect(!pr.readyToMerge, "A running check is not complete")
        expect(pr.ciState == .running, "Running checks are explicitly identified")
        for status in ["QUEUED", "WAITING", "REQUESTED", "PENDING"] {
            pr = base
            pr.commits!.nodes[0].commit.statusCheckRollup!.state = "PENDING"
            pr.commits!.nodes[0].commit.statusCheckRollup!.contexts.nodes[0].status = status
            expect(pr.ciState == .queued && !pr.readyToMerge, "Queued checks must not be called running")
        }
        pr = base
        pr.commits!.nodes[0].commit.statusCheckRollup!.state = "PENDING"
        pr.commits!.nodes[0].commit.statusCheckRollup!.contexts.nodes[0].status = nil
        pr.commits!.nodes[0].commit.statusCheckRollup!.contexts.nodes[0].state = "PENDING"
        expect(pr.ciState == .pending, "Legacy statuses cannot prove execution has started")
        pr = base
        pr.commits!.nodes[0].commit.statusCheckRollup!.state = "FAILURE"
        pr.commits!.nodes[0].commit.statusCheckRollup!.contexts.nodes[0].status = "IN_PROGRESS"
        expect(pr.ciState == .failed && pr.ciSummary.contains("other checks running"), "Failure and ongoing checks both remain visible")
        pr = base
        let submitted = Date(timeIntervalSince1970: 100)
        pr.commentReviews = Review(totalCount: 1, edges: [UserEdge(node: UserNode(
            author: User(login: "alice"), viewerDidAuthor: false, state: "COMMENTED", submittedAt: submitted))])
        expect(pr.hasUnreadReview(since: nil), "Unread review comment requires attention")
        expect(!pr.hasUnreadReview(since: submitted), "Opening a PR acknowledges existing comments")
        expect(pr.hasUnreadReview(since: submitted.addingTimeInterval(-1)), "New feedback after opening returns")
        pr.commentReviews.edges[0].node.viewerDidAuthor = true
        expect(!pr.hasUnreadReview(since: nil), "Own comments do not create an action")
        pr.commentReviews.edges[0].node.viewerDidAuthor = false
        pr.isReadByViewer = true
        expect(!pr.hasUnreadReview(since: nil), "Read PR has no new review comments")
        expect(!pr.hasUnreadReview(since: submitted.addingTimeInterval(-1)), "Reading on GitHub also acknowledges comments")
        pr = base
        pr.commits!.nodes[0].commit.statusCheckRollup!.state = "FAILURE"
        pr.reviews.edges[0].node.state = "CHANGES_REQUESTED"
        expect(pr.actionReasons(lastRead: nil).count == 2, "Show both reasons")
        expect([pr].filter { !$0.actionReasons(lastRead: nil).isEmpty }.count == 1, "Count PRs, not reasons")
        let error = try decoder.decode(GraphQlSearchResp.self, from: Foundation.Data("{\"errors\":[{\"message\":\"Denied\"}]}".utf8))
        expect(error.data == nil && error.errors?.first?.message == "Denied", "GraphQL failures are not empty results")
        pr = base
        expect(pr.ciDiagnosticLines().contains("Test merge: commit unavailable"), "Unavailable merge commit is explicit")
        pr.potentialMergeCommit = pr.commits!.nodes[0].commit
        pr.potentialMergeCommit!.oid = "abcdef123456"
        pr.potentialMergeCommit!.statusCheckRollup!.state = "PENDING"
        pr.potentialMergeCommit!.statusCheckRollup!.contexts.nodes[0].status = "IN_PROGRESS"
        pr.potentialMergeCommit!.statusCheckRollup!.contexts.nodes[0].conclusion = nil
        expect(pr.ciDiagnosticLines().contains { $0.contains("Test merge abcdef1: PENDING") }, "Both commit sources are reported independently")
        expect(pr.ciDiagnosticLines().contains { $0.contains("IN_PROGRESS / null") }, "Pending conclusion is not treated as success")
        expect(pr.readyToMerge == base.readyToMerge, "Diagnostics do not alter existing merge rules")
        pr.potentialMergeCommit!.statusCheckRollup = nil
        expect(pr.ciDiagnosticLines().contains { $0.contains("no check data (null)") }, "Null rollup differs from zero checks")
        pr = base
        pr.commits!.nodes[0].commit.statusCheckRollup!.contexts.totalCount = 101
        expect(pr.ciDiagnosticLines().contains { $0.contains("additional checks not fetched") }, "Truncated data is explicitly flagged")
        let clock = Date(timeIntervalSince1970: 1_700_000_000)
        pr = base
        pr.commits!.nodes[0].commit.statusCheckRollup!.contexts.nodes[0].status = "IN_PROGRESS"
        pr.commits!.nodes[0].commit.statusCheckRollup!.contexts.nodes[0].startedAt = clock.addingTimeInterval(-750)
        expect(pr.runningDurationLabel(now: clock) == "12 min", "Running elapsed time comes from startedAt")
        var timed = pr.commits!.nodes[0].commit.statusCheckRollup!.contexts.nodes[0]
        timed.startedAt = clock.addingTimeInterval(-3900)
        expect(timed.executionDuration(now: clock).map(ContextNode.formatDuration) == "1 h 5 min", "Long durations include hours")
        timed.status = "COMPLETED"
        timed.completedAt = clock.addingTimeInterval(-3000)
        expect(timed.executionDuration(now: clock) == 900, "Completed duration uses completedAt, not now")
        timed.completedAt = nil
        expect(timed.executionDuration(now: clock) == nil, "Missing completion time is unknown")
        timed.status = "QUEUED"
        expect(timed.executionDuration(now: clock) == nil, "Queue time is not execution time")
        timed.status = "IN_PROGRESS"
        timed.startedAt = clock.addingTimeInterval(10)
        expect(timed.executionDuration(now: clock) == nil, "Future timestamps must not produce negative durations")
        timed.startedAt = nil
        pr.commits!.nodes[0].commit.statusCheckRollup!.contexts.nodes.append(timed)
        expect(pr.runningDurationLabel(now: clock) == "longest known 12 min", "Partial timing coverage is explicit")
        pr.commits!.nodes[0].commit.statusCheckRollup!.contexts.nodes[0].startedAt = nil
        expect(pr.runningDurationLabel(now: clock) == "duration unavailable", "Missing starts must not invent durations")
        expect(ContextNode.formatDuration(30) == "<1 min", "Subminute elapsed time is explicit")
        print("Passed \(checks) action-rule checks")
    }
}
