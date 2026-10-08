//
//  BitbucketClient.swift
//  pullBar
//
//  Client for the Bitbucket Data Center (Server) REST API at /rest/api/1.0.
//  Authentication is an HTTP access token (or password) sent via Basic auth
//  using the username that owns the token as the auth username.
//

import Foundation
import Defaults
import Alamofire
import KeychainAccess

public class BitbucketClient {

    @FromKeychain(.bitbucketToken) var bitbucketToken
    @FromKeychain(.bitbucketUsername) var bitbucketUsername

    private static let pageLimit = 50

    /// Fetches open pull requests for a category's role from Bitbucket's
    /// dashboard endpoint, following pagination until every page is collected.
    /// Bitbucket DC exposes a single `dashboard/pull-requests` resource that is
    /// filtered by the `role` query parameter (REVIEWER / AUTHOR / PARTICIPANT);
    /// the dashboard only returns pull requests the authenticated user is
    /// involved in.
    func getPulls(role: BitbucketRole, completion: @escaping (([BitbucketPull]) -> Void)) -> Void {

        if (bitbucketToken.isEmpty || bitbucketUsername.isEmpty) {
            completion([BitbucketPull]())
            return
        }

        guard let baseUrl = validatedBaseUrl() else {
            completion([BitbucketPull]())
            return
        }

        var accumulated: [BitbucketPull] = []
        fetchPullsPage(baseUrl: baseUrl, role: role, start: nil, accumulated: accumulated, completion: completion)
    }

    private func fetchPullsPage(baseUrl: URL, role: BitbucketRole, start: Int?, accumulated: [BitbucketPull], completion: @escaping (([BitbucketPull]) -> Void)) {
        var url = baseUrl
        url.appendPathComponent("rest/api/1.0/dashboard/pull-requests")

        var params: [String: String] = [
            "limit": String(Self.pageLimit),
            "state": "OPEN"
        ]
        if let dashboardRole = role.dashboardRole {
            params["role"] = dashboardRole
        }
        if let start = start {
            params["start"] = String(start)
        }

        AF.request(url,
                   method: .get,
                   parameters: params,
                   headers: headers(),
                   requestModifier: { $0.cachePolicy = .reloadIgnoringLocalCacheData })
            .validate(statusCode: 200..<300)
            .responseDecodable(of: DashboardResponse.self) { response in
                switch response.result {
                case .success(let dashboard):
                    var all = accumulated
                    all.append(contentsOf: dashboard.values)
                    if dashboard.isLastPage || dashboard.nextPageStart == nil {
                        completion(all)
                    } else {
                        self.fetchPullsPage(baseUrl: baseUrl, role: role, start: dashboard.nextPageStart, accumulated: all, completion: completion)
                    }
                case .failure(let error):
                    sendNotification(body: error.localizedDescription)
                    completion(accumulated)
                    print(error)
                }
            }
    }

    /// Checks whether the configured credentials authenticate against the
    /// Bitbucket server. Bitbucket Data Center has no `/users/current`
    /// endpoint, so validation probes the same dashboard resource the app
    /// actually uses; it always requires authentication.
    func validateCredentials(completion: @escaping (Result<Void, BitbucketAuthError>) -> Void) {
        if bitbucketToken.isEmpty || bitbucketUsername.isEmpty {
            completion(.failure(.missingCredentials))
            return
        }

        guard let baseUrl = validatedBaseUrl() else {
            completion(.failure(.invalidBaseUrl))
            return
        }

        var url = baseUrl
        url.appendPathComponent("rest/api/1.0/dashboard/pull-requests")

        AF.request(url,
                   method: .get,
                   parameters: ["limit": "1"],
                   headers: headers(),
                   requestModifier: { $0.cachePolicy = .reloadIgnoringLocalCacheData })
            .response { response in
                if let error = response.error {
                    completion(.failure(BitbucketAuthError.from(error: error)))
                    return
                }
                let statusCode = response.response?.statusCode ?? 0
                switch statusCode {
                case 200..<300:
                    completion(.success(()))
                case 401, 403:
                    completion(.failure(.unauthorized))
                default:
                    completion(.failure(.http(statusCode)))
                }
            }
    }

    /// Parses the configured base URL and requires a secure `https` origin with
    /// a non-empty host before any request (and its Basic credentials) is sent.
    /// A bare host without a scheme is normalized to `https://`.
    private func validatedBaseUrl() -> URL? {
        var raw = Defaults[.bitbucketBaseUrl].trimmingCharacters(in: .whitespacesAndNewlines)
        if !raw.isEmpty && !raw.contains("://") {
            raw = "https://" + raw
        }
        guard let url = URL(string: raw),
              url.scheme?.lowercased() == "https",
              let host = url.host, !host.isEmpty else {
            return nil
        }
        return url
    }

    /// A web URL for a pull request, used by the "open in browser" menu item.
    /// Prefers the canonical self link Bitbucket returns; falls back to
    /// reconstructing the path only when the project key and slug are present.
    static func webUrl(for pull: BitbucketPull, baseUrl: String) -> URL? {
        if let selfUrl = pull.url {
            return selfUrl
        }
        guard let projectKey = pull.toRef.repository.project?.key, !projectKey.isEmpty,
              let base = URL(string: baseUrl) else {
            return nil
        }
        var url = base
        url.appendPathComponent("projects")
        url.appendPathComponent(projectKey)
        url.appendPathComponent("repos")
        url.appendPathComponent(pull.toRef.repository.slug)
        url.appendPathComponent("pull-requests")
        url.appendPathComponent(String(pull.id))
        return url
    }

    private func headers() -> HTTPHeaders {
        var auth = "\(bitbucketUsername):\(bitbucketToken)"
        if let data = auth.data(using: .utf8) {
            auth = data.base64EncodedString()
        }
        return [
            .authorization("Basic \(auth)"),
            .accept("application/json"),
            .contentType("application/json")
        ]
    }
}

/// User-facing reasons credential validation can fail.
enum BitbucketAuthError: Error {
    case missingCredentials
    case invalidBaseUrl
    case unauthorized
    case http(Int)
    case network(String)

    static func from(error: Error) -> BitbucketAuthError {
        if let afError = error as? AFError, afError.isSessionTaskError {
            return .network(error.localizedDescription)
        }
        return .network(error.localizedDescription)
    }

    var message: String {
        switch self {
        case .missingCredentials:
            return "Enter your Bitbucket username and HTTP access token."
        case .invalidBaseUrl:
            return "Enter a valid server address, for example https://bitbucket.example.com."
        case .unauthorized:
            return "Authentication failed (401/403). Check the username and HTTP access token."
        case .http(let code):
            return "Server returned HTTP \(code). Check the base URL and try again."
        case .network(let detail):
            return "Could not reach the server: \(detail)"
        }
    }
}