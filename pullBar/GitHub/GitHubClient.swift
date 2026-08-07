//
//  GitHubClient.swift
//  issueBar
//
//  Created by Pavel Makhov on 2021-11-09.
//

import Foundation
import Defaults

public class GitHubClient {
    private let ghCommandQueue = DispatchQueue(label: "pullBar.GitHubClient.gh", qos: .userInitiated)
    private let ghExecutables = [
        "/opt/homebrew/bin/gh",
        "/usr/local/bin/gh",
        "/usr/bin/gh"
    ]
    
    func getAssignedPulls(completion:@escaping (([Edge]) -> Void)) -> Void {
        fetchPulls(by: "assignee", completion: completion)
    }
    
    func getCreatedPulls(completion:@escaping (([Edge]) -> Void)) -> Void {
        fetchPulls(by: "author", completion: completion)
    }
    
    func getReviewRequestedPulls(completion:@escaping (([Edge]) -> Void)) -> Void {
        fetchPulls(by: "review-requested", completion: completion)
    }
    
    private func buildGraphQlQuery(queryString: String) -> String {
        var build = ""
        
        switch Defaults[.buildType] {
        case .checks:
            build = """
        commits(last: 1) {
            nodes {
                commit {
                    checkSuites(first: 10) {
                        nodes {
                            app {
                                name
                            }
                            checkRuns(first: 10) {
                                totalCount
                                nodes {
                                    name
                                    conclusion
                                    detailsUrl
                                }
                            }
                        }
                    }
                }
            }
        }
        """
        case .commitStatus:
            build = """
        commits(last: 1) {
            nodes {
                commit {
                    statusCheckRollup {
                        state
                        contexts (first: 20) {
                            nodes {
                                ... on StatusContext {
                                    context
                                    description
                                    state
                                    targetUrl
                                    description
                                }
                                ... on CheckRun {
                                    name
                                    conclusion
                                    detailsUrl
                                    title
                                }
                            }
                        }
                    }
                }
            }
        }
        """
        default:
            build = ""
        }
        
        return """
        {
            search(query: "\(queryString)", type: ISSUE, first: 30) {
                issueCount
                edges {
                    node {
                        ... on PullRequest {
                            number
                            createdAt
                            updatedAt
                            title
                            headRefName
                            url
                            deletions
                            additions
                            isDraft
                            isReadByViewer
                            author {
                                login
                                avatarUrl
                            }
                            repository {
                                name
                            }
                             labels(first: 5) {
                                nodes {
                                  name
                                  color
                                }
                              }
                            reviews(states: APPROVED, first: 10) {
                                totalCount
                                edges {
                                    node {
                                        author {
                                            login
                                        }
                                    }
                                }
                            }
                            \(build)
                        }
                    }
                }
            }
        }
        """
    }
    
    func getUser(completion: @escaping (User?) -> Void) {
        ghCommandQueue.async {
            do {
                let output = try self.runGhCommand(arguments: ["api", "/user"])
                let user = try JSONDecoder().decode(User.self, from: output)
                DispatchQueue.main.async {
                    completion(user)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
    
    func getLatestRelease(completion:@escaping (((LatestRelease?) -> Void))) -> Void {
        ghCommandQueue.async {
            do {
                let output = try self.runGhCommand(arguments: ["api", "/repos/menubar-apps/PullBar/releases/latest"])
                let release = try JSONDecoder().decode(LatestRelease.self, from: output)
                DispatchQueue.main.async {
                    completion(release)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
    
    private func fetchPulls(by queryQualifier: String, completion: @escaping (([Edge]) -> Void)) {
        ghCommandQueue.async {
            do {
                let username = try self.resolveUsername()
                let query = "is:open is:pr \(queryQualifier):\(username) archived:false \(Defaults[.githubAdditionalQuery])"
                let graphQlQuery = self.buildGraphQlQuery(queryString: query)
                let output = try self.runGhCommand(arguments: ["api", "graphql", "-f", "query=\(graphQlQuery)"])
                let pulls = try GithubDecoder().decode(GraphQlSearchResp.self, from: output)
                DispatchQueue.main.async {
                    completion(pulls.data.search.edges)
                }
            } catch {
                sendNotification(body: error.localizedDescription)
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }
    }
    
    private func resolveUsername() throws -> String {
        let configured = Defaults[.githubUsername].trimmingCharacters(in: .whitespacesAndNewlines)
        if !configured.isEmpty {
            return configured
        }
        
        let output = try runGhCommand(arguments: ["api", "/user", "--jq", ".login"])
        guard let login = String(data: output, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines), !login.isEmpty else {
            throw GhCliError.invalidOutput
        }
        
        Defaults[.githubUsername] = login
        return login
    }
    
    private func runGhCommand(arguments: [String]) throws -> Foundation.Data {
        let process = Process()
        process.executableURL = try findGhExecutable()
        process.arguments = arguments
        
        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr
        
        try process.run()
        process.waitUntilExit()
        
        let output: Foundation.Data = stdout.fileHandleForReading.readDataToEndOfFile()
        let errorData: Foundation.Data = stderr.fileHandleForReading.readDataToEndOfFile()
        
        guard process.terminationStatus == 0 else {
            let errorMessage = String(data: errorData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            throw GhCliError.commandFailed(message: errorMessage ?? "gh command failed with status \(process.terminationStatus)")
        }
        
        return output
    }
    
    private func findGhExecutable() throws -> URL {
        let fileManager = FileManager.default
        for path in ghExecutables where fileManager.isExecutableFile(atPath: path) {
            return URL(fileURLWithPath: path)
        }
        
        throw GhCliError.missingCli
    }
}

enum GhCliError: LocalizedError {
    case missingCli
    case invalidOutput
    case commandFailed(message: String)
    
    var errorDescription: String? {
        switch self {
        case .missingCli:
            return "GitHub CLI was not found. Install gh and run `gh auth login`."
        case .invalidOutput:
            return "GitHub CLI returned an unexpected response."
        case .commandFailed(let message):
            return message
        }
    }
}

class GithubDecoder: JSONDecoder {
    let dateFormatter = DateFormatter()
    
    override init() {
        super.init()
        dateDecodingStrategy = .iso8601
    }
}
