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
    
    func getAssignedPulls(completion:@escaping (([Edge]) -> Void)) -> Void {
        
        if (githubUsername == "" || githubToken == "") {
            completion([Edge]())
        }
        
        let headers: HTTPHeaders = [
            .authorization(username: githubUsername, password: githubToken),
            .accept("application/json")
        ]
        
        let graphQlQuery = buildGraphQlQuery(queryString: "is:open is:pr assignee:\(githubUsername)")
        
        let parameters = [
            "query": graphQlQuery,
            "variables":[]
        ] as [String: Any]
        
        AF.request("https://api.github.com/graphql", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .responseDecodable(of: GraphQlSearchResp.self, decoder: GithubDecoder()) { response in
                switch response.result {
                case .success(let prs):
                    completion(prs.data.search.edges)
                case .failure(let error):
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
            .authorization(username: githubUsername, password: githubToken),
            .accept("application/json")
        ]
        let graphQlQuery = buildGraphQlQuery(queryString: "is:open is:pr author:\(githubUsername)")
        
        let parameters = [
            "query": graphQlQuery,
            "variables":[]
        ] as [String: Any]
        
        AF.request("https://api.github.com/graphql", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .responseDecodable(of: GraphQlSearchResp.self, decoder: GithubDecoder()) { response in
                switch response.result {
                case .success(let prs):
                    completion(prs.data.search.edges)
                case .failure(let error):
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
            .authorization(username: githubUsername, password: githubToken),
            .accept("application/json")
        ]
        let graphQlQuery = buildGraphQlQuery(queryString: "is:open is:pr review-requested:\(githubUsername)")
        
        let parameters = [
            "query": graphQlQuery,
            "variables":[]
        ] as [String: Any]
        
        AF.request("https://api.github.com/graphql", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .responseDecodable(of: GraphQlSearchResp.self, decoder: GithubDecoder()) { response in
                switch response.result {
                case .success(let prs):
                    completion(prs.data.search.edges)
                case .failure(let error):
                    print(error)
                    completion([Edge]())
                }
            }
    }
    
    private func buildGraphQlQuery(queryString: String) -> String {
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
                }
              }
            }
          }
        }

        """
    }
}

class GithubDecoder: JSONDecoder {
    let dateFormatter = DateFormatter()

    override init() {
        super.init()
        dateDecodingStrategy = .iso8601
    }
}
