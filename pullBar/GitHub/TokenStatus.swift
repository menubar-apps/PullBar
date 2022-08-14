//
//  TokenStatus.swift
//  pullBar
//
//  Created by Pavel Makhov on 2022-08-13.
//

import Foundation
import Defaults
import SwiftUI

class TokenStatus: ObservableObject {
    
    @Published var icon: String!
    @Published var color: NSColor!
    @Published var tooltip: String!
    
    init() {
        toStateLoading()
    }
    
    func toStateSuccess() {
        self.icon = "check-circle"
        self.color = NSColor(named: "green")!
        self.tooltip = "Token is valid"
    }
    
    func toStateFailure() {
        self.icon = "alert"
        self.color = NSColor(named: "yellow")!
        self.tooltip = "Token is invalid"
    }
    
    func toStateLoading() {
        self.icon = "issue-draft"
        self.color = NSColor.secondaryLabelColor
        self.tooltip = "Validating Token"
    }

    func checkStatus() {
        self.toStateLoading()
        
        GitHubClient().getUser() { user in
            if user != nil {
                self.toStateSuccess()
            } else {
                self.toStateFailure()
            }
        }
    }
    
}
