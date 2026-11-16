import Foundation

// swiftc pullBar/GitHub/GitHubDtos.swift Tests/RecentMergesTests.swift -o /tmp/pullbar-merges-tests
@main
struct RecentMergesTests {
    static var checks = 0
    static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        precondition(condition(), message)
        checks += 1
    }
    static func main() throws {
        let names = try RecentMergeSettings.repositories(from: "org/ios\norg/android, ORG/IOS; team/shared")
        expect(names == ["org/ios", "org/android", "team/shared"], "Parse and deduplicate repository list")
        let empty = try RecentMergeSettings.repositories(from: " \n , ; ")
        expect(empty.isEmpty, "Empty configuration is supported")
        for invalid in ["org", "https://github.com/org/repo", "org/repo/path", "org/"] {
            do {
                _ = try RecentMergeSettings.repositories(from: invalid)
                preconditionFailure("Invalid repository accepted")
            } catch { checks += 1 }
        }
        func pull(_ number: Int, merged: TimeInterval, updated: TimeInterval, repo: String = "org/ios") -> RecentMerge {
            RecentMerge(title: "PR \(number)", url: URL(string: "https://github.com/\(repo)/pull/\(number)")!,
                        number: number, mergedAt: Date(timeIntervalSince1970: merged),
                        updatedAt: Date(timeIntervalSince1970: updated), repository: RecentMergeRepository(nameWithOwner: repo))
        }
        let oldButUpdated = pull(1, merged: 10, updated: 1000)
        let newer = pull(2, merged: 200, updated: 200)
        let newest = pull(3, merged: 300, updated: 300, repo: "org/android")
        let pulls = [oldButUpdated, newest, newer, newest]
        expect(RecentMerge.latest(pulls, limit: 3).map { $0.number } == [3, 2, 1], "Sort by merge date, deduplicate across sources")
        expect(RecentMerge.latest(pulls, limit: 1).first?.number == 3, "Limit applies globally across repositories")
        expect(!RecentMerge.canStopPaging([oldButUpdated], oldestUpdatedAt: oldButUpdated.updatedAt, limit: 1), "Updated old merge cannot stop pagination prematurely")
        expect(!RecentMerge.canStopPaging(pulls, oldestUpdatedAt: Date(timeIntervalSince1970: 200), limit: 2), "Fetch date ties for deterministic ordering")
        expect(RecentMerge.canStopPaging(pulls, oldestUpdatedAt: Date(timeIntervalSince1970: 199), limit: 2), "Stop only when unseen merges cannot enter top results")
        expect(!RecentMerge.canStopPaging(pulls, oldestUpdatedAt: Date(timeIntervalSince1970: 0), limit: 5), "Continue until enough merges or last page")
        expect(RecentMerge.latest([], limit: 5).isEmpty, "Empty repository history is valid")
        let json = #"{"data":{"repository":{"pullRequests":{"nodes":[{"title":"Merged PR","url":"https://github.com/org/repo/pull/1","number":1,"mergedAt":"2026-11-16T10:00:00Z","updatedAt":"2026-11-16T11:00:00Z","repository":{"nameWithOwner":"org/repo"}}],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}"#
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let response = try decoder.decode(RecentMergesResponse.self, from: Foundation.Data(json.utf8))
        expect(response.data?.repository?.pullRequests.nodes.first?.title == "Merged PR", "Decode merge query response")
        let inaccessible = try decoder.decode(RecentMergesResponse.self, from: Foundation.Data(#"{"data":{"repository":null},"errors":[{"message":"Not found"}]}"#.utf8))
        expect(inaccessible.data?.repository == nil && inaccessible.errors?.first?.message == "Not found", "Missing repository differs from empty history")
        print("Passed \(checks) recent-merge checks")
    }
}
