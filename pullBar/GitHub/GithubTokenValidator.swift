//
//  TokenStatus.swift
//  pullBar
//
//  Created by Pavel Makhov on 2022-08-13.
//

import Foundation
import SwiftUI

class GithubTokenValidator: ObservableObject {

    @Published var iconName: String!
    @Published var iconColor: Color!
    @Published var errorMessage: String?

    init() {
        setLoading()
    }

    func setLoading() {
        self.iconName = "clock.fill"
        self.iconColor = Color(.systemGray)
        self.errorMessage = nil
    }

    func setInvalid(message: String? = nil) {
        self.iconName = "exclamationmark.circle.fill"
        self.iconColor = Color(.systemRed)
        self.errorMessage = message
    }

    func setValid() {
        self.iconName = "checkmark.circle.fill"
        self.iconColor = Color(.systemGreen)
        self.errorMessage = nil
    }

    func validate() {
        self.setLoading()

        BitbucketClient().validateCredentials() { result in
            switch result {
            case .success:
                self.setValid()
            case .failure(let error):
                self.setInvalid(message: error.message)
            }
        }
    }
}