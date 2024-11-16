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
    
    @Default(.githubApiBaseUrl) var githubApiBaseUrl
    @Default(.githubUsername) var githubUsername
    @Default(.githubAdditionalQuery) var githubAdditionalQuery
    @FromKeychain(.githubToken) var githubToken

    @Default(.buildType) var buildType
    
    func getAssignedPulls(completion:@escaping (([Edge]) -> Void)) -> Void {
        
        if (githubUsername == "" || githubToken == "") {
            completion([Edge]())
        }
        
        let headers: HTTPHeaders = [
            .authorization(bearerToken: githubToken),
            .accept("application/json")
        ]
        
        let graphQlQuery = buildGraphQlQuery(queryString: "is:open is:pr assignee:\(githubUsername) archived:false \(githubAdditionalQuery)")
        
        let parameters = [
            "query": graphQlQuery,
            "variables":[]
        ] as [String: Any]
        
        AF.request(githubApiBaseUrl + "/graphql", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .validate(statusCode: 200..<300)
            .responseDecodable(of: GraphQlSearchResp.self, decoder: GithubDecoder()) { response in
                switch response.result {
                case .success(let prs):
                    completion(prs.data.search.edges)
                case .failure(let error):
                    sendNotification(body: error.localizedDescription)
                    completion([Edge]())
                    print(error)
                }
            }
    }
    
    func getCreatedPulls(completion:@escaping (([Edge]) -> Void)) -> Void {
        
        if (githubUsername == "" || githubToken == "") {
            completion([Edge]())
        }
        
        let headers: HTTPHeaders = [
            .authorization(bearerToken: githubToken),
            .accept("application/json")
        ]
        let graphQlQuery = buildGraphQlQuery(queryString: "is:open is:pr author:\(githubUsername) archived:false \(githubAdditionalQuery)")
        
        let parameters = [
            "query": graphQlQuery,
            "variables":[]
        ] as [String: Any]
        
        AF.request(githubApiBaseUrl + "/graphql", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .validate(statusCode: 200..<300)
            .responseDecodable(of: GraphQlSearchResp.self, decoder: GithubDecoder()) { response in
                switch response.result {
                case .success(let prs):
                    completion(prs.data.search.edges)
                case .failure(let error):
                    sendNotification(body: error.localizedDescription)
                    print(error)
                    completion([Edge]())
                }
            }
    }
    
    func getReviewRequestedPulls(completion:@escaping (([Edge]) -> Void)) -> Void {
        if (githubUsername == "" || githubToken == "") {
            completion([Edge]())
        }
        
        let headers: HTTPHeaders = [
            .authorization(bearerToken: githubToken),
            .accept("application/json")
        ]
        let graphQlQuery = buildGraphQlQuery(queryString: "is:open is:pr review-requested:\(githubUsername) archived:false \(githubAdditionalQuery)")
        
        let parameters = [
            "query": graphQlQuery,
            "variables":[]
        ] as [String: Any]
        
        AF.request(githubApiBaseUrl + "/graphql", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .validate(statusCode: 200..<300)
            .responseDecodable(of: GraphQlSearchResp.self, decoder: GithubDecoder()) { response in
                switch response.result {
                case .success(let prs):
                    completion(prs.data.search.edges)
                case .failure(let error):
                    sendNotification(body: error.localizedDescription)
                    completion([Edge]())
                }
            }
    }
    
    private func buildGraphQlQuery(queryString: String) -> String {
        
        var build = ""
        
        switch buildType {
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
        let headers: HTTPHeaders = [
            .authorization(bearerToken: githubToken),
            .contentType("application/json"),
            .accept("application/json")
        ]
        
        AF.request(githubApiBaseUrl + "/user",
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
            .authorization(username: githubUsername, password: githubToken),
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
