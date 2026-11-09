//
//  GitHubClient.swift
//  issueBar
//
//  Created by Pavel Makhov on 2021-11-09.
//

import Foundation
import Defaults
import Alamofire
import KeychainAccess

public class GitHubClient {
    
    @FromKeychain(.githubToken) var githubToken
    
    /// Paginate the search so menu counters are not limited to the first 30 PRs.
    func getPulls(filter: String, completion: @escaping (Result<[Edge], Error>) -> Void) {
        let headers: HTTPHeaders = [.authorization(bearerToken: githubToken), .accept("application/json")]
        func fetch(after: String?, accumulated: [Edge]) {
            var variables: [String: Any] = ["searchQuery": "is:open is:pr \(filter) archived:false"]
            if let after = after { variables["after"] = after }
            let parameters: [String: Any] = ["query": self.buildGraphQlQuery(), "variables": variables]
            AF.request(Defaults[.githubApiBaseUrl] + "/graphql", method: .post,
                       parameters: parameters, encoding: JSONEncoding.default, headers: headers)
                .validate(statusCode: 200..<300)
                .responseDecodable(of: GraphQlSearchResp.self, decoder: GithubDecoder()) { response in
                    switch response.result {
                    case .failure(let error): completion(.failure(error))
                    case .success(let result):
                        if let error = result.errors?.first {
                            completion(.failure(GitHubQueryError(message: error.message)))
                            return
                        }
                        guard let search = result.data?.search else {
                            completion(.failure(GitHubQueryError(message: "GitHub returned no data.")))
                            return
                        }
                        // GitHub search cannot retrieve more than 1,000 results.
                        guard search.issueCount <= 1000 else {
                            completion(.failure(GitHubQueryError(message: "More than 1,000 PRs match this search.")))
                            return
                        }
                        let pulls = accumulated + search.edges
                        if search.pageInfo.hasNextPage {
                            guard let cursor = search.pageInfo.endCursor, cursor != after else {
                                completion(.failure(GitHubQueryError(message: "Incomplete GitHub search results.")))
                                return
                            }
                            fetch(after: cursor, accumulated: pulls)
                        } else {
                            var seen = Set<URL>()
                            completion(.success(pulls.filter { seen.insert($0.node.url).inserted }))
                        }
                    }
                }
        }
        fetch(after: nil, accumulated: [])
    }

    private func buildGraphQlQuery() -> String {
        """
        query($searchQuery: String!, $after: String) {
            search(query: $searchQuery, type: ISSUE, first: 25, after: $after) {
                issueCount
                pageInfo { hasNextPage endCursor }
                edges {
                    node {
                        ... on PullRequest {
                            number createdAt updatedAt title url isDraft isReadByViewer
                            mergeable mergeStateStatus reviewDecision
                            author { login avatarUrl }
                            repository { name: nameWithOwner }
                            labels(first: 5) { nodes { name color } }
                            reviews: latestOpinionatedReviews(first: 100) {
                                totalCount
                                edges { node { author { login } viewerDidAuthor state submittedAt } }
                            }
                            commentReviews: reviews(states: COMMENTED, last: 100) {
                                totalCount
                                edges { node { author { login } viewerDidAuthor state submittedAt } }
                            }
                            reviewThreads(first: 100) {
                                totalCount
                                nodes { isResolved }
                            }
                            commits(last: 1) {
                                nodes { commit {
                                    statusCheckRollup {
                                        state
                                        contexts(first: 100) {
                                            totalCount
                                            nodes {
                                                ... on StatusContext { context state targetUrl description }
                                                ... on CheckRun { name status conclusion detailsUrl title }
                                            }
                                        }
                                    }
                                } }
                            }
                        }
                    }
                }
            }
        }
        """
    }

    func getUser(completion: @escaping (User?) -> Void) {
        let headers: HTTPHeaders = [
            .authorization(bearerToken: githubToken),
            .contentType("application/json"),
            .accept("application/json")
        ]
        
        AF.request(Defaults[.githubApiBaseUrl] + "/user",
                   method: .get,
                   headers: headers)
        .validate(statusCode: 200..<300)
        .cacheResponse(using: ResponseCacher(behavior: .doNotCache))
        .responseDecodable(of: User.self) { response in
            switch response.result {
            case .success(let repo):
                completion(repo)
            case .failure(let error):
                completion(nil)
                print(error)
            }
        }
    }
    
    func getLatestRelease(completion:@escaping (((LatestRelease?) -> Void))) -> Void {
        let headers: HTTPHeaders = [
            .authorization(bearerToken: githubToken),
            .contentType("application/json"),
            .accept("application/json")
        ]
        AF.request("https://api.github.com/repos/menubar-apps/PullBar/releases/latest",
                   method: .get,
                   encoding: JSONEncoding.default,
                   headers: headers)
            .validate(statusCode: 200..<300)
            .responseDecodable(of: LatestRelease.self) { response in
                switch response.result {
                case .success(let latestRelease):
                    completion(latestRelease)
                case .failure(let error):
                    completion(nil)
                    if let data = response.data {
                        let json = String(data: data, encoding: String.Encoding.utf8)
//                            print("Failure Response: \(json)")
                    }
                    sendNotification(body: error.localizedDescription)
                }
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

struct GitHubQueryError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}
