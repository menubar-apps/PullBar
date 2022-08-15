//
//  GitHubClient.swift
//  issueBar
//
//  Created by Pavel Makhov on 2021-11-09.
//

import Foundation
import Defaults
import Alamofire

public class GitHubClient {
    
    @Default(.githubUsername) var githubUsername
    @Default(.githubToken) var githubToken
    
    @Default(.showChecks) var showChecks
    
    func getAssignedPulls(completion:@escaping (([Edge]) -> Void)) -> Void {
        
        if (githubUsername == "" || githubToken == "") {
            completion([Edge]())
        }
        
        let headers: HTTPHeaders = [
            .authorization(bearerToken: githubToken),
            .accept("application/json")
        ]
        
        let graphQlQuery = buildGraphQlQuery(queryString: "is:open is:pr assignee:\(githubUsername)")
        
        let parameters = [
            "query": graphQlQuery,
            "variables":[]
        ] as [String: Any]
        
        AF.request("https://api.github.com/graphql", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
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
        let graphQlQuery = buildGraphQlQuery(queryString: "is:open is:pr author:\(githubUsername)")
        
        let parameters = [
            "query": graphQlQuery,
            "variables":[]
        ] as [String: Any]
        
        AF.request("https://api.github.com/graphql", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
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
        let graphQlQuery = buildGraphQlQuery(queryString: "is:open is:pr review-requested:\(githubUsername)")
        
        let parameters = [
            "query": graphQlQuery,
            "variables":[]
        ] as [String: Any]
        
        AF.request("https://api.github.com/graphql", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
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
        
        let commits = """
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
                            \(showChecks ? commits : "")
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
        
        AF.request("https://api.github.com/user",
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
}

class GithubDecoder: JSONDecoder {
    let dateFormatter = DateFormatter()

    override init() {
        super.init()
        dateDecodingStrategy = .iso8601
    }
}
