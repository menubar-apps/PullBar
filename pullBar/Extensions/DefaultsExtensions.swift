//
//  DefaultsExtensions.swift
//  issueBar
//
//  Created by Pavel Makhov on 2021-11-10.
//

import Foundation
import Defaults

extension Defaults.Keys {
    static let githubUsername = Key<String>("githubUsername", default: "")
    static let githubToken = Key<String>("githubToken", default: "")
    
    static let showAssigned = Key<Bool>("showAssigned", default: false)
    static let showCreated = Key<Bool>("showCreated", default: false)
    static let showRequested = Key<Bool>("showRequested", default: true)
    
    static let showAvatar = Key<Bool>("showAvatar", default: false)
    
    static let refreshRate = Key<Int>("refreshRate", default: 5)
}

