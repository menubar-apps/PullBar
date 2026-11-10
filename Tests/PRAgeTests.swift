import Foundation

// swiftc pullBar/Extensions/DateExtensions.swift Tests/PRAgeTests.swift -o /tmp/pullbar-age-tests
@main
struct PRAgeTests {
    static func main() {
        let created = Date(timeIntervalSince1970: 1_700_000_000)
        let cases: [(TimeInterval, String)] = [
            (-60, "Created just now"),
            (0, "Created just now"),
            (59, "Created just now"),
            (60, "Created 1 minute ago"),
            (3599, "Created 59 minutes ago"),
            (3600, "Created 1 hour ago"),
            (7200, "Created 2 hours ago"),
            (86399, "Created 23 hours ago"),
            (86400, "Created 1 day ago"),
            (90000, "Created 1 day and 1 hour ago"),
            (93600, "Created 1 day and 2 hours ago"),
            (172799, "Created 1 day and 23 hours ago"),
            (172800, "Created 2 days ago"),
            (3888000, "Created 45 days ago"),
        ]
        for (elapsed, expected) in cases {
            let actual = created.creationAgeLabel(now: created.addingTimeInterval(elapsed))
            precondition(actual == expected, "At \(elapsed)s: \(actual), expected \(expected)")
        }
        print("Passed \(cases.count) PR-age checks")
    }
}
